from __future__ import annotations

import re
from dataclasses import dataclass
from typing import TYPE_CHECKING, Callable

from BaseClasses import CollectionState
from Options import OptionError
from worlds.generic.Rules import add_rule, set_rule

from . import data, options as options_module
from .locations import (
    MENU_REGION,
    entrance_name,
    region_name,
    region_of,
    selected_layouts,
    selected_locations,
)
from .options import (
    SectorLogic,
    blueprints_gating_layout,
    blueprints_in_start_inventory,
    blueprints_placed_early,
    goal_layouts,
)

if TYPE_CHECKING:  # pragma: no cover
    from . import FTLWorld


@dataclass(frozen=True)
class _SectorLogicTier:
    """(sector threshold, blueprints required from that sector on), increasing in both columns,
    plus how many blueprints the Flagship itself demands."""

    sectors: tuple[tuple[int, int], ...]
    flagship: int


SECTOR_LOGIC_TIERS: dict[int, _SectorLogicTier] = {
    SectorLogic.option_relaxed: _SectorLogicTier(sectors=(), flagship=0),
    SectorLogic.option_standard: _SectorLogicTier(sectors=((4, 2), (6, 4)), flagship=5),
    SectorLogic.option_strict: _SectorLogicTier(sectors=((3, 3), (5, 6), (7, 9)), flagship=11),
}

_LEVEL_NAMES: dict[int, str] = {
    value: key for key, value in SectorLogic.options.items() if value in SECTOR_LOGIC_TIERS
}


_REACH_SECTOR = re.compile(r"get to sector (\d+)", re.IGNORECASE)
_BEAT_THE_BOSS = re.compile(r"beat the boss", re.IGNORECASE)
_MENTIONS_A_SECTOR = re.compile(r"sector", re.IGNORECASE)

SECTOR_MENTIONED_WITHOUT_REACHING: tuple[str, ...] = (
    "ACH_FED_DIPLOMACY",
    "ACH_MANTIS_CREW_DEAD",
    "ACH_ROCK_CRYSTAL",
    "ACH_SLUG_NEBULA",
)

SYSTEMS_AN_ACHIEVEMENT_NEEDS: dict[str, tuple[str, ...]] = {
    "ACH_BOARDING_DRONE": ("drones",),
    "ACH_FED_PATIENCE": ("artillery",),
    "ACH_INVADE_SHIP": ("teleporter",),
    "ACH_LANIUS_ADVANCED": ("hacking", "mind", "battery"),
    "ACH_ONLY_DRONES": ("drones",),
    "ACH_ROBOTIC": ("drones",),
    "ACH_STEALTH_AVOID": ("cloaking",),
    "ACH_STEALTH_DESTROY": ("cloaking",),
}

SYSTEM_COUNT_AN_ACHIEVEMENT_NEEDS: dict[str, int] = {
    "ACH_FULL_ARSENAL": 11,
}

SYSTEMS_AN_ACHIEVEMENT_MAXES: dict[str, tuple[str, ...]] = {
    "ACH_BAD_DODGING": ("engines",),
    "ACH_ENERGY_POWER": ("oxygen", "engines", "shields", "weapons", "medbay"),
}

SYSTEMS_MENTIONED_WITHOUT_NEEDING: tuple[str, ...] = (
    "ACH_ENERGY_SHIELDS",
    "ACH_FED_UPGRADE",
    "ACH_NO_DRONES",
    "ACH_NO_UPGRADES",
    "ACH_PACIFIST",
    "ACH_ROCK_MISSILES",
    "ACH_SLUG_VISION",
)

MUTUALLY_EXCLUSIVE_SYSTEMS: tuple[frozenset[str], ...] = (frozenset({"medbay", "clonebay"}),)

_MENTIONS_A_SYSTEM = re.compile(
    r"drone|teleport|hacking|mind control|battery|cloak|sensors|artillery|clone bay|medbay|"
    r"engine|shield|weapons system|systems installed|power in systems|crew aboard",
    re.IGNORECASE,
)


def location_depth(location: data.Location) -> int:
    if location.group == data.GROUP_SECTORS:
        return location.sector or 0
    if location.group == data.GROUP_VICTORIES:
        return data.SECTOR_COUNT
    found = _REACH_SECTOR.search(location.description)
    return int(found.group(1)) if found else 0


def location_needs_flagship(location: data.Location) -> bool:
    if location.group == data.GROUP_VICTORIES:
        return True
    return bool(_BEAT_THE_BOSS.search(location.description))


def blueprints_for_sector(level: int, sector: int) -> int:
    required = 0
    for threshold, count in SECTOR_LOGIC_TIERS[level].sectors:
        if sector >= threshold:
            required = count
    return required


def blueprints_for_flagship(level: int) -> int:
    return max(SECTOR_LOGIC_TIERS[level].flagship, blueprints_for_sector(level, data.SECTOR_COUNT))


def blueprints_required(level: int, location: data.Location) -> int:
    required = blueprints_for_sector(level, location_depth(location))
    if location_needs_flagship(location):
        required = max(required, blueprints_for_flagship(level))
    return required


@dataclass(frozen=True)
class LogicPlan:

    sector_logic: int
    starting_blueprints: tuple[str, ...]
    early_blueprints: tuple[str, ...]
    progression_blueprints: frozenset[str]
    extra_ship_keys: tuple[str, ...]
    warnings: tuple[str, ...]


def plan(world: "FTLWorld") -> LogicPlan:
    options = world.options
    layouts = selected_layouts(options)

    starting_blueprints = blueprints_in_start_inventory(options, _start_ship_layouts(world))

    start_items = set(starting_blueprints)
    start_items.update(_free_ship_keys(world))

    asked = options.sector_logic.value if options.system_blueprints else SectorLogic.option_relaxed
    warnings: list[str] = []

    level = next(
        (candidate for candidate in range(asked, SectorLogic.option_relaxed - 1, -1)
         if _fits(world, candidate, start_items)),
        SectorLogic.option_relaxed,
    )
    if level != asked:
        warnings.append(
            f"sector logic lowered from \"{options.sector_logic.current_key}\" to "
            f"\"{_LEVEL_NAMES[level]}\": with these options the seed had too few checks "
            "reachable without blueprints to place the first items. "
            "Enable sectorsanity or ship achievements to keep the logic you asked for."
        )

    extra_keys = _relieve_with_free_keys(world, level, start_items)
    if extra_keys:
        start_items.update(extra_keys)
        warnings.append(
            f"{len(extra_keys)} ship key(s) granted up front ({', '.join(extra_keys)}): "
            "with these options every ship opens only a handful of checks, each behind its own "
            "key, and the fill had nowhere left to place the next ones. "
            "Widen sectorsanity or enable ship achievements to return those keys to the pool."
        )

    gating = {
        name
        for layout in layouts
        for name in blueprints_gating_layout(options, layout)
    }
    if level == SectorLogic.option_relaxed:
        progression = frozenset(gating) | blueprints_the_system_rules_read(options)
    else:
        progression = frozenset(data.BLUEPRINT_ITEM_NAMES.values())

    return LogicPlan(
        sector_logic=level,
        starting_blueprints=starting_blueprints,
        early_blueprints=_early_blueprints(world, level, start_items),
        progression_blueprints=progression,
        extra_ship_keys=extra_keys,
        warnings=tuple(warnings),
    )


def _relieve_with_free_keys(
    world: "FTLWorld", level: int, start_items: set[str]
) -> tuple[str, ...]:

    if _fits(world, level, start_items):
        return ()

    candidates = [
        data.SHIP_KEY_NAMES[layout.blueprint]
        for layout in selected_layouts(world.options)
        if layout.variant == 0 and data.SHIP_KEY_NAMES[layout.blueprint] not in start_items
    ]
    given: list[str] = []
    trial = set(start_items)
    for key in sorted(candidates):
        given.append(key)
        trial.add(key)
        if _fits(world, level, trial, already_free=len(given)):
            return tuple(given)
    return tuple(given)


def _free_ship_keys(world: "FTLWorld") -> tuple[str, ...]:
    ships = {world.start_ship.blueprint}
    ships.update(data.LAYOUTS_BY_BLUEPRINT[bp].ship for bp in data.ALWAYS_UNLOCKED_LAYOUTS)
    return tuple(data.SHIP_KEY_NAMES[ship] for ship in sorted(ships))


def _start_ship_layouts(world: "FTLWorld") -> tuple[data.Layout, ...]:
    unlocks = world.options.layout_unlocks
    return tuple(
        layout
        for layout in selected_layouts(world.options)
        if layout.ship == world.start_ship.blueprint
        and (layout.variant == 0 or unlocks == unlocks.option_vanilla)
    )


def _reachable_regions(world: "FTLWorld", start_items: set[str]) -> set[str]:
    reachable = {MENU_REGION}
    reachable.update(
        region_name(layout)
        for layout in selected_layouts(world.options)
        if start_items.issuperset(layout_requirements(world, layout))
    )
    return reachable


def _sphere_zero_room(world: "FTLWorld", level: int, start_items: set[str]) -> int:
    reachable = _reachable_regions(world, start_items)
    return sum(
        1
        for location in world.created_locations
        if region_of(location) in reachable and blueprints_required(level, location) == 0
    )


def _bootstrap_cost(world: "FTLWorld", start_items: set[str]) -> int:
    costs = [
        len(set(layout_requirements(world, layout)) - start_items)
        for layout in selected_layouts(world.options)
        if not start_items.issuperset(layout_requirements(world, layout))
    ]
    return min(costs, default=1)


def _fits(
    world: "FTLWorld", level: int, start_items: set[str], already_free: int = 0
) -> bool:

    if not _sphere_zero_room(world, level, start_items):
        return False

    margin = _bootstrap_cost(world, start_items)
    demands: dict[int, int] = {}
    for location in world.created_locations:
        demand = blueprints_required(level, location)
        demands[demand] = demands.get(demand, 0) + 1
    for demand in sorted(demands):
        if demand and sum(n for d, n in demands.items() if d < demand) < demand + margin:
            return False

    if demands.get(0, 0) < _progression_item_count(world, level) - already_free + margin:
        return False
    return True


def _progression_item_count(world: "FTLWorld", level: int) -> int:
    if level == SectorLogic.option_relaxed:
        progression_blueprints = {
            name
            for layout in selected_layouts(world.options)
            for name in blueprints_gating_layout(world.options, layout)
        }
        progression_blueprints |= blueprints_the_system_rules_read(world.options)
    else:
        progression_blueprints = set(data.BLUEPRINT_ITEM_NAMES.values())

    precollected = list(world.precollected_item_names)
    count = 0
    for item in world.enabled_items:
        if item.count == 0:
            continue
        copies = item.count
        while item.name in precollected and copies > 0:
            precollected.remove(item.name)
            copies -= 1
        if copies <= 0:
            continue
        promoted = (item.group == data.GROUP_SYSTEM_LEVELS
                    and item.system in systems_whose_levels_the_rules_read(world.options))
        if item.classification != "progression" and not promoted:
            continue
        if item.group == data.GROUP_BLUEPRINTS and item.name not in progression_blueprints:
            continue
        count += copies
    return count


def _early_blueprints(world: "FTLWorld", level: int, start_items: set[str]) -> tuple[str, ...]:
    room = _sphere_zero_room(world, level, start_items) - _bootstrap_cost(world, start_items)
    wanted = dict.fromkeys(
        [*_keystone_blueprints(world), *blueprints_placed_early(world.options)]
    )
    return tuple([name for name in wanted if name not in start_items][:max(0, room)])


def _keystone_blueprints(world: "FTLWorld") -> tuple[str, ...]:
    layouts = selected_layouts(world.options)
    gated: dict[str, int] = {}
    for layout in layouts:
        for name in blueprints_gating_layout(world.options, layout):
            gated[name] = gated.get(name, 0) + 1
    majority = [(count, name) for name, count in gated.items() if count * 2 > len(layouts)]
    return tuple(name for _, name in sorted(majority, reverse=True))


def layout_requirements(world: "FTLWorld", layout: data.Layout) -> tuple[str, ...]:
    unlocks = world.options.layout_unlocks
    names = [data.SHIP_KEY_NAMES[layout.ship]]
    if layout.variant > 0 and unlocks == unlocks.option_items:
        names.append(data.LAYOUT_ITEM_NAMES[layout.blueprint])
    names.extend(blueprints_gating_layout(world.options, layout))
    return tuple(names)


def _has_blueprints(player: int, count: int) -> Callable[[CollectionState], bool]:
    group = data.GROUP_BLUEPRINTS
    return lambda state: state.has_group(group, player, count)


def set_rules(world: "FTLWorld") -> None:
    player = world.player
    level = world.sector_logic_level
    layouts = selected_layouts(world.options)

    for layout in layouts:
        requirements = layout_requirements(world, layout)
        entrance = world.get_entrance(entrance_name(layout))
        set_rule(entrance, lambda state, names=requirements: state.has_all(names, player))

    for location in world.created_locations:
        count = blueprints_required(level, location)
        if count:
            set_rule(world.get_location(location.name), _has_blueprints(player, count))

    _set_system_rules(world, layouts)

    fleet = _location_of_achievement(world, "ACH_UNLOCK_ALL")
    if fleet is not None:
        keys = tuple(data.SHIP_KEY_NAMES.values())
        add_rule(world.get_location(fleet.name), lambda state: state.has_all(keys, player))

    goal_rule = _goal_rule(world)
    set_rule(world.get_location(world.goal_location_name), goal_rule)
    world.multiworld.completion_condition[player] = goal_rule


def systems_a_location_needs(location: data.Location) -> tuple[str, ...]:
    if location.group == data.GROUP_SYSTEMS and location.system is not None:
        return (location.system,)
    if location.achievement in SYSTEMS_AN_ACHIEVEMENT_NEEDS:
        return SYSTEMS_AN_ACHIEVEMENT_NEEDS[location.achievement]
    if location.achievement in SYSTEMS_AN_ACHIEVEMENT_MAXES:
        return SYSTEMS_AN_ACHIEVEMENT_MAXES[location.achievement]
    return ()


def _layouts_able_to_try(options, location: data.Location) -> tuple[data.Layout, ...]:
    layouts = selected_layouts(options)
    if location.ship is not None and location.layout is None:
        return tuple(layout for layout in layouts if layout.ship == location.ship)
    if location.layout is not None:
        return tuple(layout for layout in layouts if layout.blueprint == location.layout)
    return layouts


def _extra_system_groups(layout: data.Layout) -> list[frozenset[str]]:
    groups: list[frozenset[str]] = []
    taken = set(layout.start_systems)
    for system in layout.empty_slots:
        exclusive = next((group for group in MUTUALLY_EXCLUSIVE_SYSTEMS if system in group), None)
        if exclusive is None:
            groups.append(frozenset({system}))
            continue
        if exclusive & taken:
            continue
        groups.append(frozenset(exclusive & set(layout.empty_slots)))
        taken |= exclusive
    return groups


def blueprints_the_system_rules_read(options) -> frozenset[str]:
    if not options.system_blueprints:
        return frozenset()
    systems: set[str] = set()
    for location in selected_locations(options):
        systems.update(systems_a_location_needs(location))
        if location.achievement in SYSTEM_COUNT_AN_ACHIEVEMENT_NEEDS:
            for layout in _layouts_able_to_try(options, location):
                systems.update(layout.empty_slots)
    return frozenset(data.BLUEPRINT_ITEM_NAMES[system] for system in systems
                     if system in data.BLUEPRINT_ITEM_NAMES)


def systems_whose_levels_the_rules_read(options) -> frozenset[str]:
    if not options.progressive_systems:
        return frozenset()
    if options.systemsanity == options.systemsanity.option_every_level:
        return frozenset(data.SYSTEMS_BY_ID)
    systems: set[str] = set()
    for location in selected_locations(options):
        systems.update(SYSTEMS_AN_ACHIEVEMENT_MAXES.get(location.achievement or "", ()))
    return frozenset(systems)


def _system_rule(world: "FTLWorld", location: data.Location) -> Callable[[CollectionState], bool] | None:
    player = world.player
    options = world.options
    needed = systems_a_location_needs(location)
    count = SYSTEM_COUNT_AN_ACHIEVEMENT_NEEDS.get(location.achievement or "")
    if not needed and count is None:
        return None
    gated = bool(options.system_blueprints)

    paths: list[tuple[str, tuple[frozenset[str], ...], int]] = []
    for layout in _layouts_able_to_try(world.options, location):
        missing = [system for system in needed if system not in layout.start_systems]
        if any(system not in layout.empty_slots for system in missing):
            continue
        groups = [frozenset({system}) for system in missing]
        extra = 0
        if count is not None:
            extra = count - len(layout.start_systems)
            groups = _extra_system_groups(layout)
            if len(groups) < extra:
                continue
            if not gated:
                groups, extra = [], 0
        elif not gated:
            groups = []
        blueprints = tuple(
            frozenset(data.BLUEPRINT_ITEM_NAMES[system] for system in group) for group in groups
        )
        paths.append((region_name(layout), blueprints, extra if count is not None else len(blueprints)))

    if not paths:
        raise OptionError(
            f"FTL: {location.name!r} needs systems that none of the selected ships can get "
            f"({', '.join(needed) or count}). Allow more ship layouts or turn this check off."
        )

    def rule(state: CollectionState) -> bool:
        for region, groups, required in paths:
            if not state.can_reach_region(region, player):
                continue
            owned = sum(1 for group in groups if state.has_any(group, player))
            if owned >= required:
                return True
        return False

    return rule


def _set_system_rules(world: "FTLWorld", layouts) -> None:
    player = world.player
    options = world.options

    for location in world.created_locations:
        rule = _system_rule(world, location)
        if rule is not None:
            add_rule(world.get_location(location.name), rule)

        if not options.progressive_systems:
            continue
        if location.group == data.GROUP_SYSTEMS and location.system is not None:
            level = location.level or 1
            if level > 1:
                upgrade = f"Progressive {data.SYSTEMS_BY_ID[location.system].display}"
                add_rule(world.get_location(location.name),
                         lambda state, name=upgrade, count=level - 1:
                             state.has(name, player, count))
        for system in SYSTEMS_AN_ACHIEVEMENT_MAXES.get(location.achievement or "", ()):
            upgrade = f"Progressive {data.SYSTEMS_BY_ID[system].display}"
            count = data.SYSTEMS_BY_ID[system].max_level - 1
            add_rule(world.get_location(location.name),
                     lambda state, name=upgrade, count=count: state.has(name, player, count))


def _goal_rule(world: "FTLWorld") -> Callable[[CollectionState], bool]:
    player = world.player
    blueprints = blueprints_for_flagship(world.sector_logic_level)
    group = data.GROUP_BLUEPRINTS
    chosen = goal_layouts(world.options)

    requirement_sets = tuple(
        layout_requirements(world, layout)
        for layout in selected_layouts(world.options)
        if chosen is None or layout.blueprint in chosen
    )

    if chosen is None:
        needed = world.options.victories_required.value
    else:
        needed = len(requirement_sets)

    if needed < 1:
        raise OptionError(
            f"FTL ({world.player_name}): the goal requires no victory at all. The seed would be "
            "won before it is played."
        )

    archives = options_module.archives_required(world.options)

    def can_win(state: CollectionState) -> bool:
        if archives and not state.has(data.ARCHIVE_ITEM_NAME, player, archives):
            return False
        if blueprints and not state.has_group(group, player, blueprints):
            return False
        reached = 0
        for names in requirement_sets:
            if state.has_all(names, player):
                reached += 1
                if reached >= needed:
                    return True
        return reached >= needed

    return can_win


def validate_goal(world: "FTLWorld") -> None:
    available = {layout.blueprint for layout in selected_layouts(world.options)}
    chosen = goal_layouts(world.options)

    if chosen is None:
        wanted = world.options.victories_required.value
        if wanted > len(available):
            raise OptionError(
                f"FTL ({world.player_name}): the goal asks for {wanted} victories but this seed "
                f"only contains {len(available)} layouts. Lower victories_required, or widen "
                "ship_layouts."
            )
        return

    missing = sorted(
        data.LAYOUTS_BY_BLUEPRINT[blueprint].display
        for blueprint in chosen
        if blueprint not in available
    )
    if missing:
        raise OptionError(
            f"FTL ({world.player_name}): the goal names layouts that are not in the seed "
            f"({', '.join(missing)}). Widen ship_layouts, or remove them from victory_layouts."
        )


def _location_of_achievement(world: "FTLWorld", achievement: str) -> data.Location | None:
    for location in world.created_locations:
        if location.achievement == achievement:
            return location
    return None


def _check() -> None:
    available = len(data.SYSTEMS)
    for level, tier in SECTOR_LOGIC_TIERS.items():
        demands = [count for _, count in tier.sectors] + [tier.flagship]
        if max(demands, default=0) > available:
            raise ValueError(
                f"sector logic level {level} demands up to {max(demands)} blueprints but the "
                f"game only has {available} systems: the seed would be unbeatable."
            )
        thresholds = [threshold for threshold, _ in tier.sectors]
        counts = [count for _, count in tier.sectors]
        if thresholds != sorted(thresholds) or counts != sorted(counts):
            raise ValueError(f"the tiers of level {level} are not increasing: {tier}")

    for level in (SectorLogic.option_relaxed, SectorLogic.option_standard,
                  SectorLogic.option_strict):
        if level not in SECTOR_LOGIC_TIERS:
            raise ValueError(f"sector logic level {level} has no declared tiers")

    unclassified = sorted(
        location.achievement
        for location in data.LOCATIONS
        if location.achievement
        and _MENTIONS_A_SECTOR.search(location.description)
        and location_depth(location) == 0
        and location.achievement not in SECTOR_MENTIONED_WITHOUT_REACHING
    )
    if unclassified:
        raise ValueError(
            f"these achievements mention a sector but the rule cannot tell which one: "
            f"{unclassified}. Add the wording to _REACH_SECTOR, or the achievement to "
            "SECTOR_MENTIONED_WITHOUT_REACHING if it does not require going there."
        )

    handled = (set(SYSTEMS_AN_ACHIEVEMENT_NEEDS) | set(SYSTEM_COUNT_AN_ACHIEVEMENT_NEEDS)
               | set(SYSTEMS_AN_ACHIEVEMENT_MAXES) | set(SYSTEMS_MENTIONED_WITHOUT_NEEDING))
    unguarded = sorted(
        location.achievement
        for location in data.LOCATIONS
        if location.achievement
        and _MENTIONS_A_SYSTEM.search(location.description)
        and location.achievement not in handled
    )
    if unguarded:
        raise ValueError(
            f"these achievements mention a system but the rule does not say which one is "
            f"needed: {unguarded}. Put them in SYSTEMS_AN_ACHIEVEMENT_NEEDS, "
            "SYSTEM_COUNT_AN_ACHIEVEMENT_NEEDS or SYSTEMS_AN_ACHIEVEMENT_MAXES, or in "
            "SYSTEMS_MENTIONED_WITHOUT_NEEDING if they need none."
        )
    for systems in (*SYSTEMS_AN_ACHIEVEMENT_NEEDS.values(), *SYSTEMS_AN_ACHIEVEMENT_MAXES.values()):
        for system in systems:
            if system not in data.SYSTEMS_BY_ID:
                raise ValueError(f"rules.py cites an unknown system: {system}")

    known = {location.achievement for location in data.LOCATIONS}
    cited = (set(SECTOR_MENTIONED_WITHOUT_REACHING) | {"ACH_UNLOCK_ALL"} | handled)
    unknown = sorted(name for name in cited if name not in known)
    if unknown:
        raise ValueError(f"rules.py cites achievements that do not exist in ftl.dat: {unknown}")

    if not any(location_depth(location) == data.SECTOR_COUNT for location in data.LOCATIONS
               if location.group == data.GROUP_GENERAL_ACHIEVEMENTS):
        raise ValueError("no general achievement requires sector 8 anymore: is the reading broken?")
    if not any(location_needs_flagship(location) for location in data.LOCATIONS
               if location.group == data.GROUP_GENERAL_ACHIEVEMENTS):
        raise ValueError("no general achievement requires a victory anymore: is the reading broken?")


_check()
