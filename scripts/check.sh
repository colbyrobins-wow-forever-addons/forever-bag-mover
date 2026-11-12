#!/usr/bin/env bash
# Runs every repository check. CI and scripts/check.ps1 both call this file, so
# local results match CI. Run from the repository root; needs luacheck, python3,
# and the lupa Python package.
set -euo pipefail

addon=ForeverBagMover

echo "== luacheck"
luacheck "$addon"

echo "== Python tests"
python3 tests/check_addon.py

echo "== TOC files"
grep -vE '^[[:space:]]*(#|$)' "$addon/$addon.toc" | tr -d '\r' |
  while read -r file; do
    if [ ! -f "$addon/$file" ]; then
      echo "::error::TOC lists a missing file: $file"
      exit 1
    fi
  done

echo "All checks passed."
