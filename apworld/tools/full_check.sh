#!/usr/bin/env bash
set -uo pipefail

HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT="$(cd "$HERE/../.." && pwd)"
failures=0
skipped=()

# Each step streams its output and keeps a copy. A check that could not run prints
# "SKIPPED: <reason>"; those lines are collected so the summary never counts them as verified.
step() {
    local name="$1"
    shift
    echo
    echo "=== $name"
    local log
    log="$(mktemp)"
    "$@" 2>&1 | tee "$log"
    local status="${PIPESTATUS[0]}"
    local notes
    notes="$(grep "^SKIPPED:" "$log" | sed 's/^SKIPPED: *//')"
    local missing
    missing="$(grep -o "skipped '[^']*[Mm]issing[^']*'" "$log" | sed "s/^skipped '//; s/'$//" | sort -u)"
    [ -n "$missing" ] && notes="$notes${notes:+$'\n'}$missing"
    if [ "$status" -ne 0 ]; then
        echo "--- FAIL"
        failures=$((failures + 1))
    elif [ -n "$notes" ]; then
        echo "--- OK, with parts skipped"
    else
        echo "--- OK"
    fi
    while IFS= read -r note; do
        [ -n "$note" ] && skipped+=("$name: $note")
    done <<< "$notes"
    rm -f "$log"
}

step "Archipelago world: instantiation, ids, options, presets" \
    "$ROOT/apworld/run_tests.sh"

step "Lua mod: game loop against a fake Hyperspace, language, events, contract" \
    "$ROOT/mod/test/run.sh"

step "Installed mod: what is really inside the game's ftl.dat" \
    "$ROOT/mod/test/check_install.sh"

step "Presets: the mod accepts everyone's slot_data" \
    python3 "$ROOT/mod/test/check_presets_accepted.py"

step "Docs: the announced numbers are still true" \
    python3 "$ROOT/tests/check_docs_numbers.py"

step "Package: the .apworld builds and contains what it should" \
    python3 "$HERE/build_apworld.py" --check

step "Presets: what each one actually produces" \
    python3 "$ROOT/apworld/tools/preset_report.py" "$ROOT"/presets/*.yaml

if [ -n "${FULL:-}" ]; then
    step "Sampling phase: the suite is green at seven offsets" \
        python3 "$ROOT/mod/test/check_phase.py"

    step "Option space sweep: 2000 draws, 0 failures expected" \
        python3 "$ROOT/apworld/tools/fuzz_options.py" 2000 700000

    step "Real multiworlds: 1, 2, 3 and 6 slots with real other games" \
        python3 "$ROOT/apworld/tools/multiworld_matrix.py"
else
    skipped+=("phase sampling, option sweep and real multiworlds: long, run with FULL=1")
fi

echo
if [ "$failures" -eq 0 ]; then
    echo "ALL GREEN."
else
    echo "$failures step(s) failed."
fi
if [ "${#skipped[@]}" -gt 0 ]; then
    echo
    echo "Skipped (not verified this run):"
    for note in "${skipped[@]}"; do
        echo "  - $note"
    done
fi
exit "$failures"
