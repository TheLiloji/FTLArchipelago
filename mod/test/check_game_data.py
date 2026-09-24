#!/usr/bin/env python3

from __future__ import annotations

import re
import sys
from pathlib import Path

from vanilla import vanilla_data

ROOT = Path(__file__).resolve().parent.parent
HARNESS = ROOT / "test" / "harness.lua"
BLUEPRINTS = ROOT / "ArchipelagoFTL" / "data" / "blueprints.xml.append"
SHOPGIFT = ROOT / "ArchipelagoFTL" / "data" / "archipelago" / "shopgift.lua"


def lua_table(name: str) -> dict[str, str]:
    source = HARNESS.read_text(encoding="utf-8")
    start = source.find(f"sim.{name} = {{")
    if start < 0:
        return {}
    end = source.find("\n    }", start)
    body = source[start:end if end > 0 else len(source)]
    return dict(re.findall(r"(\w+)\s*=\s*\"([^\"]*)\"", body))


def game_data(data: Path) -> tuple[dict[str, str], dict[str, str]]:
    texts: dict[str, str] = {}
    for name in ("text_blueprints.xml", "text_misc.xml", "text_achievements.xml"):
        path = data / name
        if path.exists():
            content = path.read_text(encoding="utf-8", errors="replace")
            texts.update(re.findall(r'<text name="([^"]+)"[^>]*>([^<]*)</text>', content))

    ships: dict[str, str] = {}
    for name in ("blueprints.xml", "dlcBlueprints.xml", "dlcBlueprintsOverwrite.xml"):
        path = data / name
        if not path.exists():
            continue
        content = path.read_text(encoding="utf-8", errors="replace")
        for block in re.finditer(
            r'<shipBlueprint name="(PLAYER_SHIP_[A-Z0-9_]*)"[^>]*>(.*?)</shipBlueprint>',
            content, re.S,
        ):
            body = block.group(2)
            identifier = re.search(r'<name id="([^"]+)"', body)
            plain = re.search(r"<name[^>]*>([^<]+)</name>", body)
            if identifier and identifier.group(1) in texts:
                ships[block.group(1)] = texts[identifier.group(1)]
            elif plain:
                ships[block.group(1)] = plain.group(1)
    return ships, texts


def deals_consistent():
    amounts = re.search(r"DEAL_REWARD = \{([^}]*)\}", SHOPGIFT.read_text(encoding="utf-8"))
    if amounts is None:
        return ["shopgift.lua: DEAL_REWARD not found"]
    lua = [int(value) for value in re.findall(r"\d+", amounts.group(1))]
    xml = [int(value) for value in re.findall(
        r'<augBlueprint name="AP_DEAL_\d">\s*<title>[^<]*?(\d+)',
        BLUEPRINTS.read_text(encoding="utf-8"))]
    if not xml:
        return ["blueprints.xml.append: no deal title read"]
    if lua != xml:
        return [
            f"deals announce {xml} in blueprints.xml.append and pay {lua} "
            "in shopgift.lua: the title the player reads before the Lua "
            "rewrites it would be wrong"
        ]
    return []


def main() -> int:
    deals = deals_consistent()
    if deals:
        print("check_game_data: issues", file=sys.stderr)
        for issue in deals:
            print(f"  {issue}", file=sys.stderr)
        return 1

    data, reason = vanilla_data()
    if data is None:
        print(f"SKIPPED: {reason}; ship names and game texts were not checked")
        return 0
    ships, texts = game_data(data)

    problems: list[str] = []

    expected = lua_table("shipNames")
    for blueprint, name in sorted(expected.items()):
        real = ships.get(blueprint)
        if real is None:
            problems.append(f"sim.shipNames: \"{blueprint}\" does not exist in ftl.dat")
        elif real != name:
            problems.append(
                f"sim.shipNames: \"{blueprint}\" is \"{name}\" in the fake "
                f"and \"{real}\" in the game"
            )

    keys = lua_table("gameTexts")
    for key, value in sorted(keys.items()):
        real = texts.get(key)
        if real is None:
            problems.append(f"sim.gameTexts: key \"{key}\" does not exist in ftl.dat")
        elif real != value:
            problems.append(
                f"sim.gameTexts: \"{key}\" is \"{value}\" in the fake "
                f"and \"{real}\" in the game"
            )

    if len(expected) < 5 or len(keys) < 10:
        problems.append(
            f"suspicious extraction: {len(expected)} ships and {len(keys)} texts read from the "
            "fake Hyperspace. This is the table reader that's broken, not the fake."
        )

    if problems:
        print("check_game_data: issues", file=sys.stderr)
        for problem in problems:
            print(f"  {problem}", file=sys.stderr)
        return 1

    print(f"check_game_data: {len(expected)} ships and {len(keys)} texts of the fake "
          f"do match the game's")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
