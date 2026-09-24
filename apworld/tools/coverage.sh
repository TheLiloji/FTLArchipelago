#!/usr/bin/env bash
set -euo pipefail
HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT="$(cd "$HERE/../.." && pwd)"
AP_SOURCE="${AP_SOURCE:-$HOME/.local/opt/Archipelago-0.6.7-src}"
AP_ROOT="${AP_ROOT:-$HOME/.local/opt/Archipelago}"
ln -sfn "$ROOT/apworld/ftl" "$AP_SOURCE/worlds/ftl"
AP_SOURCE="$AP_SOURCE" AP_ROOT="$AP_ROOT" exec python3 "$HERE/coverage.py" "$@"
