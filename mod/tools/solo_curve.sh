#!/usr/bin/env bash
set -uo pipefail
HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
OUT="${TMPDIR:-/tmp}/ftlap_curve.lua"
python3 "$HERE/../test/build.py" --curve > "$OUT" || exit 2
ftlman lua-run "$OUT" 2>&1 | grep -v "Failed to get locale"
