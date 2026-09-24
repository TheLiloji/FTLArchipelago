#!/usr/bin/env python3

from __future__ import annotations

import re
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
MODULES = ROOT / "ArchipelagoFTL" / "data" / "archipelago"
TESTS = ROOT / "test"

NAME = r"ap[A-Z][A-Za-z0-9_]*"
DEFINITION = re.compile(rf"^\s*(?:local\s+)?function\s+({NAME})\s*\(", re.MULTILINE)
ASSIGNED = re.compile(rf"^_G\.({NAME})\s*=", re.MULTILINE)
REFERENCE = re.compile(rf"\b(?:_G\.)?({NAME})\b")

ENTRY_POINTS = {
    "apNetConnect", "apNetDisconnect",
    "apCargoStatus", "apCheckStatus", "apContractStatus", "apDeathLinkStatus", "apEnergyLinkStatus",
    "apEventStatus", "apFillerStatus", "apGoalStatus", "apLangStatus", "apNetStatus",
    "apShopGiftsStatus", "apShopStatus", "apSoloStatus", "apSystemStatus", "apTrapLinkStatus",
    "apUnlockStatus", "apToggleHud", "apUnlockAll", "apSoloStart", "apSoloStop", "apLangAvailable",
    "apOnSlotData",
    "apEnergyLinkHuman", "apTrapLinkState",
}
TEST_ONLY = "ForTesting"


def sources() -> dict[str, str]:
    files = {p.name: p.read_text(encoding="utf-8") for p in sorted(MODULES.glob("*.lua"))}
    names = ["harness.lua", "dump_contract.lua", "solo_curve.lua"]
    names += [path.name for path in sorted(TESTS.glob("scenarios*.lua"))]
    for name in names:
        path = TESTS / name
        if path.is_file():
            files[f"test/{name}"] = path.read_text(encoding="utf-8")
    return files


def main() -> int:
    files = sources()
    mod_only = {name: text for name, text in files.items() if not name.startswith("test/")}

    defined: dict[str, str] = {}
    functions: set[str] = set()
    for name, text in files.items():
        for match in DEFINITION.findall(text):
            defined.setdefault(match, name)
            functions.add(match)
        for match in ASSIGNED.findall(text):
            defined.setdefault(match, name)
            if re.search(rf"^_G\.{match}\s*=\s*function", text, re.MULTILINE):
                functions.add(match)

    referenced: dict[str, set[str]] = {}
    for name, text in files.items():
        for match in REFERENCE.findall(text):
            referenced.setdefault(match, set()).add(name)

    failures: list[str] = []

    for symbol, where in sorted(referenced.items()):
        if symbol in defined:
            continue
        real = [
            place for place in where
            if re.search(rf"_G\.{symbol}\b\s*[(\[.]|(?<!function )\b{symbol}\s*\(", files[place])
        ]
        if real:
            failures.append(
                f"\"{symbol}\" is called by {', '.join(sorted(real))} and defined nowhere: "
                "the call will silently do nothing"
            )

    for symbol, where in sorted(defined.items()):
        if symbol in ENTRY_POINTS or TEST_ONLY in symbol:
            continue
        occurrences = sum(len(re.findall(rf"\b(?:_G\.)?{symbol}\b", text))
                          for text in files.values())
        if occurrences <= 1:
            failures.append(
                f"\"{symbol}\", defined in {where}, appears nowhere else: "
                "it will never run"
            )

    guard = re.compile(rf"^(\s*)if\s+_G\.({NAME})\s+then\s*$")
    for name, text in mod_only.items():
        lines = text.splitlines()
        for number, line in enumerate(lines):
            match = guard.match(line)
            if not match:
                continue
            indent, guarded = len(match.group(1)), match.group(2)
            if guarded not in functions:
                continue
            body_lines = []
            for following in lines[number + 1:]:
                stripped = following.strip()
                current = len(following) - len(following.lstrip())
                if current <= indent and stripped.startswith(("end", "else", "elseif")):
                    break
                body_lines.append(following)
            called = set(re.findall(rf"_G\.({NAME})\s*\(", "\n".join(body_lines)))
            if called and guarded not in called:
                failures.append(
                    f"{name}:{number + 1}: the guard tests \"{guarded}\" and the body calls "
                    f"\"{', '.join(sorted(called))}\", either one could be missing with "
                    "nothing to say so"
                )

    SEND = re.compile(r"^apNet(?:Send\w+|EnergyLink\w+)$")

    sends = 0
    for name, source in files.items():
        if name.startswith("test/"):
            continue
        lines = []
        in_block = False
        for line in source.splitlines():
            if in_block:
                end = line.find("]]")
                if end < 0:
                    lines.append("")
                    continue
                line, in_block = line[end + 2:], False
            start = line.find("--[[")
            if start >= 0:
                rest = line[start + 4:]
                end = rest.find("]]")
                if end < 0:
                    in_block = True
                    lines.append(line[:start])
                    continue
                line = line[:start] + rest[end + 2:]
            lines.append(line)

        for number, line in enumerate(lines, 1):
            stripped = line.strip()
            if stripped.startswith("--"):
                continue
            if re.match(r"(?:local\s+)?function\s+(?:_G\.)?apNet\w+\s*\(", stripped):
                continue
            call = re.search(r"\b(?:_G\.)?(apNet\w+)\s*\(", stripped)
            in_pcall = re.search(r"\bpcall\s*\(\s*(?:_G\.)?(apNet\w+)\s*[,)]", stripped)
            target = (call.group(1) if call else None) or (in_pcall.group(1) if in_pcall else None)
            if target is None:
                continue
            if not SEND.match(target):
                continue
            sends += 1
            before = stripped[: (call or in_pcall).start()]
            if ("=" in before or before.startswith(("return", "if ", "elseif ", "while ", "check("))
                    or before.endswith(("and ", "or ", "not ", "(", ","))):
                continue
            failures.append(
                f"{name}:{number}: the return value of \"{target}\" is discarded, off network "
                "it is `false` with no raise, and the player would be told a send happened "
                "when it did not"
            )

    if len(defined) < 60 or sends < 3:
        failures.append(
            f"suspicious extraction: {len(defined)} functions and {sends} network sends found. "
            "The mod carries a lot more: this is the reader that's broken, not the mod."
        )

    if failures:
        print("check_wiring: issues", file=sys.stderr)
        for problem in failures:
            print(f"  {problem}", file=sys.stderr)
        return 1

    print(f"check_wiring: {len(defined)} functions, all defined and all called, "
          f"{sends} network sends whose return value is read")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
