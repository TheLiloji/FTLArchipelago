from __future__ import annotations

from typing import TYPE_CHECKING

from . import data

if TYPE_CHECKING:
    from BaseClasses import Item, MultiWorld

# A bundle is shown as an important package, but starts cheaper so the first sector stays affordable.
BASE_PRICE: dict[str, int] = {"progression": 70, "bundle": 45, "useful": 30, "filler": 10, "trap": 10}
PRICE_PER_SPHERE: dict[str, int] = {"progression": 8, "bundle": 8, "useful": 4, "filler": 2, "trap": 2}
PRICE_CAP: dict[str, int] = {"progression": 150, "bundle": 120, "useful": 65, "filler": 25, "trap": 25}


def is_bundle(item: "Item") -> bool:
    entry = data.ITEMS_BY_NAME.get(item.name) if item.game == data.GAME_NAME else None
    return entry is not None and entry.group == data.GROUP_BUNDLES


def importance(item: "Item") -> str:
    if is_bundle(item):
        return "progression"
    if item.advancement:
        return "progression"
    if item.useful:
        return "useful"
    if item.trap:
        return "trap"
    return "filler"


def price(kind: str, sphere: int | None) -> int:
    depth = max(0, (sphere or 1) - 1)
    raw = BASE_PRICE[kind] + PRICE_PER_SPHERE[kind] * depth
    return min(PRICE_CAP[kind], int(round(raw / 5.0)) * 5)


def spheres_of(multiworld: "MultiWorld") -> dict[tuple[int, str], int]:
    cache = getattr(multiworld, "_ftl_spheres", None)
    if cache is None:
        cache = {}
        for index, sphere in enumerate(multiworld.get_spheres()):
            for location in sphere:
                cache.setdefault((location.player, location.name), index)
        setattr(multiworld, "_ftl_spheres", cache)
    return cache


def price_tier(item: "Item") -> str:
    return "bundle" if is_bundle(item) else importance(item)
