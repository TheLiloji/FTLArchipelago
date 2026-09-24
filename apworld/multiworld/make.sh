#!/usr/bin/env bash
set -euo pipefail

HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
AP="${AP_ROOT:-$HOME/.local/opt/Archipelago}"
OUT="${1:-$HERE/seeds}"

mkdir -p "$OUT"
python3 "$HERE/../tools/build_apworld.py" --output "$AP/custom_worlds/ftl.apworld"

cd "$AP"
./ArchipelagoGenerate \
    --player_files_path "$HERE/players" \
    --outputpath "$OUT" \
    --spoiler 3 < /dev/null 2>&1 | tail -4

cd "$OUT"
latest="$(ls -t AP_*.zip | head -1)"
unzip -o -q "$latest"
archipelago="$(ls -t AP_*.archipelago | head -1)"

python3 "$HERE/extract_gifts.py" "$OUT/$archipelago" 2>&1 | grep -v "_speedups"

echo
echo "seed ready: $OUT/$archipelago"
echo "to serve it: $HERE/serve.sh"
