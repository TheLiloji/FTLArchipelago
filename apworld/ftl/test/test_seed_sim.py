from __future__ import annotations

import collections
import importlib.util
import random
import statistics
import sys
from pathlib import Path
from unittest import TestCase

TOOLS = Path(__file__).resolve().parents[2] / "tools"
PRESETS = Path(__file__).resolve().parents[3] / "presets"


def _load_sim():
    spec = importlib.util.spec_from_file_location("seed_sim", TOOLS / "seed_sim.py")
    module = importlib.util.module_from_spec(spec)
    # dataclasses look their module up in sys.modules.
    sys.modules.setdefault("seed_sim", module)
    spec.loader.exec_module(module)
    return module


sim = _load_sim()


def tiny_seed(**overrides):
    """Two ships. The Kestrel flies from the start, its sector 2 check holds the Engi key, the Engi's sector 3 check
    holds the Archive the goal needs. One victory, on any ship."""
    state = collections.Counter()

    def has(name):
        return lambda s: s[name] > 0

    always = lambda s: True  # noqa: E731
    checks = [
        sim.Check("Kestrel sector 2", sim.PHYSICAL, 2, frozenset({"K"}), "Engi key", always, layout="K",
                  group="Sectors"),
        sim.Check("Kestrel sector 3", sim.PHYSICAL, 3, frozenset({"K"}), "Scrap", always, layout="K", group="Sectors"),
        sim.Check("Engi sector 3", sim.PHYSICAL, 3, frozenset({"E"}), "Archive", has("Engi key"), layout="E",
                  group="Sectors"),
        sim.Check("Kestrel victory", sim.VICTORY, 8, frozenset({"K"}), "Scrap", always, group="Ship victories"),
        sim.Check("Engi victory", sim.VICTORY, 8, frozenset({"E"}), "Scrap", has("Engi key"), group="Ship victories"),
    ]
    values = dict(
        checks=checks, layouts=["K", "E"], state=state,
        collect=lambda s, item: s.update([item]),
        flyable=lambda s: ["K"] + (["E"] if s["Engi key"] else []),
        depth_limit=lambda s, layout: 8,
        ready=lambda s, layout, sector: True,
        boss_ready=lambda s, layout: True,
        goal_done=lambda s, victories: bool(victories) and s["Archive"] > 0,
        victories_short=lambda victories: not victories,
    )
    values.update(overrides)
    return sim.Seed(**values)


SURE = sim.Profile(minutes_per_sector=10.0, death_ready=0.0, death_unready=0.0, win_ready=1.0, win_unready=1.0,
                   buys_per_store=0.0, events_per_sector=0.0, achievement_chance=1.0, crew_chance=1.0,
                   system_chance=1.0)


class TestModel(TestCase):

    def test_a_sure_player_reaches_the_goal_in_two_runs(self) -> None:
        result = sim.play(tiny_seed(), SURE, random.Random(1))
        self.assertTrue(result.goal, result)
        # Run 1: the Kestrel wins but the Archive waits on the Engi, flown in run 2.
        self.assertEqual(result.runs, 2)
        self.assertEqual(result.minutes, 2 * (2 + 8 * 10 + 10))

    def test_same_dice_same_play(self) -> None:
        profile = sim.PROFILES["average"]
        first = sim.play(tiny_seed(), profile, random.Random(7))
        second = sim.play(tiny_seed(), profile, random.Random(7))
        self.assertEqual(first, second)

    def test_a_seed_that_cannot_be_won_is_reported_with_what_is_left(self) -> None:
        seed = tiny_seed(goal_done=lambda s, victories: False)
        result = sim.play(seed, SURE, random.Random(1), max_runs=20)
        self.assertFalse(result.goal)
        self.assertTrue(result.stuck_reason)
        self.assertEqual(result.left_in_logic, [])

    def test_a_check_waiting_on_an_item_nobody_finds_shows_up_as_left_in_logic(self) -> None:
        seed = tiny_seed()
        # The Engi key is now behind a store that never sells: the Engi never flies.
        seed.checks[0] = sim.Check("Store 1", sim.SHOP, 1, None, "Engi key", lambda s: True, order=1)
        result = sim.play(seed, SURE, random.Random(1), max_runs=10)
        self.assertFalse(result.goal)
        self.assertEqual(result.left_in_logic, ["Store 1"])

    def test_the_player_buys_the_important_package_first(self) -> None:
        state = collections.Counter()
        seed = tiny_seed(state=state)
        seed.checks[0] = sim.Check("Store 1", sim.SHOP, 1, None, "Scrap", lambda s: True, order=1)
        seed.checks.append(sim.Check("Store 2", sim.SHOP, 1, None, "Engi key", lambda s: True, order=2, priority=2))
        profile = sim.Profile(**{**SURE.__dict__, "buys_per_store": 1.0})
        trace: list[str] = []
        sim.play(seed, profile, random.Random(1), trace=trace)
        bought = [line for line in trace if "Store" in line]
        self.assertIn("Store 2", bought[0])

    def test_sector_skip_never_skips_a_sector_whose_store_still_has_packages(self) -> None:
        seed = tiny_seed(sector_skip=True, shop_by_sector=True)
        # Only sold in sector 2, after the Kestrel already went deeper.
        seed.checks.append(sim.Check("Store 2", sim.SHOP, 2, None, "Scrap", lambda s: True, order=2))
        profile = sim.Profile(**{**SURE.__dict__, "buys_per_store": 1.0})
        result = sim.play(seed, profile, random.Random(1), play_to_the_end=True)
        self.assertEqual(result.checks_done, result.checks_total)

    def test_a_skipped_sector_does_not_hide_a_crew_check(self) -> None:
        seed = tiny_seed(sector_skip=True)
        seed.checks.append(sim.Check("First Slug aboard", sim.LUCK, 4, None, "Scrap", lambda s: True, group="crew"))
        result = sim.play(seed, SURE, random.Random(1), play_to_the_end=True)
        self.assertEqual(result.checks_done, result.checks_total)

    def test_shop_pages_match_the_mod(self) -> None:
        # apShopPages in mod/ArchipelagoFTL/data/archipelago/shopgift.lua
        self.assertEqual(sim.shop_pages(20, False, 0), 1)
        self.assertEqual(sim.shop_pages(61, False, 0), 3)
        self.assertEqual(sim.shop_pages(101, False, 0), 4)
        self.assertEqual(sim.shop_pages(31, False, 3), 4)
        self.assertEqual(sim.shop_pages(31, True, 3), 1)


class TestOnRealSeeds(TestCase):

    def test_the_sync_preset_fits_its_three_hours(self) -> None:
        options = sim.load_options(PRESETS / "sync_3h.yaml")
        rows = sim.simulate_preset(options, range(1, 31), sim.PROFILES["average"])
        errors = [row for row in rows if "error" in row]
        self.assertFalse(errors, errors[:2])
        self.assertTrue(all(row["goal"] for row in rows), [row["seed"] for row in rows if not row["goal"]])
        hours = statistics.median(row["minutes"] / 60 for row in rows)
        self.assertLessEqual(hours, 3.5, "the sync preset drifted past its 3 h")
        self.assertLessEqual(statistics.median(row["spheres"][0] for row in rows), 30, "sphere 1 grew")
        self.assertLessEqual(max(row["locations"] for row in rows), 300, "a sync wants under 300 checks")
