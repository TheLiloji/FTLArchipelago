#!/usr/bin/env python3

from __future__ import annotations

import os
import sys
import zlib
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]
OUT = ROOT / "mod" / "ArchipelagoFTL" / "data" / "archipelago" / "gifts_demo.lua"

FLAG_PROGRESSION = 0b001
FLAG_USEFUL = 0b010
FLAG_TRAP = 0b100


def bootstrap() -> None:
    source = Path(os.environ.get("AP_SOURCE", "~/.local/opt/Archipelago-0.6.7-src")).expanduser()
    frozen = Path(os.environ.get("AP_ROOT", "~/.local/opt/Archipelago")).expanduser()
    sys.path.insert(0, str(source))
    for extra in (frozen / "lib" / "library.zip", frozen / "lib"):
        if extra.exists():
            sys.path.append(str(extra))
    import ModuleUpdate  # noqa: F401

    ModuleUpdate.update_ran = True


def classification(flags: int) -> str:
    if flags & FLAG_TRAP:
        return "trap"
    if flags & FLAG_PROGRESSION:
        return "progression"
    if flags & FLAG_USEFUL:
        return "useful"
    return "filler"


def lua_string(value: str) -> str:
    return '"' + str(value).replace("\\", "\\\\").replace('"', '\\"') + '"'


SOLO_OUT = (ROOT / "mod" / "ArchipelagoFTL" / "data" / "archipelago" / "solo_order.lua")


def lua_table(value, indent: int = 0) -> str:

    pad = "    " * (indent + 1)
    closing = "    " * indent
    if isinstance(value, bool):
        return "true" if value else "false"
    if isinstance(value, (int, float)):
        return repr(value)
    if isinstance(value, str):
        return lua_string(value)
    if isinstance(value, dict):
        if not value:
            return "{}"
        lines = [f"{pad}[{lua_string(str(k))}] = {lua_table(v, indent + 1)},"
                 for k, v in sorted(value.items())]
        return "{\n" + "\n".join(lines) + f"\n{closing}}}"
    if isinstance(value, (list, tuple)):
        if not value:
            return "{}"
        return "{ " + ", ".join(lua_table(v, indent) for v in value) + " }"
    return "nil"


def write_solo_order(data, slot_info, ftl_slot, datapackage) -> None:

    table = datapackage.get("FTL: Faster Than Light", {})
    item_names = {code: name for name, code in table.get("item_name_to_id", {}).items()}
    location_names = {code: name for name, code in table.get("location_name_to_id", {}).items()}

    ordered = []
    for location_id, (item_id, receiving_slot, flags) in _LOCATIONS[ftl_slot].items():
        if receiving_slot != ftl_slot:
            continue
        ordered.append((location_id, item_id))

    lines = [
        "_G.apSoloOrder = {",
    ]
    for location_id, item_id in ordered:
        name = item_names.get(item_id, f"item {item_id}")
        where = location_names.get(location_id, f"location {location_id}")
        lines.append(f'    {{ item = {lua_string(name)}, location = {lua_string(where)} }},')
    lines += ["}", ""]

    slot_data = data.get("slot_data", {}).get(ftl_slot, {})
    keep = ("contract", "kinds", "kinds_required", "items", "loc", "start_ship", "goal",
            "seed_name", "seed_hash", "shop", "links", "language")
    trimmed = {key: slot_data[key] for key in keep if key in slot_data}
    lines += [
        f"_G.apSoloSlotData = {lua_table(trimmed)}",
        "",
    ]

    SOLO_OUT.write_text("\n".join(lines), encoding="utf-8")
    print(f"written: {SOLO_OUT.relative_to(ROOT)} ({len(ordered)} items to receive, "
          f"slot_data of {len(trimmed.get('items', {}))} items)")


_LOCATIONS = {}


def main() -> int:
    bootstrap()
    import Utils

    if len(sys.argv) < 2:
        print("usage: extract_gifts.py <file.archipelago>", file=sys.stderr)
        return 2

    raw = Path(sys.argv[1]).read_bytes()
    data = Utils.restricted_loads(zlib.decompress(raw[1:]))

    _LOCATIONS.update(data["locations"])
    slot_info = data["slot_info"]
    ftl_slots = [n for n, info in slot_info.items() if info.game == "FTL: Faster Than Light"]
    if not ftl_slots:
        print("no FTL world in this seed", file=sys.stderr)
        return 1
    ftl_slot = ftl_slots[0]
    print(f"FTL world: slot {ftl_slot} ({slot_info[ftl_slot].name})")

    sphere_of: dict[int, int] = {}
    for index, sphere in enumerate(data.get("spheres", []), start=1):
        for location_id in sphere.get(ftl_slot, ()):
            sphere_of[location_id] = index

    datapackage = data["datapackage"]

    def reverse(table: dict) -> dict:
        return {code: name for name, code in table.items()}

    items_by_game = {
        game: reverse(entry.get("item_name_to_id", {})) for game, entry in datapackage.items()
    }
    locations = reverse(datapackage.get("FTL: Faster Than Light", {}).get("location_name_to_id", {}))

    def item_name(game: str, code: int) -> str:
        return items_by_game.get(game, {}).get(code, f"Unknown item {code}")

    def location_name(code: int) -> str:
        return locations.get(code, f"Unknown location {code}")

    shop_prefix = "Archipelago Shop "

    gifts = []
    for location_id, (item_id, receiving_slot, flags) in data["locations"][ftl_slot].items():
        receiver = slot_info[receiving_slot]
        if receiving_slot == ftl_slot:
            continue
        if not location_name(location_id).startswith(shop_prefix):
            continue
        gifts.append({
            "slot": receiver.name,
            "game": receiver.game,
            "item": item_name(receiver.game, item_id),
            "sphere": sphere_of.get(location_id, 0),
            "kind": classification(flags),
            "location": "shop:" + location_name(location_id)[len(shop_prefix):],
            "cost": 0,
        })

    price = {"progression": 70, "useful": 45, "filler": 25, "trap": 15}
    for gift in gifts:
        gift["cost"] = price[gift["kind"]] + min(gift["sphere"], 4) * 5

    order = {"progression": 0, "useful": 1, "filler": 2, "trap": 3}
    gifts.sort(key=lambda g: (order[g["kind"]], g["sphere"], g["slot"]))

    lines = [
        "_G.apGiftsDemo = {",
    ]
    for gift in gifts:
        lines.append(
            "    { slot = %s, item = %s, sphere = %d, kind = %s,"
            % (lua_string(gift["slot"]), lua_string(gift["item"]), gift["sphere"],
               lua_string(gift["kind"]))
        )
        lines.append(
            "      location = %s, cost = %d, game = %s },"
            % (lua_string(gift["location"]), gift["cost"], lua_string(gift["game"]))
        )
    lines += ["}", ""]

    if not gifts:
        print("NO shop slot in this seed: is the shop_checks option set to 0?",
              file=sys.stderr)

    OUT.write_text("\n".join(lines), encoding="utf-8")
    print(f"written: {OUT.relative_to(ROOT)} ({len(gifts)} gifts)")

    write_solo_order(data, slot_info, ftl_slot, datapackage)
    for gift in gifts[:6]:
        print(f"  {gift['kind']:12} sphere {gift['sphere']}  {gift['item']} -> {gift['slot']}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
