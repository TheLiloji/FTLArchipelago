"""Per-ship milestones: the same targets as E, measured on the ship that does the check, with a fair deal for
ships that start without shields (Stealth).

A check tied to a layout is judged on that layout. A check any ship can do needs one flyable layout that meets
the milestone. Ships that start with no shields need one shield layer less in sectors 5 to 8, but engines 5
(evasion) instead; the Flagship asks the same of every ship.
"""

NAME = "per-ship milestones"
SUMMARY = ("Measured on the ship you fly: sector 5 needs 2 shield layers, sector 8 also weapons 5, the Flagship "
           "3 layers, weapons 6 and engines 4. Ships that start without shields (Stealth) need one layer less "
           "before the Flagship, if their engines are at 5.")

# Requirements in shield LAYERS (2 levels each) and system levels.
MILESTONES = {
    5: {"layers": 2},
    8: {"layers": 2, "weapons": 5},
    "boss": {"layers": 3, "weapons": 6, "engines": 4},
}
# Floor for engines on a shieldless ship before the +2 is added (so sector 5 asks for engines 5).
SHIELDLESS_ENGINE_BASE = 3
SHIELDLESS_ENGINE_BONUS = 2


def progression_items(data):
    return {"Progressive Shields", "Shields blueprint", "Progressive Weapon Control", "Progressive Engines"}


def _key(h, location):
    if h.needs_flagship(location):
        return "boss"
    depth = h.depth(location)
    key = None
    for sector in (5, 8):
        if depth >= sector:
            key = sector
    return key


def _wanted_for(h, key, layout):
    wanted = dict(MILESTONES[key])
    if key != "boss" and layout is not None and h.start_level("shields", layout) == 0:
        wanted["layers"] -= 1
        wanted["engines"] = max(wanted.get("engines", 0), SHIELDLESS_ENGINE_BASE) + SHIELDLESS_ENGINE_BONUS
    return wanted


def _level(h, state, system, layout):
    """Like h.level, but honest about the options: without Progressive items a level is never capped, without
    blueprints a system can be bought freely, and Full System Upgrades gives every level with one item."""
    options = h.world.options
    spec = h.data.SYSTEMS_BY_ID[system]
    base = h.start_level(system, layout)
    if base == 0:
        if options.system_blueprints and not state.has(f"{spec.display} blueprint", h.player):
            return 0
        base = 1
    if not options.progressive_systems or options.progressive_systems_per_ship:
        return spec.max_level
    progressive = state.count(f"Progressive {spec.display}", h.player)
    if options.full_system_upgrades and progressive:
        return spec.max_level
    return min(base + progressive, spec.max_level)


def _meets(h, state, layout, wanted):
    for stat, n in wanted.items():
        have = _level(h, state, "shields", layout) // 2 if stat == "layers" else _level(h, state, stat, layout)
        if have < n:
            return False
    return True


def _rule_for(h, key, layout):
    if layout is not None:
        wanted = _wanted_for(h, key, layout)
        return lambda state: _meets(h, state, layout, wanted)
    table = {lay.blueprint: _wanted_for(h, key, lay.blueprint) for lay in h.layouts}
    # Cheap item test first, region reachability only for the layouts that pass it.
    return lambda state: any(_meets(h, state, lay, wanted) for lay, wanted in table.items()
                             if _meets(h, state, lay, wanted) and lay in h.flyable(state))


def location_rule(h, location):
    key = _key(h, location)
    if key is None:
        return None
    return _rule_for(h, key, h.layout_of(location))


def win_rule(h):
    return _rule_for(h, "boss", None)
