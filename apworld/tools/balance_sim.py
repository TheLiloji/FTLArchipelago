#!/usr/bin/env python3
"""Compares sector logic proposals by generating seeds with each and replaying them.

usage: balance_sim.py [seeds per proposal] [proposal name filter]

Built in: "current standard" and "current strict" (the apworld as it is). Every other proposal is a plugin
file in apworld/tools/sim_proposals/ (see _template.py). For each one, seeds are generated with its rule,
then replayed item by item. It reports, for sector 5, sector 8 and the Flagship, when they come into logic
(share of the seed's checks already done) and how strong the player is then: shield layers, weapon level,
engine level of the strongest flyable layout.

Environment:
  SIM_PRESET=presets/long_game.yaml   generate with a preset's options instead of the defaults
  SIM_JSON=path                       also write the results as JSON
  SIM_DEBUG=1                         print why a generation failed
"""

from __future__ import annotations

import importlib.util
import json
import os
import statistics
import sys
from pathlib import Path

HERE = Path(__file__).resolve().parent
ROOT = HERE.parents[1]
sys.path.insert(0, str(HERE))
from curve import bootstrap  # noqa: E402

START_LEVELS: dict[str, dict[str, int]] = json.loads((HERE / "ship_start_levels.json").read_text())
# A typical start, for checks that belong to no ship.
TYPICAL = {"shields": 2, "engines": 2, "weapons": 3, "oxygen": 1, "pilot": 1, "doors": 1, "sensors": 1,
           "medbay": 1, "reactor": 8}


class Helpers:
    """What a proposal can read from a CollectionState."""

    def __init__(self, world, data, rules, locations_module):
        self.world = world
        self.player = world.player
        self.data = data
        self.rules = rules
        self.locations = locations_module
        self.layouts = locations_module.selected_layouts(world.options)

    def start_level(self, system: str, layout: str | None) -> int:
        table = START_LEVELS.get(layout, TYPICAL) if layout else TYPICAL
        return table.get(system, 0)

    def level(self, state, system: str, layout: str | None = None) -> int:
        """The highest level of a system the player may have on that layout (or a typical ship): its start
        level plus the Progressive items received, or 1 + Progressive once its blueprint came in."""
        spec = self.data.SYSTEMS_BY_ID[system]
        progressive = state.count(f"Progressive {spec.display}", self.player)
        base = self.start_level(system, layout)
        if base == 0:
            if not state.has(f"{spec.display} blueprint", self.player):
                return 0
            base = 1
        return min(base + progressive, spec.max_level)

    def reactor(self, state, layout: str | None = None) -> int:
        return self.start_level("reactor", layout) + state.count("Reactor Power", self.player)

    def layers(self, state, layout: str | None = None) -> int:
        return self.level(state, "shields", layout) // 2

    def flyable(self, state) -> list[str]:
        """The layouts whose region the player can reach."""
        out = []
        for layout in self.layouts:
            region = self.world.multiworld.get_region(self.locations.region_name(layout), self.player)
            if region.can_reach(state):
                out.append(layout.blueprint)
        return out

    def layout_of(self, location) -> str | None:
        """The layout a check is played with, or None when any ship can do it."""
        if location.layout:
            return location.layout
        if location.ship:
            return location.ship
        return None

    def depth(self, location) -> int:
        return self.rules.location_depth(location, bool(self.world.options.shop_by_sector))

    def needs_flagship(self, location) -> bool:
        return self.rules.location_needs_flagship(location)


def load_plugins() -> dict:
    found = {}
    for path in sorted((HERE / "sim_proposals").glob("*.py")):
        if path.name.startswith("_"):
            continue
        spec = importlib.util.spec_from_file_location(f"sim_proposal_{path.stem}", path)
        module = importlib.util.module_from_spec(spec)
        spec.loader.exec_module(module)
        found[module.NAME] = module
    return found


def preset_options() -> dict | None:
    preset = os.environ.get("SIM_PRESET")
    if not preset:
        return None
    import yaml
    from worlds.ftl import data
    content = yaml.safe_load((ROOT / preset).read_text())
    return content[data.GAME_NAME]


def run(name: str, plugin, seeds: int):
    from BaseClasses import ItemClassification
    from Fill import distribute_items_restrictive
    from test.general import setup_multiworld, setup_solo_multiworld
    from worlds.AutoWorld import AutoWorldRegister
    from worlds.ftl import data, items as ftl_items, locations as ftl_locations, rules

    world_type = AutoWorldRegister.world_types[data.GAME_NAME]
    original_set_rules = world_type.set_rules
    original_create_item = ftl_items.create_item
    wanted = plugin.progression_items(data) if plugin else set()

    # The pool is built with items.create_item, not the world's method: patch that one.
    def create_item(world, item_name):
        item = original_create_item(world, item_name)
        if item_name in wanted:
            item.classification = ItemClassification.progression
        return item

    def set_rules(self):
        level = {"current standard": "option_standard", "current strict": "option_strict"}.get(name,
                                                                                             "option_relaxed")
        self.options.sector_logic.value = getattr(self.options.sector_logic, level)
        self.sector_logic_level = self.options.sector_logic.value
        original_set_rules(self)
        if not plugin:
            return
        helpers = Helpers(self, data, rules, ftl_locations)
        # Optional: a proposal may also act on placement, e.g. multiworld.early_items or local_early_items.
        if hasattr(plugin, "adjust"):
            plugin.adjust(helpers, self)
        for location in self.created_locations:
            rule = plugin.location_rule(helpers, location)
            if rule is not None:
                placed = self.get_location(location.name)
                old = placed.access_rule
                placed.access_rule = lambda state, old=old, rule=rule: old(state) and rule(state)
        win = plugin.win_rule(helpers)
        if win is not None:
            old_win = self.multiworld.completion_condition[self.player]
            self.multiworld.completion_condition[self.player] = lambda state: old_win(state) and win(state)

    world_type.set_rules = set_rules
    ftl_items.create_item = create_item
    options = preset_options()
    results, failures = [], 0
    try:
        for seed in range(seeds):
            try:
                if options is None:
                    multiworld = setup_solo_multiworld(world_type, seed=seed)
                else:
                    steps = ("generate_early", "create_regions", "create_items", "set_rules",
                             "connect_entrances", "generate_basic", "pre_fill")
                    multiworld = setup_multiworld(world_type, steps, seed=seed, options=options)
                distribute_items_restrictive(multiworld)
            except Exception as error:
                failures += 1
                if os.environ.get("SIM_DEBUG"):
                    print(f"  {name} seed {seed}: {type(error).__name__}: {str(error)[-600:]}")
                continue
            helpers = Helpers(multiworld.worlds[1], data, rules, ftl_locations)
            results.append(replay(multiworld, data, rules, helpers))
    finally:
        world_type.set_rules = original_set_rules
        ftl_items.create_item = original_create_item
    return results, failures


def strongest(helpers, state):
    best = (0, 0, 0)
    for layout in helpers.flyable(state) or [None]:
        best = max(best, (helpers.layers(state, layout), helpers.level(state, "weapons", layout),
                          helpers.level(state, "engines", layout)))
    return best


def replay(multiworld, data, rules, helpers):
    player = 1
    state = multiworld.state.copy()
    remaining = [loc for loc in multiworld.get_filled_locations(player) if loc.item is not None]
    total = len(remaining)
    probes = {5: [], 8: [], "boss": []}
    for loc in remaining:
        entry = data.LOCATIONS_BY_NAME.get(loc.name)
        if entry is None:
            continue
        if rules.location_needs_flagship(entry):
            probes["boss"].append(loc)
        elif rules.location_depth(entry) == 8:
            probes[8].append(loc)
        elif rules.location_depth(entry) == 5:
            probes[5].append(loc)
    opened, done, spheres, first_sphere = {}, 0, 0, 0
    while remaining:
        reachable = [loc for loc in remaining if loc.can_reach(state)]
        if not reachable:
            break
        spheres += 1
        if spheres == 1:
            first_sphere = len(reachable)
        for loc in reachable:
            # Checked after every item, not every sphere: a seed has only a handful of spheres.
            for key, locs in probes.items():
                if key not in opened and any(probe.can_reach(state) for probe in locs):
                    opened[key] = (done / total, *strongest(helpers, state))
            state.collect(loc.item, prevent_sweep=True)
            remaining.remove(loc)
            done += 1
    return {"opened": opened, "spheres": spheres, "first_sphere": first_sphere, "total": total}


def summarize(results):
    out = {}
    for key in (5, 8, "boss"):
        rows = [r["opened"][key] for r in results if key in r["opened"]]
        if rows:
            out[str(key)] = {"at": statistics.mean(r[0] for r in rows),
                             "layers": statistics.mean(r[1] for r in rows),
                             "weapons": statistics.mean(r[2] for r in rows),
                             "engines": statistics.mean(r[3] for r in rows)}
    if results:
        out["spheres"] = statistics.mean(r["spheres"] for r in results)
        out["first_sphere"] = statistics.mean(r["first_sphere"] for r in results)
    return out


def main() -> int:
    bootstrap()
    seeds = int(sys.argv[1]) if len(sys.argv) > 1 else 30
    only = sys.argv[2] if len(sys.argv) > 2 else os.environ.get("SIM_ONLY")
    plugins = load_plugins()
    proposals = {"current standard": None, "current strict": None, **plugins}
    print(f"{seeds} seeds per proposal, options: {os.environ.get('SIM_PRESET') or 'defaults'}.")
    print("'open' = share of the seed's checks done when it comes into logic, then shield layers / weapon "
          "level / engine level of the strongest flyable layout. 'early' = checks reachable at the start.")
    print()
    header = (f"{'proposal':<28} {'fail':>4} {'early':>5} {'sph':>4} | {'sector 5':^20} | {'sector 8':^20} | "
              f"{'Flagship':^20}")
    print(header)
    print("-" * len(header))
    report = {}
    for name, plugin in proposals.items():
        if only and only not in name:
            continue
        results, failures = run(name, plugin, seeds)
        summary = summarize(results)
        summary["failures"] = failures
        summary["seeds"] = seeds
        report[name] = summary
        cells = []
        for key in ("5", "8", "boss"):
            if key not in summary:
                cells.append(f"{'-':^20}")
                continue
            s = summary[key]
            cells.append(f"{s['at'] * 100:3.0f}% {s['layers']:3.1f}L {s['weapons']:3.1f}w {s['engines']:3.1f}e")
        print(f"{name:<28} {failures:>4} {summary.get('first_sphere', 0):5.0f} {summary.get('spheres', 0):4.1f} | "
              + " | ".join(cells), flush=True)
    if os.environ.get("SIM_JSON"):
        Path(os.environ["SIM_JSON"]).write_text(json.dumps(report, indent=1))
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
