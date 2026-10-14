"""Placement instead of gates: the fill puts the first shield, weapon and engine upgrades early in the seed,
and only the Flagship asks for a power level. No sector is gated by ship power."""

NAME = "early priority (placement)"
SUMMARY = ("The first upgrades of Shields, Weapons and Engines are placed early; to fight the Flagship you need "
           "4 Progressive Shields, 3 Progressive Weapon Control and 2 Progressive Engines.")

# Progressive items received (on top of a typical start: shields 2, weapons 3, engines 2).
BOSS = {"Progressive Shields": 4, "Progressive Weapon Control": 3, "Progressive Engines": 2}
# How many of each the fill must put in sphere 1 (capped by what the pool holds).
EARLY = {"Progressive Shields": 2, "Progressive Weapon Control": 1, "Progressive Engines": 1}
# Light gates that only ask for the early items themselves, so they never hold a player back for long.
SECTOR5 = {"Progressive Shields": 2}
SECTOR8 = dict(EARLY)


def progression_items(data):
    return set(BOSS) | set(EARLY) | set(SECTOR5) | set(SECTOR8)


def _need(h, wanted):
    full = bool(h.world.options.full_system_upgrades)
    player = h.player
    if full:  # one item gives every level of its system
        return lambda state: all(state.has(name, player) for name in wanted)
    return lambda state: all(state.has(name, player, n) for name, n in wanted.items())


def adjust(h, world):
    in_pool = {}
    for item in world.multiworld.itempool:
        if item.player == h.player:
            in_pool[item.name] = in_pool.get(item.name, 0) + 1
    early = world.multiworld.local_early_items[h.player]
    for name, n in EARLY.items():
        n = min(n, in_pool.get(name, 0))
        if n:
            early[name] = max(early.get(name, 0), n)


def location_rule(h, location):
    if h.needs_flagship(location):
        return _need(h, BOSS)
    if SECTOR8 and h.depth(location) >= 8:
        return _need(h, SECTOR8)
    if SECTOR5 and h.depth(location) >= 5:
        return _need(h, SECTOR5)
    return None


def win_rule(h):
    return _need(h, BOSS)
