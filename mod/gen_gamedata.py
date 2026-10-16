#!/usr/bin/env python3

import re
import sys
from pathlib import Path
from lxml import etree

DATA = Path.home() / ".local/share/ftl-extract/vanilla/data"
OUT = Path(__file__).resolve().parent / "ArchipelagoFTL/data/archipelago/gamedata.lua"

EXCLUDED_SHIPS = {"PLAYER_SHIP_TUTORIAL", "PLAYER_SHIP_EASY"}


def parse(filename):
    path = DATA / filename
    if not path.exists():
        return None
    return etree.parse(str(path), etree.XMLParser(recover=True)).getroot()


def collect_achievements():
    root = parse("achievements.xml")
    general, per_ship = [], {}
    for node in root.iter("achievement"):
        ach_id = node.get("id")
        if not ach_id:
            continue
        ship = node.findtext("ship")
        if ship:
            per_ship.setdefault(ship.strip(), []).append(ach_id)
        else:
            general.append(ach_id)
    return sorted(general), {k: sorted(v) for k, v in sorted(per_ship.items())}


def collect_achievement_images():
    root = parse("achievements.xml")
    images = {}
    for node in root.iter("achievement"):
        ach_id, img = node.get("id"), (node.findtext("img") or "").strip()
        if ach_id and img:
            images[ach_id] = img
    return dict(sorted(images.items()))


def collect_weapon_art(roots_blueprints, roots_animations):
    """Each weapon's first animation frame, as a store draws it: image, image size, frame size, frame position."""
    sheets, anims = {}, {}
    for root in roots_animations:
        for node in root.iter("animSheet"):
            sheets[node.get("name")] = (node.text or "").strip(), node
        for node in root.iter("weaponAnim"):
            desc = node.find("desc")
            anims[node.get("name")] = ((node.findtext("sheet") or "").strip(),
                                       int(desc.get("x", 0)) if desc is not None else 0,
                                       int(desc.get("y", 0)) if desc is not None else 0)
    art = {}
    for root in roots_blueprints:
        for node in root.iter("weaponBlueprint"):
            name, anim = node.get("name"), (node.findtext("weaponArt") or "").strip()
            if not name or anim not in anims:
                continue
            sheet, x, y = anims[anim]
            if sheet not in sheets:
                continue
            path, sheet_node = sheets[sheet]
            numbers = [int(sheet_node.get(k, 0)) for k in ("w", "h", "fw", "fh")]
            if path and all(numbers):
                art[name] = (path, *numbers, x, y)
    return dict(sorted(art.items()))


def lua_weapon_art(art, target):
    return [f'{target}.{name} = {{ "{path}", {w}, {h}, {fw}, {fh}, {x}, {y} }}'
            for name, (path, w, h, fw, fh, x, y) in art.items()]


IMG = DATA.parent / "img"


def drone_art_path(image, icon, exists):
    """The picture the start-of-run menu draws for a drone: the drone itself, a crew drone's sprite,
    or its drone bar icon."""
    if image and exists(f"ship/drones/{image}_base.png"):
        return f"ship/drones/{image}_base.png"
    if icon and exists(f"people/{icon}_base.png"):
        return f"people/{icon}_base.png"
    if icon and exists(f"systemUI/weapbox_icon_D_{icon}.png"):
        return f"systemUI/weapbox_icon_D_{icon}.png"
    return None


def collect_drone_art(roots_blueprints):
    art = {}
    for root in roots_blueprints:
        for node in root.iter("droneBlueprint"):
            name = node.get("name")
            path = drone_art_path((node.findtext("droneImage") or "").strip(), (node.findtext("iconImage") or "").strip(),
                                  lambda rel: (IMG / rel).exists())
            if name and path:
                art[name] = path
    return dict(sorted(art.items()))


def collect_ships():
    ships = {}
    for filename in ("blueprints.xml", "dlcBlueprints.xml", "dlcBlueprintsOverwrite.xml"):
        root = parse(filename)
        if root is None:
            continue
        for node in root.iter("shipBlueprint"):
            name = node.get("name") or ""
            if not name.startswith("PLAYER_SHIP_"):
                continue
            base = re.sub(r"_(2|3)$", "", name)
            if base in EXCLUDED_SHIPS:
                continue
            variant = 3 if name.endswith("_3") else (2 if name.endswith("_2") else 1)
            ships[base] = max(ships.get(base, 0), variant)
    return dict(sorted(ships.items()))


def lua_string_list(values, indent="        "):
    return "\n".join(f'{indent}"{value}",' for value in values)


def collect_systems():
    systems = {}
    for filename in ("blueprints.xml", "dlcBlueprints.xml", "dlcBlueprintsOverwrite.xml"):
        root = parse(filename)
        if root is None:
            continue
        for node in root.iter("systemBlueprint"):
            name = node.get("name")
            if not name:
                continue
            max_power = node.findtext("maxPower")
            systems[name] = int(max_power) if max_power and max_power.strip().isdigit() else 1
    return dict(sorted(systems.items()))


def main():
    if not DATA.exists():
        sys.exit(f"extracted resources not found: {DATA}")

    general, per_ship = collect_achievements()
    ships = collect_ships()

    lines = [
        "--[[",
        "    ArchipelagoFTL - game data.",
        "",
        "    GENERATED FILE by mod/gen_gamedata.py from ftl.dat. Do not hand-edit: any fix",
        "    must go through the generator, or it will be lost next time it runs. These",
        "    identifiers are the boundary with the game, a typo would only show up in game,",
        "    long after the fact.",
        "]]",
        "",
        "local gamedata = {}",
        "",
        "-- Number of playable layouts per ship (1 = A, 2 = A and B, 3 = A, B and C).",
        "gamedata.ships = {",
    ]
    for base, layouts in ships.items():
        lines.append(f'    {{ name = "{base}", layouts = {layouts} }},')

    systems = collect_systems()
    lines += [
        "}",
        "",
        "-- The sixteen systems, with their max level in FTL. Used by the dashboard:",
        "-- it also shows what is STILL locked, which gives the player a goal.",
        "gamedata.systems = {",
    ]
    for name, max_level in systems.items():
        lines.append(f'    {{ id = "{name}", maxLevel = {max_level} }},')

    lines += [
        "}",
        "",
        "-- Blueprint name suffix per layout: A has none.",
        'gamedata.variantSuffix = { [0] = "", [1] = "_2", [2] = "_3" }',
        "",
        f"-- General achievements ({len(general)}), independent of ship.",
        "gamedata.generalAchievements = {",
        lua_string_list(general, "    "),
        "}",
        "",
        f"-- Ship achievements ({sum(len(v) for v in per_ship.values())} across {len(per_ship)} ships).",
        "gamedata.shipAchievements = {",
    ]
    for ship, achievements in per_ship.items():
        lines.append(f"    [\"{ship}\"] = {{")
        lines.append(lua_string_list(achievements))
        lines.append("    },")
    lines += [
        "}",
        "",
        "-- Each weapon's art: image, its width and height, a frame's width and height, the first frame's column and row.",
        "gamedata.weaponArt = {}",
    ]
    blueprints = [r for r in (parse(f) for f in ("blueprints.xml", "dlcBlueprints.xml", "dlcBlueprintsOverwrite.xml")) if r is not None]
    animations = [r for r in (parse(f) for f in ("animations.xml", "dlcAnimations.xml")) if r is not None]
    lines += lua_weapon_art(collect_weapon_art(blueprints, animations), "gamedata.weaponArt")
    lines += [
        "",
        "-- Each drone's picture: the drone, a crew drone's sprite sheet (people/), or its drone bar icon.",
        "gamedata.droneArt = {}",
    ]
    lines += [f'gamedata.droneArt.{name} = "{path}"' for name, path in collect_drone_art(blueprints).items()]
    lines += [
        "",
        "-- Each achievement's icon, as the game's achievement screen draws it.",
        "gamedata.achievementImages = {",
    ]
    for ach_id, img in collect_achievement_images().items():
        lines.append(f'    {ach_id} = "{img}",')
    lines += [
        "}",
        "",
        "-- Hyperspace Lua has neither require nor package: a mod's scripts only share",
        "-- globals, and load order follows hyperspace.xml.",
        "_G.apGameData = gamedata",
        "",
    ]

    OUT.write_text("\n".join(lines), encoding="utf-8", newline="\n")
    print(f"written: {OUT}")
    print(f"  {len(ships)} ships, {sum(ships.values())} layouts")
    print(f"  {len(general)} general achievements, {sum(len(v) for v in per_ship.values())} ship achievements")


if __name__ == "__main__":
    main()
