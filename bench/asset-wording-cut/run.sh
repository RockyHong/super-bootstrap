#!/usr/bin/env bash
# DEBT-sxck — fire N cold headless reads of one arm, every item (a b c e).
#
# Reading-only probe (house shape of bench/lean-brief-numbers): no fixture repo,
# no tools — the model gets only what loads at the item's governed moment plus
# the task, and answers in the item's fixed shape.
#
# Decontamination: runs from an empty scratch cwd with
#   CLAUDE_CODE_DISABLE_CLAUDE_MDS=1   (no device ~/.claude/CLAUDE.md)
#   --setting-sources project          (no user settings / hooks / plugins)
#   --tools "" --strict-mcp-config     (no tools, no MCP)
#
# Usage: bash run.sh <scratch-dir> <arm> [N] [items]
# Env:   MODEL (default opus — the session model the shipped runway serves)
# Out:   runs/<item>-<arm>-r<n>.txt   the model's return (the whole evidence)
set -u
SCR="${1:?usage: run.sh <scratch-dir> <arm> [N] [items]}"
ARM="${2:?arm: current | trimmed}"
N="${3:-3}"
ITEMS="${4:-a b c e}"
MODEL="${MODEL:-opus}"
SRC="$(cd "$(dirname "$0")" && pwd)"

python "$SRC/build.py" >/dev/null || exit 1
mkdir -p "$SCR/cwd" "$SRC/runs"

for item in $ITEMS; do
  n=1
  while [ "$n" -le "$N" ]; do
    out="$SRC/runs/$item-$ARM-r$n.txt"
    if [ -s "$out" ]; then echo "[skip] $item-$ARM-r$n"; n=$((n + 1)); continue; fi
    (
      cd "$SCR/cwd" || exit 1
      CLAUDE_CODE_DISABLE_CLAUDE_MDS=1 claude -p --model "$MODEL" \
        --tools "" --strict-mcp-config --setting-sources project \
        < "$SRC/prompts/$item-$ARM.txt"
    ) > "$out" 2> "$SCR/$item-$ARM-r$n.err"
    echo "[$item-$ARM-r$n] exit=$? bytes=$(wc -c < "$out")"
    n=$((n + 1))
  done
done
