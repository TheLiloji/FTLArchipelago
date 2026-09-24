#!/usr/bin/env python3

from __future__ import annotations

import json
import os
import subprocess
import sys
import tempfile
import types
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]
PRESETS = ROOT / "presets"
SOURCE = Path(os.environ.get("AP_SOURCE", "~/.local/opt/Archipelago-0.6.7-src")).expanduser()
FROZEN = Path(os.environ.get("AP_ROOT", "~/.local/opt/Archipelago")).expanduser()

if not (SOURCE / "worlds" / "ftl").exists():
    sys.exit("run apworld/run_tests.sh once: it installs the sources and the world's symlink")

os.chdir(SOURCE)
sys.path.insert(0, str(SOURCE))
_stub = types.ModuleType("bsdiff4.core")
_stub.diff = _stub.patch = lambda *a, **k: b""
sys.modules["bsdiff4.core"] = _stub
sys.path.append(str(FROZEN / "lib" / "library.zip"))
sys.path.append(str(FROZEN / "lib"))

import logging  # noqa: E402
import warnings  # noqa: E402

logging.disable(logging.ERROR)
warnings.simplefilter("ignore")

import yaml  # noqa: E402
from test.general import setup_multiworld  # noqa: E402
from worlds.ftl import FTLWorld, data  # noqa: E402

GEN_STEPS = ("generate_early", "create_regions", "create_items", "set_rules",
             "connect_entrances", "generate_basic", "pre_fill")


def lua_value(value, indent: int = 0) -> str:
    pad = "    " * (indent + 1)
    closing = "    " * indent
    if value is None:
        return "nil"
    if isinstance(value, bool):
        return "true" if value else "false"
    if isinstance(value, (int, float)):
        return repr(value)
    if isinstance(value, str):
        return '"' + value.replace("\\", "\\\\").replace('"', '\\"') + '"'
    if isinstance(value, dict):
        if not value:
            return "{}"
        items = "\n".join(
            f'{pad}[{lua_value(str(k))}] = {lua_value(v, indent + 1)},'
            for k, v in sorted(value.items())
        )
        return "{\n" + items + f"\n{closing}}}"
    if isinstance(value, (list, tuple)):
        if not value:
            return "{}"
        return "{ " + ", ".join(lua_value(v, indent) for v in value) + " }"
    raise TypeError(f"type not serializable to Lua: {type(value)}")


def main() -> int:
    presets = sorted(PRESETS.glob("*.yaml"))
    if not presets:
        sys.exit(f"no preset in {PRESETS}")

    blocks = []
    for path in presets:
        document = yaml.safe_load(path.read_text(encoding="utf-8"))
        options = document[data.GAME_NAME]
        multiworld = setup_multiworld(FTLWorld, GEN_STEPS, seed=4242, options=options)
        slot_data = multiworld.worlds[1].fill_slot_data()
        json.dumps(slot_data)
        blocks.append((path.name, slot_data))

    lines = [
        "local failures = 0",
        "local out = sim.realPrint",
        "local function report(name, ok, detail)",
        "    if ok then",
        '        out(string.format("  OK      %-40s %s", name, detail or ""))',
        "    else",
        '        out(string.format("  REFUSED %-40s %s", name, detail or ""))',
        "        failures = failures + 1",
        "    end",
        "end",
        "",
    ]
    for name, slot_data in blocks:
        lines += [
            f"do",
            f"    local slot = {lua_value(slot_data, 1)}",
            "    if _G.apContractResetForTesting then apContractResetForTesting() end",
            "    local accepted = apApplySlotData(slot)",
            "    local descriptors, locations = 0, 0",
            "    for _ in pairs(slot.items) do descriptors = descriptors + 1 end",
            "    for _ in pairs(slot.loc) do locations = locations + 1 end",
            "    local refusal = _G.apContractState and _G.apContractState.refusal or nil",
            f'    report({lua_value(name)}, accepted ~= false,',
            '           refusal or string.format("%d items, %d locations, goal %s",',
            '               descriptors, locations,',
            '               tostring(slot.goal and (slot.goal.layouts and #slot.goal.layouts',
            '                                       or slot.goal.count) or "?")))',
            "end",
            "",
        ]
    lines += [
        "if failures == 0 then",
        f'    out("check_presets_accepted: the {len(blocks)} presets are accepted by the mod")',
        "else",
        '    out(failures .. " preset(s) REFUSED by the mod")',
        "end",
    ]

    with tempfile.NamedTemporaryFile("w", suffix=".lua", delete=False, encoding="utf-8") as handle:
        handle.write("\n".join(lines))
        tail = handle.name

    built = subprocess.run(
        [sys.executable, str(ROOT / "mod/test/build.py"), "--no-tail"],
        capture_output=True, text=True, check=True,
    ).stdout
    with tempfile.NamedTemporaryFile("w", suffix=".lua", delete=False, encoding="utf-8") as handle:
        handle.write(built + "\n" + Path(tail).read_text(encoding="utf-8"))
        script = handle.name

    result = subprocess.run(
        ["ftlman", "lua-run", script], capture_output=True, text=True,
    )
    output = "\n".join(
        line for line in result.stdout.splitlines() + result.stderr.splitlines()
        if "Failed to get locale" not in line
    )
    print(output)
    if "accepted by the mod" not in output:
        print(f"  (script kept: {script})", file=sys.stderr)
        return 1
    Path(tail).unlink(missing_ok=True)
    Path(script).unlink(missing_ok=True)
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
