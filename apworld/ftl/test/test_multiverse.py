from __future__ import annotations

from .. import data
from .bases import FTLTestBase


class TestMultiverse(FTLTestBase):
    options = {"multiverse": True}

    def test_only_multiverse_ships_are_in_the_seed(self) -> None:
        self.assertEqual(len(self.world.selected_layouts), 7)
        for layout in self.world.selected_layouts:
            self.assertTrue(data.SHIPS_BY_BLUEPRINT[layout.ship].multiverse, layout.display)
        blueprints = {layout.blueprint for layout in self.world.selected_layouts}
        self.assertIn("PLAYER_SHIP_MVKESTREL", blueprints)

    def test_the_mod_is_told(self) -> None:
        slot_data = self.world.fill_slot_data()
        self.assertTrue(slot_data["multiverse"])
        self.assertEqual(slot_data["start_ship"], "PLAYER_SHIP_MVKESTREL")
        self.assertEqual(len(slot_data["all_layouts"]), len(data.MV_LAYOUTS), "to check the whole profile")

    def test_no_key_or_achievement_of_a_base_game_ship(self) -> None:
        vanilla = {ship.blueprint for ship in data.SHIPS}
        for item in self.world.enabled_items:
            self.assertNotIn(item.ship, vanilla, item.name)
        for location in self.world.created_locations:
            self.assertNotIn(location.ship, vanilla, location.name)

    def test_names_never_collide_with_the_base_game(self) -> None:
        self.assertEqual(data.SHIPS_BY_BLUEPRINT["PLAYER_SHIP_KESTREL"].display, "Kestrel Cruiser (MV)")


class TestMultiverseLargestSeed(FTLTestBase):
    options = {"multiverse": True, "layout_count": len(data.LAYOUTS), "victories_required": 10}

    def test_as_many_layouts_as_the_base_game_allows(self) -> None:
        self.assertEqual(len(self.world.selected_layouts), len(data.LAYOUTS))


class TestMultiverseVictorySelection(FTLTestBase):
    options = {"multiverse": True, "layout_count": 3, "goal": "victory_selection",
               "victory_layouts": ["Union Cruiser B"]}

    def test_a_multiverse_layout_can_be_the_goal(self) -> None:
        blueprints = {layout.blueprint for layout in self.world.selected_layouts}
        self.assertIn("PLAYER_SHIP_UNION_2", blueprints)
        self.assertEqual(self.world.fill_slot_data()["goal"]["layouts"], ["PLAYER_SHIP_UNION_2"])


class TestMultiverseShop(FTLTestBase):
    options = {"multiverse": True, "weapon_bundle_size": 1, "drone_bundle_size": 1, "augment_bundle_size": 1}

    def test_the_shop_items_are_multiverse_s(self) -> None:
        shop = [item for item in self.world.enabled_items if item.kind == data.KIND_SHOP]
        self.assertEqual(len(shop), 37 + 14 + 22, "the base game's counts, drawn from Multiverse's catalogue")
        mv_names = set(data.SHOP_ITEM_NAMES[item] for item in data.MV_SHOP_ITEMS)
        for item in shop:
            self.assertIn(item.name, mv_names)


class TestMultiverseBundles(FTLTestBase):
    options = {"multiverse": True}

    def test_bundles_hold_multiverse_items_under_their_own_names(self) -> None:
        descriptors = self.world.fill_slot_data()["items"]
        names = {data.SHOP_ITEM_NAMES[item]: item for item in data.MV_SHOP_ITEMS}
        bundles = [descriptor for descriptor in descriptors.values() if descriptor["k"] == "bundle"]
        self.assertTrue(bundles)
        held = []
        for descriptor in bundles:
            for blueprint, name in zip(descriptor["bps"], descriptor["names"]):
                self.assertIn(name, names, "named as Multiverse names it")
                self.assertEqual(names[name].blueprint, blueprint)
                held.append(name)
        chosen = sorted(data.SHOP_ITEM_NAMES[item] for item in self.world.shop_items)
        self.assertEqual(sorted(held), chosen, "every chosen Multiverse item is in one bundle")


class TestBaseGameBundlesKeepBaseNames(FTLTestBase):

    def test_a_base_game_bundle_names_its_items_as_the_base_game(self) -> None:
        base_names = {data.SHOP_ITEM_NAMES[item] for item in data.SHOP_ITEMS}
        descriptors = self.world.fill_slot_data()["items"]
        bundles = [descriptor for descriptor in descriptors.values() if descriptor["k"] == "bundle"]
        self.assertTrue(bundles)
        for descriptor in bundles:
            for name in descriptor["names"]:
                self.assertIn(name, base_names, "a Multiverse name in a base game seed")


class TestBaseGameRangesUnchanged(FTLTestBase):
    run_default_tests = False

    def test_multiverse_does_not_widen_the_base_game_shop_options(self) -> None:
        from ..options import ShopAugments, ShopDrones, ShopWeapons
        self.assertEqual((ShopWeapons.range_end, ShopDrones.range_end, ShopAugments.range_end), (37, 14, 23))

    def test_ftl_multiverse_offers_every_multiverse_layout(self) -> None:
        from ..options import LayoutCount, VictoriesRequired
        self.assertEqual(VictoriesRequired.range_end, len(data.MV_LAYOUTS))
        self.assertEqual(LayoutCount.range_end, len(data.MV_LAYOUTS))


class TestTooManyLayoutsWithoutMultiverse(FTLTestBase):
    options = {"multiverse": False, "layout_count": 100, "victories_required": 50}

    def test_the_counts_come_down_to_the_base_game(self) -> None:
        self.assertLessEqual(self.world.options.layout_count.value, len(data.LAYOUTS))
        self.assertLessEqual(self.world.options.victories_required.value, len(data.LAYOUTS))


class TestMultiverseAchievements(FTLTestBase):
    options = {"multiverse": True, "multiverse_achievements": True}

    def test_twenty_six_achievements_only_ever_hold_filler(self) -> None:
        from BaseClasses import LocationProgressType
        from Fill import distribute_items_restrictive
        distribute_items_restrictive(self.multiworld)
        mv = [location for location in self.multiworld.get_locations(self.player)
              if location.name.startswith("MV Achievement: ")]
        self.assertEqual(len(mv), len(data.MV_ACHIEVEMENTS_RAW))
        self.assertEqual(len(mv), 26)
        for location in mv:
            self.assertEqual(location.progress_type, LocationProgressType.EXCLUDED, location.name)
            self.assertFalse(location.item.advancement, f"{location.name} holds {location.item.name}")

    def test_the_mod_gets_their_check_keys(self) -> None:
        loc = self.world.fill_slot_data()["loc"]
        self.assertEqual(loc.get("ach:ACH_ACC_DATABASE"), "MV Achievement: Well Informed")


class TestMultiverseAchievementsOff(FTLTestBase):
    options = {"multiverse": True}

    def test_off_by_default(self) -> None:
        names = [location.name for location in self.multiworld.get_locations(self.player)]
        self.assertFalse(any(name.startswith("MV Achievement: ") for name in names))


class TestMultiverseAchievementsNeedMultiverse(FTLTestBase):
    options = {"multiverse_achievements": True}

    def test_the_base_game_ignores_them(self) -> None:
        names = [location.name for location in self.multiworld.get_locations(self.player)]
        self.assertFalse(any(name.startswith("MV Achievement: ") for name in names))


class TestMultiverseRaces(FTLTestBase):
    options = {"multiverse": True}

    def test_each_multiverse_race_has_its_first_crew_check(self) -> None:
        names = {location.name for location in self.multiworld.get_locations(self.player)}
        for _, _, label, _ in data.MV_CREW_RACES:
            self.assertIn(f"First {label} aboard", names)
        self.assertEqual(self.world.fill_slot_data()["loc"].get("crew:orchid"), "First Orchid aboard",
                         "the mod sends crew:<race>, variants included")

    def test_the_rare_races_only_ever_hold_filler(self) -> None:
        from BaseClasses import LocationProgressType
        from Fill import distribute_items_restrictive
        distribute_items_restrictive(self.multiworld)
        rare = {f"First {label} aboard" for _, _, label, hard in data.MV_CREW_RACES if hard}
        common = {f"First {label} aboard" for _, _, label, hard in data.MV_CREW_RACES if not hard}
        self.assertTrue(rare and common)
        for location in self.multiworld.get_locations(self.player):
            if location.name in rare:
                self.assertEqual(location.progress_type, LocationProgressType.EXCLUDED, location.name)
                self.assertFalse(location.item.advancement, f"{location.name} holds {location.item.name}")
            elif location.name in common:
                self.assertNotEqual(location.progress_type, LocationProgressType.EXCLUDED, location.name)


class TestMultiverseRacesNeedMultiverse(FTLTestBase):
    options = {"crew_checks": True}

    def test_the_base_game_keeps_its_seven_races(self) -> None:
        names = {location.name for location in self.multiworld.get_locations(self.player)}
        self.assertNotIn("First Orchid aboard", names)
        self.assertIn("First Engi aboard", names)


class TestMultiverseRacesFollowCrewChecks(FTLTestBase):
    options = {"multiverse": True, "crew_checks": False}

    def test_no_race_check_without_crew_checks(self) -> None:
        names = {location.name for location in self.multiworld.get_locations(self.player)}
        self.assertNotIn("First Orchid aboard", names)
        self.assertNotIn("First Siren aboard", names)


class TestMultiverseExcludedShips(FTLTestBase):
    options = {"multiverse": True, "layout_count": 28, "excluded_layouts": ["Union Cruiser", "MV Union Cruiser A"]}

    def test_multiverse_ships_can_be_left_out(self) -> None:
        drawn = {layout.display for layout in self.world.selected_layouts}
        self.assertFalse([name for name in drawn if name.startswith("Union Cruiser")], drawn)
        self.assertNotIn("MV Union Cruiser A", drawn)


class TestMultiverseKestrelCannotBeLeftOut(FTLTestBase):
    options = {"multiverse": True, "excluded_layouts": ["MV Kestrel Cruiser"]}
    auto_construct = False

    def test_generation_is_refused_with_a_readable_message(self) -> None:
        from Options import OptionError
        with self.assertRaises(OptionError) as raised:
            self.world_setup()
        self.assertIn("MV Kestrel Cruiser", str(raised.exception))


class TestMultiverseLevelChecksCountTheStartingLevels(FTLTestBase):
    options = {"multiverse": True, "systemsanity": "every_level"}

    def test_the_mv_kestrel_starts_with_shields_2_and_engines_2(self) -> None:
        from BaseClasses import CollectionState
        state = CollectionState(self.multiworld)
        for item in self.multiworld.precollected_items[self.player]:
            state.collect(item, prevent_sweep=True)
        for name in ("MV Kestrel Cruiser Key", "Shields blueprint", "Engines blueprint",
                     "Progressive Shields", "Progressive Shields", "Progressive Engines"):
            state.collect(self.world.create_item(name), prevent_sweep=True)

        def reach(check: str) -> bool:
            return self.multiworld.get_location(check, self.player).can_reach(state)

        self.assertTrue(reach("Shields level 4"), "2 at the start, 2 received")
        self.assertFalse(reach("Shields level 5"))
        self.assertTrue(reach("Engines level 3"), "2 at the start, 1 received")


class TestMagicHatByGroup(FTLTestBase):
    options = {"multiverse": True, "magic_hat": "by_group", "layout_count": 20}

    def test_nine_family_items_cover_every_destination_once(self) -> None:
        hats = [item for item in self.multiworld.itempool if data.ITEMS_BY_NAME[item.name].group == data.GROUP_MAGIC_HAT]
        self.assertEqual(len(hats), 9)
        keys = [key for item in hats for key in data.ITEMS_BY_NAME[item.name].hat]
        self.assertEqual(sorted(keys), sorted(key for key, *_ in data.MAGIC_HAT_DESTINATIONS))
        self.assertTrue(all(item.useful for item in hats))
        descriptor = self.world.fill_slot_data()["items"]["Magic Hat: Hostile Sectors"]
        self.assertEqual(descriptor["k"], "hat")
        self.assertIn("rebel_generic", descriptor["hat"])


class TestMagicHatBySector(FTLTestBase):
    options = {"multiverse": True, "magic_hat": "by_sector", "layout_count": 40}

    def test_one_item_per_destination(self) -> None:
        hats = [item for item in self.multiworld.itempool if data.ITEMS_BY_NAME[item.name].group == data.GROUP_MAGIC_HAT]
        self.assertEqual(len(hats), len(data.MAGIC_HAT_DESTINATIONS))


class TestMagicHatWithoutMultiverse(FTLTestBase):
    options = {"multiverse": False, "magic_hat": "by_sector"}

    def test_no_hat_item_in_the_base_game(self) -> None:
        self.assertFalse(any(data.ITEMS_BY_NAME[item.name].group == data.GROUP_MAGIC_HAT
                             for item in self.multiworld.itempool))
