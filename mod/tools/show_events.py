#!/usr/bin/env python3

from __future__ import annotations

import argparse
import re
from pathlib import Path

from lxml import etree

ROOT = Path(__file__).resolve().parents[2]
DATA = ROOT / "mod" / "ArchipelagoFTL" / "data"
WRAPPER = '<FTL xmlns:mod="http://www.subsetgames.com/mod" xmlns:mod-append="http://www.subsetgames.com/mod-append">'

RESOURCE_LABEL = {
    "scrap": "scrap", "fuel": "fuel", "missiles": "missiles", "drones": "drone parts",
}


def parse(path: Path) -> etree._Element:
    return etree.fromstring((WRAPPER + path.read_text(encoding="utf-8") + "</FTL>").encode("utf-8"))


def texts(path: Path) -> dict[str, str]:
    return {
        node.get("name"): "".join(node.itertext())
        for node in parse(path).iter("text")
        if node.get("name")
    }


def describe_effects(event: etree._Element, lua: str) -> list[str]:
    lines: list[str] = []
    for modify in event.findall("item_modify"):
        for item in modify.findall("item"):
            low, high = int(item.get("min", "0")), int(item.get("max", "0"))
            label = RESOURCE_LABEL.get(item.get("type", "?"), item.get("type", "?"))
            amount = f"{low}" if low == high else f"{low} to {high}"
            lines.append(f"{'+' if low > 0 else ''}{amount} {label}")
    for damage in event.findall("damage"):
        value = int(damage.get("amount", "0"))
        lines.append(f"{-value} hull" if value > 0 else f"+{-value} hull (repair)")
    for pursuit in event.findall("modifyPursuit"):
        value = int(pursuit.get("amount", "0"))
        lines.append("the rebel fleet advances" if value > 0 else "the rebel fleet retreats")
    for crew in event.findall("crewMember"):
        count = int(crew.get("amount", "1"))
        species = crew.get("class", "human")
        lines.append(f"+1 {species} crew member" if count > 0 else "-1 crew member")
    for boarders in event.findall("boarders"):
        lines.append(f"boarding: {boarders.get('min', '?')} to {boarders.get('max', '?')} enemies")
    for ship in event.findall("ship"):
        if ship.get("hostile") == "true":
            lines.append("COMBAT")
    for reward in event.findall("autoReward"):
        lines.append(f"random reward ({reward.get('level', '?')}, {reward.text})")
    if event.find("reveal_map") is not None:
        lines.append("the sector map is revealed")
    name = event.get("name")
    if name and f"{name} =" in lua:
        lines.append("+ an Archipelago effect (see events.lua)")
    return lines


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--lang", choices=("fr", "en"), default="fr")
    parser.add_argument("--effects", action="store_true")
    arguments = parser.parse_args()

    table = texts(DATA / ("text-fr.xml.append" if arguments.lang == "fr" else "text_misc.xml.append"))
    lua = (DATA / "archipelago" / "events.lua").read_text(encoding="utf-8")
    tree = parse(DATA / "events.xml.append")
    placements = re.findall(
        r'name="([A-Z_]+)" panic="throw">\s*((?:\s*<mod-append:event[^>]*>)+)',
        (DATA / "sector_data.xml.append").read_text(encoding="utf-8"),
    )
    sectors_of: dict[str, list[str]] = {}
    for sector, block in placements:
        for event_name in re.findall(r'name="(AP_EVT_[A-Z_]+)"', block):
            sectors_of.setdefault(event_name, []).append(sector)

    def resolve(node) -> str:
        identifier = node.get("id") if node is not None else None
        return table.get(identifier, f"[{identifier} MISSING]") if identifier else "[no text]"

    count = 0
    for event in tree.iter("event"):
        name = event.get("name") or ""
        if not name.startswith("AP_EVT_") or event.getparent().tag == "choice":
            continue
        count += 1
        print(f"\n{'=' * 96}")
        print(f"{count}. {name}")
        where = ", ".join(sorted(sectors_of.get(name, []))) or "NO SECTOR"
        print(f"   sectors: {where}")
        print(f"{'=' * 96}")
        print(f"\n{resolve(event.find('text'))}\n")
        for index, choice in enumerate(event.findall("choice"), 1):
            inner = choice.find("event")
            print(f"  [{index}] {resolve(choice.find('text'))}")
            print(f"      -> {resolve(inner.find('text') if inner is not None else None)}")
            if arguments.effects and inner is not None:
                effects = describe_effects(inner, lua)
                print(f"      EFFECTS: {' | '.join(effects) if effects else 'NONE'}")
            print()
    print(f"{count} events, in {arguments.lang}.")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
