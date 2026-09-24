#!/usr/bin/env python3

from __future__ import annotations

import argparse
import collections
import json
import logging
import os
import sys
import types
import warnings
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]
SOURCE = Path(os.environ.get("AP_SOURCE", "~/.local/opt/Archipelago-0.6.7-src")).expanduser()
FROZEN = Path(os.environ.get("AP_ROOT", "~/.local/opt/Archipelago")).expanduser()

if not (SOURCE / "worlds" / "ftl").exists():
    sys.exit("run apworld/run_tests.sh once: it installs the sources and the world's symlink")

os.chdir(SOURCE)
sys.path.insert(0, str(SOURCE))
_stub = types.ModuleType("bsdiff4.core")
_stub.diff = _stub.patch = lambda *a, **k: b""
sys.modules["bsdiff4.core"] = _stub
sys.path.append(str(FROZEN / "lib" / "library.zip"))
sys.path.append(str(FROZEN / "lib"))
logging.disable(logging.ERROR)
warnings.simplefilter("ignore")

import yaml  # noqa: E402
from test.general import setup_multiworld  # noqa: E402
from worlds.ftl import FTLWorld, data  # noqa: E402

GEN_STEPS = (
    "generate_early", "create_regions", "create_items", "set_rules",
    "connect_entrances", "generate_basic", "pre_fill",
)

MINUTES_PER_SECTOR = 5.0
DEPTH_REACHED = {
    "beginner": 5.0,
    "veteran": 8.0,
}
MINUTES_BETWEEN_RUNS = 3.0
RUNS_PER_VICTORY = {"beginner": 4.0, "veteran": 1.7}
WARMUP_RUNS = 3.0


def load_options(path: Path) -> tuple[str, dict]:
    document = yaml.safe_load(path.read_text(encoding="utf-8"))
    game = data.GAME_NAME
    if game not in document:
        raise SystemExit(f"{path.name}: no \"{game}\" section")
    return document.get("name", path.stem), document[game]


def spheres(multiworld, player: int) -> list[list[str]]:

    from BaseClasses import CollectionState

    state = CollectionState(multiworld)
    remaining = {
        location for location in multiworld.get_locations(player)
        if location.address is not None
    }
    waves: list[list[str]] = []
    pool = list(multiworld.itempool)

    while remaining:
        reachable = sorted(
            location.name for location in remaining if location.can_reach(state)
        )
        if not reachable:
            break
        waves.append(reachable)
        remaining = {loc for loc in remaining if loc.name not in set(reachable)}
        for _ in range(len(reachable)):
            if not pool:
                break
            state.collect(pool.pop(0), prevent_sweep=True)
    return waves


FAMILY_LABEL = {
    data.GROUP_SECTORS: "sector",
    data.GROUP_VICTORIES: "victory",
    data.GROUP_SHIP_ACHIEVEMENTS: "ship achievement",
    data.GROUP_GENERAL_ACHIEVEMENTS: "general achievement",
    data.GROUP_SHOP_SLOTS: "shop",
}


def families(names: list[str]) -> collections.Counter:
    counter: collections.Counter = collections.Counter()
    for name in names:
        location = data.LOCATIONS_BY_NAME.get(name)
        group = location.group if location else "?"
        counter[FAMILY_LABEL.get(group, group)] += 1
    return counter


def estimate_hours(
    by_family: collections.Counter, victories_required: int, level: str
) -> tuple[float, float]:

    depth = DEPTH_REACHED[level]
    minutes_per_run = depth * MINUTES_PER_SECTOR + MINUTES_BETWEEN_RUNS

    runs_to_goal = WARMUP_RUNS + victories_required * RUNS_PER_VICTORY[level]

    sector_checks = by_family.get("sector", 0)
    checks_per_run = max(1.0, depth - 1)
    runs_for_sectors = sector_checks / checks_per_run if sector_checks else 0.0
    runs_for_victories = float(by_family.get("victory", 0))
    runs_for_achievements = (
        by_family.get("ship achievement", 0) + by_family.get("general achievement", 0)
    ) / 3.0
    runs_to_finish = max(
        runs_to_goal,
        runs_for_sectors + runs_for_victories + runs_for_achievements,
    )

    return (
        runs_to_goal * minutes_per_run / 60.0,
        runs_to_finish * minutes_per_run / 60.0,
    )


def checks_per_hour(options, by_family: collections.Counter, level: str) -> float:

    depth = DEPTH_REACHED[level]
    minutes_per_run = depth * MINUTES_PER_SECTOR + MINUTES_BETWEEN_RUNS

    floor = options.sectorsanity_first_sector.value
    ceiling = min(options.sectorsanity_last_sector.value, int(depth))
    sectors_per_run = max(0, ceiling - floor + 1) if by_family.get("sector") else 0

    shops_per_run = depth / 2.0 if by_family.get("shop") else 0.0

    return (sectors_per_run + shops_per_run) / (minutes_per_run / 60.0)


def worst_wait(options, by_family: collections.Counter, level: str) -> float:

    depth = DEPTH_REACHED[level]
    run_length = depth * MINUTES_PER_SECTOR
    floor = options.sectorsanity_first_sector.value
    ceiling = options.sectorsanity_last_sector.value

    def worst_for_a_phase(phase: int) -> float:

        instants: list[float] = []
        for sector in range(1, int(depth) + 1):
            minute = (sector - 1) * MINUTES_PER_SECTOR
            sector_check = by_family.get("sector") and floor <= sector <= ceiling
            shop = by_family.get("shop") and sector % 2 == phase % 2
            if sector_check or shop:
                instants.append(minute)
        if not instants:
            return run_length + MINUTES_BETWEEN_RUNS
        gaps = [b - a for a, b in zip(instants, instants[1:])]
        gaps.append((run_length - instants[-1]) + MINUTES_BETWEEN_RUNS + instants[0])
        return max(gaps)

    return max(worst_for_a_phase(1), worst_for_a_phase(2))


def report(path: Path, level: str, seed: int, as_json: bool) -> dict:
    name, options = load_options(path)
    multiworld = setup_multiworld(FTLWorld, GEN_STEPS, seed=seed, options=options)
    world = multiworld.worlds[1]

    addressed = [
        location.name for location in multiworld.get_locations(1)
        if location.address is not None
    ]
    by_family = families(addressed)

    pool = collections.Counter(
        (item.classification.name or str(item.classification))
        for item in multiworld.itempool
    )
    waves = spheres(multiworld, 1)

    filler_share = (
        100.0 * (pool.get("filler", 0) + pool.get("trap", 0)) / max(1, len(multiworld.itempool))
    )
    victories = (
        len(world.options.victory_layouts.value)
        if world.options.goal == world.options.goal.option_victory_selection
        else world.options.victories_required.value
    )
    to_goal, to_finish = estimate_hours(by_family, victories, level)
    rate = checks_per_hour(world.options, by_family, level)
    first_wave_share = 100.0 * len(waves[0]) / max(1, len(addressed)) if waves else 0.0

    result = {
        "preset": path.name,
        "name": name,
        "locations": len(addressed),
        "families": dict(by_family),
        "pool": dict(pool),
        "filler_%": round(filler_share, 1),
        "spheres": [len(wave) for wave in waves],
        "sphere_1_%": round(first_wave_share, 1),
        "free_shop_slots": by_family.get("shop", 0),
        "layouts": len(world.selected_layouts),
        "hours_to_goal": round(to_goal, 1),
        "hours_100": round(to_finish, 1),
        "checks_per_hour": round(rate, 1),
        "worst_wait_min": round(worst_wait(world.options, by_family, level), 1),
    }

    if as_json:
        return result

    print(f"\n=== {path.name} - {name}")
    print(f"  {result['locations']} locations, {result['layouts']} layouts")
    print("  families : " + ", ".join(
        f"{count} {family}" for family, count in by_family.most_common()
    ))
    print("  pool     : " + ", ".join(
        f"{count} {kind}" for kind, count in pool.most_common()
    ) + f"  ({result['filler_%']} % filler)")
    print(f"  spheres  : {result['spheres']}  (sphere 1 = {result['sphere_1_%']} % of checks)")
    print(f"  free shop slots: {result['free_shop_slots']}")
    print(f"  estimated duration ({level}): ~{result['hours_to_goal']} h to the goal, "
          f"~{result['hours_100']} h to collect everything")
    print(f"  throughput: ~{result['checks_per_hour']} checks per hour of play")
    print(f"  worst wait with nothing to give: ~{result['worst_wait_min']} min")
    return result


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("presets", nargs="+", type=Path)
    parser.add_argument("--seed", type=int, default=4242)
    parser.add_argument(
        "--level", choices=sorted(DEPTH_REACHED), default="beginner",
        help="player level, for the duration model; \"veteran\" goes further per run",
    )
    parser.add_argument("--json", action="store_true")
    arguments = parser.parse_args()

    results = []
    for path in arguments.presets:
        target = path if path.is_absolute() else ROOT / path
        level = arguments.level
        if "veteran" in target.stem.lower():
            level = "veteran"
        results.append(report(target, level, arguments.seed, arguments.json))

    if arguments.json:
        print(json.dumps(results, indent=2, ensure_ascii=False))
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
