from __future__ import annotations

import collections
import re
from dataclasses import dataclass
from typing import TYPE_CHECKING, Callable

from BaseClasses import CollectionState
from Options import OptionError
from worlds.generic.Rules import add_rule, set_rule

from . import data, options as options_module
from .locations import (
    MENU_REGION,
    ship_systems,
    entrance_name,
    region_name,
    region_of,
    selected_layouts,
    selected_locations,
)
from .options import (
    SectorLogic,
    VictoryDifficulty,
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
    SectorLogic.option_none: _SectorLogicTier(sectors=(), flagship=0),
    SectorLogic.option_standard: _SectorLogicTier(sectors=((4, 2), (6, 4)), flagship=5),
    SectorLogic.option_strict: _SectorLogicTier(sectors=((3, 3), (5, 6), (7, 9)), flagship=11),
    SectorLogic.option_power: _SectorLogicTier(sectors=(), flagship=0),
}

# Power sector logic: what the ship doing a check must have, by Victory Difficulty, in shield layers (2 levels
# each) and system levels. "boss" is the Flagship and the victories.
POWER_MILESTONES: dict[int, dict[int | str, dict[str, int]]] = {
    VictoryDifficulty.option_any: {
        5: {"layers": 2},
        8: {"layers": 2, "weapons": 4},
        "boss": {"layers": 2, "weapons": 5, "engines": 3},
    },
    VictoryDifficulty.option_normal: {
        5: {"layers": 2},
        8: {"layers": 2, "weapons": 5},
        "boss": {"layers": 3, "weapons": 6, "engines": 4},
    },
    VictoryDifficulty.option_hard: {
        5: {"layers": 2},
        8: {"layers": 3, "weapons": 5},
        "boss": {"layers": 4, "weapons": 7, "engines": 4},
    },
}
# A ship that starts without shields trades one layer for engines at this level, except for the Flagship.
SHIELDLESS_ENGINES = 5

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


# How deep a run usually goes before a first crew member of each race joins: Lanius are rare before sector 5.
CREW_RACE_DEPTH: dict[str, int] = {"human": 0, "engi": 3, "energy": 3, "mantis": 3, "rock": 4, "slug": 4,
                                   "anaerobic": 5}


def location_depth(location: data.Location, shop_by_sector: bool = False) -> int:
    if shop_by_sector and location.shop_slot is not None:
        return data.shop_sector(location.shop_slot)
    if location.group == data.GROUP_CREW:
        return CREW_RACE_DEPTH[location.race]
    if location.group in (data.GROUP_SECTORS, data.GROUP_SECTOR_FIGHTS):
        return location.sector or 0
    if location.group == data.GROUP_FIGHTS:
        # A run wins about four fights per sector: the tenth one is a third-sector check.
        return (location.fight + 3) // 4
    if location.group == data.GROUP_EVENTS:
        # Archipelago events show up about twice a sector.
        return min(data.SECTOR_COUNT, (location.fight + 1) // 2)
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


def blueprints_required(level: int, location: data.Location, shop_by_sector: bool = False) -> int:
    required = blueprints_for_sector(level, location_depth(location, shop_by_sector))
    if location_needs_flagship(location):
        required = max(required, blueprints_for_flagship(level))
    return required


def power_milestones_apply(level: int, options) -> bool:
    """power always reads the milestones. standard and strict add them to their blueprints once Progressive System
    Upgrades caps the levels: otherwise five blueprints could send a ship with one shield layer to the Flagship."""
    if level == SectorLogic.option_power:
        return True
    return bool(options.progressive_systems) and level in (SectorLogic.option_standard, SectorLogic.option_strict)


def power_milestone(options, level: int, location: data.Location,
                    shop_by_sector: bool = False) -> int | str | None:
    if not power_milestones_apply(level, options):
        return None
    if location_needs_flagship(location):
        return "boss"
    depth = location_depth(location, shop_by_sector)
    return 8 if depth >= 8 else 5 if depth >= 5 else None


def _logic_demand(options, level: int, location: data.Location, shop_by_sector: bool) -> int:
    """What a check asks before the first items: its blueprint count, and at least 1 for a power milestone."""
    required = blueprints_required(level, location, shop_by_sector)
    if power_milestone(options, level, location, shop_by_sector) is not None:
        return max(required, 1)
    return required


def power_wanted(options, milestone: int | str, layout: data.Layout) -> dict[str, int]:
    wanted = dict(POWER_MILESTONES[options.victory_difficulty.value][milestone])
    if milestone != "boss" and data.LAYOUT_START_LEVELS[layout.blueprint]["shields"] == 0:
        wanted["layers"] -= 1
        wanted["engines"] = max(wanted.get("engines", 0), SHIELDLESS_ENGINES)
    return wanted


def system_level(options, state: CollectionState, player: int, system: str, layout: data.Layout) -> int:
    """The highest level of a system this layout may have with what was received: its start level, or 1 once
    a place and the blueprint allow buying it, then one level per Progressive item (all of them with Full
    System Upgrades). Without Progressive items, levels are bought with scrap and never capped."""
    spec = data.SYSTEMS_BY_ID[system]
    base = data.LAYOUT_START_LEVELS[layout.blueprint][system]
    if base == 0:
        if system not in layout.empty_slots:
            return 0
        if options.system_blueprints and not state.has(data.BLUEPRINT_ITEM_NAMES[system], player):
            return 0
        base = 1
    if not options.progressive_systems:
        return spec.max_level
    if options.progressive_systems_per_ship:
        ship = data.SHIPS_BY_BLUEPRINT[layout.ship].display
        got = state.count(f"{ship}: Progressive {spec.display}", player)
    else:
        got = state.count(f"Progressive {spec.display}", player)
    if options.full_system_upgrades and got:
        return spec.max_level
    return min(base + got, spec.max_level)


def meets_power(options, state: CollectionState, player: int, layout: data.Layout,
                wanted: dict[str, int]) -> bool:
    for stat, needed in wanted.items():
        if stat == "layers":
            have = system_level(options, state, player, "shields", layout) // 2
        else:
            have = system_level(options, state, player, stat, layout)
        if have < needed:
            return False
    return True


def _power_rule(world: "FTLWorld", location: data.Location,
                milestone: int | str) -> Callable[[CollectionState], bool]:
    """In logic once one reachable layout able to do the check meets the milestone."""
    player = world.player
    options = world.options
    paths = tuple((layout, region_name(layout), power_wanted(options, milestone, layout))
                  for layout in _layouts_able_to_try(options, location))

    def rule(state: CollectionState) -> bool:
        return any(meets_power(options, state, player, layout, wanted) and state.can_reach_region(region, player)
                   for layout, region, wanted in paths)

    return rule


def power_upgrade_names(options) -> frozenset[str]:
    """The items the power logic reads: Progressive levels of its systems, and the Shields blueprint for the
    ships that start without shields."""
    if not power_milestones_apply(options.sector_logic.value, options):
        return frozenset()
    names: set[str] = set()
    layouts = selected_layouts(options)
    for system in data.POWER_SYSTEMS:
        display = data.SYSTEMS_BY_ID[system].display
        if options.progressive_systems and options.progressive_systems_per_ship:
            names.update(f"{data.SHIPS_BY_BLUEPRINT[ship].display}: Progressive {display}"
                         for ship in {layout.ship for layout in layouts})
        elif options.progressive_systems:
            names.add(f"Progressive {display}")
    if options.system_blueprints:
        names.update(data.BLUEPRINT_ITEM_NAMES[system] for layout in layouts for system in data.POWER_SYSTEMS
                     if data.LAYOUT_START_LEVELS[layout.blueprint][system] == 0 and system in layout.empty_slots)
    return frozenset(names)


@dataclass(frozen=True)
class LogicPlan:

    sector_logic: int
    starting_blueprints: tuple[str, ...]
    early_blueprints: tuple[str, ...]
    progression_blueprints: frozenset[str]
    extra_ship_keys: tuple[str, ...]
    early_ship_keys: tuple[str, ...]
    warnings: tuple[str, ...]


def plan(world: "FTLWorld") -> LogicPlan:
    options = world.options
    layouts = selected_layouts(options)

    starting_blueprints = blueprints_in_start_inventory(options, _start_ship_layouts(world))

    start_items = set(starting_blueprints)
    start_items.update(_free_ship_keys(world))

    asked = options.sector_logic.value
    if not options.system_blueprints and asked != SectorLogic.option_power:
        # Nothing left to count, but capped levels still need their milestones. none asked for nothing.
        milestones = options.progressive_systems and asked in (SectorLogic.option_standard, SectorLogic.option_strict)
        asked = SectorLogic.option_power if milestones else SectorLogic.option_none
    warnings: list[str] = []

    candidates = ((asked, SectorLogic.option_none) if asked == SectorLogic.option_power
                  else range(asked, SectorLogic.option_none - 1, -1))
    level = next(
        (candidate for candidate in candidates if _fits(world, candidate, start_items)),
        SectorLogic.option_none,
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
    if level in (SectorLogic.option_none, SectorLogic.option_power):
        progression = (frozenset(gating) | blueprints_the_system_rules_read(options)
                       | (power_upgrade_names(options) & frozenset(data.BLUEPRINT_ITEM_NAMES.values())))
    else:
        progression = frozenset(data.BLUEPRINT_ITEM_NAMES.values())

    early_keys = _early_ship_keys(world, level, start_items)
    if len(early_keys) < options.early_ship_keys.value and len(early_keys) < len(_early_key_candidates(world, start_items)):
        warnings.append(
            f"early_ship_keys lowered from {options.early_ship_keys.value} to {len(early_keys)}: "
            "only that many checks can be reached from the very start. "
            "Enable sectorsanity or ship achievements to place more keys early."
        )

    return LogicPlan(
        sector_logic=level,
        starting_blueprints=starting_blueprints,
        early_blueprints=_early_blueprints(world, level, start_items, len(early_keys)),
        progression_blueprints=progression,
        extra_ship_keys=extra_keys,
        early_ship_keys=early_keys,
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
        if _met_at_start(start_items, layout_requirements(world, layout))
    )
    return reachable


def _sphere_zero_room(world: "FTLWorld", level: int, start_items: set[str]) -> int:
    reachable = _reachable_regions(world, start_items)
    return sum(
        1
        for location in world.created_locations
        if region_of(location, world.options) in reachable
        and _logic_demand(world.options, level, location, bool(world.options.shop_by_sector)) == 0
    )


def _bootstrap_cost(world: "FTLWorld", start_items: set[str]) -> int:
    costs = [
        _missing_at_start(start_items, layout_requirements(world, layout))
        for layout in selected_layouts(world.options)
        if not _met_at_start(start_items, layout_requirements(world, layout))
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
        if location.group in data.FILLER_ONLY_GROUPS:
            continue
        demand = _logic_demand(world.options, level, location, bool(world.options.shop_by_sector))
        demands[demand] = demands.get(demand, 0) + 1
    for demand in sorted(demands):
        if demand and sum(n for d, n in demands.items() if d < demand) < demand + margin:
            return False

    if demands.get(0, 0) < _progression_item_count(world, level) - already_free + margin:
        return False
    return True


def _progression_item_count(world: "FTLWorld", level: int) -> int:
    if level in (SectorLogic.option_none, SectorLogic.option_power):
        progression_blueprints = {
            name
            for layout in selected_layouts(world.options)
            for name in blueprints_gating_layout(world.options, layout)
        }
        progression_blueprints |= blueprints_the_system_rules_read(world.options)
        progression_blueprints |= power_upgrade_names(world.options)
    else:
        progression_blueprints = set(data.BLUEPRINT_ITEM_NAMES.values())

    precollected = list(world.precollected_item_names)
    count = 0
    for item in world.enabled_items:
        if item.count == 0:
            continue
        copies = options_module.item_copies(world.options, item)
        while item.name in precollected and copies > 0:
            precollected.remove(item.name)
            copies -= 1
        if copies <= 0:
            continue
        promoted = ((item.group == data.GROUP_SYSTEM_LEVELS
                     and item.system in systems_whose_levels_the_rules_read(world.options))
                    or (item.group == data.GROUP_SHIP_SYSTEM_LEVELS
                        and item.name in upgrades_the_rules_read(world)))
        if item.classification != "progression" and not promoted:
            continue
        if item.group == data.GROUP_BLUEPRINTS and item.name not in progression_blueprints:
            continue
        count += copies
    return count


def _early_key_candidates(world: "FTLWorld", start_items: set[str]) -> list[str]:
    return sorted(
        data.SHIP_KEY_NAMES[layout.blueprint]
        for layout in selected_layouts(world.options)
        if layout.variant == 0 and data.SHIP_KEY_NAMES[layout.blueprint] not in start_items
    )


def _early_ship_keys(world: "FTLWorld", level: int, start_items: set[str]) -> tuple[str, ...]:
    """Type A keys put in the player's own first checks, so a second ship does not hang on the luck of the fill."""
    candidates = _early_key_candidates(world, start_items)
    wanted = min(world.options.early_ship_keys.value, len(candidates), _sphere_zero_room(world, level, start_items))
    return tuple(sorted(world.random.sample(candidates, wanted)))


def _early_blueprints(
    world: "FTLWorld", level: int, start_items: set[str], taken: int = 0
) -> tuple[str, ...]:
    room = _sphere_zero_room(world, level, start_items) - _bootstrap_cost(world, start_items) - taken
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


def _has_requirements(state: CollectionState, names: tuple[str, ...], player: int) -> bool:
    """A name listed twice asks for two copies (progressive ship keys)."""
    if len(set(names)) == len(names):
        return state.has_all(names, player)
    return state.has_all_counts(collections.Counter(names), player)


def _met_at_start(start_items: set[str], names: tuple[str, ...]) -> bool:
    """The start items hold one copy of each: a name asked twice is not met."""
    return _missing_at_start(start_items, names) == 0


def _missing_at_start(start_items: set[str], names: tuple[str, ...]) -> int:
    return sum(max(0, count - (name in start_items)) for name, count in collections.Counter(names).items())


def layout_requirements(world: "FTLWorld", layout: data.Layout) -> tuple[str, ...]:
    unlocks = world.options.layout_unlocks
    independent = unlocks == unlocks.option_independent
    key = data.SHIP_KEY_NAMES[layout.ship]
    names = [] if layout.variant > 0 and independent else [key]
    if unlocks == unlocks.option_progressive:
        # The nth copy of the key gives the nth layout: the name repeats once per copy needed.
        copies = 1 + options_module.progressive_layouts(world.options, layout.ship).index(layout)
        names = [key] * copies
    elif layout.variant > 0 and unlocks != unlocks.option_vanilla:
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
        set_rule(entrance, lambda state, names=requirements: _has_requirements(state, names, player))

    for location in world.created_locations:
        count = blueprints_required(level, location, bool(world.options.shop_by_sector))
        if count:
            set_rule(world.get_location(location.name), _has_blueprints(player, count))
        milestone = power_milestone(world.options, level, location, bool(world.options.shop_by_sector))
        if milestone is not None:
            add_rule(world.get_location(location.name), _power_rule(world, location, milestone))

    _set_system_rules(world, layouts)

    fleet = _location_of_achievement(world, "ACH_UNLOCK_ALL")
    if fleet is not None:
        keys = tuple(data.SHIP_KEY_NAMES.values())
        add_rule(world.get_location(fleet.name), lambda state: state.has_all(keys, player))

    goal_rule = _goal_rule(world)
    set_rule(world.get_location(world.goal_location_name), goal_rule)
    world.multiworld.completion_condition[player] = goal_rule


def systems_a_location_needs(location: data.Location) -> tuple[str, ...]:
    if location.group in (data.GROUP_SYSTEMS, data.GROUP_SHIP_SYSTEMS) and location.system is not None:
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
    if power_milestones_apply(options.sector_logic.value, options) and not options.progressive_systems_per_ship:
        systems.update(data.POWER_SYSTEMS)
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
        upgrades = _upgrades_needed(options, location)
        if upgrades:
            add_rule(world.get_location(location.name), _upgrade_rule(world, location, upgrades))
            continue

        rule = _system_rule(world, location)
        if rule is not None:
            add_rule(world.get_location(location.name), rule)


def _upgrades_needed(options, location: data.Location) -> dict[str, int]:
    if not options.progressive_systems:
        return {}
    needed: dict[str, int] = {}
    if location.group == data.GROUP_SYSTEMS and location.system is not None and (location.level or 1) > 1:
        needed[location.system] = (location.level or 1) - 1
    for system in SYSTEMS_AN_ACHIEVEMENT_MAXES.get(location.achievement or "", ()):
        needed[system] = data.SYSTEMS_BY_ID[system].max_level - 1
    return needed


# With upgrades per ship, the logic counts on one ship: the achievement's own, or else the starting ship. That
# same ship must hold the blueprints and the upgrades, or a check could be counted on two half ships.
def _upgrade_ships(world: "FTLWorld", location: data.Location, systems) -> tuple[str, ...]:
    room = ship_systems(world.options)
    ship = location.ship or world.start_ship.blueprint
    if all(system in room.get(ship, ()) for system in systems):
        return (ship,)
    return tuple(other for other in room if all(system in room[other] for system in systems))


def start_level(layout: data.Layout, system: str) -> int:
    """The level a layout starts a system at: read from ftl.dat for the power systems, else 1 if aboard."""
    known = data.LAYOUT_START_LEVELS[layout.blueprint].get(system)
    if known is not None:
        return known
    return 1 if system in layout.start_systems else 0


def _upgrade_rule(world: "FTLWorld", location: data.Location,
                  upgrades: dict[str, int]) -> Callable[[CollectionState], bool]:
    """In logic on one reachable layout holding the systems: the levels it starts with count, a bought system
    starts at 1, and each Progressive item adds one (all of them with Full System Upgrades)."""
    player = world.player
    options = world.options
    gated = bool(options.system_blueprints)
    per_ship = bool(options.progressive_systems_per_ship)
    ships = _upgrade_ships(world, location, upgrades) if per_ship else None
    paths = []
    for layout in _layouts_able_to_try(options, location):
        if ships is not None and layout.ship not in ships:
            continue
        room = set(layout.start_systems) | set(layout.empty_slots)
        if not all(system in room for system in upgrades):
            continue
        missing = [system for system in upgrades if system not in layout.start_systems]
        blueprints = tuple(data.BLUEPRINT_ITEM_NAMES[system] for system in missing) if gated else ()
        prefix = f"{data.SHIPS_BY_BLUEPRINT[layout.ship].display}: " if per_ship else ""
        needs = []
        for system, count in upgrades.items():
            count = max(0, count - max(0, start_level(layout, system) - 1))
            if count and options.full_system_upgrades:
                count = 1
            if count:
                needs.append((f"{prefix}Progressive {data.SYSTEMS_BY_ID[system].display}", count))
        paths.append((region_name(layout), blueprints, tuple(needs)))

    if not paths:
        raise OptionError(
            f"FTL: {location.name!r} needs upgrades that none of the selected ships can hold. Allow more ship "
            "layouts or turn this check off."
        )

    def rule(state: CollectionState) -> bool:
        return any(
            state.can_reach_region(region, player) and state.has_all(blueprints, player)
            and all(state.has(name, player, count) for name, count in needs)
            for region, blueprints, needs in paths
        )

    return rule


def upgrades_the_rules_read(world: "FTLWorld") -> frozenset[str]:
    cached = getattr(world, "_ftl_upgrades_read", None)
    if cached is not None and cached[0] is world.created_locations:
        return cached[1]
    names: set[str] = set()
    for location in world.created_locations:
        upgrades = _upgrades_needed(world.options, location)
        for ship in _upgrade_ships(world, location, upgrades) if upgrades else ():
            display = data.SHIPS_BY_BLUEPRINT[ship].display
            names.update(f"{display}: Progressive {data.SYSTEMS_BY_ID[system].display}" for system in upgrades)
    if world.options.progressive_systems_per_ship:
        names.update(name for name in power_upgrade_names(world.options) if ": Progressive " in name)
    world._ftl_upgrades_read = (world.created_locations, frozenset(names))
    return world._ftl_upgrades_read[1]


def _goal_rule(world: "FTLWorld") -> Callable[[CollectionState], bool]:
    player = world.player
    blueprints = blueprints_for_flagship(world.sector_logic_level)
    group = data.GROUP_BLUEPRINTS
    chosen = goal_layouts(world.options)

    goal_candidates = tuple(
        layout for layout in selected_layouts(world.options)
        if chosen is None or layout.blueprint in chosen
    )
    requirement_sets = tuple(layout_requirements(world, layout) for layout in goal_candidates)
    options = world.options
    # With power milestones, a victory counts only on a layout ready for the Flagship.
    flagship_ready = tuple(
        power_wanted(options, "boss", layout) if power_milestones_apply(world.sector_logic_level, options) else None
        for layout in goal_candidates
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
        for layout, names, wanted in zip(goal_candidates, requirement_sets, flagship_ready):
            if _has_requirements(state, names, player) and (wanted is None
                                                 or meets_power(options, state, player, layout, wanted)):
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

    for level in (SectorLogic.option_none, SectorLogic.option_standard,
                  SectorLogic.option_strict, SectorLogic.option_power):
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

    for difficulty, table in POWER_MILESTONES.items():
        for milestone, wanted in table.items():
            for stat, needed in wanted.items():
                system = "shields" if stat == "layers" else stat
                top = data.SYSTEMS_BY_ID[system].max_level // (2 if stat == "layers" else 1)
                if system not in data.POWER_SYSTEMS or not 0 < needed <= top:
                    raise ValueError(f"power milestone {difficulty}/{milestone} asks {stat} {needed}")

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
