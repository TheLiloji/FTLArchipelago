#!/usr/bin/env python3

from __future__ import annotations

import re
import subprocess
import sys
from pathlib import Path

from lxml import etree

from vanilla import vanilla_data

ROOT = Path(__file__).resolve().parent.parent
DATA = ROOT / "ArchipelagoFTL" / "data"
EVENTS = DATA / "events.xml.append"
TEXT_EN = DATA / "text_misc.xml.append"
TRANSLATIONS = {code: DATA / f"text-{code}.xml.append"
                for code in ("de", "es", "fr", "it", "pt")}
EVENTS_LUA = DATA / "archipelago" / "events.lua"
SECTORS = DATA / "sector_data.xml.append"

WRAPPER = (
    '<FTL xmlns:mod="http://www.subsetgames.com/mod" '
    'xmlns:mod-append="http://www.subsetgames.com/mod-append" '
    'xmlns:mod-before="http://www.subsetgames.com/mod-before" '
    'xmlns:mod-overwrite="http://www.subsetgames.com/mod-overwrite">'
)

COSTS = {
    "damage",
    "boarders",
    "modifyPursuit",
    "ship",
    "crewMember",
    "removeCrew",
}


def parse(path: Path) -> etree._Element:
    raw = path.read_text(encoding="utf-8")
    return etree.fromstring((WRAPPER + raw + "</FTL>").encode("utf-8"))


REUSED = {"list_tutorial_2"}


def text_names(path: Path) -> set[str]:
    return {
        node.get("name")
        for node in parse(path).iter("text")
        if node.get("name")
    }


def main() -> int:
    failures: list[str] = []

    trees = {}
    for path in sorted(DATA.glob("*.xml.append")):
        try:
            trees[path.name] = parse(path)
        except etree.XMLSyntaxError as error:
            failures.append(f"{path.name}: invalid XML - {error}")
    if failures:
        for problem in failures:
            print(f"  {problem}", file=sys.stderr)
        return 1

    events_tree = trees[EVENTS.name]
    english = text_names(TEXT_EN)

    for node in events_tree.iter("text"):
        identifier = node.get("id")
        if identifier and identifier.startswith("ap_") and identifier not in english:
            failures.append(f"text cited and never declared: \"{identifier}\"")

    for code, path in sorted(TRANSLATIONS.items()):
        if not path.is_file():
            failures.append(f"translation missing: text-{code}.xml.append")
            continue
        translated = text_names(path)
        for missing in sorted(english - translated):
            failures.append(f"missing from language \"{code}\": \"{missing}\"")
        for extra in sorted(translated - english):
            failures.append(f"present in \"{code}\" and not in english: \"{extra}\"")

    candidates = [
        node for node in events_tree.iter("event")
        if (node.get("name") or "").startswith("AP_EVT_")
        and node.getparent().tag != "choice"
        and node.getparent().tag != "loadEventList"
    ]
    # An event made of a loadEventList only picks which version the beacon loads.
    switches = {
        node.get("name"): {node.find("loadEventList").get("default")}
        | {inner.get("load") for inner in node.find("loadEventList").findall("event")}
        for node in candidates if node.find("loadEventList") is not None
    }
    top_level = [node for node in candidates if node.get("name") not in switches]
    if len(top_level) < 4:
        failures.append(f"{len(top_level)} custom events, at least 4 are required")

    branches_in_xml: set[str] = set()
    for event in top_level:
        name = event.get("name")

        choices = event.findall("choice")
        if len(choices) not in (2, 3):
            failures.append(f"{name}: {len(choices)} choices, 2 are needed, plus a third to leave")

        pay_in_scrap = 0
        for index, choice in enumerate(choices, 1):
            inner = choice.find("event")
            if inner is None:
                failures.append(f"{name}, choice {index}: no result event")
                continue
            branch = inner.get("name")
            if branch:
                branches_in_xml.add(branch)

            has_cost = any(child.tag in COSTS for child in inner)
            pays = False
            for modify in inner.findall("item_modify"):
                for item in modify.findall("item"):
                    if int(item.get("min", "0")) < 0:
                        has_cost = True
                        if item.get("type") == "scrap":
                            pays = True
            pay_in_scrap += pays
            if not has_cost and branch and branch in EVENTS_LUA.read_text(encoding="utf-8"):
                has_cost = True
            exit_choice = index == 3
            if exit_choice and has_cost:
                failures.append(
                    f"{name}, choice 3: the third choice is for leaving, it must be free"
                )
            if not exit_choice and not has_cost:
                failures.append(
                    f"{name}, choice {index}: no cost and no risk, "
                    "a dilemma whose two branches are free is just a menu"
                )
        if choices and pay_in_scrap == len(choices):
            failures.append(
                f"{name}: every choice costs scrap. If short, FTL still opens the "
                "first one and the player pays what they have: one choice must cost nothing"
            )

    lua = EVENTS_LUA.read_text(encoding="utf-8")
    for branch in sorted(set(re.findall(r"\b(AP_EVT_[A-Z_]+)\s*=", lua))):
        if branch not in branches_in_xml:
            failures.append(
                f"Lua effect on \"{branch}\", which exists in no XML choice: "
                "it will never trigger"
            )

    placed = set(re.findall(r'<mod-(?:append|before):event name="(AP_EVT_[A-Z_]+)"',
                            SECTORS.read_text(encoding="utf-8")))
    for switch, versions in switches.items():
        if switch in placed:
            placed |= versions
    for event in top_level:
        if event.get("name") not in placed:
            failures.append(
                f"{event.get('name')} is placed in no sector: nobody will see it"
            )

    on_the_map = [
        node for node in events_tree.iter("event")
        if (node.get("name") or "").startswith("AP_")
        and node.getparent().tag != "choice"
    ]
    for event in on_the_map:
        tags = [node.get("load") for node in event.findall("beaconType")]
        if not any(b in ("AP_BEACON", "AP_BEACON_SIGNAL") for b in tags):
            failures.append(
                f"{event.get('name')} is not tagged ARCHIPELAGO on the map: "
                "the player cannot choose to go there"
            )

    scenarios = "\n".join(
        path.read_text(encoding="utf-8")
        for path in sorted((ROOT / "test").glob("scenarios*.lua"))
    )
    for branch in sorted(set(re.findall(r"\b(AP_EVT_[A-Z_]+)\s*=", lua))):
        if f'"{branch}"' not in scenarios:
            failures.append(
                f"branch \"{branch}\" has a Lua effect that no test names explicitly"
            )

    vanilla, reason = vanilla_data()
    if vanilla is None:
        print(f"SKIPPED: {reason}; sector and text patch application not verified")
    else:
        extracted = vanilla / "sector_data.xml"
        if not extracted.is_file():
            failures.append("sector_data.xml missing from the ftl.dat extraction")
        else:
            result = subprocess.run(
                ["ftlman", "append", str(extracted), str(SECTORS)],
                capture_output=True, text=True,
            )
            if result.returncode != 0:
                failures.append(f"the sector patch does not apply: {result.stderr.strip()}")
            else:
                applied = len(re.findall(r'name="AP_EVT_[A-Z_]+"', result.stdout))
                expected = len(re.findall(r'<mod-(?:append|before):event name="AP_EVT_[A-Z_]+"',
                                          SECTORS.read_text(encoding="utf-8")))
                if applied != expected:
                    failures.append(
                        f"sector patch: {applied} placements applied out of {expected} declared"
                    )
                for block in re.finditer(r'<sectorDescription[^>]*name="([A-Z_]+)".*?</sectorDescription>',
                                        result.stdout, re.S):
                    names = re.findall(r'<event[^>]*name="([A-Z_]+)"', block.group(0))
                    ranks = [rank for rank, name in enumerate(names) if name.startswith("AP_")]
                    if ranks and ranks != list(range(len(ranks))):
                        failures.append(
                            f"{block.group(1)}: the Archipelago events are not first. FTL places "
                            "events in order and drops the ones that no longer fit: added "
                            "at the end, they vanish from loaded sectors"
                        )

        targets = [(TEXT_EN, "text_misc.xml")]
        targets += [(path, f"text-{code}.xml") for code, path in sorted(TRANSLATIONS.items())]
        for patch, target in targets:
            original = vanilla / target
            if not original.is_file():
                failures.append(f"{target} is not in ftl.dat: ftlman would ignore {patch.name}")
                continue
            result = subprocess.run(
                ["ftlman", "append", str(original), str(patch)],
                capture_output=True, text=True,
            )
            if result.returncode != 0:
                failures.append(f"{patch.name} does not apply: {result.stderr.strip()}")
                continue
            applied = len(re.findall(r'name="(ap_[a-z0-9_.]+)"', result.stdout))
            declared = len({name for name in text_names(patch) if name.startswith("ap_")})
            if applied < declared:
                failures.append(
                    f"{patch.name}: {applied} texts applied out of {declared} declared"
                )

            vanilla_names = set(re.findall(r'name="([^"]+)"', original.read_text(encoding="utf-8")))
            for name in sorted(name for name in text_names(patch) if not name.startswith("ap_")):
                if name not in REUSED:
                    failures.append(
                        f"{patch.name}: \"{name}\" is neither a mod text nor a declared reuse. "
                        "If intended, add it to REUSED with the reason."
                    )
                elif name not in vanilla_names:
                    failures.append(
                        f"{patch.name}: \"{name}\" is declared as a reuse, but this name "
                        f"does not exist in {target}, it would replace nothing."
                    )
            for name in sorted(REUSED):
                if name not in text_names(patch):
                    failures.append(f"{patch.name}: the reuse \"{name}\" is not there")

    blueprints = DATA / "blueprints.xml.append"
    if blueprints.is_file():
        arts = re.findall(r"<weaponArt>([^<]+)</weaponArt>",
                          blueprints.read_text(encoding="utf-8"))
        if not arts:
            failures.append("blueprints.xml.append declares no weaponArt")
        anims = DATA / "animations.xml.append"
        declared_anims = set()
        sheets = {}
        if anims.is_file():
            anims_text = anims.read_text(encoding="utf-8")
            declared_anims = set(re.findall(r'<weaponAnim name="([^"]+)"', anims_text))
            sheets = dict(re.findall(
                r'<animSheet name="([^"]+)"[^>]*>([^<]+)</animSheet>', anims_text))
        for art in sorted(set(arts)):
            name = art.strip()
            if name not in declared_anims:
                failures.append(
                    f"blueprints.xml.append names animation \"{name}\", which no "
                    "`<weaponAnim>` in animations.xml.append declares, the item's box "
                    "would be empty"
                )
                continue
            relative = sheets.get(name)
            if relative is None:
                failures.append(
                    f"\"{name}\" has a `<weaponAnim>` but no `<animSheet>` of the same name"
                )
                continue
            if not (ROOT / "ArchipelagoFTL" / "img" / relative.strip()).is_file():
                failures.append(
                    f"animation \"{name}\" points to \"{relative.strip()}\", which does not "
                    "exist in img/, the item's box would be empty"
                )

    listing = DATA / "events_imageList.xml.append"
    if listing.is_file():
        files = re.findall(r"<img[^>]*>([^<]+)</img>", listing.read_text(encoding="utf-8"))
        if not files:
            failures.append("events_imageList.xml.append declares no image")
        for relative in files:
            if not (ROOT / "ArchipelagoFTL" / "img" / relative.strip()).is_file():
                failures.append(
                    f"events_imageList.xml.append names \"{relative.strip()}\", "
                    "which does not exist in img/, the event would display on an empty background"
                )
        carrying = len(re.findall(r'<img back="AP_BACKGROUND" planet="AP_PLANET"/>',
                                 EVENTS.read_text(encoding="utf-8")))
        if carrying != len(top_level):
            failures.append(
                f"{carrying} event(s) carry the Archipelago background out of {len(top_level)}, "
                "the ones without it display on the sky of whatever beacon"
            )

        hyperspace = (DATA / "hyperspace.xml.append").read_text(encoding="utf-8")
        repainted = set(re.findall(
            r'<event name="(AP_EVT_[A-Z_]+)">\s*<changeBackground>AP_BACKGROUND</changeBackground>',
            hyperspace))
        top_names = {node.get("name") for node in top_level}
        missing = sorted(top_names - repainted)
        if missing:
            failures.append(
                f"{len(missing)} event(s) with no `changeBackground` in "
                f"hyperspace.xml.append, including \"{missing[0]}\", their background would "
                "only apply when the beacon is generated, never when the event triggers"
            )

    if failures:
        print("check_events: issues", file=sys.stderr)
        for problem in failures:
            print(f"  {problem}", file=sys.stderr)
        return 1

    print(
        f"check_events: {len(top_level)} events, {len(branches_in_xml)} branches, "
        f"{len(english)} texts in {len(TRANSLATIONS) + 1} languages, no free branch, "
        f"{len(placed)} placed in sectors"
    )
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
