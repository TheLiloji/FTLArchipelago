#!/usr/bin/env python3
import pathlib
import re
import sys

ROOT = pathlib.Path(__file__).resolve().parents[2]
MODULES = ROOT / "mod/ArchipelagoFTL/data/archipelago"

FTL_KEY_ROLES = {
    "a": "shields", "d": "medbay", "e": "drones", "f": "oxygen",
    "g": "teleporter", "h": "cloaking", "j": "jump", "k": "mind control",
    "l": "hacking", "m": "mind control (variant)", "p": "lockdown",
    "s": "engines", "w": "weapons", "y": "artillery",
}

LETTER = re.compile(r"Defines\.SDL\.KEY_([a-z])\b")
GUARD_MARKERS = ("not keyAllowed(", "if not onMenu")
GUARD_DEFINITION = "keyAllowed"
BLOCK_START = re.compile(r"^(?:local\s+)?function\s+([A-Za-z_][A-Za-z0-9_.]*)|^script\.")


def blocks(lines):
    starts = []
    for number, line in enumerate(lines, 1):
        found = BLOCK_START.match(line)
        if found:
            starts.append((number, found.group(1)))
    result = []
    for i, (start, name) in enumerate(starts):
        end = starts[i + 1][0] - 1 if i + 1 < len(starts) else len(lines)
        result.append((start, end, name))
    return result


def block_of(number, listing):
    for start, end, name in listing:
        if start <= number <= end:
            return start, end, name
    return None


def guard_before(lines, start, number):
    return any(guard in lines[i - 1] for i in range(start, number) for guard in GUARD_MARKERS)


def guarded(lines, listing, number, depth=0):
    block = block_of(number, listing)
    if block is None:
        return False
    start, _, name = block
    if guard_before(lines, start, number):
        return True
    if name is None or depth > 3:
        return False
    if name == GUARD_DEFINITION:
        return True
    call = re.compile(r"(?<![A-Za-z0-9_.:])" + re.escape(name) + r"\(")
    calls = [i for i, line in enumerate(lines, 1)
              if call.search(line) and i != start]
    return bool(calls) and all(guarded(lines, listing, i, depth + 1) for i in calls)


def command_lines(lines):
    found = []
    for number, line in enumerate(lines, 1):
        if "[Defines.SDL.KEY_" in line:
            continue
        for letter in LETTER.findall(line):
            found.append((number, letter))
    return found


def main():
    problems = []
    checked = 0
    for path in sorted(MODULES.glob("*.lua")):
        lines = path.read_text(encoding="utf-8").splitlines()
        found = command_lines(lines)
        if not found:
            continue
        listing = blocks(lines)
        checked += len(found)
        for number, letter in found:
            if guarded(lines, listing, number):
                continue
            role = FTL_KEY_ROLES.get(letter)
            detail = f", in FTL \"{letter}\" controls {role}" if role else ""
            problems.append(
                f"{path.name}:{number}: key \"{letter}\" acts with no F10 arming "
                f"nor menu guard before it in its handler{detail}. In a real run, the player "
                "presses it to play, not to test."
            )

    if problems:
        print("check_keys: issues")
        for problem in problems:
            print(f"  {problem}")
        return 1
    print(f"check_keys: {checked} letter key(s), each behind a guard in its own handler")
    return 0


if __name__ == "__main__":
    sys.exit(main())
