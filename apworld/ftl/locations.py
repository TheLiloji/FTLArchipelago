from __future__ import annotations

from BaseClasses import Location

from . import data
from .options import apply_sector_floor


class FTLLocation(Location):
    game = data.GAME_NAME


MENU_REGION = "Menu"

GOAL_LOCATION = "Mission Accomplished"

MILESTONE_SECTORS = (5, 8)

_ACHIEVEMENT_TIERS_BY_LEVEL: dict[int, tuple[str, ...]] = {
    0: (),
    1: (data.TIER_GENERAL,),
    2: (data.TIER_GENERAL, data.TIER_DISTANCE),
    3: (data.TIER_GENERAL, data.TIER_DISTANCE, data.TIER_FEATS, data.TIER_DIFFICULTY),
}

LOCATION_NAME_TO_ID: dict[str, int] = {loc.name: loc.code for loc in data.LOCATIONS}


def region_name(layout: data.Layout) -> str:
    return layout.display


def entrance_name(layout: data.Layout) -> str:
    return f"Fly the {layout.display}"


def allowed_layouts(options) -> tuple[data.Layout, ...]:
    if options.ship_layouts == options.ship_layouts.option_type_a_only:
        highest_variant = 0
    elif options.ship_layouts == options.ship_layouts.option_up_to_type_b:
        highest_variant = 1
    else:
        highest_variant = 2
    return tuple(layout for layout in data.LAYOUTS if layout.variant <= highest_variant)


def selected_layouts(options) -> tuple[data.Layout, ...]:
    drawn = getattr(options, "drawn_layouts", None)
    return tuple(layout for layout in allowed_layouts(options) if drawn is None or layout.blueprint in drawn)


def selected_ships(options) -> frozenset[str]:
    return frozenset(layout.ship for layout in selected_layouts(options))


def available_systems(options) -> frozenset[str]:
    return frozenset(system for layout in selected_layouts(options)
                     for system in (*layout.start_systems, *layout.empty_slots))


def ship_systems(options) -> dict[str, set[str]]:
    room: dict[str, set[str]] = {}
    for layout in selected_layouts(options):
        room.setdefault(layout.ship, set()).update(layout.start_systems, layout.empty_slots)
    return room


def draw_layouts(options, rng, forced: tuple[str, ...], wanted: int) -> frozenset[str] | None:
    # A Type B or C only comes with its ship's Type A: the hangar opens a ship by its Type A.
    allowed = allowed_layouts(options)
    if wanted >= len(allowed):
        return None
    picked = set(forced)
    picked.update(data.LAYOUTS_BY_BLUEPRINT[blueprint].ship for blueprint in forced)
    while len(picked) < wanted:
        eligible = [
            layout.blueprint for layout in allowed
            if layout.blueprint not in picked and (layout.variant == 0 or layout.ship in picked)
        ]
        picked.add(rng.choice(eligible))
    return frozenset(picked)


def selected_sectors(options) -> tuple[int, ...]:
    if options.sectorsanity == options.sectorsanity.option_disabled:
        return ()
    if options.sectorsanity == options.sectorsanity.option_milestones:
        chosen: tuple[int, ...] = MILESTONE_SECTORS
    else:
        chosen = tuple(range(1, data.SECTOR_COUNT + 1))
    return apply_sector_floor(options, chosen)


def selected_locations(options) -> tuple[data.Location, ...]:
    layouts = {layout.blueprint for layout in selected_layouts(options)}
    ships = selected_ships(options)
    every_ship = len(ships) == len(data.SHIPS)
    systems = available_systems(options)
    per_ship = bool(options.systemsanity_per_ship)
    ship_room = ship_systems(options)
    ship_start: dict[str, set[str]] = {}
    for layout in selected_layouts(options):
        ship_start.setdefault(layout.ship, set()).update(layout.start_systems)
    sectors = set(selected_sectors(options))
    tiers = set(_ACHIEVEMENT_TIERS_BY_LEVEL[options.general_achievements.value])
    cross_run = bool(options.cross_run_achievements)

    kept: list[data.Location] = []
    for location in data.LOCATIONS:
        if location.group == data.GROUP_SECTORS:
            if location.layout in layouts and location.sector in sectors:
                kept.append(location)
        elif location.group == data.GROUP_VICTORIES:
            if location.layout in layouts:
                kept.append(location)
        elif location.group == data.GROUP_SHOP_SLOTS:
            if location.shop_slot is not None and location.shop_slot <= options.shop_checks.value:
                kept.append(location)
        elif location.group == data.GROUP_SYSTEMS:
            mode = options.systemsanity.value
            if mode == options.systemsanity.option_disabled or location.system not in systems:
                continue
            if location.level == 1 and per_ship:
                continue
            if location.level == 1 or mode == options.systemsanity.option_every_level:
                kept.append(location)
        elif location.group == data.GROUP_SHIP_SYSTEMS:
            if options.systemsanity == options.systemsanity.option_disabled or not per_ship:
                continue
            room = ship_room.get(location.ship, set()) - ship_start.get(location.ship, set())
            if location.system in room:
                kept.append(location)
        elif location.group == data.GROUP_CREW:
            if options.crew_checks:
                kept.append(location)
        elif location.group == data.GROUP_SHIP_ACHIEVEMENTS:
            if options.ship_achievements and location.ship in ships:
                kept.append(location)
        elif location.group == data.GROUP_GENERAL_ACHIEVEMENTS:
            if location.tier not in tiers:
                continue
            if location.achievement in data.CROSS_RUN_ACHIEVEMENTS and not cross_run:
                continue
            if location.achievement == "ACH_UNLOCK_ALL" and not every_ship:
                continue
            kept.append(location)
        else:  # pragma: no cover
            raise ValueError(
                f"{location.name!r} belongs to group {location.group!r}, which "
                "locations.selected_locations does not know how to filter"
            )
    return tuple(kept)


def shop_owners(options) -> tuple[data.Layout, ...]:
    mode = options.shop_per_ship
    if mode == mode.option_per_layout:
        return selected_layouts(options)
    if mode == mode.option_per_class:
        return tuple(layout for layout in selected_layouts(options) if layout.variant == 0)
    return ()


def region_of(location: data.Location, options=None) -> str:
    if location.shop_slot is not None and options is not None:
        owners = shop_owners(options)
        if owners:
            owner = owners[data.shop_owner(location.shop_slot, len(owners), bool(options.shop_by_sector))]
            return region_name(owner)
    if location.layout is not None:
        return region_name(data.LAYOUTS_BY_BLUEPRINT[location.layout])
    if location.ship is not None:
        return region_name(data.LAYOUTS_BY_BLUEPRINT[location.ship])
    return MENU_REGION


def location_plan(options) -> dict[str, dict[str, int]]:
    plan: dict[str, dict[str, int]] = {MENU_REGION: {}}
    for layout in selected_layouts(options):
        plan[region_name(layout)] = {}
    for location in selected_locations(options):
        plan[region_of(location, options)][location.name] = location.code
    return plan
