#!/usr/bin/env python3

from __future__ import annotations

import argparse
import json
import re
import os
import shutil
import subprocess
import sys
import tempfile
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]
PRESETS = ROOT / "presets"
AP = Path(os.environ.get("AP_ROOT", "~/.local/opt/Archipelago")).expanduser()
GAME = "FTL: Faster Than Light"

COMPANIONS = {
    "ChecksFinder": {},
    "Yacht Dice": {},
    "Bumper Stickers": {},
    "A Short Hike": {},
}

ITEM_LINKS = """  item_links:
    - name: Systems
      item_pool:
        - System blueprints
      replacement_item: null
"""

PLANDO = """  shop_items: 0
  plando_items:
    - item: "Burst Laser Mark II"
      location: "Kestrel Cruiser A: Reach sector 1"
      world: false
      percentage: 100
"""

GENERIC_OPTIONS = """  accessibility: minimal
  progression_balancing: extreme
  start_inventory_from_pool:
    Engi Cruiser Key: 1
  local_items:
    - System blueprints
  non_local_items:
    - Ship keys
  exclude_locations:
    - "Kestrel Cruiser A: Reach sector 3"
  priority_locations:
    - "Kestrel Cruiser A: Reach sector 4"
"""

CASE_FLAGS = {"plando": ["--plando", "items"]}

CASES = {
    "solo":    [("C1_two_evenings_beginner.yaml", "Solo")],
    "duo":     [("A1_multi_game_beginner.yaml", "Fast"),
                ("B2_solo_veteran.yaml", "Deep")],
    "mixed":   [("C1_two_evenings_beginner.yaml", "Pilot"),
                ("ChecksFinder", "Nina"),
                ("Yacht Dice", "Axel")],
    "grand":   [("A1_multi_game_beginner.yaml", "Fast"),
                ("A2_multi_game_veteran.yaml", "Fast2"),
                ("C2_two_evenings_veteran.yaml", "Pilot"),
                ("ChecksFinder", "Nina"),
                ("Yacht Dice", "Axel"),
                ("Bumper Stickers", "Loki")],
    "links":   [("B1_solo_beginner.yaml", "Link1", ITEM_LINKS),
                ("B2_solo_veteran.yaml", "Link2", ITEM_LINKS),
                ("ChecksFinder", "Nina")],
    "plando":  [("C1_two_evenings_beginner.yaml", "Plando", PLANDO),
                ("ChecksFinder", "Nina")],
    "hostile": [("A2_multi_game_veteran.yaml", "Hostile", GENERIC_OPTIONS),
                ("B1_solo_beginner.yaml", "Neighbor"),
                ("ChecksFinder", "Nina")],
    "all":     [("A1_multi_game_beginner.yaml", "A1"),
                ("A2_multi_game_veteran.yaml", "A2"),
                ("B1_solo_beginner.yaml", "B1"),
                ("B2_solo_veteran.yaml", "B2"),
                ("C1_two_evenings_beginner.yaml", "C1"),
                ("C2_two_evenings_veteran.yaml", "C2"),
                ("ChecksFinder", "Nina"),
                ("Yacht Dice", "Axel")],
}


def write_player(directory: Path, source: str, name: str, extra: str = "") -> None:
    if source.endswith(".yaml"):
        document = (PRESETS / source).read_text(encoding="utf-8")
        lines = [
            f"name: {name}" if line.startswith("name:") else line
            for line in document.splitlines()
        ]
        reused_keys = {
            line.split(":", 1)[0].strip()
            for line in extra.splitlines()
            if re.match(r"^  \w+:", line)
        }
        lines = [
            line for line in lines
            if not (re.match(r"^  (\w+):", line)
                    and line.split(":", 1)[0].strip() in reused_keys)
        ]
        (directory / f"{name}.yaml").write_text(
            "\n".join(lines) + "\n" + extra, encoding="utf-8")
    else:
        (directory / f"{name}.yaml").write_text(
            f'name: {name}\ngame: "{source}"\nrequires:\n  version: 0.6.7\n"{source}": {{}}\n',
            encoding="utf-8",
        )


def read_multidata(path: Path) -> dict:
    sys.path.insert(0, str(AP / "lib" / "library.zip"))
    sys.path.append(str(AP / "lib"))
    import Utils  # noqa: E402

    return Utils.restricted_loads(
        __import__("zlib").decompress(path.read_bytes()[1:])
    )


def slots_ftl(multidata: dict) -> list:
    return [
        slot for slot, info in multidata["slot_info"].items()
        if info.game == GAME and int(getattr(info, "type", 1)) == 1
    ]


def pool_items_by_id() -> dict[int, str]:
    module = _pool_data_module()
    return {item.code: item.name for item in module.ITEMS if item.code is not None}


def check_items_match(name: str, multidata: dict) -> list[str]:
    problems: list[str] = []
    by_id = pool_items_by_id()
    for slot in slots_ftl(multidata):
        declared = set((multidata["slot_data"][slot].get("items") or {}))
        received: set[str] = set()
        for table in multidata["locations"].values():
            for _, (item_id, recipient, _flags) in table.items():
                if recipient == slot and item_id in by_id:
                    received.add(by_id[item_id])
        missing = sorted(received - declared)
        if missing:
            problems.append(
                f"{name}, slot {slot}: {len(missing)} item(s) this slot will receive with no "
                f"descriptor in slot_data, including \"{missing[0]}\", they would arrive doing "
                f"nothing"
            )
    return problems


def pool_locations_by_name() -> dict[str, int]:
    return {location.name: location.code for location in _pool_data_module().LOCATIONS}


_DATA: list = []


def _pool_data_module():
    import types

    if _DATA:
        return _DATA[0]
    path = ROOT / "apworld" / "ftl" / "data.py"
    module = types.ModuleType("ftl_data_for_the_matrix")
    module.__file__ = str(path)
    sys.modules["ftl_data_for_the_matrix"] = module
    exec(compile(path.read_text(encoding="utf-8"), str(path), "exec"), module.__dict__)
    _DATA.append(module)
    return module


def check_locations_match(name: str, multidata: dict) -> list[str]:
    problems: list[str] = []
    by_name = pool_locations_by_name()
    for slot in slots_ftl(multidata):
        loc_table = multidata["slot_data"][slot].get("loc") or {}
        unknown = sorted(n for n in loc_table.values() if n not in by_name)
        if unknown:
            problems.append(
                f"{name}, slot {slot}: {len(unknown)} `loc` name(s) missing from data.py, "
                f"including \"{unknown[0]}\""
            )
        announced = {by_name[n] for n in loc_table.values() if n in by_name}
        offered = set(multidata["locations"].get(slot, {}))
        missing = offered - announced
        extra = announced - offered
        if missing:
            problems.append(
                f"{name}, slot {slot}: {len(missing)} location(s) offered by the server "
                f"that the mod cannot send, the seed would never finish"
            )
        if extra:
            problems.append(
                f"{name}, slot {slot}: {len(extra)} location(s) announced to the mod that the "
                f"server does not know, these checks would land nowhere"
            )
    return problems


def check_slot_data(name: str, multidata: dict) -> list[str]:
    problems: list[str] = []
    ftl_slots = slots_ftl(multidata)
    if not ftl_slots:
        return [f"{name}: no FTL slot in the multidata"]

    for slot in ftl_slots:
        data = multidata["slot_data"][slot]
        for field in ("contract", "kinds", "kinds_required", "items", "loc", "start_ship"):
            if field not in data:
                problems.append(f"{name}, slot {slot}: \"{field}\" missing from slot_data")
        if "language" not in data:
            problems.append(f"{name}, slot {slot}: \"language\" missing from slot_data")
        if data.get("items") is not None and not data["items"]:
            problems.append(f"{name}, slot {slot}: empty item table")
        for kind in data.get("kinds_required", []):
            if kind not in data.get("kinds", []):
                problems.append(
                    f"{name}, slot {slot}: required kind \"{kind}\" missing from the kinds list"
                )
    return problems


def check_reproducible(name: str) -> tuple[bool, str]:
    firsts = []
    for _ in range(2):
        ok, message, multidata = _generate(name)
        if not ok:
            return False, f"{name} (reproducibility): {message}"
        firsts.append(multidata)
    a, b = firsts
    if a["slot_data"] != b["slot_data"]:
        different_slots = sorted(
            slot for slot in a["slot_data"]
            if a["slot_data"].get(slot) != b["slot_data"].get(slot)
        )
        return False, (f"{name}: two generations of the SAME seed give different slot_data, "
                       f"slots {different_slots}")
    if a["locations"] != b["locations"]:
        return False, (f"{name}: two generations of the SAME seed do not place items "
                       f"in the same spots")
    return True, f"{name}: two generations of the same seed are identical"


def _generate(name: str, keep: Path | None = None) -> tuple[bool, str, dict]:
    players = CASES[name]
    workdir = Path(tempfile.mkdtemp(prefix=f"ftl-mw-{name}-"))
    player_dir = workdir / "players"
    player_dir.mkdir()
    for entry in players:
        source, slot_name = entry[0], entry[1]
        write_player(player_dir, source, slot_name, entry[2] if len(entry) > 2 else "")

    output = workdir / "out"
    output.mkdir()
    result = subprocess.run(
        [str(AP / "ArchipelagoGenerate"),
         "--player_files_path", str(player_dir),
         "--outputpath", str(output),
         "--seed", "20260915",
         "--spoiler", "3", *CASE_FLAGS.get(name, [])],
        cwd=AP, capture_output=True, text=True, stdin=subprocess.DEVNULL,
    )
    if result.returncode != 0:
        tail = "\n".join((result.stderr or result.stdout).strip().splitlines()[-12:])
        shutil.rmtree(workdir, ignore_errors=True)
        return False, f"{name}: ArchipelagoGenerate failed\n{tail}", {}

    archives = sorted(output.glob("AP_*.zip"))
    if not archives:
        shutil.rmtree(workdir, ignore_errors=True)
        return False, f"{name}: no seed produced", {}
    subprocess.run(["unzip", "-o", "-q", str(archives[-1]), "-d", str(output)], check=True)
    multidata_files = sorted(output.glob("AP_*.archipelago"))
    if not multidata_files:
        shutil.rmtree(workdir, ignore_errors=True)
        return False, f"{name}: no multidata in the archive", {}

    try:
        multidata = read_multidata(multidata_files[-1])
    except Exception as error:  # noqa: BLE001
        shutil.rmtree(workdir, ignore_errors=True)
        return False, f"{name}: unreadable multidata - {error}", {}

    if keep:
        destination = keep / name
        destination.mkdir(parents=True, exist_ok=True)
        for produced in output.glob("AP_*"):
            shutil.copy2(produced, destination / produced.name)
        shutil.copytree(player_dir, destination / "players", dirs_exist_ok=True)
    shutil.rmtree(workdir, ignore_errors=True)
    return True, "", multidata


def run_case(name: str, keep: Path | None) -> tuple[bool, str]:
    ok, message, multidata = _generate(name, keep)
    if not ok:
        return False, message

    problems = (check_slot_data(name, multidata)
                + check_locations_match(name, multidata)
                + check_items_match(name, multidata))
    if problems:
        return False, "\n".join(f"  {problem}" for problem in problems)

    slots = len(multidata["slot_info"])
    locations = sum(len(table) for table in multidata["locations"].values())
    return True, f"{name}: {slots} slots, {locations} locations, complete slot_data"


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--case", choices=sorted(CASES), action="append")
    parser.add_argument("--keep", type=Path, help="folder to keep the produced seeds in")
    arguments = parser.parse_args()

    subprocess.run(
        [sys.executable, str(ROOT / "apworld/tools/build_apworld.py"),
         "--output", str(AP / "custom_worlds" / "ftl.apworld")],
        check=True, capture_output=True,
    )

    requested = arguments.case or sorted(CASES)
    failures = 0
    for name in requested:
        ok, message = run_case(name, arguments.keep)
        print(("  OK    " if ok else "  FAIL  ") + message)
        failures += not ok

    if "duo" in requested:
        ok, message = check_reproducible("duo")
        print(("  OK    " if ok else "  FAIL  ") + message)
        failures += not ok
    return 1 if failures else 0


if __name__ == "__main__":
    raise SystemExit(main())
