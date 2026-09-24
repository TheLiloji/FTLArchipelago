#!/usr/bin/env bash
set -uo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
FTL_DIR="${FTL_DIR:-$HOME/.steam/steam/steamapps/common/FTL Faster Than Light}"

say() {
    if command -v kdialog >/dev/null 2>&1; then
        kdialog --title "FTL Archipelago" --error "$1"
    elif command -v zenity >/dev/null 2>&1; then
        zenity --error --title="FTL Archipelago" --text="$1"
    else
        echo "$1" >&2
    fi
}

if [ "${1:-}" != "--as-is" ]; then
    if ! out="$("$ROOT/mod/install.sh" 2>&1)"; then
        say "Mod install failed, the game was not launched.\n\n$(echo "$out" | tail -12)"
        exit 1
    fi
fi

[ -x "$FTL_DIR/FTL" ] || { say "FTL not found in:\n$FTL_DIR"; exit 1; }

cd "$FTL_DIR" || exit 1
exec ./FTL
