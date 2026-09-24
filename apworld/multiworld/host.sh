#!/usr/bin/env bash
set -euo pipefail

HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
AP="${AP_ROOT:-$HOME/.local/opt/Archipelago}"
PLAYERS="${1:-$HERE/players}"
OUTPUT="$HERE/to-host"

[ -d "$PLAYERS" ] || { echo "players folder not found: $PLAYERS" >&2; exit 1; }
[ -x "$AP/ArchipelagoGenerate" ] || { echo "Archipelago not found in $AP" >&2; exit 1; }

nb="$(find "$PLAYERS" -maxdepth 1 -name '*.yaml' | wc -l)"
[ "$nb" -gt 0 ] || { echo "no .yaml in $PLAYERS" >&2; exit 1; }

mkdir -p "$OUTPUT"
rm -f "$OUTPUT"/AP_*.zip "$OUTPUT"/AP_*.archipelago "$OUTPUT"/AP_*_Spoiler.txt

echo "1/3  apworld"
python3 "$HERE/../tools/build_apworld.py" --output "$AP/custom_worlds/ftl.apworld"

echo "2/3  generation ($nb player(s))"
(cd "$AP" && ./ArchipelagoGenerate \
    --player_files_path "$PLAYERS" \
    --outputpath "$OUTPUT" \
    --spoiler 3 < /dev/null 2>&1 | tail -3)

zip="$(ls -t "$OUTPUT"/AP_*.zip 2>/dev/null | head -1 || true)"
[ -n "$zip" ] || { echo "generation produced no .zip" >&2; exit 1; }

echo "3/3  verification"
python3 - "$zip" <<'PY'
import sys, zipfile, zlib
from pathlib import Path

path = Path(sys.argv[1])
with zipfile.ZipFile(path) as z:
    names = z.namelist()
    multi = [n for n in names if n.endswith(".archipelago")]
    if not multi:
        raise SystemExit("  FAIL: the zip contains no .archipelago")
    raw = zlib.decompress(z.read(multi[0])[1:]).decode("latin-1")

for expected in ("datapackage", "item_name_to_id", "location_name_to_id",
                "FTL: Faster Than Light"):
    if expected not in raw:
        raise SystemExit(f"  FAIL: \"{expected}\" missing from the multidata")
print("  the multidata embeds its datapackage, FTL included")

with zipfile.ZipFile(path) as z:
    spoilers = [n for n in z.namelist() if n.endswith("_Spoiler.txt")]
    if spoilers:
        lines = z.read(spoilers[0]).decode("utf-8", "replace").splitlines()
        player = None
        print()
        print("  slots in this game:")
        for line in lines:
            if line.startswith("Player "):
                player = line.split(":", 1)[1].strip()
            elif line.startswith("Game:") and player:
                print(f"    {player:<20} {line.split(':', 1)[1].strip()}")
                player = None
PY

echo
echo "================================================================"
echo "  TO UPLOAD: $zip"
echo
echo "  1. open  https://archipelago.gg/uploads"
echo "  2. drop this .zip there (the site opens a room and gives its address)"
echo "  3. give each player: the address, their slot name, the password if any"
echo "  4. on the FTL side: mod/install.sh, then the title screen to connect"
echo
echo "  The spoiler is INSIDE the zip: it says where every item is, do not share it."
echo "================================================================"
