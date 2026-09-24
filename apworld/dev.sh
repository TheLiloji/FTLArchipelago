#!/usr/bin/env bash
set -euo pipefail

AP="${AP_ROOT:-$HOME/.local/opt/Archipelago}"
HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PLAYERS="${1:-$HERE/players}"
OUT="${2:-$(mktemp -d)}"

python3 "$HERE/tools/build_apworld.py" --output "$AP/custom_worlds/ftl.apworld"

cd "$AP"
./ArchipelagoGenerate \
    --player_files_path "$PLAYERS" \
    --outputpath "$OUT" \
    --seed "${SEED:-4242}" \
    --spoiler 3 \
    < /dev/null

echo "output: $OUT"
