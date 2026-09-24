#!/usr/bin/env bash
set -uo pipefail
HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
OUT="${TMPDIR:-/tmp}/ftlap_coverage.lua"
python3 "$HERE/../test/build.py" --coverage > "$OUT" || exit 2
ftlman lua-run "$OUT" 2>&1 | grep -v "Failed to get locale" | sed -n '/^Coverage/,$p'
