#!/usr/bin/env bash
set -euo pipefail

here="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
FTL_DATA="${FTL_DATA:-$HOME/.steam/steam/steamapps/common/FTL Faster Than Light/data}"
MODS_DIR="${MODS_DIR:-$HOME/.local/share/ftl-mods}"
FTLMAN="${FTLMAN:-$(command -v ftlman || echo "$HOME/.local/bin/ftlman")}"

[ -d "$FTL_DATA" ] || { echo "FTL data folder not found: $FTL_DATA" >&2; exit 1; }
[ -x "$FTLMAN" ]   || { echo "ftlman not found: $FTLMAN" >&2; exit 1; }
[ -f "$MODS_DIR/Hyperspace.ftl" ] || {
    echo "Hyperspace.ftl not found in $MODS_DIR: put it there, or give its folder via MODS_DIR" >&2
    exit 1
}

LOCK="${TMPDIR:-/tmp}/ftl-archipelago-install.lock"
exec 9>"$LOCK"
if ! flock -w 300 9; then
    echo "another install has held the lock for more than 5 minutes: $LOCK" >&2
    exit 1
fi

header_ok() {
    [ -f "$1" ] || return 0
    [ "$(head -c 4 "$1" | xxd -p)" = "504b470a" ]
}

if ! header_ok "$FTL_DATA/ftl.dat"; then
    echo "ftl.dat is no longer a PKG archive: restore ftl.dat.vanilla before continuing" >&2
    exit 1
fi

"$here/build.sh" >/dev/null

CAP=()
if command -v systemd-run >/dev/null 2>&1; then
    CAP=(systemd-run --user --scope --quiet -p MemoryMax=6G -p MemorySwapMax=0)
fi

"${CAP[@]}" "$FTLMAN" patch -d "$FTL_DATA" \
    "$MODS_DIR/Hyperspace.ftl" \
    "$here/ArchipelagoFTL.ftl" 2>&1 | tr '\r' '\n' | grep -vE 'KiB/|MiB/'

header_ok "$FTL_DATA/ftl.dat" || {
    echo "ftl.dat came out damaged from the install: restore ftl.dat.vanilla" >&2
    exit 1
}

echo "mods applied to $FTL_DATA"
