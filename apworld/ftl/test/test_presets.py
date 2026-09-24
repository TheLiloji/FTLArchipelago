
from __future__ import annotations

from pathlib import Path

import yaml
from Fill import distribute_items_restrictive
from test.general import setup_multiworld
from unittest import TestCase

from .. import FTLWorld, data

PRESETS = Path(__file__).resolve().parents[3] / "presets"
GAME = data.GAME_NAME
GEN_STEPS = (
    "generate_early", "create_regions", "create_items", "set_rules",
    "connect_entrances", "generate_basic", "pre_fill",
)


def load(name: str) -> dict:
    document = yaml.safe_load((PRESETS / name).read_text(encoding="utf-8"))
    return document[GAME]


def build(name: str, seed: int = 4242):
    multiworld = setup_multiworld(FTLWorld, GEN_STEPS, seed=seed, options=load(name))
    distribute_items_restrictive(multiworld)
    return multiworld, multiworld.worlds[1]


def locations_of_group(multiworld, group: str) -> list[str]:
    return [
        location.name
        for location in multiworld.get_locations(1)
        if location.address is not None
        and (entry := data.LOCATIONS_BY_NAME.get(location.name))
        and entry.group == group
    ]


ALL_PRESETS = sorted(path.name for path in PRESETS.glob("*.yaml"))


class TestEveryPresetGenerates(TestCase):

    def test_there_are_six_presets(self) -> None:
        self.assertEqual(len(ALL_PRESETS), 6, ALL_PRESETS)

    def test_each_one_generates_and_fills(self) -> None:
        for name in ALL_PRESETS:
            with self.subTest(preset=name):
                multiworld, _ = build(name)
                addressed = [
                    location for location in multiworld.get_locations(1)
                    if location.address is not None
                ]
                self.assertTrue(addressed, "no location")
                for location in addressed:
                    self.assertIsNotNone(location.item, f"{location.name} stayed empty")

    def test_each_one_can_be_beaten(self) -> None:
        for name in ALL_PRESETS:
            with self.subTest(preset=name):
                multiworld, _ = build(name)
                multiworld.state = multiworld.get_all_state()
                self.assertTrue(multiworld.has_beaten_game(multiworld.state, 1))

    def test_each_one_survives_a_different_seed(self) -> None:
        for name in ALL_PRESETS:
            for seed in (1, 987654, 20260915):
                with self.subTest(preset=name, seed=seed):
                    build(name, seed=seed)

    def test_slot_data_is_complete(self) -> None:
        for name in ALL_PRESETS:
            with self.subTest(preset=name):
                _, world = build(name)
                slot_data = world.fill_slot_data()
                self.assertIn("items", slot_data)
                self.assertIn("loc", slot_data)
                self.assertTrue(slot_data["kinds"])


class TestPresetsKeepTheirPromises(TestCase):

    def test_the_shop_slot_counts_are_the_announced_ones(self) -> None:
        announced = {
            "A1_multi_game_beginner.yaml": 56,
            "A2_multi_game_veteran.yaml": 51,
            "B1_solo_beginner.yaml": 40,
            "B2_solo_veteran.yaml": 50,
            "C1_two_evenings_beginner.yaml": 54,
            "C2_two_evenings_veteran.yaml": 41,
        }
        for name, count in announced.items():
            with self.subTest(preset=name):
                multiworld, _ = build(name)
                slots = locations_of_group(multiworld, data.GROUP_SHOP_SLOTS)
                self.assertEqual(len(slots), count)

    def test_the_sector_interval_is_respected(self) -> None:
        for name in ALL_PRESETS:
            with self.subTest(preset=name):
                options = load(name)
                floor = options["sectorsanity_first_sector"]
                ceiling = options["sectorsanity_last_sector"]
                multiworld, _ = build(name)
                sectors = {
                    data.LOCATIONS_BY_NAME[location].sector
                    for location in locations_of_group(multiworld, data.GROUP_SECTORS)
                }
                self.assertTrue(sectors, "no sector check")
                self.assertEqual(min(sectors), floor)
                self.assertEqual(max(sectors), ceiling)

    def test_level_one_presets_carry_no_traps(self) -> None:
        for name in ALL_PRESETS:
            if not name.endswith("beginner.yaml"):
                continue
            with self.subTest(preset=name):
                self.assertEqual(load(name)["trap_chance"], 0)
                multiworld, _ = build(name)
                traps = [item for item in multiworld.itempool if item.trap]
                self.assertEqual(traps, [])

    def test_level_two_presets_do_carry_traps(self) -> None:
        for name in ALL_PRESETS:
            if not name.endswith("veteran.yaml"):
                continue
            with self.subTest(preset=name):
                self.assertGreater(load(name)["trap_chance"], 0)


class TestContextCHardConstraints(TestCase):

    PRESETS = ("C1_two_evenings_beginner.yaml", "C2_two_evenings_veteran.yaml")

    def test_they_have_plenty_of_free_outlets(self) -> None:
        for name in self.PRESETS:
            with self.subTest(preset=name):
                multiworld, _ = build(name)
                slots = locations_of_group(multiworld, data.GROUP_SHOP_SLOTS)
                self.assertGreaterEqual(len(slots), 25)

    def test_the_free_outlets_are_reachable_from_the_start(self) -> None:
        from BaseClasses import CollectionState

        for name in self.PRESETS:
            with self.subTest(preset=name):
                multiworld, _ = build(name)
                empty = CollectionState(multiworld)
                reachable = [
                    location for location in multiworld.get_locations(1)
                    if location.address is not None
                    and (entry := data.LOCATIONS_BY_NAME.get(location.name))
                    and entry.group == data.GROUP_SHOP_SLOTS
                    and location.can_reach(empty)
                ]
                self.assertGreaterEqual(len(reachable), 25)

    def test_the_seed_stays_within_two_evenings(self) -> None:
        for name in self.PRESETS:
            with self.subTest(preset=name):
                multiworld, _ = build(name)
                addressed = [
                    location for location in multiworld.get_locations(1)
                    if location.address is not None
                ]
                self.assertLessEqual(len(addressed), 200, f"{name}: seed too big")

    def test_a_lost_run_never_costs_a_check(self) -> None:

        known_groups = {
            data.GROUP_SECTORS, data.GROUP_VICTORIES, data.GROUP_SHIP_ACHIEVEMENTS,
            data.GROUP_GENERAL_ACHIEVEMENTS, data.GROUP_SHOP_SLOTS, data.GROUP_SYSTEMS,
            data.GROUP_CREW,
        }
        for name in self.PRESETS:
            with self.subTest(preset=name):
                multiworld, _ = build(name)
                for location in multiworld.get_locations(1):
                    if location.address is None:
                        continue
                    entry = data.LOCATIONS_BY_NAME[location.name]
                    self.assertIn(entry.group, known_groups, location.name)


class TestPresetsDoNotPromiseWhatTheyCannotDeliver(TestCase):

    CURSORS = {
        "shields_blueprint_logic": "Shields blueprint",
        "sensors_blueprint_logic": "Sensors blueprint",
        "medbay_blueprint_logic": "Medbay blueprint",
    }

    def test_no_required_cursor_is_cancelled_by_the_starting_ship(self) -> None:
        for name in ALL_PRESETS:
            options = load(name)
            required = [
                cursor for cursor, _ in self.CURSORS.items()
                if options.get(cursor) == "required"
            ]
            if not required:
                continue
            with self.subTest(preset=name):
                _, world = build(name)
                given = set(world.logic.starting_blueprints)
                for cursor in required:
                    blueprint = self.CURSORS[cursor]
                    self.assertNotIn(
                        blueprint, given,
                        f"{name} sets {cursor}: required, but {world.start_ship.display} "
                        f"already has this system: the blueprint is given for free and the "
                        f"lock does not exist",
                    )

    def test_each_veteran_preset_locks_something_real(self) -> None:
        for name in ALL_PRESETS:
            if not name.endswith("veteran.yaml"):
                continue
            with self.subTest(preset=name):
                options = load(name)
                locked = [
                    cursor for cursor in self.CURSORS
                    if options.get(cursor) == "required"
                ]
                self.assertTrue(locked, f"{name} locks no system")
