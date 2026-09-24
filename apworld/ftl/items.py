
from __future__ import annotations

from typing import TYPE_CHECKING

from BaseClasses import Item, ItemClassification
from Options import OptionError

from . import data, locations, rules

if TYPE_CHECKING:  # pragma: no cover
    from . import FTLWorld


class FTLItem(Item):
    game = data.GAME_NAME


CLASSIFICATIONS: dict[str, ItemClassification] = {
    "progression": ItemClassification.progression,
    "progression_skip_balancing": ItemClassification.progression_skip_balancing,
    "useful": ItemClassification.useful,
    "filler": ItemClassification.filler,
    "trap": ItemClassification.trap,
}

ITEM_NAME_TO_ID: dict[str, int] = {item.name: item.code for item in data.ITEMS}


def effective_classification(world: "FTLWorld", item: data.Item) -> str:

    if item.group == data.GROUP_SYSTEM_LEVELS:
        options = getattr(world, "options", None)
        if options is not None and item.system in rules.systems_whose_levels_the_rules_read(options):
            return "progression"
        return item.classification
    if item.group != data.GROUP_BLUEPRINTS:
        return item.classification
    plan = getattr(world, "logic", None)
    if plan is None:
        return item.classification
    return item.classification if item.name in plan.progression_blueprints else "useful"


def create_item(world: "FTLWorld", name: str) -> FTLItem:

    if name == data.VICTORY_ITEM_NAME:
        return FTLItem(name, ItemClassification.progression, None, world.player)
    item = data.ITEMS_BY_NAME.get(name)
    if item is None:
        raise OptionError(f"FTL: '{name}' is not an item of this world.")
    classification = CLASSIFICATIONS[effective_classification(world, item)]
    return FTLItem(name, classification, item.code, world.player)


def selected_shop_items(options, rng) -> tuple[data.ShopItem, ...]:

    requested = {
        "weapon": options.shop_weapons.value,
        "drone": options.shop_drones.value,
        "augment": options.shop_augments.value,
    }

    chosen: list[data.ShopItem] = []
    for family, count in requested.items():
        if count <= 0:
            continue
        pool = list(data.SHOP_ITEMS_BY_FAMILY.get(family, ()))
        if len(pool) <= count:
            chosen.extend(pool)
        else:
            chosen.extend(rng.sample(pool, count))
    return tuple(sorted(chosen, key=lambda item: (item.family, item.slot)))


def enabled_items(options, shop_items: tuple[data.ShopItem, ...] = ()) -> tuple[data.Item, ...]:

    layouts = {layout.blueprint for layout in locations.selected_layouts(options)}
    layout_items = options.layout_unlocks == options.layout_unlocks.option_items
    shop_blueprints = {item.blueprint for item in shop_items}

    kept: list[data.Item] = []
    for item in data.ITEMS:
        group = item.group
        if group == data.GROUP_SHIP_KEYS:
            kept.append(item)
        elif group == data.GROUP_SHIP_LAYOUTS:
            if layout_items and item.blueprint in layouts:
                kept.append(item)
        elif group == data.GROUP_BLUEPRINTS:
            if options.system_blueprints:
                kept.append(item)
        elif group == data.GROUP_SYSTEM_LEVELS:
            if options.progressive_systems:
                kept.append(item)
        elif group in (data.GROUP_HEAD_STARTS, data.GROUP_BONUSES):
            if options.head_starts:
                kept.append(item)
        elif group == data.GROUP_CREW_MEMBERS:
            if options.crew_members:
                kept.append(item)
        elif group == data.GROUP_ARCHIVES:
            if options.archives.value > 0:
                kept.append(item)
        elif group == data.GROUP_FILLER:
            kept.append(item)
        elif group == data.GROUP_TRAPS:
            if options.trap_chance.value > 0:
                kept.append(item)
        elif group in (data.GROUP_SHOP_WEAPONS, data.GROUP_SHOP_DRONES, data.GROUP_SHOP_AUGMENTS):
            if item.blueprint in shop_blueprints:
                kept.append(item)
        else:  # pragma: no cover
            raise ValueError(
                f"{item.name!r} belongs to group {group!r}, which items.enabled_items does not "
                "know how to filter"
            )
    return tuple(kept)


def items_wanting_a_place(world: "FTLWorld") -> int:

    options = world.options
    total = 0
    for item in world.enabled_items:
        if item.count == 0 or item.group in (data.GROUP_FILLER, data.GROUP_TRAPS):
            continue
        total += options.archives.value if item.group == data.GROUP_ARCHIVES else item.count
    return total - len(world.precollected_item_names)


def build_item_pool(world: "FTLWorld") -> list[FTLItem]:

    options = world.options
    capacity = len(world.multiworld.get_unfilled_locations(world.player))
    precollected = list(world.precollected_item_names)

    required: list[str] = []
    optional: list[tuple[int, str]] = []

    for item in world.enabled_items:
        if item.count == 0:
            continue
        copies = item.count
        if item.group == data.GROUP_ARCHIVES:
            copies = options.archives.value
        while item.name in precollected and copies > 0:
            precollected.remove(item.name)
            copies -= 1
        if copies <= 0:
            continue
        if effective_classification(world, item).startswith("progression"):
            required.extend([item.name] * copies)
        else:
            optional.extend((rank, item.name) for rank in range(copies))

    if len(required) > capacity:
        raise OptionError(
            f"FTL: {len(required)} progression items for only {capacity} locations. This "
            "combination of options creates more required items than there are checks. Turn on "
            "sectorsanity or the achievements, or turn off the system blueprints."
        )

    world.random.shuffle(optional)
    optional.sort(key=lambda entry: entry[0])
    kept_optional = [name for _, name in optional[: capacity - len(required)]]

    filler_needed = capacity - len(required) - len(kept_optional)
    pool_names = required + kept_optional + roll_filler(world, filler_needed)
    return [create_item(world, name) for name in pool_names]


def roll_filler(world: "FTLWorld", count: int) -> list[str]:

    if count <= 0:
        return []

    filler = [item for item in world.enabled_items if item.group == data.GROUP_FILLER]
    traps = [item for item in world.enabled_items if item.group == data.GROUP_TRAPS]
    filler_names = [item.name for item in filler]
    filler_weights = [item.weight for item in filler]
    trap_names = [item.name for item in traps]
    trap_weights = [item.weight for item in traps]
    trap_chance = world.options.trap_chance.value

    names: list[str] = []
    for _ in range(count):
        if trap_names and world.random.random() * 100 < trap_chance:
            names.append(world.random.choices(trap_names, trap_weights)[0])
        else:
            names.append(world.random.choices(filler_names, filler_weights)[0])
    return names
