#!/usr/bin/env python3

import re
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
MODULES = ROOT / "ArchipelagoFTL" / "data" / "archipelago"
TESTS = ROOT / "test"


LOCAL_DECL = re.compile(r"^(\s*)local function ([A-Za-z_][A-Za-z0-9_]*)\(([^()]*)\)\s*$")

OPENS_BRANCH = re.compile(r"\bthen\s*$")
ONE_LINE = re.compile(r"\bthen\b.+\bend\b")


def instrument(source: str, module: str) -> tuple[str, list[str]]:
    lines: list[str] = []
    names: list[str] = []
    branches: list[str] = []
    unmeasured = 0
    in_comment = False
    for number, line in enumerate(source.splitlines(), 1):
        lines.append(line)
        stripped = line.strip()

        if not in_comment and stripped.startswith("--[["):
            in_comment = True
        if in_comment:
            if "]]" in line:
                in_comment = False
            continue
        if stripped.startswith("--"):
            continue

        match = LOCAL_DECL.match(line)
        if match:
            indent, name = match.group(1), match.group(2)
            label = f"{module}:{name}"
            names.append(label)
            lines.append(f'{indent}  _G.apCoverageLocal("{label}")')
            continue

        if OPENS_BRANCH.search(line) or stripped == "else":
            indent = line[: len(line) - len(line.lstrip())]
            label = f"{module}:{number}"
            branches.append(label)
            lines.append(f'{indent}  _G.apCoverageBranch("{label}")')
        elif ONE_LINE.search(line):
            unmeasured += 1
    return "\n".join(lines), names, branches, unmeasured


LOCAL_NAMES_SEEN: list[str] = []
BRANCH_NAMES_SEEN: list[str] = []
BRANCHES_UNMEASURED = 0


def wrap(path: Path, coverage: bool = False) -> str:
    global BRANCHES_UNMEASURED
    source = path.read_text(encoding="utf-8")
    if coverage:
        source, names, branches, missed = instrument(source, path.stem)
        LOCAL_NAMES_SEEN.extend(names)
        BRANCH_NAMES_SEEN.extend(branches)
        BRANCHES_UNMEASURED += missed
    level = 1
    while ("]" + "=" * level + "]") in source:
        level += 1
    eq = "=" * level
    return (
        f'do\n'
        f'  local chunk, err = load([{eq}[\n{source}\n]{eq}], "@{path.name}", "t", _ENV)\n'
        f'  if chunk == nil then\n'
        f'    print("SYNTAX ERROR in {path.name}: " .. tostring(err))\n'
        f'    _G.__syntaxErrors = (_G.__syntaxErrors or 0) + 1\n'
        f'  else\n'
        f'    local ok, runErr = pcall(chunk)\n'
        f'    if not ok then\n'
        f'      print("LOAD ERROR in {path.name}: " .. tostring(runErr))\n'
        f'      _G.__loadErrors = (_G.__loadErrors or 0) + 1\n'
        f'    end\n'
        f'  end\n'
        f'end\n'
    )


NOT_TESTED = {"testkeys.lua"}


def order_from_hyperspace_xml() -> list[str]:
    xml = (ROOT / "ArchipelagoFTL" / "data" / "hyperspace.xml.append").read_text(encoding="utf-8")
    names = re.findall(r"<script>data/archipelago/([a-z0-9_]+\.lua)</script>", xml)
    return [name for name in names if name not in NOT_TESTED]


def main() -> int:
    phase_values = {
        sys.argv[index + 1]
        for index, argument in enumerate(sys.argv)
        if argument == "--phase" and index + 1 < len(sys.argv)
    }
    order = [arg for arg in sys.argv[1:] if not arg.startswith("--") and arg not in phase_values] \
        or order_from_hyperspace_xml()

    coverage = "--coverage" in sys.argv
    parts = [(TESTS / "harness.lua").read_text(encoding="utf-8")]
    if coverage:
        parts.append(
            "_G.apCoverageLocals = { calls = {}, names = {} }\n"
            "function _G.apCoverageLocal(name)\n"
            "  local t = _G.apCoverageLocals.calls\n"
            "  t[name] = (t[name] or 0) + 1\n"
            "end\n"
            "_G.apCoverageBranches = { calls = {}, names = {}, unmeasured = 0 }\n"
            "function _G.apCoverageBranch(name)\n"
            "  local t = _G.apCoverageBranches.calls\n"
            "  t[name] = (t[name] or 0) + 1\n"
            "end\n"
        )
    for name in order:
        path = MODULES / name
        if not path.exists():
            print(f"-- module missing, skipped: {name}", file=sys.stderr)
            continue
        parts.append(wrap(path, coverage))
    phase = 0
    for index, argument in enumerate(sys.argv):
        if argument == "--phase" and index + 1 < len(sys.argv):
            phase = int(sys.argv[index + 1])
    if phase:
        parts.append(f"sim.tick({phase})\nsim.clearLog()\n")

    if "--no-tail" in sys.argv:
        tail = None
    elif "--dump" in sys.argv:
        tail = "dump_contract.lua"
    elif "--curve" in sys.argv:
        tail = "solo_curve.lua"
    elif "--script" in sys.argv:
        tail = "solo_script.lua"
    else:
        tail = "scenarios.lua"
    if coverage:
        declared = ",\n  ".join('"%s"' % n for n in LOCAL_NAMES_SEEN)
        parts.append("_G.apCoverageLocals.names = {\n  " + declared + "\n}\n")
        seen = ",\n  ".join('"%s"' % n for n in BRANCH_NAMES_SEEN)
        parts.append("_G.apCoverageBranches.names = {\n  " + seen + "\n}\n")
        parts.append(f"_G.apCoverageBranches.unmeasured = {BRANCHES_UNMEASURED}\n")
        parts.append((TESTS / "coverage_probe.lua").read_text(encoding="utf-8"))
    if tail is not None:
        parts.append((TESTS / tail).read_text(encoding="utf-8"))
    if tail == "scenarios.lua":
        for supplement in sorted(TESTS.glob("scenarios_*.lua")):
            parts.append("do\n" + supplement.read_text(encoding="utf-8") + "\nend\n")
        parts.append((TESTS / "report.lua").read_text(encoding="utf-8"))
    if coverage:
        parts.append((TESTS / "coverage_report.lua").read_text(encoding="utf-8"))

    sys.stdout.write("\n".join(parts))
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
