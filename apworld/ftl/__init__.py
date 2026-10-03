from __future__ import annotations

import logging
import zlib
from typing import Any, ClassVar, Iterator, Mapping

from BaseClasses import LocationProgressType, Region
from Options import OptionError, PerGameCommonOptions
from worlds.AutoWorld import World

from . import data, items, locations, options, pricing, rules
from .items import FTLItem
from .locations import FTLLocation
from .options import FTLOptions
from .web_world import FTLWeb


class FTLWorld(World):
    """FTL: Faster Than Light is a spaceship roguelike. Every ship, every alternate layout and
    every system blueprint is scattered across the multiworld; you earn checks by flying deeper
    into rebel space, by unlocking achievements and by destroying the Flagship. Items you receive
    make your *next* run stronger, which is what makes a roguelike playable in an Archipelago.
    """

    game = data.GAME_NAME
    web = FTLWeb()

    options_dataclass: ClassVar[type[PerGameCommonOptions]] = FTLOptions
    options: FTLOptions

    item_name_to_id = items.ITEM_NAME_TO_ID
    location_name_to_id = locations.LOCATION_NAME_TO_ID
    item_name_groups = {name: set(values) for name, values in data.ITEM_NAME_GROUPS.items()}
    location_name_groups = {
        name: set(values) for name, values in data.LOCATION_NAME_GROUPS.items()
    }

    origin_region_name = locations.MENU_REGION
    topology_present = True

    selected_layouts: tuple[data.Layout, ...]
    created_locations: tuple[data.Location, ...]
    enabled_items: tuple[data.Item, ...]
    shop_items: tuple[data.ShopItem, ...]
    bundles: dict[str, list[tuple[data.ShopItem, ...]]]
    start_ship: data.Ship
    logic: rules.LogicPlan
    sector_logic_level: int

    goal_location_name = locations.GOAL_LOCATION

    def generate_early(self) -> None:
        self.start_ship = self._resolve_start_ship()
        self._draw_layouts()
        self.selected_layouts = locations.selected_layouts(self.options)
        self.created_locations = locations.selected_locations(self.options)
        self.shop_items = items.selected_shop_items(self.options, self.random)
        self.enabled_items = items.enabled_items(self.options, self.shop_items)
        self.bundles = items.bundled_families(self.options, self.shop_items, self.random)
        self._balance_shop_and_filler()

        rules.validate_goal(self)

        for name in self._starting_keys():
            self.push_precollected(self.create_item(name))

        self.logic = rules.plan(self)
        self.sector_logic_level = self.logic.sector_logic
        for name in self.logic.extra_ship_keys:
            self.push_precollected(self.create_item(name))
        for message in self.logic.warnings:
            logging.getLogger("FTL").warning("FTL (%s) : %s", self.player_name, message)

        for name in self.logic.starting_blueprints:
            self.push_precollected(self.create_item(name))

        for name in self.logic.early_blueprints:
            self.multiworld.local_early_items[self.player][name] = 1

    def _resolve_start_ship(self) -> data.Ship:
        if locations.multiverse(self.options):
            return data.SHIPS_BY_BLUEPRINT[data.MV_ALWAYS_UNLOCKED_LAYOUTS[0]]
        by_slot = {ship.slot: ship for ship in data.SHIPS}
        slot = self.options.start_ship.value
        if slot not in by_slot:  # pragma: no cover
            raise OptionError(f"FTL: start_ship={slot} does not name any known ship.")
        return by_slot[slot]

    def _draw_layouts(self) -> None:
        forced = [self.start_ship.blueprint, *locations.always_unlocked(self.options)]
        forced.extend(options.goal_layouts(self.options) or ())
        wanted = max(self.options.layout_count.value, options.goal_victory_count(self.options))
        self.options.drawn_layouts = locations.draw_layouts(
            self.options, self.random, tuple(dict.fromkeys(forced)), wanted)

    def _starting_keys(self) -> tuple[str, ...]:
        always = {
            data.LAYOUTS_BY_BLUEPRINT[blueprint].ship for blueprint in locations.always_unlocked(self.options)
        }
        wanted = dict.fromkeys([self.start_ship.blueprint, *sorted(always)])
        return tuple(data.SHIP_KEY_NAMES[blueprint] for blueprint in wanted)

    @property
    def precollected_item_names(self) -> list[str]:
        return [item.name for item in self.multiworld.precollected_items[self.player]]

    def create_regions(self) -> None:
        plan = locations.location_plan(self.options)

        regions = {name: Region(name, self.player, self.multiworld) for name in plan}
        self.multiworld.regions += list(regions.values())

        for name, contents in plan.items():
            regions[name].add_locations(contents, FTLLocation)
        for location in self.created_locations:
            if location.group == data.GROUP_MV_ACHIEVEMENTS:
                self.get_location(location.name).progress_type = LocationProgressType.EXCLUDED

        menu = regions[locations.MENU_REGION]
        for layout in self.selected_layouts:
            menu.connect(regions[locations.region_name(layout)], locations.entrance_name(layout))

        menu.add_event(
            self.goal_location_name,
            data.VICTORY_ITEM_NAME,
            location_type=FTLLocation,
            item_type=FTLItem,
        )

    def create_item(self, name: str) -> FTLItem:
        return items.create_item(self, name)

    def get_filler_item_name(self) -> str:
        return data.FILLER_ITEM_NAME

    def create_items(self) -> None:
        self.multiworld.itempool += items.build_item_pool(self)

    def set_rules(self) -> None:
        rules.set_rules(self)

    def fill_slot_data(self) -> Mapping[str, Any]:
        descriptors = {item.name: data.item_descriptor(item) for item in self._items_in_seed()}
        # Multiverse and the base game share blueprints: name each one as this seed's catalogue does.
        shop_names = {item.blueprint: data.SHOP_ITEM_NAMES[item] for item in self.shop_items}
        for name, descriptor in descriptors.items():
            item = data.ITEMS_BY_NAME[name]
            if item.group == data.GROUP_SYSTEM_LEVELS and self.options.full_system_upgrades:
                descriptor["n"] = item.count
            if item.kind == data.KIND_BUNDLE:
                members = self.bundles[item.family][int(name.rsplit(" ", 1)[1]) - 1]
                descriptor["bps"] = [member.blueprint for member in members]
                descriptor["names"] = [shop_names[member.blueprint] for member in members]

        kinds = {descriptor["k"] for descriptor in descriptors.values()}
        required_kinds = {
            data.ITEMS_BY_NAME[name].kind
            for name in descriptors
            if data.ITEMS_BY_NAME[name].classification in (
                "progression", "progression_skip_balancing", "useful")
        }

        slot_data: dict[str, Any] = {
            "contract": data.CONTRACT_VERSION,
            "kinds": sorted(kinds),
            "kinds_required": sorted(required_kinds),
            "seed_name": self.multiworld.seed_name,
            "seed_hash": zlib.crc32(self.multiworld.seed_name.encode("utf-8")) & 0x7FFFFFFF,
            "start_ship": self.start_ship.blueprint,
            "multiverse": locations.multiverse(self.options),
            "all_layouts": ([layout.blueprint for layout in data.MV_LAYOUTS]
                            if locations.multiverse(self.options) else []),
            "layouts": [layout.blueprint for layout in self.selected_layouts],
            "language": options.mod_language(self.options),
            "goal": self._goal_for_the_mod(),
            "loc": self._check_key_table(),
            "items": descriptors,
            "caps": self._cap_totals(),
            "system_caps": bool(self.options.progressive_systems.value),
            "system_blueprints": bool(self.options.system_blueprints.value),
            "shop": self._shop_for_the_mod(),
            "links": self._links_for_the_mod(),
            "options": self.options.as_dict("death_link", "sectorsanity", "trap_chance",
                                            "victory_collects_layout"),
        }
        return slot_data

    def _balance_shop_and_filler(self) -> None:
        items_needed = items.items_wanting_a_place(self)
        non_shop_checks = sum(
            1 for location in self.created_locations if location.shop_slot is None
        )
        reserved = items.reserved_filler(self)
        room = non_shop_checks + self.options.shop_checks.value - reserved
        dropped = min(items.spare_items(self), max(0, items_needed - room))
        wanted_slots = max(self.options.shop_checks.value,
                    items_needed - dropped + reserved - non_shop_checks)
        if wanted_slots > data.MAX_SHOP_SLOTS and self.options.progressive_systems_per_ship:
            left_out = items_needed - non_shop_checks - data.MAX_SHOP_SLOTS
            if left_out > 0:
                logging.getLogger("FTL").warning(
                    "FTL (%s): the Archipelago shop stops at %d slots, %d useful item(s) are left out.",
                    self.player_name, data.MAX_SHOP_SLOTS, left_out)
            wanted_slots = data.MAX_SHOP_SLOTS
        if wanted_slots > data.MAX_SHOP_SLOTS:
            raise OptionError(
                f"FTL: these options create {items_needed} items for {non_shop_checks} checks; "
                f"balancing them would need {wanted_slots} Archipelago shop slots, more than the "
                f"{data.MAX_SHOP_SLOTS} the world can hold. Lower Shop Weapons, Shop Drones or "
                "Shop Augments, or turn on more sectors."
            )
        if wanted_slots != self.options.shop_checks.value:
            logging.getLogger("FTL").info(
                "FTL (%s): %d items for %d checks outside the shop, the Archipelago shop grows from %d "
                "to %d slots.", self.player_name, items_needed, non_shop_checks,
                self.options.shop_checks.value, wanted_slots,
            )
            self.options.shop_checks.value = wanted_slots
            self.created_locations = locations.selected_locations(self.options)

    def _shop_for_the_mod(self) -> dict[str, Any]:
        mode = self.options.shop_unlock_mode.current_key
        shop: dict[str, Any] = {
            "mode": mode,
            "deliver": bool(self.options.shop_item_delivery),
            "slots": self.options.shop_checks.value,
        }
        if self.options.shop_by_sector:
            shop["sectors"] = data.SHOP_SECTORS
        owners = locations.shop_owners(self.options)
        if owners:
            shop["owners"] = [owner.blueprint for owner in owners]
            shop["per"] = self.options.shop_per_ship.current_key
        if mode == "locked":
            shop["baseline"] = [item.blueprint for item in self.shop_items]
        shop["offers"] = self._shop_offers()
        return shop

    def _shop_offers(self) -> dict[str, dict[str, Any]]:
        spheres = pricing.spheres_of(self.multiworld)
        offers: dict[str, dict[str, Any]] = {}
        for location in self.created_locations:
            if location.shop_slot is None:
                continue
            placed = self.multiworld.get_location(location.name, self.player)
            if placed.item is None:
                continue
            kind = pricing.importance(placed.item)
            sphere = spheres.get((self.player, location.name))
            # Spheres stay shallow in practice: a package sold in a later sector costs at least that sector's price.
            depth = sphere or 1
            if self.options.shop_by_sector:
                depth = max(depth, data.shop_sector(location.shop_slot))
            offers[location.check_id] = {
                "price": pricing.price(pricing.price_tier(placed.item), depth),
                "sphere": sphere,
                "kind": kind,
            }
        return offers

    def _links_for_the_mod(self) -> dict[str, Any]:
        return {
            "death": {
                "enabled": bool(self.options.death_link),
                "trigger": self.options.death_link_trigger.current_key,
                "cloned": bool(self.options.death_link_cloned_crew),
                "effect": self.options.death_link_effect.current_key,
            },
            "energy": {
                "enabled": bool(self.options.energy_link),
            },
            "trap": {
                "enabled": bool(self.options.trap_link),
            },
        }

    def _goal_for_the_mod(self) -> dict[str, Any]:
        chosen = options.goal_layouts(self.options)
        goal: dict[str, Any] = {
            "kind": "victories",
            "count": options.goal_victory_count(self.options),
            "difficulty": self.options.victory_difficulty.current_key,
            "archives": options.archives_required(self.options),
        }
        if chosen is not None:
            goal["layouts"] = list(chosen)
        return goal

    def _player_item_names(self) -> Iterator[str]:
        """Every item name this player ends up with: precollected, or placed anywhere in the
        multiworld. Used to build slot_data, which must describe items regardless of where the
        fill put them."""

        yield from self.precollected_item_names
        for location in self.multiworld.get_locations():
            item = location.item
            if item is not None and item.player == self.player:
                yield item.name

    def _items_in_seed(self) -> tuple[data.Item, ...]:
        names = {item.name for item in self.enabled_items}
        names.update(name for name in self._player_item_names() if name in data.ITEMS_BY_NAME)
        return tuple(item for item in data.ITEMS if item.name in names)

    def _cap_totals(self) -> dict[str, int]:
        totals: dict[str, int] = {}
        for name in self._player_item_names():
            entry = data.ITEMS_BY_NAME.get(name)
            if entry is not None and entry.group == data.GROUP_SYSTEM_LEVELS and entry.system is not None:
                levels = entry.count if self.options.full_system_upgrades else 1
                totals[entry.system] = totals.get(entry.system, 0) + levels
        return totals

    def _check_key_table(self) -> dict[str, str]:
        table: dict[str, str] = {}
        for location in self.get_locations():
            if location.address is None:
                continue
            table[data.LOCATIONS_BY_NAME[location.name].check_id] = location.name
        return table
