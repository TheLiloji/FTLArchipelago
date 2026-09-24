
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


def selected_layouts(options) -> tuple[data.Layout, ...]:
    if options.ship_layouts == options.ship_layouts.option_type_a_only:
        highest_variant = 0
    elif options.ship_layouts == options.ship_layouts.option_up_to_type_b:
        highest_variant = 1
    else:
        highest_variant = 2
    return tuple(layout for layout in data.LAYOUTS if layout.variant <= highest_variant)


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
            if mode == options.systemsanity.option_disabled:
                continue
            if location.level == 1 or mode == options.systemsanity.option_every_level:
                kept.append(location)
        elif location.group == data.GROUP_CREW:
            if options.crew_checks:
                kept.append(location)
        elif location.group == data.GROUP_SHIP_ACHIEVEMENTS:
            if options.ship_achievements:
                kept.append(location)
        elif location.group == data.GROUP_GENERAL_ACHIEVEMENTS:
            if location.tier not in tiers:
                continue
            if location.achievement in data.CROSS_RUN_ACHIEVEMENTS and not cross_run:
                continue
            kept.append(location)
        else:  # pragma: no cover
            raise ValueError(
                f"{location.name!r} belongs to group {location.group!r}, which "
                "locations.selected_locations does not know how to filter"
            )
    return tuple(kept)


def region_of(location: data.Location) -> str:
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
        plan[region_of(location)][location.name] = location.code
    return plan
