#!/usr/bin/env bash
set -uo pipefail

HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT="$(cd "$HERE/../.." && pwd)"
FTL_DATA="${FTL_DATA:-$HOME/.steam/steam/steamapps/common/FTL Faster Than Light/data}"
DAT="$FTL_DATA/ftl.dat"
OUT="$(mktemp -d)"
trap 'rm -rf "$OUT"' EXIT

[ -f "$DAT" ] || { echo "SKIPPED: no ftl.dat at $DAT"; exit 0; }
FTLMAN="${FTLMAN:-ftlman}"
command -v "$FTLMAN" >/dev/null || { echo "SKIPPED: ftlman not found"; exit 0; }

CAP=()
if command -v systemd-run >/dev/null 2>&1; then
    CAP=(systemd-run --user --scope --quiet -p MemoryMax=6G -p MemorySwapMax=0)
fi

"${CAP[@]}" "$FTLMAN" extract "$OUT" "$DAT" 2>&1 \
    | grep -vE "Failed to get locale|^\[INFO\]" || true
D="$OUT/data"
failures=0

expect() {
    local label="$1" actual="$2" minimum="$3"
    if [ "$actual" -ge "$minimum" ]; then
        printf '  %-38s %s\n' "$label" "$actual"
    else
        printf '  %-38s %s  EXPECTED >= %s\n' "$label" "$actual" "$minimum" >&2
        failures=$((failures + 1))
    fi
}

SRC="$ROOT/mod/ArchipelagoFTL/data"
events=$(grep -c '<event name="AP_EVT_' "$SRC/events.xml.append")
texts=$(grep -c '<text name="ap_' "$SRC/text_misc.xml.append")
placements=$(grep -c '<mod-append:event name="AP_EVT_' "$SRC/sector_data.xml.append")
DEBUG_ONLY="testkeys.lua gifts_demo.lua"
if [ -f "$D/archipelago/testkeys.lua" ]; then
    build="debug"
    modules=$(ls "$SRC/archipelago"/*.lua | wc -l)
else
    build="player"
    modules=$(ls "$SRC/archipelago"/*.lua | grep -vcE "/(testkeys|gifts_demo)\.lua$")
fi
echo "  installed build: $build"

expect "events in events.xml"          "$(grep -c '<event name="AP_EVT_' "$D/events.xml")" "$events"
expect "english texts in text_misc.xml" "$(grep -o 'name="ap_[a-z0-9_.]*"' "$D/text_misc.xml" | wc -l)" "$texts"
for lang in de es fr it pt; do
    expect "texts $lang in text-$lang.xml" \
        "$(grep -o 'name="ap_[a-z0-9_.]*"' "$D/text-$lang.xml" | wc -l)" "$texts"
done
expect "placements in sector_data.xml"  "$(grep -o 'AP_EVT_[A-Z_]*' "$D/sector_data.xml" | wc -l)" "$placements"
expect "Lua modules"                    "$(ls "$D/archipelago"/*.lua 2>/dev/null | wc -l)" "$modules"
expect "Archipelago shops per sector"   "$(grep -c 'AP_STORE_EVENT' "$D/sector_data.xml")" 20
expect "embedded languages"             "$(grep -o 'apLangTables\["[a-z-]*"\]' "$D/archipelago/lang.lua" | sort -u | wc -l)" 6

stale=0
first=""
for src in "$SRC/archipelago"/*.lua; do
    name="$(basename "$src")"
    [ "$build" = player ] && [[ " $DEBUG_ONLY " == *" $name "* ]] && continue
    installed="$D/archipelago/$name"
    if [ ! -f "$installed" ]; then
        stale=$((stale + 1))
        [ -z "$first" ] && first="$name (missing)"
    elif ! cmp -s "$src" "$installed"; then
        stale=$((stale + 1))
        [ -z "$first" ] && first="$name"
    fi
done
if [ "$build" = player ] && grep -qE "testkeys|gifts_demo" "$D/hyperspace.xml"; then
    echo "  player build still loads a debug script from hyperspace.xml" >&2
    failures=$((failures + 1))
fi

if [ "$stale" -eq 0 ]; then
    printf '  %-38s %s\n' "Lua modules identical to source" "$modules"
else
    printf '  %-38s %s  (first: %s)\n' \
        "STALE or missing Lua modules" "$stale" "$first" >&2
    echo "  -> the game is not running what you just wrote. Rerun mod/install.sh." >&2
    failures=$((failures + 1))
fi

if [ "$failures" -eq 0 ]; then
    echo "check_install: the installed mod is complete and identical to the source"
    exit 0
fi
echo "check_install: $failures mismatch(es) between the source and the installed ftl.dat" >&2
exit 1
