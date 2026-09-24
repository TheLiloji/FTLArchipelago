
from __future__ import annotations

import importlib.util
import json
import sys
import unittest
from pathlib import Path

from .. import data

BASELINE_PATH = Path(__file__).with_name("ids_baseline.json")

REGENERATE = "Regenerate with: python3 apworld/tools/gen_id_baseline.py"


def _load_data_copy():

    spec = importlib.util.spec_from_file_location("ftl_data_reordered", Path(data.__file__))
    assert spec is not None and spec.loader is not None
    module = importlib.util.module_from_spec(spec)
    sys.modules[spec.name] = module
    try:
        spec.loader.exec_module(module)
    finally:
        del sys.modules[spec.name]
    return module


class TestIdentifiersAreWellFormed(unittest.TestCase):

    def test_item_names_and_ids_are_unique(self) -> None:
        names = [item.name for item in data.ITEMS]
        codes = [item.code for item in data.ITEMS]
        self.assertEqual(len(set(names)), len(names))
        self.assertEqual(len(set(codes)), len(codes))

    def test_location_names_ids_and_check_keys_are_unique(self) -> None:
        names = [location.name for location in data.LOCATIONS]
        codes = [location.code for location in data.LOCATIONS]
        checks = [location.check_id for location in data.LOCATIONS]
        self.assertEqual(len(set(names)), len(names))
        self.assertEqual(len(set(codes)), len(codes))
        self.assertEqual(
            len(set(checks)), len(checks),
            "two locations share a check key: the mod would tick one of them at random",
        )

    def test_item_and_location_ranges_do_not_overlap(self) -> None:
        self.assertLess(max(item.code for item in data.ITEMS), data.LOCATION_ID_BASE)
        self.assertGreaterEqual(
            min(location.code for location in data.LOCATIONS), data.LOCATION_ID_BASE
        )

    def test_ids_fit_in_a_signed_32_bit_integer(self) -> None:
        highest = max(
            max(item.code for item in data.ITEMS),
            max(location.code for location in data.LOCATIONS),
        )
        self.assertLess(highest, 2 ** 31)

    def test_check_keys_follow_the_formats_the_mod_emits(self) -> None:

        for location in data.LOCATIONS:
            if location.group == data.GROUP_SECTORS:
                expected = data.SECTOR_CHECK_FORMAT.format(
                    layout=location.layout, sector=location.sector
                )
            elif location.group == data.GROUP_VICTORIES:
                expected = data.VICTORY_CHECK_FORMAT.format(layout=location.layout)
            elif location.group == data.GROUP_SHOP_SLOTS:
                expected = data.SHOP_CHECK_FORMAT.format(slot=location.shop_slot)
            elif location.group == data.GROUP_SYSTEMS:
                if location.level == 1:
                    expected = data.SYSTEM_CHECK_FORMAT.format(system=location.system)
                else:
                    expected = data.SYSTEM_LEVEL_CHECK_FORMAT.format(
                        system=location.system, level=location.level
                    )
            elif location.group == data.GROUP_CREW:
                expected = data.CREW_CHECK_FORMAT.format(race=location.race)
            else:
                expected = data.ACHIEVEMENT_CHECK_FORMAT.format(
                    achievement=location.achievement
                )
            self.assertEqual(location.check_id, expected, location.name)

    def test_sector_numbers_have_no_decimal_point(self) -> None:

        for location in data.LOCATIONS:
            if location.group == data.GROUP_SECTORS:
                self.assertTrue(location.check_id.split(":")[-1].isdigit(), location.check_id)


class TestIdentifiersDoNotDependOnOrder(unittest.TestCase):

    @classmethod
    def setUpClass(cls) -> None:
        module = _load_data_copy()

        for table in ("SHIPS_RAW", "SYSTEMS_RAW", "GENERAL_ACHIEVEMENTS_RAW",
                      "SHIP_ACHIEVEMENTS_RAW", "FILLER_RAW", "TRAPS_RAW", "BONUS_RAW"):
            setattr(module, table, tuple(reversed(getattr(module, table))))

        module.SHIPS = module._build_ships()
        module.SHIPS_BY_BLUEPRINT = {ship.blueprint: ship for ship in module.SHIPS}
        module.LAYOUTS = module._build_layouts()
        module.SYSTEMS = module._build_systems()
        module.SYSTEMS_BY_ID = {system.system_id: system for system in module.SYSTEMS}

        cls.reordered_items = {item.name: item.code for item in module._build_items()}
        cls.reordered_locations = {
            location.name: (location.code, location.check_id)
            for location in module._build_locations()
        }

    def test_item_ids_are_unchanged(self) -> None:
        expected = {item.name: item.code for item in data.ITEMS}
        self.assertEqual(self.reordered_items, expected)

    def test_location_ids_and_check_keys_are_unchanged(self) -> None:
        expected = {
            location.name: (location.code, location.check_id) for location in data.LOCATIONS
        }
        self.assertEqual(self.reordered_locations, expected)


class TestIdentifiersMatchTheBaseline(unittest.TestCase):

    @classmethod
    def setUpClass(cls) -> None:
        cls.baseline = json.loads(BASELINE_PATH.read_text(encoding="utf-8"))

    def test_game_name_is_unchanged(self) -> None:
        self.assertEqual(
            data.GAME_NAME, self.baseline["game"],
            "changing the game name changes the identity of the whole world on the server side",
        )

    def test_known_items_kept_their_id(self) -> None:
        current = {item.name: item.code for item in data.ITEMS}
        self._compare(self.baseline["items"], current, "item")

    def test_known_locations_kept_their_id_and_check_key(self) -> None:
        current = {
            location.name: [location.code, location.check_id] for location in data.LOCATIONS
        }
        self._compare(self.baseline["locations"], current, "location")

    def test_baseline_is_up_to_date(self) -> None:
        missing_items = sorted(
            {item.name for item in data.ITEMS} - set(self.baseline["items"])
        )
        missing_locations = sorted(
            {loc.name for loc in data.LOCATIONS} - set(self.baseline["locations"])
        )
        self.assertEqual(
            (missing_items, missing_locations), ([], []),
            f"new content is not yet in the baseline. {REGENERATE}",
        )

    def _compare(self, recorded: dict, current: dict, label: str) -> None:
        removed = sorted(name for name in recorded if name not in current)
        self.assertEqual(
            removed, [],
            f"{label}(s) gone from the world: seeds that contain them are no longer "
            f"playable. If this is intended, edit {BASELINE_PATH.name} by hand.",
        )
        changed = sorted(
            f"{name}: {value} -> {current[name]}"
            for name, value in recorded.items()
            if name in current and _as_list(current[name]) != _as_list(value)
        )
        self.assertEqual(
            changed, [],
            f"{label}(s) whose id moved. A seed generated before this change is no longer "
            f"playable. {REGENERATE} only if the break is intended.",
        )


def _as_list(value):
    return value if isinstance(value, list) else [value]
