#!/usr/bin/env python3

from __future__ import annotations

import importlib.util
import json
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]
DATA_PY = ROOT / "apworld" / "ftl" / "data.py"
BASELINE = ROOT / "apworld" / "ftl" / "test" / "ids_baseline.json"

NOTE = (
    "Id baseline, written by apworld/tools/gen_id_baseline.py and checked by "
    "apworld/ftl/test/test_ids.py. Additions only: a name already present must never change "
    "its id or its check key, or it invalidates seeds already generated. "
    "items = {Archipelago name: id}. locations = {Archipelago name: [id, check key "
    "sent by the Lua mod]}."
)


def load_data():
    spec = importlib.util.spec_from_file_location("ftl_data_standalone", DATA_PY)
    if spec is None or spec.loader is None:  # pragma: no cover
        sys.exit(f"could not load {DATA_PY}")
    module = importlib.util.module_from_spec(spec)
    sys.modules[spec.name] = module
    spec.loader.exec_module(module)
    return module


def snapshot(data) -> dict:
    return {
        "_note": NOTE,
        "game": data.GAME_NAME,
        "items": {item.name: item.code for item in data.ITEMS},
        "locations": {loc.name: [loc.code, loc.check_id] for loc in data.LOCATIONS},
    }


def conflicts(old: dict, new: dict) -> list[str]:
    problems: list[str] = []
    if old.get("game") != new["game"]:
        problems.append(
            f"the game name changes from {old.get('game')!r} to {new['game']!r}: the whole "
            "DataPackage changes owner"
        )
    for section in ("items", "locations"):
        for name, value in old.get(section, {}).items():
            if name not in new[section]:
                problems.append(f"{section}: {name!r} disappeared (was {value!r})")
            elif new[section][name] != value:
                problems.append(
                    f"{section}: {name!r} changes from {value!r} to {new[section][name]!r}"
                )
    return problems


def dump(snap: dict) -> str:
    # Hand-rolled instead of json.dumps(..., indent=...): the stdlib pretty-printer would put
    # each location's [id, check key] pair on three lines instead of one, tripling the diff
    # for a ~900-entry file every time a single location changes.
    lines = ["{", f' "_note": {json.dumps(snap["_note"], ensure_ascii=False)},',
             f' "game": {json.dumps(snap["game"], ensure_ascii=False)},']
    for index, section in enumerate(("items", "locations")):
        lines.append(f' "{section}": {{')
        entries = sorted(snap[section].items())
        for position, (name, value) in enumerate(entries):
            comma = "," if position < len(entries) - 1 else ""
            key = json.dumps(name, ensure_ascii=False)
            lines.append(f"  {key}: {json.dumps(value, ensure_ascii=False)}{comma}")
        lines.append(" }" + ("," if index == 0 else ""))
    lines.append("}")
    return "\n".join(lines) + "\n"


def main() -> int:
    data = load_data()
    new = snapshot(data)

    if BASELINE.exists():
        old = json.loads(BASELINE.read_text(encoding="utf-8"))
        problems = conflicts(old, new)
        if problems:
            print("Refused: these changes would invalidate seeds already generated.\n", file=sys.stderr)
            for problem in problems:
                print(f"  - {problem}", file=sys.stderr)
            print(
                "\nIf the break is intentional, edit apworld/ftl/test/ids_baseline.json by hand "
                "and say why in the commit message.",
                file=sys.stderr,
            )
            return 1
        added_items = len(new["items"]) - len(old.get("items", {}))
        added_locations = len(new["locations"]) - len(old.get("locations", {}))
        print(f"baseline up to date: +{added_items} item(s), +{added_locations} location(s)")
    else:
        print("baseline created")

    BASELINE.parent.mkdir(parents=True, exist_ok=True)
    BASELINE.write_text(dump(new), encoding="utf-8")
    print(f"{BASELINE.relative_to(ROOT)}: {len(new['items'])} items, "
          f"{len(new['locations'])} locations")
    return 0


if __name__ == "__main__":
    sys.exit(main())
