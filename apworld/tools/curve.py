#!/usr/bin/env python3

from __future__ import annotations

import os
import statistics
import sys
from collections import defaultdict
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]


def bootstrap():
    source = Path(os.environ.get("AP_SOURCE", "~/.local/opt/Archipelago-0.6.7-src")).expanduser()
    frozen = Path(os.environ.get("AP_ROOT", "~/.local/opt/Archipelago")).expanduser()
    sys.path.insert(0, str(source))
    for extra in (frozen / "lib" / "library.zip", frozen / "lib"):
        if extra.exists():
            sys.path.append(str(extra))
    import ModuleUpdate
    ModuleUpdate.update_ran = True
    os.chdir(source)


STEPS = (10, 50, 90)


def measure(world, data, items):
    caps = defaultdict(int)
    starts = defaultdict(int)
    ships = set()

    for name in items:
        item = data.ITEMS_BY_NAME.get(name)
        if item is None:
            continue
        if item.kind == data.KIND_CAP and item.system:
            caps[item.system] += 1
        elif item.kind == data.KIND_START and item.system:
            starts[item.system] += 1
        elif item.kind == data.KIND_SHIP and item.blueprint:
            ships.add(item.blueprint)

    reactor_bonus = starts.get(data.REACTOR_TARGET, 0)
    free_levels = sum(count for system, count in starts.items()
                      if system != data.REACTOR_TARGET)

    detail = {}
    for system, count in caps.items():
        detail["cap_" + system] = count
    for system, count in starts.items():
        detail["start_" + system] = count

    return {
        **detail,
        "shields": min(caps["shields"] + 1, 8),
        "systems": sum(1 for system, count in caps.items() if count > 0),
        "free_levels": free_levels,
        "reactor": reactor_bonus,
        "usable": min(free_levels, reactor_bonus + 8),
        "ships": len(ships),
    }


def main() -> int:
    bootstrap()
    from worlds.ftl import data

    count = int(sys.argv[1]) if len(sys.argv) > 1 else 40
    from test.bases import WorldTestBase  # noqa: F401
    from BaseClasses import MultiWorld
    from worlds.AutoWorld import AutoWorldRegister
    import Utils  # noqa: F401

    from test.general import setup_solo_multiworld
    from Fill import distribute_items_restrictive

    rows = {step: defaultdict(list) for step in STEPS}

    for seed in range(count):
        multiworld = setup_solo_multiworld(
            AutoWorldRegister.world_types[data.GAME_NAME], seed=seed
        )
        world = multiworld.worlds[1]

        distribute_items_restrictive(multiworld)

        ordered: list[str] = []
        state = multiworld.state.copy()
        remaining = [loc for loc in multiworld.get_filled_locations(1)
                     if loc.item is not None]
        guard = 0
        while remaining and guard < 500:
            guard += 1
            reachable = [loc for loc in remaining if loc.can_reach(state)]
            if not reachable:
                reachable = list(remaining)
            for loc in reachable:
                ordered.append(loc.item.name)
                state.collect(loc.item, prevent_sweep=True)
                remaining.remove(loc)

        total = len(ordered)
        for step in STEPS:
            taken = ordered[: max(1, total * step // 100)]
            for key, value in measure(world, data, taken).items():
                rows[step][key].append(value)

    print(f"Power curve over {count} seeds, default options")
    print()
    print(f"{'% items':>8} | {'shld.cap':>9} | {'systems':>8} | {'lvl.given':>11} | "
          f"{'reactor':>8} | {'usable':>11} | {'ships':>9}")
    print("-" * 82)
    for step in STEPS:
        row = rows[step]
        def avg(key):
            return statistics.mean(row[key]) if row[key] else 0
        print(f"{step:>7}% | {avg('shields'):>9.1f} | {avg('systems'):>8.1f} | "
              f"{avg('free_levels'):>11.1f} | {avg('reactor'):>8.1f} | {avg('usable'):>11.1f} | "
              f"{avg('ships'):>9.1f}")

    print()
    print("Detail by system, to write faithful test profiles:")
    for step in STEPS:
        detail = rows[step]
        print(f"  at {step:>3}% - caps: " + ", ".join(
            f"{name}={statistics.mean(values):.1f}"
            for name, values in sorted(detail.items()) if name.startswith("cap_")
        ))
        print(f"           starts: " + ", ".join(
            f"{name[6:]}={statistics.mean(values):.1f}"
            for name, values in sorted(detail.items()) if name.startswith("start_")
        ))
    print()
    print("Baseline: a vanilla ship starts with ~8 reactor bars and 6 to 8 levels")
    print("allocated. \"lvl. given\" is what gets added to that at the start of EACH run.")
    print("\"usable\" removes what the reactor cannot power.")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
