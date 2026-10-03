from __future__ import annotations

from .. import data
from ..locations import region_of
from .bases import FTLTestBase


class TestLayoutCountDefault(FTLTestBase):
    options = {"start_ship": "engi_cruiser"}

    def blueprints(self) -> set[str]:
        return {layout.blueprint for layout in self.world.selected_layouts}

    def test_seven_layouts_by_default(self) -> None:
        self.assertEqual(len(self.world.selected_layouts), 7)

    def test_the_starting_ship_and_the_kestrel_are_always_in(self) -> None:
        self.assertIn("PLAYER_SHIP_CIRCLE", self.blueprints())
        self.assertIn("PLAYER_SHIP_HARD", self.blueprints())

    def test_a_type_b_or_c_comes_with_its_type_a(self) -> None:
        for layout in self.world.selected_layouts:
            self.assertIn(layout.ship, self.blueprints(), layout.display)

    def test_no_check_and_no_key_for_a_layout_left_out(self) -> None:
        regions = {layout.display for layout in self.world.selected_layouts} | {"Menu"}
        for location in self.world.created_locations:
            self.assertIn(region_of(location), regions, location.name)
        ships = {layout.ship for layout in self.world.selected_layouts}
        keys = [item for item in self.world.enabled_items if item.group == data.GROUP_SHIP_KEYS]
        self.assertEqual({item.ship for item in keys}, ships)
        layout_items = {item.blueprint for item in self.world.enabled_items
                        if item.group == data.GROUP_SHIP_LAYOUTS}
        self.assertLessEqual(layout_items, self.blueprints())

    def test_the_mod_gets_the_list(self) -> None:
        self.assertEqual(set(self.world.fill_slot_data()["layouts"]), self.blueprints())

    def test_the_fleet_achievement_needs_every_ship(self) -> None:
        names = {location.achievement for location in self.world.created_locations}
        self.assertNotIn("ACH_UNLOCK_ALL", names)


class TestLayoutCountDiffersBySeed(FTLTestBase):
    run_default_tests = False

    def test_two_seeds_draw_different_layouts(self) -> None:
        from test.general import setup_multiworld
        from .. import FTLWorld

        drawn = set()
        for seed in range(1, 6):
            multiworld = setup_multiworld(FTLWorld, ("generate_early",), seed=seed)
            drawn.add(frozenset(layout.blueprint for layout in multiworld.worlds[1].selected_layouts))
        self.assertGreater(len(drawn), 1)


class TestLayoutCountAll(FTLTestBase):
    options = {"layout_count": len(data.LAYOUTS), "cross_run_achievements": True}

    def test_every_allowed_layout_is_in(self) -> None:
        self.assertEqual(len(self.world.selected_layouts), len(data.LAYOUTS))
        names = {location.achievement for location in self.world.created_locations}
        self.assertIn("ACH_UNLOCK_ALL", names)


class TestLayoutCountBelowTheGoal(FTLTestBase):
    options = {"layout_count": 2, "victories_required": 6}

    def test_there_are_enough_layouts_for_the_goal(self) -> None:
        self.assertEqual(len(self.world.selected_layouts), 6)


class TestLayoutCountKeepsTheGoalLayouts(FTLTestBase):
    options = {
        "layout_count": 3,
        "goal": "victory_selection",
        "victory_layouts": ["Zoltan Cruiser C", "Rock Cruiser B"],
    }

    def test_the_goal_layouts_and_their_type_a_are_in(self) -> None:
        blueprints = {layout.blueprint for layout in self.world.selected_layouts}
        for wanted in ("PLAYER_SHIP_ENERGY_3", "PLAYER_SHIP_ENERGY", "PLAYER_SHIP_ROCK_2",
                       "PLAYER_SHIP_ROCK", "PLAYER_SHIP_HARD"):
            self.assertIn(wanted, blueprints)


class TestLayoutCountWithoutTheFederation(FTLTestBase):
    options = {"layout_count": 1, "start_ship": "kestrel_cruiser", "goal": "victory_selection",
               "victory_layouts": ["Engi Cruiser A"]}

    def test_no_item_for_a_system_no_ship_of_the_seed_can_have(self) -> None:
        self.assertEqual({layout.blueprint for layout in self.world.selected_layouts},
                         {"PLAYER_SHIP_HARD", "PLAYER_SHIP_CIRCLE"})
        names = {item.name for item in self.world.enabled_items}
        for name in ("Artillery Beam blueprint", "Progressive Artillery Beam", "Head Start: Artillery Beam"):
            self.assertNotIn(name, names)
        self.assertIn("Head Start: Shields", names)
