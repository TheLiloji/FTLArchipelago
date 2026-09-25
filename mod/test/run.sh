#!/usr/bin/env bash
set -uo pipefail

HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
OUT="${TMPDIR:-/tmp}/ftlap_tests.lua"
LOG="${TMPDIR:-/tmp}/ftlap_checks.log"

export PYTHONUTF8=1

if command -v flock >/dev/null 2>&1; then
    LOCK="${TMPDIR:-/tmp}/ftl-archipelago-install.lock"
    exec 9>"$LOCK"
    if ! flock -w 600 9; then
        echo "an install has held the lock for more than ten minutes: $LOCK" >&2
        exit 2
    fi
fi

: > "$LOG"

# Runs a check live (so output streams as usual) while also keeping a copy, so any
# "SKIPPED: ..." line it prints can be collected into one summary at the end.
runcheck() {
    "$@" 2>&1 | tee -a "$LOG"
    return "${PIPESTATUS[0]}"
}

runcheck python3 "$HERE/../gen_lang.py" --check || exit 2

runcheck python3 "$HERE/check_i18n.py" || exit 2

runcheck python3 "$HERE/check_glyphs.py" || exit 2

runcheck python3 "$HERE/check_events.py" || exit 2

runcheck python3 "$HERE/check_wiring.py" || exit 2

runcheck python3 "$HERE/check_game_data.py" || exit 2

runcheck python3 "$HERE/check_harness.py" || exit 2

runcheck python3 "$HERE/check_module.py" || exit 2

runcheck python3 "$HERE/check_keys.py" || exit 2

python3 "$HERE/build.py" "$@" > "$OUT" || exit 2

OUTPUT="$("${FTLMAN:-ftlman}" lua-run "$OUT" 2>&1 | grep -v "Failed to get locale")"
echo "$OUTPUT"

if ! grep -q "^TESTS OK" <<< "$OUTPUT"; then
    exit 1
fi

if [ -z "${SKIP_CONTRACT:-}" ]; then
    echo
    runcheck python3 "$HERE/../../apworld/tools/check_contract.py" || exit 1
else
    echo "SKIPPED: contract check disabled via SKIP_CONTRACT" | tee -a "$LOG"
fi

skipped="$(grep "^SKIPPED:" "$LOG" || true)"
if [ -n "$skipped" ]; then
    echo
    echo "Skipped (not verified this run):"
    sed 's/^/  /' <<< "$skipped"
fi
exit 0
