#!/usr/bin/env bash
# DEBT-118 M1+M2 — score every captured run, one TSV row per run.
# Readings and their definitions: score.py's docstring.
#
# Usage: bash score.sh <fixture-root>
set -u
FX="${1:?usage: score.sh <fixture-root>}"
SRC="$(cd "$(dirname "$0")" && pwd)"
PY=$(command -v python3 || command -v python)
printf 'run\t'
"$PY" "$SRC/score.py" needme "$FX/golden/needme.md" "$FX/golden/needme.md" --header | head -1
for board in "$SRC"/runs/*-r*.board.md; do
  [ -f "$board" ] || continue
  tag="$(basename "$board" .board.md)"
  mode="$(printf '%s' "$tag" | cut -d- -f2)"
  printf '%s\t' "$tag"
  "$PY" "$SRC/score.py" "$mode" "$FX/golden/$mode.md" "$board" "$SRC/runs/$tag.reads.txt"
done
