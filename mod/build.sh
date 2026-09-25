#!/usr/bin/env bash
set -euo pipefail

here="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
src="$here/ArchipelagoFTL"
out="$here/ArchipelagoFTL.ftl"

[ -d "$src" ] || { echo "source not found: $src" >&2; exit 1; }

rm -f "$out"
if command -v zip >/dev/null 2>&1; then
    (cd "$src" && zip -q -r -X "$out" . -x '.*' -x '*/.*')
else
    python3 - "$src" "$out" <<'PY'
import os, sys, zipfile
src, out = sys.argv[1], sys.argv[2]
with zipfile.ZipFile(out, "w", zipfile.ZIP_DEFLATED) as archive:
    for folder, dirs, files in os.walk(src):
        dirs[:] = sorted(d for d in dirs if not d.startswith("."))
        for name in sorted(files):
            if not name.startswith("."):
                path = os.path.join(folder, name)
                archive.write(path, os.path.relpath(path, src).replace(os.sep, "/"))
PY
fi

echo "$out"
unzip -l "$out" | tail -n +4 | head -n -2
