#!/usr/bin/env python3

from __future__ import annotations

import re
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
HARNESS = ROOT / "test" / "harness.lua"
WIKI = ROOT.parent / "reference" / "hyperspace" / "wiki"

SIGNATURE = re.compile(
    r"^-\s+(?:\[`?([\w:<>\*]+)`?\]\([^)]*\)|`?([A-Za-z_][\w:<>\*\s]*?)`?)\s*`?[:.]?\*?(\w+)\s*\(([^)]*)\)",
    re.MULTILINE,
)

VOID = {"void", ""}


def wiki_returns() -> tuple[dict[str, set[str]], dict[str, set[int]]]:
    kinds: dict[str, set[str]] = {}
    arities: dict[str, set[int]] = {}
    for path in sorted(WIKI.glob("*.md")):
        for link, bare, method, args in SIGNATURE.findall(path.read_text(encoding="utf-8")):
            kind = link or bare
            kinds.setdefault(method, set()).add(kind.strip().rstrip("*").strip())
            args = args.strip()
            arities.setdefault(method, set()).add(
                0 if not args else len([a for a in args.split(",") if a.strip()])
            )
    return kinds, arities


def strip_comments(text: str) -> str:

    out: list[str] = []
    in_block = False
    for line in text.splitlines():
        if in_block:
            end = line.find("]]")
            if end < 0:
                out.append("")
                continue
            line = line[end + 2:]
            in_block = False
        start = line.find("--[[")
        if start >= 0:
            rest = line[start + 4:]
            end = rest.find("]]")
            if end < 0:
                in_block = True
                out.append(line[:start])
                continue
            line = line[:start] + rest[end + 2:]
        short = line.find("--")
        if short >= 0:
            line = line[:short]
        out.append(line)
    return "\n".join(out)


def mod_calls() -> list[tuple[str, str, int, int]]:

    found: list[tuple[str, str, int, int]] = []
    for path in sorted((ROOT / "ArchipelagoFTL" / "data" / "archipelago").glob("*.lua")):
        if path.name in ("lang.lua", "gamedata.lua", "solo_order.lua", "gifts_demo.lua"):
            continue
        text = path.read_text(encoding="utf-8")
        text = strip_comments(text)
        pattern = (r":(\w+)\s*\(|\b(?:Hyperspace|Graphics)(?:\.\w+)*\.(\w+)\s*\(")
        for match in re.finditer(pattern, text):
            method = match.group(1) or match.group(2)
            i, depth, args, current = match.end() - 1, 0, [], ""
            while i < len(text):
                c = text[i]
                if c in "\"'":
                    quote, end = c, i + 1
                    while end < len(text) and (text[end] != quote or text[end - 1] == "\\"):
                        end += 1
                    current += text[i:end + 1]
                    i = end + 1
                    continue
                if c in "([{":
                    depth += 1
                    if depth == 1 and c == "(":
                        i += 1
                        continue
                elif c in ")]}":
                    depth -= 1
                    if depth == 0:
                        args.append(current)
                        break
                elif c == "," and depth == 1:
                    args.append(current)
                    current = ""
                    i += 1
                    continue
                current += c
                i += 1
            count = len([a for a in args if a.strip()])
            line = text[: match.start()].count("\n") + 1
            found.append((path.name, method, line, count))
    return found


def harness_methods() -> dict[str, str]:
    source = HARNESS.read_text(encoding="utf-8")
    bodies: dict[str, str] = {}

    for match in re.finditer(r"^\s*(\w+)\s*=\s*function\s*\(([^)]*)\)", source, re.MULTILINE):
        name = match.group(1)
        rest = source[match.end():]
        line_end = rest.find("\n")
        first = rest[:line_end if line_end > 0 else len(rest)]
        if re.search(r"\bend\b", first):
            bodies[name] = first
            continue
        stop = rest.find("\n        end")
        bodies[name] = rest[:stop if stop > 0 else 400]

    for match in re.finditer(r"^\s*function\s+\w+:(\w+)\s*\(([^)]*)\)", source, re.MULTILINE):
        name = match.group(1)
        rest = source[match.end():]
        stop = rest.find("\n    end")
        bodies[name] = rest[:stop if stop > 0 else 400]

    return bodies


def main() -> int:
    if not WIKI.is_dir():
        print(f"SKIPPED: Hyperspace wiki not available ({WIKI} is a local checkout, "
              "not part of the published repo); fake-return and call-arity checks not run")
        return 0

    declared, arities = wiki_returns()
    bodies = harness_methods()
    problems: list[str] = []
    checked = 0

    for method, body in sorted(bodies.items()):
        kinds = declared.get(method)
        if not kinds:
            continue
        returning = {kind for kind in kinds if kind.lower() not in VOID}
        if not returning:
            continue
        checked += 1
        if not re.search(r"\breturn\b", body):
            problems.append(
                f"\"{method}\" returns {', '.join(sorted(returning))} per the wiki, "
                "and the fake returns nothing"
            )

    arity_checked = 0
    for file, method, line, count in mod_calls():
        expected = arities.get(method)
        if not expected:
            continue
        arity_checked += 1
        if count not in expected:
            problems.append(
                f"{file}:{line}: \"{method}\" takes {' or '.join(map(str, sorted(expected)))}"
                f" argument(s) per the wiki, and the mod passes {count}"
            )

    if checked < 10 or arity_checked < 40:
        problems.append(
            f"suspicious extraction: {checked} returns and {arity_checked} arities checked. "
            "The wiki and the mod carry a lot more: this is the reader that's broken."
        )

    if problems:
        print("check_harness: issues", file=sys.stderr)
        for problem in problems:
            print(f"  {problem}", file=sys.stderr)
        return 1

    print(f"check_harness: {checked} fake methods do return a value, "
          f"{arity_checked} mod calls have the right number of arguments")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
