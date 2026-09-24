#!/usr/bin/env python3

from __future__ import annotations

import json
import re
import subprocess
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]
APWORLD = ROOT / "apworld"
MOD = ROOT / "mod"
sys.path.insert(0, str(MOD / "test"))
from vanilla import vanilla_data  # noqa: E402

failures: list[str] = []
checks_run = 0


def check(condition: bool, message: str) -> bool:
    global checks_run
    checks_run += 1
    if not condition:
        failures.append(message)
    return condition


def load_data_module():

    import types

    path = APWORLD / "ftl" / "data.py"
    module = types.ModuleType("ftl_data")
    module.__file__ = str(path)
    sys.modules["ftl_data"] = module
    exec(compile(path.read_text(encoding="utf-8"), str(path), "exec"), module.__dict__)
    return module


def dump_mod_contract() -> dict:
    assembled = subprocess.run(
        [sys.executable, str(MOD / "test" / "build.py"), "--dump"],
        capture_output=True, text=True, check=True,
    ).stdout

    scratch = Path("/tmp") / "ftlap_contract_dump.lua"
    scratch.write_text(assembled, encoding="utf-8")

    result = subprocess.run(
        ["ftlman", "lua-run", str(scratch)], capture_output=True, text=True,
    )
    output = result.stdout + result.stderr
    match = re.search(r"CONTRACT_DUMP_BEGIN\n(.*?)\nCONTRACT_DUMP_END", output, re.S)
    if match is None:
        raise SystemExit(
            "the mod did not print its contract. ftlman output:\n" + output[-2000:]
        )
    return json.loads(match.group(1))


def load_options_module():

    import importlib
    import importlib.util
    import os

    source = Path(os.environ.get("AP_SOURCE", "~/.local/opt/Archipelago-0.6.7-src")).expanduser()
    frozen = Path(os.environ.get("AP_ROOT", "~/.local/opt/Archipelago")).expanduser()

    if source.is_dir() and str(source) not in sys.path:
        sys.path.insert(0, str(source))
    for extra in (frozen / "lib" / "library.zip", frozen / "lib"):
        if extra.exists() and str(extra) not in sys.path:
            sys.path.append(str(extra))

    try:
        import ModuleUpdate  # noqa: F401
        ModuleUpdate.update_ran = True
    except Exception:
        pass

    import types

    package = types.ModuleType("ftl_probe")
    package.__path__ = [str(APWORLD / "ftl")]
    sys.modules["ftl_probe"] = package
    sys.modules["ftl_probe.data"] = sys.modules["ftl_data"]

    try:
        return importlib.import_module("ftl_probe.options")
    except Exception as error:
        print(f"  (could not import options.py: {error})", file=sys.stderr)
        return None


def blueprint_names_from_game() -> tuple[set[str] | None, str]:
    """Every blueprint name FTL itself knows, read straight from ftl.dat: the same source of
    truth check_game_data.py already uses for ship names, so any contributor with FTL
    installed gets the full check, not just this machine's private notes."""
    vanilla_dir, reason = vanilla_data()
    if vanilla_dir is None:
        return None, reason
    names: set[str] = set()
    for filename in ("blueprints.xml", "dlcBlueprints.xml", "dlcBlueprintsOverwrite.xml"):
        path = vanilla_dir / filename
        if path.exists():
            text = path.read_text(encoding="utf-8", errors="replace")
            names |= set(re.findall(
                r'<(?:weapon|drone|aug|system|crew|item)Blueprint\s+name="([^"]+)"', text))
    return names, ""


LUA_NON_BLUEPRINTS = {
    "BURST_LASER_2", "DRONE_DEFENSE_1", "THIS_NAME_DOES_NOT_EXIST",
    "FAIL", "TEST", "STORE", "BOSS_DESTROYED",
}


def mod_declared_names() -> set[str]:

    names: set[str] = set()
    data_dir = MOD / "ArchipelagoFTL" / "data"
    for path in data_dir.glob("*.append"):
        text = path.read_text(encoding="utf-8")
        names |= set(re.findall(r'<(?:weapon|drone|aug|system|ship)Blueprint\s+name="([^"]+)"', text))
        names |= set(re.findall(r'<event\s+name="([^"]+)"', text))
        names |= set(re.findall(r'<customStore\s+id="([^"]+)"', text))
    return names


def lua_string_literals(filename: str) -> set[str]:
    source = (MOD / "ArchipelagoFTL" / "data" / "archipelago" / filename).read_text(
        encoding="utf-8"
    )
    source = re.sub(r"--\[\[.*?\]\]", "", source, flags=re.S)
    source = re.sub(r"--[^\n]*", "", source)
    quoted = set(re.findall(r'"([A-Z][A-Z0-9_]{2,})"', source))
    keys = set(re.findall(r"^\s*([A-Z][A-Z0-9_]{2,})\s*=", source, re.M))
    return quoted | keys


def main() -> int:
    data = load_data_module()
    mod = dump_mod_contract()

    mod_kinds = set(mod["kinds"])
    mod_resources = set(mod["resources"])
    mod_effects = set(mod["trap_effects"])

    apworld_kinds = {item.kind for item in data.ITEMS}
    missing = sorted(apworld_kinds - mod_kinds)
    check(not missing,
          f"kinds used by the apworld and missing from the mod: {missing}. "
          "The matching items would be received with no effect.")

    declared = set(data.KINDS_IMPLEMENTED)
    check(declared == mod_kinds,
          f"data.KINDS_IMPLEMENTED and the mod do not agree.\n"
          f"    declared by apworld : {sorted(declared)}\n"
          f"    implemented by mod  : {sorted(mod_kinds)}")

    apworld_resources = {item.resource for item in data.ITEMS if item.resource}
    missing = sorted(apworld_resources - mod_resources)
    check(not missing,
          f"resources used by the apworld and not applied by the mod: {missing}. "
          "Add their delivery in filler.lua.")

    check(set(data.RESOURCES_IMPLEMENTED) == mod_resources,
          f"data.RESOURCES_IMPLEMENTED and filler.lua disagree.\n"
          f"    declared : {sorted(data.RESOURCES_IMPLEMENTED)}\n"
          f"    applied  : {sorted(mod_resources)}")

    apworld_effects = {item.trap_effect for item in data.ITEMS if item.trap_effect}
    missing = sorted(apworld_effects - mod_effects)
    check(not missing,
          f"trap effects used by the apworld and not applied by the mod: {missing}.")

    check(set(data.TRAP_EFFECTS_IMPLEMENTED) == mod_effects,
          f"data.TRAP_EFFECTS_IMPLEMENTED and filler.lua disagree.\n"
          f"    declared : {sorted(data.TRAP_EFFECTS_IMPLEMENTED)}\n"
          f"    applied  : {sorted(mod_effects)}")

    ships = {ship.blueprint for ship in data.SHIPS} | {
        layout.blueprint for layout in data.LAYOUTS
    }
    cited_ships = set()
    for filename in ("inventory.lua", "unlocks.lua", "testkeys.lua"):
        cited_ships |= {
            name for name in lua_string_literals(filename)
            if name.startswith("PLAYER_SHIP_")
        }
    unknown_ships = sorted(cited_ships - ships)
    check(not unknown_ships,
          f"layouts cited by the mod and unknown to the apworld: {unknown_ships}")

    known, reason = blueprint_names_from_game()
    if known is None:
        print(f"SKIPPED: {reason}; blueprint names not checked against ftl.dat")
    elif not known:
        check(False, "ftl.dat extraction produced no blueprint at all: "
                     "ftlman or the archive is broken")
    else:
        unknown = sorted(
            item.blueprint for item in data.ITEMS
            if item.kind == data.KIND_SHOP and item.blueprint not in known
        )
        check(not unknown,
              f"shop items unknown to ftl.dat: {unknown}")

        declared_by_mod = mod_declared_names()
        check(bool(declared_by_mod),
              "no identifier declared by the mod was found in its .append files: "
              "the check below would be meaningless")

        for filename in ("inventory.lua", "shop.lua", "testkeys.lua", "traplink.lua"):
            cited = lua_string_literals(filename)
            unknown = sorted(
                name for name in cited
                if name not in known and name not in ships
                and not name.startswith("PLAYER_SHIP_") and not name.startswith("ACH_")
                and name not in LUA_NON_BLUEPRINTS
                and name not in declared_by_mod
            )
            check(not unknown,
                  f"{filename} cites identifiers missing from ftl.dat: {unknown}. "
                  "FTL returns an EMPTY blueprint for an unknown name, so nothing would flag "
                  "it in game.")

    options_module = load_options_module()
    if options_module is None:
        check(False,
              "could not import options.py: the values offered to the player were NOT "
              "checked against the mod. Install the Archipelago sources (see "
              "apworld/run_tests.sh) or set AP_SOURCE.")
    else:
        pairs = [
            ("DeathLinkTrigger", mod["death_link_triggers"]),
            ("DeathLinkEffect", mod["death_link_effects"]),
            ("ShopUnlockMode", mod["shop_modes"]),
        ]
        for class_name, mod_values in pairs:
            option = getattr(options_module, class_name, None)
            if option is None:
                check(False, f"options.py has no {class_name} class")
                continue
            sent_to_the_mod = set(option.name_lookup.values())
            missing = sorted(sent_to_the_mod - set(mod_values))
            check(not missing,
                  f"{class_name} offers {missing} to the player, value(s) the mod does not "
                  "know: the setting would be silently ignored.")

            unreachable = sorted(set(mod_values) - sent_to_the_mod)
            if unreachable:
                print(f"  (note: {class_name} - the mod handles {unreachable}, "
                      "which no option can request)")

    for system in data.SYSTEMS:
        cap_items = sum(
            item.count for item in data.ITEMS
            if item.kind == data.KIND_CAP and item.system == system.system_id
        )
        starts = sum(
            item.count for item in data.ITEMS
            if item.kind == data.KIND_START and item.system == system.system_id
        )
        check(starts <= cap_items,
              f"{system.system_id}: {starts} level(s) given at the start for {cap_items} "
              "cap item(s). Levels beyond the cap would be lost "
              "(MOD_CONTRACT §2.4).")

    check(data.CONTRACT_VERSION >= mod["contract_min"],
          f"apworld contract version ({data.CONTRACT_VERSION}) below the mod's minimum "
          f"({mod['contract_min']})")

    contract_max = mod.get("contract_max")
    check(contract_max is not None and data.CONTRACT_VERSION <= contract_max,
          f"apworld contract version ({data.CONTRACT_VERSION}) above the mod's maximum "
          f"({contract_max}): any generated seed would be refused on connect")

    if failures:
        print(f"check_contract: {len(failures)} mismatch(es) out of {checks_run} checks\n")
        for failure in failures:
            print(f"  FAIL  {failure}\n")
        return 1
    print(f"check_contract: {checks_run} checks, no mismatch")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
