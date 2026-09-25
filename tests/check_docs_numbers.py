#!/usr/bin/env python3

from __future__ import annotations

import re
import subprocess
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent

def preset_table() -> list[str]:

    report = subprocess.run(
        [sys.executable, str(ROOT / "apworld" / "tools" / "preset_report.py"),
         *sorted(str(p) for p in (ROOT / "presets").glob("*.yaml"))],
        capture_output=True, text=True,
    ).stdout

    measured: dict[str, dict[str, float]] = {}
    current = None
    for line in report.splitlines():
        header = re.match(r"=== (\w+?)_\S+\.yaml", line)
        if header:
            current = header.group(1)
            measured[current] = {}
            continue
        if current is None:
            continue
        for pattern, key in ((r"^\s*(\d+) locations", "locations"),
                             (r"free shop slots: (\d+)", "free_slots"),
                             (r"throughput: ~([\d.]+) checks", "throughput"),
                             (r"~([\d.]+) h to the goal", "goal"),
                             (r"worst wait with nothing to give: ~([\d.]+) min", "wait")):
            found = re.search(pattern, line)
            if found:
                measured[current][key] = float(found.group(1))

    issues: list[str] = []
    read = 0
    for path in sorted((ROOT / "presets").glob("*.yaml")):
        name = path.name.split("_")[0]
        text = path.read_text(encoding="utf-8")
        found = re.search(r"# Measured: (\d+) locations, (\d+) free shop slots, ~([\d.]+) checks per hour,"
                           r"\s*# ~([\d.]+) h to the goal, ~([\d.]+) minutes max wait", text)
        if not found:
            issues.append(f"presets/{path.name}: no Measured header")
            continue
        read += 1
        real = measured.get(name, {})
        for announced, key in zip(map(float, found.groups()),
                                  ("locations", "free_slots", "throughput", "goal", "wait")):
            if abs(real.get(key, -1) - announced) > 0.05:
                issues.append(f"presets/{path.name}: announces {announced:g} {key}, "
                              f"the report measures {real.get(key)}")
    if read != 6:
        issues.append(f"suspicious extraction: {read} preset header(s) read instead of six")
    return issues


WORDS = {
    "one": 1, "two": 2, "three": 3, "four": 4, "five": 5, "six": 6, "seven": 7, "eight": 8,
    "nine": 9, "ten": 10, "eleven": 11, "twelve": 12, "thirteen": 13, "fourteen": 14,
    "fifteen": 15, "sixteen": 16, "seventeen": 17, "eighteen": 18, "nineteen": 19, "twenty": 20, "thirty": 30, "forty": 40, "fifty": 50, "sixty": 60,
}

GAME_DOC_PAGE = "apworld/ftl/docs/en_FTL Faster Than Light.md"

DESIGN_NUMBERS = (
    (GAME_DOC_PAGE, r"any number of layouts you like, (\w+) by default", "VictoriesRequired"),
    (GAME_DOC_PAGE, r"at least (\w+) slots by default \(Archipelago Shop", "ShopChecks"),
    (GAME_DOC_PAGE, r"filler makes up the difference \(at least (\w+), Minimum Filler\)", "MinimumFiller"),
    (GAME_DOC_PAGE, r"(\w+) checks by default, one per system", "systems"),
    (GAME_DOC_PAGE, r"FTL has (\d+) weapons, drones and augments", "shop_items"),
)


def _option_default(class_name: str) -> int | None:
    text = (ROOT / "apworld" / "ftl" / "options.py").read_text(encoding="utf-8")
    block = re.search(rf"^class {class_name}\(.*?(?=^class |\Z)", text, re.MULTILINE | re.DOTALL)
    if block is None:
        return None
    found = re.search(r"^\s+default = (\d+)$", block.group(0), re.MULTILINE)
    return int(found.group(1)) if found else None


def _count_in_data(pattern: str) -> int:
    text = (ROOT / "apworld" / "ftl" / "data.py").read_text(encoding="utf-8")
    start = text.index(pattern)
    end = text.index("\n)\n", start)
    return len(re.findall(r"^    \(", text[start:end], re.MULTILINE))


def design_numbers() -> list[str]:
    actual = {
        "systems": _count_in_data("\nSYSTEMS_RAW: "),
        "shop_items": _count_in_data("\nSHOP_ITEMS_RAW: "),
    }
    issues: list[str] = []
    for name, pattern, source in DESIGN_NUMBERS:
        text = (ROOT / name).read_text(encoding="utf-8")
        found = re.search(pattern, text)
        if found is None:
            issues.append(f"{name} no longer says {pattern!r}: the check does not know what to read anymore")
            continue
        raw = found.group(1)
        announced = int(raw) if raw.isdigit() else WORDS.get(raw.lower())
        actual_value = actual[source] if source in actual else _option_default(source)
        if announced is None or actual_value is None or announced != actual_value:
            issues.append(f"{name} announces \"{raw}\" ({source}); the code says {actual_value}")
    return issues


def main() -> int:
    issues = preset_table() + design_numbers()
    if issues:
        print("check_docs_numbers: issues", file=sys.stderr)
        for issue in issues:
            print(f"  {issue}", file=sys.stderr)
        return 1
    print(f"check_docs_numbers: the six preset headers and {len(DESIGN_NUMBERS)} numbers of the "
          "game page match the code")
    return 0


if __name__ == "__main__":
    sys.exit(main())
