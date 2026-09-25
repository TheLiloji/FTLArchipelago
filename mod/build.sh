#!/usr/bin/env bash
# Builds ArchipelagoFTL.ftl. The test keys and the demo shop are left out unless --debug is given.
set -euo pipefail

here="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
src="$here/ArchipelagoFTL"
out="$here/ArchipelagoFTL.ftl"
debug=0
[ "${1:-}" = "--debug" ] && debug=1

[ -d "$src" ] || { echo "source not found: $src" >&2; exit 1; }

PYTHON="$(command -v python3 || command -v python)"

rm -f "$out"
"$PYTHON" - "$src" "$out" "$debug" <<'PY'
import os, sys, zipfile
src, out, debug = sys.argv[1], sys.argv[2], sys.argv[3] == "1"
DEBUG_ONLY = {"data/archipelago/testkeys.lua", "data/archipelago/gifts_demo.lua"}
with zipfile.ZipFile(out, "w", zipfile.ZIP_DEFLATED) as archive:
    for folder, dirs, files in os.walk(src):
        dirs[:] = sorted(d for d in dirs if not d.startswith("."))
        for name in sorted(files):
            if name.startswith("."):
                continue
            path = os.path.join(folder, name)
            inside = os.path.relpath(path, src).replace(os.sep, "/")
            if not debug and inside in DEBUG_ONLY:
                continue
            if not debug and inside == "data/hyperspace.xml.append":
                with open(path, encoding="utf-8") as f:
                    lines = [line for line in f
                             if not any(f"<script>{d}</script>" in line for d in DEBUG_ONLY)]
                archive.writestr(inside, "".join(lines))
                continue
            archive.write(path, inside)
PY

echo "$out$([ "$debug" = 1 ] && echo " (debug: test keys included)")"
