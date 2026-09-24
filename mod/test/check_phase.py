#!/usr/bin/env python3

from __future__ import annotations

import re
import subprocess
import sys
from pathlib import Path

HERE = Path(__file__).resolve().parent
ROOT = HERE.parent.parent

OFFSETS = (0, 1, 7, 13, 29, 59, 119)


def play(offset: int) -> tuple[int, set[str]]:
    built = subprocess.run(
        [sys.executable, str(HERE / "build.py"), "--phase", str(offset)],
        capture_output=True, text=True, check=True,
    ).stdout
    file_path = HERE / f".phase_{offset}.lua"
    file_path.write_text(built, encoding="utf-8")
    try:
        output = subprocess.run(
            ["ftlman", "lua-run", str(file_path)], capture_output=True, text=True,
        ).stdout
    finally:
        file_path.unlink(missing_ok=True)

    failures = {
        line.split(" : ", 1)[0].replace("  FAIL  ", "").strip()
        for line in output.splitlines()
        if line.startswith("  FAIL")
    }
    match = re.search(r"(\d+) tests passed", output)
    return (int(match.group(1)) if match else -1), failures


def main() -> int:
    results = {offset: play(offset) for offset in OFFSETS}

    passed_counts = {count for count, _ in results.values()}
    flaky: set[str] = set()
    for _, failures in results.values():
        flaky |= failures

    if -1 in passed_counts:
        print("check_phase: at least one run announced nothing, the reader is broken",
              file=sys.stderr)
        return 2

    if flaky or len(passed_counts) != 1:
        print("check_phase: some tests depend on the sampling phase", file=sys.stderr)
        for offset in OFFSETS:
            count, failures = results[offset]
            if failures:
                print(f"  offset {offset:3d}: {count} passed, failures: "
                      f"{', '.join(sorted(failures))}", file=sys.stderr)
        print("  A test that waits for a sample must tick at least as much as the largest "
              "divisor it depends on (120 for the delivery queue).", file=sys.stderr)
        return 1

    print(f"check_phase: {passed_counts.pop()} tests, green at {len(OFFSETS)} phase offsets "
          f"({', '.join(str(d) for d in OFFSETS)})")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
