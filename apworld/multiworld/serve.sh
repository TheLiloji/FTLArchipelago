#!/usr/bin/env bash
set -euo pipefail

HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
AP="${AP_ROOT:-$HOME/.local/opt/Archipelago}"
SEED="${1:-}"

if [ -z "$SEED" ]; then
    SEED="$(ls -t "$HERE"/seeds/AP_*.archipelago 2>/dev/null | head -1 || true)"
fi
[ -n "$SEED" ] || { echo "no seed found: run ./make.sh first" >&2; exit 1; }

echo "seed    : $SEED"
echo "address : localhost:38281"
echo "slots   : from the seed, the server lists them at startup"
echo
exec "$AP/ArchipelagoServer" "$SEED"
