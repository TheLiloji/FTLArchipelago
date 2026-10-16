"""Template for a sector logic proposal: copy it to a new file (no leading underscore) and fill it in.

h is a balance_sim.Helpers: h.level(state, system, layout), h.layers(state, layout), h.reactor(state, layout),
h.flyable(state), h.layout_of(location), h.depth(location), h.needs_flagship(location), h.start_level(system,
layout), h.player, h.data. A rule returns True when the check is in logic.
"""

NAME = "template"
SUMMARY = "one sentence a player would understand"


def progression_items(data) -> set[str]:
    """Item names the rules read: they must be progression, or the fill cannot place them correctly."""
    return set()


def location_rule(h, location):
    """A function(state) -> bool for this check, or None for no extra requirement."""
    return None


def win_rule(h):
    """A function(state) -> bool added to the goal, or None."""
    return None


# Optional:
# def adjust(h, world):
#     """Act on placement before the rules: e.g. world.multiworld.early_items[h.player]["Progressive Shields"] = 2."""
