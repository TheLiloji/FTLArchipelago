"""Hybrid: a shield floor (Jam) plus a small power score for everything else (studkid), with diminishing
returns on late levels of the big systems. Shields never count in the score: they are the floor.

Defense floor, in shield layers (2 shield levels = 1 layer), on the ship the check is played with (a typical
ship for checks that belong to no ship). Optional EQUIVALENTS (off): Zoltan super shield or Stealth cloaking
counted as one layer.
Power score (absolute levels, so each layout starts with its own score):
  - Weapon Control, Drone Control, Engines: 1 point per level up to 4, then 0.5 for levels 5-6, 0.25 for 7-8;
  - Crew Teleporter, Cloaking, Hacking, Mind Control, Artillery Beam: 1 point per level;
  - each Reactor Power: 0.5 point.
A typical start (weapons 3, engines 2) is worth 5 points.
"""

NAME = "hybrid shields + power"
SUMMARY = ("Sector 5 needs 2 shield layers and 7 power, sector 8 2 layers and 9 power, the Flagship 3 layers "
           "and 10 power (weapons, drones, engines, teleporter, cloaking, hacking, mind control, reactor).")

# (layers, power)
MILESTONES = {5: (2, 7.0), 8: (2, 9.0), "boss": (3, 10.0)}

BIG = ("weapons", "drones", "engines")
SMALL = ("teleporter", "cloaking", "hacking", "mind", "artillery")
REACTOR_POINT = 0.5
# Zoltan super shield / Stealth cloaking counted as one layer: tried, it let the Flagship in at 2.6 layers
# on average. Off: shields are the floor for every ship (Jam's point: you cannot rush them in Archipelago).
EQUIVALENTS = False


def progression_items(data):
    names = {"Reactor Power"}
    for system in ("shields",) + BIG + SMALL:
        spec = data.SYSTEMS_BY_ID[system]
        names.add(f"{spec.display} blueprint")
        if spec.max_level > 1:
            names.add(f"Progressive {spec.display}")
            names.update(f"{ship.display}: Progressive {spec.display}" for ship in data.SHIPS)
    return names


def level(h, state, system, layout):
    """The highest level the player may have, honouring the seed's upgrade options (the stock helper counts
    one level per item and ignores Full System Upgrades, per-ship upgrades and room on the layout)."""
    data, options = h.data, h.world.options
    spec = data.SYSTEMS_BY_ID[system]
    entry = data.LAYOUTS_BY_BLUEPRINT.get(layout) if layout else None
    base = h.start_level(system, layout)
    if base == 0:
        if entry is not None and system not in entry.empty_slots:
            return 0
        if options.system_blueprints and not state.has(f"{spec.display} blueprint", h.player):
            return 0
        base = 1
    if not options.progressive_systems or options.free_upgrades:
        return spec.max_level
    if options.progressive_systems_per_ship:
        if entry is None:
            # No ship: the best ship's copies.
            got = max(state.count(f"{ship.display}: Progressive {spec.display}", h.player) for ship in data.SHIPS)
        else:
            ship = data.SHIPS_BY_BLUEPRINT[entry.ship].display
            got = state.count(f"{ship}: Progressive {spec.display}", h.player)
    else:
        got = state.count(f"Progressive {spec.display}", h.player)
    if options.full_system_upgrades and got:
        return spec.max_level
    return min(base + got, spec.max_level)


def _big_points(level):
    return min(level, 4) + 0.5 * max(0, min(level, 6) - 4) + 0.25 * max(0, level - 6)


def defense(h, state, layout):
    layers = level(h, state, "shields", layout) // 2
    if not EQUIVALENTS:
        return layers
    if layout and layout.startswith("PLAYER_SHIP_ENERGY"):
        layers += 1
    if layout and h.start_level("shields", layout) == 0 and level(h, state, "cloaking", layout) >= 2:
        layers += 1
    return layers


def power(h, state, layout):
    score = sum(_big_points(level(h, state, s, layout)) for s in BIG)
    score += sum(level(h, state, s, layout) for s in SMALL)
    score += REACTOR_POINT * state.count("Reactor Power", h.player)
    return score


def ready(h, state, layout, wanted):
    layers, points = wanted
    return defense(h, state, layout) >= layers and power(h, state, layout) >= points


def _wanted(h, location):
    if h.needs_flagship(location):
        return MILESTONES["boss"]
    depth = h.depth(location)
    wanted = None
    for sector in (5, 8):
        if depth >= sector:
            wanted = MILESTONES[sector]
    return wanted


def location_rule(h, location):
    wanted = _wanted(h, location)
    if wanted is None:
        return None
    layout = h.layout_of(location)
    return lambda state: ready(h, state, layout, wanted)


def win_rule(h):
    return lambda state: ready(h, state, None, MILESTONES["boss"])
