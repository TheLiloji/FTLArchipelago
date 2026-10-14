"""Option E of the first round: fixed milestones on a typical ship."""

NAME = "E milestones (fixed)"
SUMMARY = "Sector 5 needs 2 shield layers; the Flagship 3 layers, weapons 6 and engines 4."

MILESTONES = {5: {"shields": 4}, 8: {"shields": 4, "weapons": 5},
              "boss": {"shields": 6, "weapons": 6, "engines": 4}}


def progression_items(data):
    systems = {s for wanted in MILESTONES.values() for s in wanted}
    return {f"Progressive {data.SYSTEMS_BY_ID[s].display}" for s in systems}


def _wanted(h, location):
    if h.needs_flagship(location):
        return MILESTONES["boss"]
    depth = h.depth(location)
    wanted = {}
    for sector in (5, 8):
        if depth >= sector:
            wanted = MILESTONES[sector]
    return wanted


def location_rule(h, location):
    wanted = _wanted(h, location)
    if not wanted:
        return None
    return lambda state: all(h.level(state, s) >= n for s, n in wanted.items())


def win_rule(h):
    return lambda state: all(h.level(state, s) >= n for s, n in MILESTONES["boss"].items())
