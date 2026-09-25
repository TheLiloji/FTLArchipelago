#!/usr/bin/env python3

from __future__ import annotations

import json
import os
import re
import struct
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
BASELINE = Path(__file__).resolve().parent / "ftl_glyphs.json"
DAT = Path(os.environ.get(
    "FTL_DATA", Path.home() / ".steam/steam/steamapps/common/FTL Faster Than Light/data"))


def glyphs(path: Path) -> set[int]:
    raw = path.read_bytes()
    if raw[:4] != b"FONT":
        raise ValueError(f"{path.name} is not an FTL font")
    count, stride = struct.unpack_from(">HH", raw, 0x0C)
    start = struct.unpack_from(">I", raw, 0x08)[0]
    return {struct.unpack_from(">I", raw, start + i * stride)[0] for i in range(count)}


def baseline_from_the_game() -> tuple[dict, str] | tuple[None, str]:
    import subprocess
    import tempfile

    source = DAT / "ftl.dat.vanilla"
    if not source.exists():
        source = DAT / "ftl.dat"
    if not source.exists():
        return None, "FTL is not installed"
    with tempfile.TemporaryDirectory() as tmp:
        out = Path(tmp) / "dat"
        result = subprocess.run(
            ["ftlman", "extract", str(out), str(source)],
            capture_output=True, text=True,
        )
        if result.returncode != 0:
            return None, "ftlman extract failed"
        fonts = sorted((out / "fonts").glob("*.font"))
        if not fonts:
            return None, "no font in the archive"
        tables = {f.name: glyphs(f) for f in fonts}
    common = sorted(set.intersection(*tables.values()))
    return {
        "_comment": [
            "Automatic baseline, do not hand-edit: `check_glyphs.py --regen`.",
            "INTERSECTION of the glyph tables of every latin font in ftl.dat.",
            "A character missing from here has no texture in the game: it does not show,",
            "with no error nor placeholder square, and the sentence reads with a hole.",
            "The ja/ and zh-Hans/ fonts are excluded: those languages have their own, and the",
            "mod is not translated into them.",
        ],
        "source": source.name,
        "fonts": sorted(tables),
        "codepoints": common,
    }, f"{len(fonts)} fonts read from {source.name}"


def displayed_strings() -> list[tuple[str, str, str]]:
    found: list[tuple[str, str, str]] = []
    for file in sorted((ROOT / "lang").glob("*.json")):
        data = json.loads(file.read_text(encoding="utf-8"))
        for key, value in data.get("strings", {}).items():
            found.append((f"lang/{file.name}", key, value))
    for file in sorted((ROOT / "ArchipelagoFTL" / "data").glob("text*.append")):
        for line in file.read_text(encoding="utf-8").splitlines():
            if not line.startswith("<text "):
                continue
            match = re.match(r'<text name="([^"]+)"[^>]*>(.*)</text>\s*$', line)
            if match:
                found.append((file.name, match.group(1), match.group(2)))
    return found


def main() -> int:
    regen = "--regen" in sys.argv

    read, reason = baseline_from_the_game()
    if regen:
        if read is None:
            print(f"check_glyphs: could not redo the baseline ({reason})", file=sys.stderr)
            return 2
        BASELINE.write_text(json.dumps(read, ensure_ascii=False, indent=2) + "\n", encoding="utf-8")
        print(f"check_glyphs: baseline redone, {len(read['codepoints'])} codepoints ({reason})")
        return 0

    if not BASELINE.exists():
        print("check_glyphs: baseline missing, run --regen on a machine where FTL is installed",
              file=sys.stderr)
        return 2
    baseline = json.loads(BASELINE.read_text(encoding="utf-8"))
    known = set(baseline["codepoints"])

    problems: list[str] = []

    if read is not None and set(read["codepoints"]) != known:
        missing = sorted(known - set(read["codepoints"]))
        added = sorted(set(read["codepoints"]) - known)
        problems.append(
            "the committed baseline no longer matches ftl.dat's fonts "
            f"(extra: {len(missing)}, missing: {len(added)}), rerun --regen"
        )

    for file, key, text in displayed_strings():
        absent = sorted({c for c in text if ord(c) > 0x7F and ord(c) not in known})
        for character in absent:
            problems.append(
                f"{file}: \"{key}\" uses \"{character}\" (U+{ord(character):04X}), "
                f"missing from FTL's fonts, it will not show at all, the sentence will have a hole"
            )

    if problems:
        print("check_glyphs: issues", file=sys.stderr)
        for problem in problems:
            print(f"  {problem}", file=sys.stderr)
        return 1

    count = len(displayed_strings())
    checked = "baseline confirmed against ftl.dat" if read is not None else "committed baseline"
    if read is None:
        print("SKIPPED: no ftl.dat; the committed glyph baseline was not compared with the game")
    print(f"check_glyphs: {count} displayed strings, every character exists "
          f"in the {len(baseline['fonts'])} fonts ({checked})")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
