from __future__ import annotations

import os
import random
import subprocess
import sys

from .. import data, items, pricing
from .bases import FTLTestBase


class TestShopItemsOff(FTLTestBase):
    options = {"shop_weapons": 0, "shop_drones": 0, "shop_augments": 0}

    def test_no_shop_item_is_created(self) -> None:
        created = [item for item in self.world.enabled_items if item.kind == data.KIND_SHOP]
        self.assertEqual(created, [])

    def test_slot_data_says_nothing_is_locked(self) -> None:
        slot_data = self.world.fill_slot_data()
        self.assertEqual(slot_data["shop"].get("baseline", []), [])


class TestShopItemsLocked(FTLTestBase):
    options = {
        "shop_weapons": 20, "shop_drones": 10, "shop_augments": 0,
        "shop_unlock_mode": "locked",
        "shop_item_delivery": True,
        "sectorsanity": "full",
    }

    def test_exactly_the_requested_number_is_drawn(self) -> None:
        self.assertEqual(len(self.world.shop_items), 30)

    def test_every_drawn_object_can_actually_appear_in_a_shop(self) -> None:
        for shop_item in self.world.shop_items:
            self.assertGreater(shop_item.rarity, 0, shop_item.blueprint)

    def test_the_mod_is_told_what_is_locked(self) -> None:
        slot_data = self.world.fill_slot_data()
        baseline = slot_data["shop"]["baseline"]
        self.assertEqual(len(baseline), 30)
        self.assertEqual(
            sorted(baseline), sorted(item.blueprint for item in self.world.shop_items)
        )

    def test_every_locked_object_has_an_item_that_unlocks_it(self) -> None:
        slot_data = self.world.fill_slot_data()
        descriptors = slot_data["items"]
        unlockable = {
            descriptor["bp"] for descriptor in descriptors.values()
            if descriptor["k"] == data.KIND_SHOP
        }
        for blueprint in slot_data["shop"]["baseline"]:
            self.assertIn(blueprint, unlockable, blueprint)

    def test_shop_items_are_never_progression(self) -> None:
        for item in self.world.enabled_items:
            if item.kind == data.KIND_SHOP:
                self.assertEqual(item.classification, "useful", item.name)


class TestShopItemFamilies(FTLTestBase):
    options = {"shop_weapons": 37, "shop_drones": 0, "shop_augments": 0}

    def test_only_the_chosen_family_is_drawn(self) -> None:
        families = {item.family for item in self.world.shop_items}
        self.assertEqual(families, {"weapon"})

    def test_asking_for_more_than_exists_is_not_an_error(self) -> None:
        self.assertEqual(len(self.world.shop_items), len(data.SHOP_ITEMS_BY_FAMILY["weapon"]))


class TestLinks(FTLTestBase):
    options = {
        "death_link": True,
        "death_link_trigger": "crew_death",
        "death_link_effect": "varied",
        "energy_link": True,
        "trap_link": True,
    }

    def test_links_reach_the_mod_with_the_field_names_the_lua_expects(self) -> None:
        links = self.world.fill_slot_data()["links"]
        self.assertEqual(links["death"]["enabled"], True)
        self.assertEqual(links["death"]["trigger"], "crew_death")
        self.assertEqual(links["death"]["effect"], "varied")
        self.assertEqual(links["energy"]["enabled"], True)
        self.assertEqual(links["trap"]["enabled"], True)

    def test_the_old_trigger_names_still_read(self) -> None:
        from ..options import DeathLinkTrigger

        for old_name in ("run_lost", "hull_destroyed_only", "any_crew_death"):
            self.assertIn(f"alias_{old_name}", dir(DeathLinkTrigger), old_name)

    def test_the_default_covers_both_kinds_of_death(self) -> None:
        from ..options import DeathLinkTrigger

        self.assertEqual(DeathLinkTrigger.default, DeathLinkTrigger.option_both)

    def test_death_link_trigger_is_a_string_and_not_an_index(self) -> None:
        links = self.world.fill_slot_data()["links"]
        self.assertIsInstance(links["death"]["trigger"], str)
        self.assertIsInstance(links["death"]["effect"], str)


class TestLinksOff(FTLTestBase):
    options = {"death_link": False, "energy_link": False, "trap_link": False}

    def test_everything_is_off_by_default(self) -> None:
        links = self.world.fill_slot_data()["links"]
        self.assertEqual(links["death"]["enabled"], False)
        self.assertEqual(links["energy"]["enabled"], False)
        self.assertEqual(links["trap"]["enabled"], False)


class TestSelectionIsReproducible(FTLTestBase):
    options = {"shop_weapons": 15, "shop_drones": 0, "shop_augments": 0}

    def test_the_same_options_and_seed_give_the_same_objects(self) -> None:
        first = [
            item.blueprint
            for item in items.selected_shop_items(self.world.options, random.Random(1234))
        ]
        second = [
            item.blueprint
            for item in items.selected_shop_items(self.world.options, random.Random(1234))
        ]
        self.assertEqual(first, second)
        self.assertTrue(first, "the selection is empty: the test would pass for nothing")

    def test_two_processes_choose_the_same_objects(self) -> None:
        snippet = (
            "import os, sys, random;"
            "sys.path.insert(0, os.environ['AP_SOURCE']);"
            "sys.path.append(os.path.join(os.environ['AP_ROOT'], 'lib', 'library.zip'));"
            "sys.path.append(os.path.join(os.environ['AP_ROOT'], 'lib'));"
            "os.chdir(os.environ['AP_SOURCE']);"
            "import types;"
            "stub = types.ModuleType('bsdiff4.core');"
            "stub.diff = stub.patch = lambda *a, **k: b'';"
            "sys.modules['bsdiff4.core'] = stub;"
            "from worlds.ftl import data, items;"
            "from worlds.ftl.options import ShopWeapons, ShopDrones, ShopAugments;"
            "o = types.SimpleNamespace("
            "shop_weapons=ShopWeapons(15),"
            "shop_drones=ShopDrones(0),"
            "shop_augments=ShopAugments(0));"
            "print(','.join(i.blueprint for i in "
            "items.selected_shop_items(o, random.Random(1234))))"
        )
        outputs = []
        for seed in ("0", "1"):
            env = dict(os.environ, PYTHONHASHSEED=seed)
            result = subprocess.run(
                [sys.executable, "-c", snippet], env=env, capture_output=True, text=True,
            )
            self.assertEqual(result.returncode, 0, result.stderr[-800:])
            outputs.append(result.stdout.strip())
        self.assertTrue(outputs[0], "empty selection: the test would pass for nothing")
        self.assertEqual(
            outputs[0], outputs[1],
            "two processes draw different objects: there is a `set` somewhere in the path, "
            "and two generations of the same seed would not give the same world",
        )

    def test_the_selection_is_sorted_for_readability(self) -> None:
        chosen = self.world.shop_items
        self.assertEqual(
            list(chosen), sorted(chosen, key=lambda item: (item.family, item.slot))
        )


class TestShopChecks(FTLTestBase):

    options = {"shop_checks": 12}

    def test_exactly_the_requested_number_exists(self) -> None:
        shop = [
            location for location in self.multiworld.get_locations(self.player)
            if location.name.startswith("Archipelago Shop ")
        ]
        self.assertEqual(len(shop), 12)

    def test_they_are_reachable_from_the_start(self) -> None:
        state = self.multiworld.get_all_state(False)
        for location in self.multiworld.get_locations(self.player):
            if location.name.startswith("Archipelago Shop "):
                self.assertTrue(location.can_reach(state), location.name)

    def test_their_check_keys_are_what_the_mod_sends(self) -> None:
        keys = self.world.fill_slot_data()["loc"]
        for slot in range(1, 13):
            self.assertIn(f"shop:{slot}", keys)
        self.assertNotIn("shop:13", keys)

    def test_the_mod_is_told_how_many_slots_it_has(self) -> None:
        shop = self.world.fill_slot_data()["shop"]
        self.assertEqual(shop["slots"], 12)


class TestShopChecksOff(FTLTestBase):
    options = {"shop_checks": 0, "archives": 0, "archives_required": 0}

    def test_no_shop_location_exists(self) -> None:
        shop = [
            location for location in self.multiworld.get_locations(self.player)
            if location.name.startswith("Archipelago Shop ")
        ]
        self.assertEqual(shop, [])

    def test_the_mod_is_told_there_are_none(self) -> None:
        self.assertEqual(self.world.fill_slot_data()["shop"]["slots"], 0)


class TestShopPrices(FTLTestBase):

    options = {"shop_checks": 12}

    def test_every_slot_is_priced_by_importance_and_sphere(self) -> None:
        from Fill import distribute_items_restrictive

        distribute_items_restrictive(self.multiworld)
        offers = self.world.fill_slot_data()["shop"]["offers"]
        self.assertEqual(len(offers), 12, "one price for every shop slot")
        for key, offer in offers.items():
            self.assertTrue(key.startswith("shop:"), key)
            self.assertGreater(offer["price"], 0, f"{key} must never be free")
            self.assertEqual(offer["price"], pricing.price(offer["kind"], offer["sphere"]))

    def test_an_important_item_always_costs_more_than_filler(self) -> None:
        for sphere in range(0, 12):
            self.assertGreater(pricing.price("progression", sphere), pricing.price("useful", 30))
            self.assertGreater(pricing.price("useful", sphere), pricing.price("filler", 30))

    def test_the_price_rises_with_the_sphere_up_to_a_cap(self) -> None:
        prices = [pricing.price("progression", sphere) for sphere in range(1, 30)]
        self.assertEqual(prices, sorted(prices))
        self.assertEqual(prices[-1], pricing.PRICE_CAP["progression"])

    def test_the_mod_falls_back_on_the_same_base_prices(self) -> None:
        import re
        from pathlib import Path

        lua = (Path(__file__).resolve().parents[3] / "mod" / "ArchipelagoFTL" / "data" / "archipelago"
               / "shopgift.lua").read_text(encoding="utf-8")
        table = re.search(r"local BASE_PRICE = \{([^}]*)\}", lua)
        self.assertIsNotNone(table, "the mod no longer has readable fallback prices")
        mod = {key: int(value) for key, value in re.findall(r"(\w+) = (\d+)", table.group(1))}
        self.assertEqual(mod, pricing.BASE_PRICE)
