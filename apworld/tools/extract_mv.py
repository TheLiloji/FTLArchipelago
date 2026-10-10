#!/usr/bin/env python3
"""Writes apworld/ftl/data_mv.py from the Data zip of FTL: Multiverse.

usage: extract_mv.py "Multiverse 5.5.1 - Data.zip"
"""

from __future__ import annotations

import re
import sys
import zipfile
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]
OUT = ROOT / "apworld" / "ftl" / "data_mv.py"
SYSTEMS = ("pilot", "doors", "sensors", "oxygen", "engines", "shields", "weapons", "drones", "medbay",
           "clonebay", "teleporter", "cloaking", "artillery", "battery", "mind", "hacking")
FIRST_SLOT = 10
ACHIEVEMENT_SECTIONS = ("Accomplishments", "Special Events")


def blueprints(text: str) -> dict[str, str]:
    found = {}
    for match in re.finditer(r'<shipBlueprint name="([A-Z_0-9]+)"(.*?)</shipBlueprint>', text, re.S):
        found.setdefault(match.group(1), match.group(2))
    return found


def systems_of(body: str) -> tuple[tuple[str, ...], tuple[str, ...]]:
    listing = body[body.find("<systemList>"):body.find("</systemList>")]
    start, empty = [], []
    for name, attrs in re.findall(r"<(\w+)\s([^>]*)>", listing):
        if name not in SYSTEMS:
            continue
        (start if 'start="true"' in attrs else empty).append(name)
    # No store sells the Artillery Beam: a ship only has it when it starts with it.
    return tuple(dict.fromkeys(start)), tuple(s for s in dict.fromkeys(empty) if s not in start and s != "artillery")


FAMILIES = {"weapon": "weapon", "drone": "drone", "aug": "augment"}


def shop_items(text: str, titles: dict[str, str]) -> list[tuple[int, str, str, str, int, int]]:
    last = {}
    for match in re.finditer(r'<(weapon|drone|aug)Blueprint name="([A-Z_0-9]+)"(.*?)</\1Blueprint>', text, re.S):
        last[match.group(2)] = (FAMILIES[match.group(1)], match.group(3))
    found, slots = [], {family: 0 for family in FAMILIES.values()}
    for name, (family, body) in last.items():
        rarity = re.search(r"<rarity>(\d+)</rarity>", body)
        cost = re.search(r"<cost>(\d+)</cost>", body)
        title = re.search(r'<title(?:\s+id="([^"]+)")?\s*(?:/>|>([^<]*)</title>)', body)
        display = (title.group(2) or titles.get(title.group(1) or "", "")).strip() if title else ""
        if not rarity or int(rarity.group(1)) <= 0 or not cost or not display:
            continue
        found.append((slots[family], family, name, display, int(rarity.group(1)), int(cost.group(1))))
        slots[family] += 1
    return found


def achievements(hs: str) -> list[tuple[int, str, str]]:
    listing = re.sub(r"<!--.*?-->", "", hs[hs.find("<achievements>"):hs.find("</achievements>")], flags=re.S)
    found = []
    for section in re.finditer(r'<section text="([^"]*)" hidden="false">(.*?)</section>', listing, re.S):
        if section.group(1) in ACHIEVEMENT_SECTIONS:
            for name, label in re.findall(r'<achievement name="([A-Z_0-9]+)">\s*<name>([^<]*)</name>', section.group(2)):
                found.append((len(found), name, label.strip()))
    return found


def main() -> int:
    archive = zipfile.ZipFile(sys.argv[1])
    read = lambda name: archive.read(name).decode("utf-8", errors="replace")
    version = re.search(r"(\d+\.\d+(?:\.\d+)?)", Path(sys.argv[1]).name).group(1)
    hs = read("data/hyperspace.xml")
    order = re.findall(r"<ship>([A-Z_0-9]+)</ship>", hs[hs.find("<shipOrder>"):hs.find("</shipOrder>")])
    listed = {}
    for match in re.finditer(r'<ship name="(PLAYER_SHIP_[A-Z_0-9]+)"([^>]*)>', hs):
        listed.setdefault(match.group(1), match.group(2))
    bps = {}
    for name in ("data/blueprints.xml.append", "data/autoBlueprints.xml.append", "data/dlcBlueprints.xml.append"):
        if name in archive.namelist():
            for key, body in blueprints(read(name)).items():
                bps.setdefault(key, body)

    texts = read("data/text_blueprints.xml.append") if "data/text_blueprints.xml.append" in archive.namelist() else ""
    titles = dict(re.findall(r'<text name="([^"]+)"[^>]*>([^<]*)</text>', texts))
    catalogue = ""
    for name in ("data/blueprints.xml.append", "data/autoBlueprints.xml.append", "data/dlcBlueprints.xml.append"):
        if name in archive.namelist():
            catalogue += read(name)
    sold = shop_items(catalogue, titles)
    feats = achievements(hs)

    ships, layouts, taken = [], [], set()
    for name in dict.fromkeys(order):
        attrs = listed.get(name)
        if attrs is None or 'secret="true"' in attrs or name not in bps:
            continue
        variants = ["A"]
        if 'b="true"' in attrs and name + "_2" in bps:
            variants.append("B")
        if 'c="true"' in attrs and name + "_3" in bps:
            variants.append("C")
        label = re.search(r"<class>([^<]+)</class>", bps[name])
        display = label.group(1).strip() if label else name.replace("PLAYER_SHIP_", "").title()
        if display in taken:
            display = f"{display} ({name.replace('PLAYER_SHIP_', '').title()})"
        taken.add(display)
        ships.append((FIRST_SLOT + len(ships), name, display, tuple(variants)))
        for letter, suffix in zip("ABC", ("", "_2", "_3")):
            if letter in variants:
                layouts.append((name + suffix, *systems_of(bps[name + suffix])))

    lines = [
        f'"""Extracted from FTL: Multiverse {version} by apworld/tools/extract_mv.py, do not edit by hand."""',
        "",
        f'MV_VERSION = "{version}"',
        "",
        "MV_SHIPS_RAW: tuple[tuple[int, str, str, tuple[str, ...]], ...] = (",
        *(f"    {ship!r}," for ship in ships),
        ")",
        "",
        "MV_LAYOUT_SYSTEMS_RAW: tuple[tuple[str, tuple[str, ...]], ...] = (",
        *(f"    ({bp!r}, {start!r})," for bp, start, _ in layouts),
        ")",
        "",
        "MV_LAYOUT_EMPTY_SLOTS_RAW: tuple[tuple[str, tuple[str, ...]], ...] = (",
        *(f"    ({bp!r}, {empty!r})," for bp, _, empty in layouts),
        ")",
        "",
        "MV_SHOP_ITEMS_RAW: tuple[tuple[int, str, str, str, int, int], ...] = (",
        *(f"    {item!r}," for item in sold),
        ")",
        "",
        "MV_ACHIEVEMENTS_RAW: tuple[tuple[int, str, str], ...] = (",
        *(f"    {feat!r}," for feat in feats),
        ")",
        "",
    ]
    OUT.write_text("\n".join(lines), encoding="utf-8", newline="\n")
    print(f"{OUT.name}: {len(ships)} ships, {len(layouts)} layouts, {len(sold)} items for sale "
          f"{len(feats)} achievements (Multiverse {version})")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
