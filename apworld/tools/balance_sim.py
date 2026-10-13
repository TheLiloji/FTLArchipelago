#!/usr/bin/env python3
"""Compares sector logic proposals by generating seeds with each and replaying them.

usage: balance_sim.py [seeds per proposal]

For every proposal, seeds are generated with that rule, then played sphere by sphere. It reports when
sector 5, sector 8 and the Flagship come into logic (as a share of the seed's checks) and how strong the
player is at that point: shield layers, weapon level, engine level.
"""

from __future__ import annotations

import os
import statistics
import sys
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent))
from curve import bootstrap  # noqa: E402

# Levels most ships start with: the logic is ship-agnostic, so it assumes a typical start.
BASE_LEVEL = {"shields": 2, "engines": 2, "weapons": 3, "oxygen": 1, "pilot": 1, "doors": 1, "sensors": 1,
              "medbay": 1}
CORE = set(BASE_LEVEL)


def levels(state, player, data, system: str) -> int:
    progressive = state.count(f"Progressive {data.SYSTEMS_BY_ID[system].display}", player)
    if system in CORE:
        base = BASE_LEVEL[system]
    elif state.has(f"{data.SYSTEMS_BY_ID[system].display} blueprint", player):
        base = 1
    else:
        return 0
    return min(base + progressive, data.SYSTEMS_BY_ID[system].max_level)


def score_weighted(state, player, data) -> float:
    """Shields count a lot and keep their value; engines and weapons lose value in their last levels."""
    score = 4.0 * (levels(state, player, data, "shields") // 2)
    engines = levels(state, player, data, "engines")
    score += 1.5 * min(engines, 6) + 0.5 * max(0, engines - 6)
    weapons = levels(state, player, data, "weapons")
    score += 2.0 * min(weapons, 6) + 1.0 * max(0, weapons - 6)
    drones = levels(state, player, data, "drones")
    score += (3.0 + drones) if drones else 0.0
    for system in ("teleporter", "cloaking", "hacking", "mind", "artillery"):
        n = levels(state, player, data, system)
        score += (2.0 + n) if n else 0.0
    for system in ("oxygen", "pilot", "doors", "sensors", "medbay", "clonebay", "battery"):
        score += 0.5 * levels(state, player, data, system)
    score += 1.0 * state.count("Reactor Power", player)
    return score


def score_flat(state, player, data) -> float:
    """Every upgrade item counts the same: blueprints, progressive levels and reactor bars."""
    total = sum(state.count(f"Progressive {s.display}", player) + state.count(f"{s.display} blueprint", player)
                for s in data.SYSTEMS)
    return float(total + state.count("Reactor Power", player))


def score_current(state, player, data) -> float:
    return float(state.count_group(data.GROUP_BLUEPRINTS, player))


# Milestones: minimum levels per sector instead of a score (shields count in levels: 2 levels = 1 layer).
MILESTONES = {
    5: {"shields": 4},
    8: {"shields": 4, "weapons": 5},
    "boss": {"shields": 6, "weapons": 6, "engines": 4},
}

PROPOSALS = {
    "current standard": None,
    "current strict": None,
    "A weighted, gentle": (score_weighted, {3: 0.10, 5: 0.20, 7: 0.32, "boss": 0.40}),
    "B weighted, medium": (score_weighted, {3: 0.15, 5: 0.30, 7: 0.45, "boss": 0.55}),
    "B2 weighted, lower": (score_weighted, {3: 0.08, 5: 0.16, 7: 0.26, "boss": 0.34}),
    "C flat, medium": (score_flat, {3: 0.10, 5: 0.25, 7: 0.40, "boss": 0.50}),
    "D milestones, soft": "milestones",
    "E milestones, firm": "milestones",
}

MILESTONE_SETS = {
    "D milestones, soft": {5: {"shields": 4}, 8: {"shields": 4, "weapons": 4},
                           "boss": {"shields": 6, "weapons": 5}},
    "E milestones, firm": {5: {"shields": 4}, 8: {"shields": 4, "weapons": 5},
                           "boss": {"shields": 6, "weapons": 6, "engines": 4}},
}

if os.environ.get("SIM_MILESTONES") == "shields":
    MILESTONES = {5: {"shields": 4}, 8: {"shields": 4}, "boss": {"shields": 6}}
if os.environ.get("SIM_MILESTONES") == "boss":
    MILESTONES = {5: {}, 8: {}, "boss": {"shields": 6}}
if os.environ.get("SIM_MILESTONES") == "soft":
    MILESTONES = {5: {"shields": 4}, 8: {"shields": 4, "weapons": 4}, "boss": {"shields": 6, "weapons": 5}}


def run(name: str, seeds: int):
    from BaseClasses import ItemClassification
    from Fill import distribute_items_restrictive
    from test.general import setup_solo_multiworld
    from worlds.AutoWorld import AutoWorldRegister
    from worlds.ftl import data, items as ftl_items, rules

    world_type = AutoWorldRegister.world_types[data.GAME_NAME]
    proposal = PROPOSALS[name]
    global MILESTONES
    if name in MILESTONE_SETS:
        MILESTONES = MILESTONE_SETS[name]
    original_set_rules = world_type.set_rules
    original_create_item = ftl_items.create_item
    upgrade_groups = {data.GROUP_SYSTEM_LEVELS, data.GROUP_BLUEPRINTS}

    # Only what the rule reads becomes progression: marking every upgrade overloads the early locations.
    milestone_systems = {system for wanted in MILESTONES.values() for system in wanted}

    def create_item(world, item_name):
        item = original_create_item(world, item_name)
        entry = data.ITEMS_BY_NAME.get(item_name)
        if not proposal or not entry:
            return item
        if proposal == "milestones":
            if entry.group == data.GROUP_SYSTEM_LEVELS and entry.system in milestone_systems:
                item.classification = ItemClassification.progression
        elif entry.group in upgrade_groups or item_name == "Reactor Power":
            item.classification = ItemClassification.progression
        return item

    def set_rules(self):
        if name == "current strict":
            self.options.sector_logic.value = self.options.sector_logic.option_strict
            self.sector_logic_level = self.options.sector_logic.value
        if name == "current standard":
            self.options.sector_logic.value = self.options.sector_logic.option_standard
            self.sector_logic_level = self.options.sector_logic.value
        if proposal:
            self.options.sector_logic.value = self.options.sector_logic.option_relaxed
            self.sector_logic_level = self.options.sector_logic.value
        original_set_rules(self)
        if not proposal:
            return
        player = self.player
        if proposal == "milestones":
            def meets(state, wanted):
                return all(levels(state, player, data, system) >= level for system, level in wanted.items())

            def wanted_at(depth, boss):
                wanted = {}
                for sector in (5, 8):
                    if depth >= sector:
                        wanted = MILESTONES[sector]
                if boss:
                    wanted = MILESTONES["boss"]
                return wanted

            for location in self.created_locations:
                wanted = wanted_at(rules.location_depth(location, bool(self.options.shop_by_sector)),
                                   rules.location_needs_flagship(location))
                if wanted:
                    placed = self.get_location(location.name)
                    old = placed.access_rule
                    placed.access_rule = lambda state, old=old, w=wanted: old(state) and meets(state, w)
            old_win = self.multiworld.completion_condition[player]
            self.multiworld.completion_condition[player] = (
                lambda state: old_win(state) and meets(state, MILESTONES["boss"]))
            return
        score, steps = proposal
        full = score(_FullState(self, data), player, data)

        def need(depth, boss):
            share = 0.0
            for sector, value in steps.items():
                if sector != "boss" and depth >= sector:
                    share = value
            if boss:
                share = max(share, steps["boss"])
            return share * full

        for location in self.created_locations:
            threshold = need(rules.location_depth(location, bool(self.options.shop_by_sector)),
                             rules.location_needs_flagship(location))
            if threshold > 0:
                placed = self.get_location(location.name)
                old = placed.access_rule
                placed.access_rule = (lambda state, old=old, t=threshold:
                                      old(state) and score(state, player, data) >= t)
        boss_need = steps["boss"] * full
        old_win = self.multiworld.completion_condition[player]
        self.multiworld.completion_condition[player] = (
            lambda state: old_win(state) and score(state, player, data) >= boss_need)

    world_type.set_rules = set_rules
    ftl_items.create_item = create_item
    from worlds.ftl import options as ftl_options
    combat_default = ftl_options.CombatChecks.default
    ftl_options.CombatChecks.default = int(os.environ.get("SIM_COMBAT", "0"))
    results = []
    failures = 0
    try:
        for seed in range(seeds):
            try:
                multiworld = setup_solo_multiworld(world_type, seed=seed)
                distribute_items_restrictive(multiworld)
            except Exception as error:
                failures += 1
                if os.environ.get("SIM_DEBUG"):
                    print(f"  {name} seed {seed}: {type(error).__name__}: {str(error)[-900:]}")
                continue
            results.append(replay(multiworld, data, rules))
    finally:
        world_type.set_rules = original_set_rules
        ftl_items.create_item = original_create_item
        ftl_options.CombatChecks.default = combat_default
    return results, failures


class _FullState:
    """Counts every item of the world's pool: the most a seed can give."""

    def __init__(self, world, data):
        self.counts = {}
        for item in world.multiworld.itempool:
            if item.player == world.player:
                self.counts[item.name] = self.counts.get(item.name, 0) + 1
        self.data = data

    def count(self, name, player):
        return self.counts.get(name, 0)

    def has(self, name, player, count=1):
        return self.counts.get(name, 0) >= count

    def count_group(self, group, player):
        return sum(n for name, n in self.counts.items()
                   if name in self.data.ITEMS_BY_NAME and self.data.ITEMS_BY_NAME[name].group == group)


def replay(multiworld, data, rules):
    player = 1
    state = multiworld.state.copy()
    remaining = [loc for loc in multiworld.get_filled_locations(player) if loc.item is not None]
    total = len(remaining)
    done = 0
    opened = {}
    spheres = 0
    probes = {5: None, 8: None, "boss": None}
    probe_locations = {key: [] for key in probes}
    for loc in remaining:
        entry = data.LOCATIONS_BY_NAME.get(loc.name)
        if entry is None:
            continue
        depth = rules.location_depth(entry)
        if rules.location_needs_flagship(entry):
            probe_locations["boss"].append(loc)
        elif depth == 8:
            probe_locations[8].append(loc)
        elif depth == 5:
            probe_locations[5].append(loc)
    while remaining:
        reachable = [loc for loc in remaining if loc.can_reach(state)]
        if not reachable:
            break
        spheres += 1
        for loc in reachable:
            # Checked after every item, not every sphere: a seed has only a handful of spheres.
            for key, locs in probe_locations.items():
                if key not in opened and any(probe.can_reach(state) for probe in locs):
                    opened[key] = (done / total, levels(state, player, data, "shields") // 2,
                                   levels(state, player, data, "weapons"),
                                   levels(state, player, data, "engines"))
            state.collect(loc.item, prevent_sweep=True)
            remaining.remove(loc)
            done += 1
    return {"opened": opened, "spheres": spheres}


def main() -> int:
    bootstrap()
    seeds = int(sys.argv[1]) if len(sys.argv) > 1 else 30
    print(f"{seeds} seeds per proposal, default options. 'open at' = share of the seed's checks done "
          "when it comes into logic; then shield layers / weapon level / engine level at that point.")
    print()
    header = f"{'proposal':<22} {'fail':>4} {'spheres':>7} | {'sector 5':^22} | {'sector 8':^22} | {'Flagship':^22}"
    print(header)
    print("-" * len(header))
    only = os.environ.get("SIM_ONLY")
    for name in PROPOSALS:
        if only and only not in name:
            continue
        results, failures = run(name, seeds)
        cells = []
        for key in (5, 8, "boss"):
            rows = [r["opened"][key] for r in results if key in r["opened"]]
            if not rows:
                cells.append(f"{'-':^22}")
                continue
            at = statistics.mean(r[0] for r in rows) * 100
            sh = statistics.mean(r[1] for r in rows)
            wp = statistics.mean(r[2] for r in rows)
            en = statistics.mean(r[3] for r in rows)
            cells.append(f"{at:4.0f}%  {sh:3.1f}sh {wp:3.1f}w {en:3.1f}e")
        spheres = statistics.mean(r["spheres"] for r in results) if results else 0
        print(f"{name:<22} {failures:>4} {spheres:7.1f} | " + " | ".join(cells))
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
