"""Usable power: only system levels the reactor can actually power count, plus a shield floor.

Power = levels of shields + weapons + engines + drones + cloaking, capped by the reactor bars available for them:
the layout's start reactor, plus Reactor Power items, plus the bars a player normally buys with scrap by that
sector (the reactor is never locked by Archipelago), minus 1 bar kept for oxygen. A level the reactor cannot
feed is useless in FTL, so it does not count. Ships that start without a shield system (Stealth) get one layer
less on the floor before the Flagship if they have cloaking; at the Flagship everyone needs 3 real layers.
"""

NAME = "reactor aware (usable power)"
SUMMARY = ("Only levels your reactor can power count: sector 5 needs 2 shield layers and 9 powered bars, sector 8 "
           "13 bars, the Flagship 3 layers and 16 bars (shields, weapons, engines, drones, cloaking).")

POWER_SYSTEMS = ("shields", "weapons", "engines", "drones", "cloaking")
# depth key -> (shield layers, powered bars, reactor bars bought with scrap by then)
STAGES = {5: (2, 9, 3), 8: (2, 13, 5), "boss": (3, 16, 6)}
# Without Head Starts there is no Reactor Power item: assume that much more scrap goes into the reactor.
NO_REACTOR_ITEMS_BONUS = 3
REACTOR_ITEMS = 8
OXYGEN_BARS = 1


def progression_items(data):
    names = {"Reactor Power"}
    for system in POWER_SYSTEMS:
        display = data.SYSTEMS_BY_ID[system].display
        names.add(f"Progressive {display}")
        names.add(f"{display} blueprint")
    return names


def adjust(h, world):
    """Reactor Power is a spare item the pool may drop when room is short. The rule reads it, so this logic
    keeps all copies: missing ones replace filler, as a real implementation would by making them progression."""
    if not world.options.head_starts:
        return
    from worlds.ftl import items as ftl_items
    pool = world.multiworld.itempool
    have = sum(1 for item in pool if item.player == h.player and item.name == "Reactor Power")
    replaceable = (h.data.GROUP_FILLER, h.data.GROUP_TRAPS)
    for index, item in enumerate(pool):
        if have >= REACTOR_ITEMS:
            break
        entry = h.data.ITEMS_BY_NAME.get(item.name)
        if item.player == h.player and entry is not None and entry.group in replaceable:
            pool[index] = ftl_items.create_item(world, "Reactor Power")
            have += 1


def _level(h, state, system, layout, full):
    """h.level, except that with Full System Upgrades one Progressive item gives every level of the system."""
    level = h.level(state, system, layout)
    if full and level > 0:
        spec = h.data.SYSTEMS_BY_ID[system]
        if state.has(f"Progressive {spec.display}", h.player):
            return spec.max_level
    return level


def _stage(h, location):
    if h.needs_flagship(location):
        return STAGES["boss"]
    depth = h.depth(location)
    if depth >= 8:
        return STAGES[8]
    if depth >= 5:
        return STAGES[5]
    return None


def _make_rule(h, stage, layout):
    layers_needed, power_needed, bought = stage
    # Ships built without shields (Stealth) may lean on cloaking before the Flagship, never at it.
    cloak_for_layer = h.start_level("shields", layout) == 0 and stage is not STAGES["boss"]
    if not h.world.options.head_starts:
        bought += NO_REACTOR_ITEMS_BONUS
    full = bool(h.world.options.full_system_upgrades)

    def rule(state):
        layers = _level(h, state, "shields", layout, full) // 2
        if cloak_for_layer and _level(h, state, "cloaking", layout, full) > 0:
            layers += 1
        if layers < layers_needed:
            return False
        budget = h.reactor(state, layout) + bought - OXYGEN_BARS
        if budget < power_needed:
            return False
        levels = 0
        for system in POWER_SYSTEMS:
            levels += _level(h, state, system, layout, full)
            if levels >= power_needed:
                return True
        return False

    return rule


def location_rule(h, location):
    stage = _stage(h, location)
    if stage is None:
        return None
    return _make_rule(h, stage, h.layout_of(location))


def win_rule(h):
    return _make_rule(h, STAGES["boss"], None)
