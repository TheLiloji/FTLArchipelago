#!/usr/bin/env python3

from __future__ import annotations

import collections
import dataclasses
import json
import logging
import os
import random
import re
import sys
import traceback
import types
import typing
import warnings
from pathlib import Path

SOURCE = Path(os.environ.get("AP_SOURCE", "~/.local/opt/Archipelago-0.6.7-src")).expanduser()
FROZEN = Path(os.environ.get("AP_ROOT", "~/.local/opt/Archipelago")).expanduser()

if not (SOURCE / "worlds" / "AutoWorld.py").is_file():
    sys.exit(
        f"Archipelago sources not found in {SOURCE}. "
        "Run apworld/run_tests.sh once, it installs them."
    )
if not (SOURCE / "worlds" / "ftl").exists():
    sys.exit(
        f"{SOURCE / 'worlds' / 'ftl'} does not exist. Run apworld/run_tests.sh once, "
        "it creates the symlink to apworld/ftl."
    )

os.chdir(SOURCE)
sys.path.insert(0, str(SOURCE))
_stub = types.ModuleType("bsdiff4.core")
_stub.diff = _stub.patch = lambda *a, **k: b""
sys.modules["bsdiff4.core"] = _stub
sys.path.append(str(FROZEN / "lib" / "library.zip"))
sys.path.append(str(FROZEN / "lib"))
logging.disable(logging.ERROR)
warnings.simplefilter("ignore")

from BaseClasses import CollectionState  # noqa: E402
from Fill import FillError, distribute_items_restrictive  # noqa: E402
from Options import Choice, NamedRange, OptionSet, Range, Toggle  # noqa: E402
from test.general import setup_multiworld  # noqa: E402
from worlds.ftl import FTLWorld, data  # noqa: E402
from worlds.ftl.options import FTLOptions  # noqa: E402

COMMON = {
    "progression_balancing", "accessibility", "local_items", "non_local_items",
    "start_inventory", "start_hints", "start_location_hints", "exclude_locations",
    "priority_locations", "item_links", "plando_items", "start_inventory_from_pool",
}

HINTS = typing.get_type_hints(FTLOptions)
FIELDS = [
    (field.name, HINTS[field.name])
    for field in dataclasses.fields(FTLOptions)
    if field.name not in COMMON
]

GEN_STEPS = (
    "generate_early", "create_regions", "create_items", "set_rules",
    "connect_entrances", "generate_basic", "pre_fill",
)


def sample(rng: random.Random, name: str, option: type) -> object:
    if issubclass(option, OptionSet):
        keys = list(option.valid_keys)
        return sorted(rng.sample(keys, rng.randint(0, min(6, len(keys)))))
    if issubclass(option, (Range, NamedRange)):
        return rng.randint(option.range_start, option.range_end)
    if issubclass(option, (Choice, Toggle)):
        return rng.choice(sorted(option.options.values()))
    raise SystemExit(f"unhandled option type: {name} ({option})")


def make_the_goal_reachable(rng: random.Random, options: dict) -> dict:
    last_variant = options["ship_layouts"]
    available = [layout.display for layout in data.LAYOUTS if layout.variant <= last_variant]
    if options["goal"] == 0:
        options["victories_required"] = rng.randint(1, len(available))
        options["victory_layouts"] = []
    else:
        options["victory_layouts"] = sorted(
            rng.sample(available, rng.randint(1, min(6, len(available))))
        )
    return options


def run(seed: int, options: dict) -> tuple[str, str]:
    try:
        multiworld = setup_multiworld(FTLWorld, GEN_STEPS, seed=seed, options=options)
    except Exception as error:  # noqa: BLE001
        if type(error).__name__ == "OptionError":
            return "refusal", f"OptionError: {error}"
        return "FAIL", traceback.format_exc()

    try:
        world = multiworld.worlds[1]
        locations = [loc for loc in multiworld.get_locations(1) if loc.address is not None]
        if len(locations) != len(multiworld.itempool):
            return "FAIL", f"pool={len(multiworld.itempool)} for {len(locations)} locations"
        distribute_items_restrictive(multiworld)
        multiworld.state = multiworld.get_all_state()
        if not multiworld.has_beaten_game(multiworld.state, 1):
            return "FAIL", "goal unreachable with every item"
        for location in multiworld.get_locations(1):
            if not location.can_reach(multiworld.state):
                return "FAIL", f"location unreachable with every item: {location.name}"

        state = CollectionState(multiworld)
        state.sweep_for_advancements()
        if not multiworld.has_beaten_game(state, 1):
            return "FAIL", "UNPLAYABLE seed: the goal stays out of reach starting from nothing"

        json.dumps(world.fill_slot_data())
    except FillError as error:
        return "FAIL", f"FillError: {error}"
    except Exception:  # noqa: BLE001
        return "FAIL", traceback.format_exc()
    return "ok", "degraded" if world.logic.warnings else ""


def main() -> int:
    count = int(sys.argv[1]) if len(sys.argv) > 1 else 200
    first = int(sys.argv[2]) if len(sys.argv) > 2 else 0
    coherent = os.environ.get("COHERENT", "1") != "0"

    failures = 0
    refusals: list[str] = []
    generated = 0
    degraded = 0

    for seed in range(first, first + count):
        rng = random.Random(seed)
        options = {name: sample(rng, name, option) for name, option in FIELDS}
        if coherent:
            options = make_the_goal_reachable(rng, options)

        status, detail = run(seed, options)
        if status == "FAIL":
            failures += 1
            print(f"### FAIL seed={seed}")
            print(json.dumps(options, indent=1, sort_keys=True))
            print(detail)
            print("-" * 70)
            if failures >= 5:
                print("stopping after 5 failures")
                break
        elif status == "refusal":
            refusals.append(detail)
        else:
            generated += 1
            degraded += bool(detail)

    for reason, times in collections.Counter(
        re.sub(r"\d+", "N", reason)[:110] for reason in refusals
    ).most_common():
        print(f"  refusal x{times}: {reason}")
    print(f"loosened sector logic: {degraded}/{generated} seeds generated")
    print(f"summary: {count} draws, {failures} failures, {len(refusals)} explicit refusals")
    return 1 if failures else 0


if __name__ == "__main__":
    sys.exit(main())
