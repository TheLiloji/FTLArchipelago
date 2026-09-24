#!/usr/bin/env bash
set -uo pipefail

OUTPUT="${1:-/tmp/ftl-$(date +%Y%m%d-%H%M%S).png}"
export DISPLAY="${DISPLAY:-:0}"

command -v import >/dev/null 2>&1 || { echo "ImageMagick missing: apt install imagemagick" >&2; exit 1; }
command -v xdotool >/dev/null 2>&1 || { echo "xdotool missing: apt install xdotool" >&2; exit 1; }

pgrep -x FTL.amd64 >/dev/null || { echo "FTL is not running." >&2; exit 1; }

WINDOW=$(xdotool search --name "^FTL" 2>/dev/null | head -1)
[ -n "$WINDOW" ] || { echo "FTL window not found via X (game running under native Wayland?)" >&2; exit 1; }

if ! timeout 10 import -window "$WINDOW" "$OUTPUT" 2>/dev/null; then
    echo "capture failed, was window $WINDOW closed?" >&2
    exit 1
fi
echo "$OUTPUT"
