#!/usr/bin/env python3
"""Writes apworld/ftl/data_mv.py from the Data zip of FTL: Multiverse.

usage: extract_mv.py "Multiverse 5.5.1 - Data.zip" ["Multiverse 5.5 - Assets.zip" (for the drone pictures)]
"""

from __future__ import annotations

import re
import sys
import zipfile
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]
OUT = ROOT / "apworld" / "ftl" / "data_mv.py"
MOD_OUT = ROOT / "mod" / "ArchipelagoFTL" / "data" / "archipelago" / "gamedata_mv.lua"
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


POWER_SYSTEMS = ("shields", "weapons", "engines")


def start_levels(body: str) -> tuple[int, ...]:
    """The level each power system starts at, 0 when the ship does not start with it."""
    listing = body[body.find("<systemList>"):body.find("</systemList>")]
    levels = {}
    for name, attrs in re.findall(r"<(\w+)\s([^>]*)>", listing):
        if name in POWER_SYSTEMS and name not in levels and 'start="true"' in attrs:
            power = re.search(r'power="(\d+)"', attrs)
            levels[name] = int(power.group(1)) if power else 1
    return tuple(levels.get(name, 0) for name in POWER_SYSTEMS)


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
                layouts.append((name + suffix, *systems_of(bps[name + suffix]), start_levels(bps[name + suffix])))

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
        *(f"    ({bp!r}, {start!r})," for bp, start, _, _ in layouts),
        ")",
        "",
        "MV_LAYOUT_EMPTY_SLOTS_RAW: tuple[tuple[str, tuple[str, ...]], ...] = (",
        *(f"    ({bp!r}, {empty!r})," for bp, _, empty, _ in layouts),
        ")",
        "",
        "# Start level of shields, weapons and engines, 0 when the layout does not start with the system.",
        "MV_LAYOUT_START_LEVELS_RAW: tuple[tuple[str, int, int, int], ...] = (",
        *(f"    ({bp!r}, {', '.join(map(str, levels))})," for bp, _, _, levels in layouts),
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

    # The dashboard draws each Multiverse achievement with the icon Hyperspace gives it.
    icons = dict(re.findall(r'<achievement name="([A-Z_0-9]+)">.*?<icon>([^<]+)</icon>', hs, re.S))
    # And each weapon with its art's first frame, as the start-of-run menu draws it.
    # Multiverse weapons may reuse a base game animation: read the base game's too, Multiverse's last.
    vanilla = Path.home() / ".local/share/ftl-extract/vanilla"
    animations = "".join((vanilla / "data" / name).read_text(encoding="utf-8", errors="replace")
                         for name in ("animations.xml", "dlcAnimations.xml") if (vanilla / "data" / name).exists())
    animations += "".join(read(name) for name in ("data/animations.xml.append", "data/dlcAnimations.xml.append")
                          if name in archive.namelist())
    sheets = {m.group(1): (m.group(6).strip(), *map(int, m.group(2, 3, 4, 5))) for m in re.finditer(
        r'<animSheet name="([^"]+)" w="(\d+)" h="(\d+)" fw="(\d+)" fh="(\d+)">([^<]+)</animSheet>', animations)}
    weapon_anims = {}
    for m in re.finditer(r'<weaponAnim name="([^"]+)">(.*?)</weaponAnim>', animations, re.S):
        sheet = re.search(r"<sheet>([^<]+)</sheet>", m.group(2))
        desc = re.search(r'<desc[^>]*x="(\d+)"[^>]*y="(\d+)"', m.group(2))
        if sheet:
            weapon_anims[m.group(1)] = (sheet.group(1).strip(), *(map(int, desc.groups()) if desc else (0, 0)))
    sold_names = {item[2] for item in sold}
    weapon_art = {}
    for name, body in re.findall(r'<weaponBlueprint name="([A-Z_0-9]+)"[^>]*>(.*?)</weaponBlueprint>', catalogue, re.S):
        art = re.search(r"<weaponArt>([^<]+)</weaponArt>", body)
        anim = weapon_anims.get(art.group(1).strip()) if art else None
        if anim and anim[0] in sheets and name in sold_names:
            weapon_art[name] = (*sheets[anim[0]], anim[1], anim[2])
    # And each drone sold, with the same choice as the base game's generator: drone, crew drone sprite, or icon.
    assets = set()
    if len(sys.argv) > 2:
        assets = {name[len("img/"):] for name in zipfile.ZipFile(sys.argv[2]).namelist() if name.startswith("img/")}
    exists = lambda rel: rel in assets or (vanilla / "img" / rel).exists()
    drone_art = {}
    for name, body in re.findall(r'<droneBlueprint name="([A-Z_0-9]+)"[^>]*>(.*?)</droneBlueprint>', catalogue, re.S):
        if name not in sold_names:
            continue
        image = re.search(r"<droneImage>([^<]+)</droneImage>", body)
        icon = re.search(r"<iconImage>([^<]+)</iconImage>", body)
        image, icon = (image.group(1).strip() if image else ""), (icon.group(1).strip() if icon else "")
        for path in (f"ship/drones/{image}_base.png" if image else None, f"people/{icon}_base.png" if icon else None,
                     f"systemUI/weapbox_icon_D_{icon}.png" if icon else None):
            if path and exists(path):
                drone_art[name] = path
                break
    mod_lines = [
        f"-- Extracted from FTL: Multiverse {version} by apworld/tools/extract_mv.py, do not edit by hand.",
        "local images = (_G.apGameData or {}).achievementImages",
        "if images then",
        *(f'    images.{name} = "achievements/{icons[name].strip()}.png"'
          for _, name, _ in feats if name in icons),
        "end",
        "local drones = (_G.apGameData or {}).droneArt",
        "if drones then",
        *(f'    drones.{name} = "{path}"' for name, path in sorted(drone_art.items())),
        "end",
        "local weapons = (_G.apGameData or {}).weaponArt",
        "if weapons then",
        *(f'    weapons.{name} = {{ "{path}", {w}, {h}, {fw}, {fh}, {x}, {y} }}'
          for name, (path, w, h, fw, fh, x, y) in sorted(weapon_art.items())),
        "end",
        "",
    ]
    MOD_OUT.write_text("\n".join(mod_lines), encoding="utf-8", newline="\n")
    print(f"{OUT.name}: {len(ships)} ships, {len(layouts)} layouts, {len(sold)} items for sale "
          f"{len(feats)} achievements (Multiverse {version})")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
