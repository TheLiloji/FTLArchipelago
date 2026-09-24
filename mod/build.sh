#!/usr/bin/env bash
set -euo pipefail

here="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
src="$here/ArchipelagoFTL"
out="$here/ArchipelagoFTL.ftl"

[ -d "$src" ] || { echo "source not found: $src" >&2; exit 1; }

rm -f "$out"
(cd "$src" && zip -q -r -X "$out" . -x '.*' -x '*/.*')

echo "$out"
unzip -l "$out" | tail -n +4 | head -n -2
