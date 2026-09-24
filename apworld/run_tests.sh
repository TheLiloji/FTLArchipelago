#!/usr/bin/env bash
set -euo pipefail

HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
AP_SOURCE="${AP_SOURCE:-$HOME/.local/opt/Archipelago-0.6.7-src}"
AP_ROOT="${AP_ROOT:-$HOME/.local/opt/Archipelago}"
AP_TAG="0.6.7"

if [ ! -f "$AP_SOURCE/worlds/AutoWorld.py" ]; then
    echo "Archipelago $AP_TAG sources missing, cloning into $AP_SOURCE"
    git clone --depth 1 --branch "$AP_TAG" \
        https://github.com/ArchipelagoMW/Archipelago.git "$AP_SOURCE"
fi

ln -sfn "$HERE/ftl" "$AP_SOURCE/worlds/ftl"

AP_SOURCE="$AP_SOURCE" AP_ROOT="$AP_ROOT" exec python3 "$HERE/tools/run_tests.py" "$@"
