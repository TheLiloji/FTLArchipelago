"""Difficulty-scaled milestones: E's fixed milestones, gentler or firmer with the seed's victory_difficulty.

any    (Easy wins count): sector 5 needs 2 shield layers; the Flagship 2 layers, weapons 5, engines 3.
normal (default)        : sector 5 needs 2 layers; sector 8 adds weapons 5; the Flagship 3 layers, weapons 6, engines 4.
hard   (Hard only)      : sector 5 needs 2 layers and engines 3; sector 8 3 layers and weapons 5;
                          the Flagship 4 layers, weapons 7, engines 5.

Levels are counted on a typical ship (2 shield bars, 2 engines, 3 weapons at start) plus the Progressive items.
For the simulator only: DIFFICULTY_SIM_FORCE=any|normal|hard overrides the seed's option.
"""

import os

NAME = "difficulty-scaled milestones"
SUMMARY = ("Sector 5 needs 2 shield layers; the Flagship needs 3 layers, weapons 6 and engines 4 "
           "(2 layers / 5 / 3 if Easy wins count, 4 layers / 7 / 5 if only Hard wins count).")

MILESTONES = {
    "any": {5: {"shields": 4},
            8: {"shields": 4, "weapons": 4},
            "boss": {"shields": 4, "weapons": 5, "engines": 3}},
    "normal": {5: {"shields": 4},
               8: {"shields": 4, "weapons": 5},
               "boss": {"shields": 6, "weapons": 6, "engines": 4}},
    "hard": {5: {"shields": 4, "engines": 3},
             8: {"shields": 6, "weapons": 5},
             "boss": {"shields": 8, "weapons": 7, "engines": 5}},
}


def _table(h):
    key = os.environ.get("DIFFICULTY_SIM_FORCE") or h.world.options.victory_difficulty.current_key
    return MILESTONES[key]


def progression_items(data):
    systems = {s for table in MILESTONES.values() for wanted in table.values() for s in wanted}
    return {f"Progressive {data.SYSTEMS_BY_ID[s].display}" for s in systems}


def _wanted(table, h, location):
    if h.needs_flagship(location):
        return table["boss"]
    depth = h.depth(location)
    wanted = {}
    for sector in (5, 8):
        if depth >= sector:
            wanted = table[sector]
    return wanted


def _active(h):
    # Without Progressive items, levels are bought freely: nothing to wait for. Per-ship items are named
    # "<Ship>: Progressive X" and are not modelled here.
    options = h.world.options
    return bool(options.progressive_systems) and not options.progressive_systems_per_ship


def _level(h, state, system):
    """Typical-ship level, aware of Full System Upgrades (one Progressive item = the whole system)."""
    if not h.world.options.full_system_upgrades:
        return h.level(state, system)
    spec = h.data.SYSTEMS_BY_ID[system]
    base = h.level(state, system)
    if base and state.has(f"Progressive {spec.display}", h.player):
        return spec.max_level
    return base


def _meets(h, wanted):
    return lambda state: all(_level(h, state, s) >= n for s, n in wanted.items())


def location_rule(h, location):
    if not _active(h):
        return None
    wanted = _wanted(_table(h), h, location)
    return _meets(h, wanted) if wanted else None


def win_rule(h):
    return _meets(h, _table(h)["boss"]) if _active(h) else None
