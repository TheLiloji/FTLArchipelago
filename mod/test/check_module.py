#!/usr/bin/env python3

from __future__ import annotations

import re
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
MODULES = ROOT / "ArchipelagoFTL" / "data" / "archipelago"
FACADE = ROOT.parent / "hyperspace-patch" / "src" / "Archipelago.i"
HARNESS = ROOT / "test" / "harness.lua"


def calls_in_mod() -> dict[str, str]:
    calls: dict[str, str] = {}
    for path in sorted(MODULES.glob("*.lua")):
        for name in re.findall(r"\bap:([A-Z][A-Za-z]+)\(", path.read_text(encoding="utf-8")):
            calls.setdefault(name, path.name)
    return calls


def facade() -> set[str]:
    return set(re.findall(r"ArchipelagoFTL::Client::([A-Za-z]+);", FACADE.read_text(encoding="utf-8")))


def fake_client() -> set[str]:
    text = HARNESS.read_text(encoding="utf-8")
    start = text.index("sim.net.client = {")
    end = text.index("\n    }\n", start)
    return set(re.findall(r"^        ([A-Z][A-Za-z]+) = function", text[start:end], re.MULTILINE))


def main() -> int:
    calls, exposed, simulated = calls_in_mod(), facade(), fake_client()
    issues: list[str] = []
    for name, file in sorted(calls.items()):
        if name not in exposed:
            issues.append(f"{file} calls ap:{name}(), which Archipelago.i does not expose to Lua: "
                          "the real game will raise an error")
        if name not in simulated:
            issues.append(f"{file} calls ap:{name}(), which the fake client does not simulate: "
                          "no test can exercise it")
    for name in sorted(simulated - exposed):
        issues.append(f"the fake client simulates {name}, which the real facade does not expose: it lies")
    if not calls or not exposed or not simulated:
        issues.append("suspicious read: one of the three lists is empty")
    if issues:
        print("check_module: issues", file=sys.stderr)
        for issue in issues:
            print(f"  {issue}", file=sys.stderr)
        return 1
    print(f"check_module: {len(calls)} methods called by the mod, all exposed by the module "
          f"and simulated by the fake client")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
