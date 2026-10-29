from __future__ import annotations

import json

from BaseClasses import CollectionState

from .. import FTLWorld, data
from .bases import FTLTestBase


class TestDefaultOptions(FTLTestBase):
    run_default_tests = True

    def test_world_is_registered_under_the_expected_name(self) -> None:
        self.assertEqual(self.world.game, data.GAME_NAME)
        self.assertEqual(self.multiworld.game[self.player], data.GAME_NAME)

    def test_datapackage_is_complete(self) -> None:
        self.assertEqual(
            self.world.item_name_to_id, {item.name: item.code for item in data.ITEMS}
        )
        self.assertEqual(
            self.world.location_name_to_id, {loc.name: loc.code for loc in data.LOCATIONS}
        )

    def test_regions_are_connected_to_the_origin(self) -> None:
        state = self.multiworld.get_all_state(False)
        unreachable = [
            region.name for region in self.multiworld.get_regions(self.player)
            if not region.can_reach(state)
        ]
        self.assertEqual(unreachable, [])

    def test_item_pool_size_matches_location_count(self) -> None:
        self.assertEqual(len(self.multiworld.itempool), len(self.addressed_locations()))

    def test_the_only_event_is_the_goal(self) -> None:
        events = self.event_locations()
        self.assertEqual([location.name for location in events], [self.world.goal_location_name])
        self.assertIsNotNone(events[0].item)
        self.assertEqual(events[0].item.name, data.VICTORY_ITEM_NAME)

    def test_progression_items_are_not_duplicated_by_the_starting_inventory(self) -> None:
        counts: dict[str, int] = {}
        for name in self.world.precollected_item_names:
            counts[name] = counts.get(name, 0) + 1
        for item in self.multiworld.itempool:
            counts[item.name] = counts.get(item.name, 0) + 1

        for name, count in counts.items():
            declared = data.ITEMS_BY_NAME[name]
            if declared.count == 0:
                continue
            self.assertLessEqual(count, declared.count, f"{name} appears {count} times")

    def test_starting_keys_are_handed_out(self) -> None:
        given = self.world.precollected_item_names
        self.assertIn(data.SHIP_KEY_NAMES[self.world.start_ship.blueprint], given)

        for blueprint in data.ALWAYS_UNLOCKED_LAYOUTS:
            ship = data.LAYOUTS_BY_BLUEPRINT[blueprint].ship
            self.assertIn(
                data.SHIP_KEY_NAMES[ship], given,
                f"{blueprint} is playable no matter what: its key must be precollected, "
                "otherwise the logic thinks it can use it as a lock",
            )

    def test_goal_is_reachable_with_every_item(self) -> None:
        self.multiworld.state = self.multiworld.get_all_state(False)
        self.assertBeatable(True)

    def test_every_location_is_reachable_with_every_item(self) -> None:
        state = self.multiworld.get_all_state(False)
        unreachable = [
            location.name for location in self.multiworld.get_locations(self.player)
            if not location.can_reach(state)
        ]
        self.assertEqual(unreachable, [])

    def test_goal_is_not_reachable_with_nothing(self) -> None:
        self.assertGreater(self.world.options.victories_required.value, 1)
        self.multiworld.state = CollectionState(self.multiworld)
        self.assertBeatable(False)

    def test_caps_count_every_item_that_raises_a_system(self) -> None:
        caps = self.world.fill_slot_data()["caps"]
        for system, total in caps.items():
            expected = sum(
                1
                for item in self.multiworld.itempool
                if item.player == self.player
                and data.ITEMS_BY_NAME[item.name].system == system
                and data.ITEMS_BY_NAME[item.name].group in (
                    data.GROUP_SYSTEM_LEVELS, data.GROUP_BLUEPRINTS)
            )
            expected += sum(
                1
                for name in self.world.precollected_item_names
                if name in data.ITEMS_BY_NAME
                and data.ITEMS_BY_NAME[name].system == system
                and data.ITEMS_BY_NAME[name].group in (
                    data.GROUP_SYSTEM_LEVELS, data.GROUP_BLUEPRINTS)
            )
            self.assertEqual(
                total, expected,
                f"{system}: the mod counts this total to say 'all received', it must "
                "match the items that actually raise the cap",
            )

    def test_the_default_goal_asks_for_ten_of_twelve_archives(self) -> None:
        names = [item.name for item in self.multiworld.itempool]
        self.assertEqual(names.count(data.ARCHIVE_ITEM_NAME), 12)
        self.assertEqual(self.world.fill_slot_data()["goal"]["archives"], 10)

    def test_slot_data_is_serialisable(self) -> None:
        json.dumps(self.world.fill_slot_data())

    def test_slot_data_lists_exactly_the_locations_of_this_seed(self) -> None:
        slot_data = self.world.fill_slot_data()
        created = {location.name for location in self.addressed_locations()}

        self.assertEqual(set(slot_data["loc"].values()), created)
        for check_id, name in slot_data["loc"].items():
            self.assertEqual(
                data.LOCATIONS_BY_NAME[name].check_id, check_id,
                "table `loc` maps a check key to a location that is not its own",
            )

    def test_every_item_of_the_seed_has_a_descriptor(self) -> None:
        slot_data = self.world.fill_slot_data()
        received = {item.name for item in self.multiworld.itempool}
        received.update(self.world.precollected_item_names)
        received.discard(data.VICTORY_ITEM_NAME)

        missing = sorted(received - set(slot_data["items"]))
        self.assertEqual(missing, [], "items created but missing from slot_data")

    def test_declared_kinds_are_implemented_by_the_mod(self) -> None:
        slot_data = self.world.fill_slot_data()
        self.assertLessEqual(set(slot_data["kinds_required"]), set(slot_data["kinds"]))
        unimplemented = sorted(set(slot_data["kinds_required"]) - set(data.KINDS_IMPLEMENTED))
        self.assertEqual(unimplemented, [])

    def test_seed_hash_survives_metavariables(self) -> None:
        slot_data = self.world.fill_slot_data()
        self.assertIsInstance(slot_data["seed_hash"], int)
        self.assertGreaterEqual(slot_data["seed_hash"], 0)
        self.assertLess(slot_data["seed_hash"], 2 ** 31)
        self.assertEqual(slot_data["contract"], data.CONTRACT_VERSION)


class TestNoArchives(FTLTestBase):
    options = {"archives": 0, "archives_required": 0}

    def test_archives_are_absent_when_the_option_is_zero(self) -> None:
        names = [item.name for item in self.multiworld.itempool]
        self.assertNotIn(data.ARCHIVE_ITEM_NAME, names)
        self.assertEqual(self.world.fill_slot_data()["goal"]["archives"], 0)


class TestUniversalTrackerRebuildsTheSameWorld(FTLTestBase):
    """Universal Tracker regenerates from slot_data alone, with default options and another seed."""

    options = {"layout_count": 6, "ship_layouts": "up_to_type_b", "sectorsanity": "full",
               "sectorsanity_first_sector": 3, "shop_weapons": 12, "weapon_bundle_size": 3,
               "shop_by_sector": True, "victories_required": 3}

    def _rebuild(self, slot_data):
        from argparse import Namespace
        from BaseClasses import MultiWorld
        from worlds import AutoWorld
        from worlds.AutoWorld import call_all

        multiworld = MultiWorld(1)
        multiworld.game[1] = self.game
        multiworld.player_name = {1: "Tester"}
        multiworld.set_seed(self.multiworld.seed + 1)
        args = Namespace()
        for name, option in AutoWorld.AutoWorldRegister.world_types[self.game].options_dataclass.type_hints.items():
            setattr(args, name, {1: option.from_any(option.default)})
        multiworld.set_options(args)
        multiworld.state = CollectionState(multiworld)
        multiworld.re_gen_passthrough = {self.game: FTLWorld.interpret_slot_data(slot_data)}
        for step in ("generate_early", "create_regions", "create_items", "set_rules"):
            call_all(multiworld, step)
        return multiworld

    def test_same_locations_layouts_and_shop(self) -> None:
        import json
        slot_data = json.loads(json.dumps(self.world.fill_slot_data()))
        rebuilt = self._rebuild(slot_data)
        tracker = rebuilt.worlds[1]
        self.assertEqual({location.name for location in self.multiworld.get_locations(self.player)},
                         {location.name for location in rebuilt.get_locations(1)})
        self.assertEqual(self.world.selected_layouts, tracker.selected_layouts)
        self.assertEqual(self.world.shop_items, tracker.shop_items)
        self.assertEqual(self.world.bundles, tracker.bundles)
        self.assertEqual(tracker.options.sectorsanity_first_sector.value, 3)


class TestLogicCopyForTheMod(FTLTestBase):
    options = {"sector_logic": "strict", "layout_count": 4}

    def test_the_mod_gets_each_layouts_needs_and_each_checks_blueprints(self) -> None:
        logic = self.world.fill_slot_data()["logic"]
        self.assertTrue(logic["layouts"])
        for layout, needs in logic["layouts"].items():
            self.assertTrue(all(name in data.ITEMS_BY_NAME for name in needs), layout)
        self.assertTrue(any(entry["bp"] for entry in logic["checks"].values()), "strict logic asks blueprints somewhere")
        self.assertTrue(all(name in data.ITEMS_BY_NAME for name in logic["blueprint_items"]))


class TestEveryOptionTheModReadsIsSent(FTLTestBase):
    options = {"layout_count": 3}

    def test_slot_data_options_cover_the_mods_apseedoption_calls(self) -> None:
        import re
        from pathlib import Path
        mod = Path(__file__).resolve().parents[3] / "mod" / "ArchipelagoFTL" / "data" / "archipelago"
        if not mod.is_dir():
            self.skipTest("the mod's sources are not next to this apworld")
        names = set()
        for path in mod.glob("*.lua"):
            names |= set(re.findall(r'apSeedOption\("([a-z_]+)"\)', path.read_text(encoding="utf-8")))
        sent = set(self.world.fill_slot_data()["options"])
        self.assertEqual(sorted(names - sent), [], "options the mod reads but the seed never sends")


class TestLogicCopyKeepsDeepShopSlotsAboardTheirOwner(FTLTestBase):
    options = {"sector_locks": True, "layout_count": 4, "shop_by_sector": True, "shop_checks": 40,
               "shop_per_ship": "per_layout"}

    def test_a_deep_shop_slot_lists_only_its_owner(self) -> None:
        from .. import locations
        logic = self.world.fill_slot_data()["logic"]
        owners = locations.shop_owners(self.world.options)
        deep = 0
        for location in self.world.created_locations:
            if location.shop_slot is None:
                continue
            entry = logic["checks"][location.check_id]
            if not entry["pass"]:
                continue
            owner = owners[data.shop_owner(location.shop_slot, len(owners), True)]
            self.assertEqual([way["l"] for way in entry["ways"]], [owner.blueprint], location.check_id)
            deep += 1
        self.assertTrue(deep, "no deep shop slot")


class TestLogicCopyFollowsSectorLocks(FTLTestBase):
    options = {"sector_logic": "strict", "sector_locks": True, "layout_count": 4, "system_blueprints": True}

    def test_deep_checks_ask_for_passes_and_installs_for_their_blueprint(self) -> None:
        logic = self.world.fill_slot_data()["logic"]
        layout = self.world.selected_layouts[0]
        self.assertEqual(logic["checks"][f"{layout.blueprint}:sector:5"]["pass"], 1)
        self.assertEqual(logic["checks"][f"{layout.blueprint}:sector:8"]["pass"], 2)
        self.assertEqual(logic["checks"][f"{layout.blueprint}:sector:4"]["pass"], 0)
        installs = [entry for key, entry in logic["checks"].items() if key.startswith("sys:") and key.count(":") == 1]
        for entry in installs:
            self.assertTrue(entry["ways"])
