#!/usr/bin/env bash
exec "$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)/apworld/tools/full_check.sh" "$@"
