#!/usr/bin/env bash
# DEBT-118 M6 — fire N cold headless reads of one arm, both tasks.
#
# Reading-only probe (house shape of bench/rot-scan-liveness): no fixture repo,
# no tools — the model gets the arm's Principles excerpt + a labelled CLAUDE.md
# and answers with the line IDs it deletes.
#
# Decontamination: runs from an empty scratch cwd with
#   CLAUDE_CODE_DISABLE_CLAUDE_MDS=1   (no device ~/.claude/CLAUDE.md — probed:
#                                       without it the reader quotes "# Global Rules")
#   --setting-sources project          (no user settings / hooks / plugins)
#   --tools "" --strict-mcp-config     (no tools, no MCP)
#
# Usage: bash run.sh <scratch-dir> <arm> [N]
# Env:   MODEL (default opus — the harness-bootstrap executor is the session model)
# Out:   runs/<arm>-<task>-r<n>.txt   the model's return (the whole evidence)
set -u
SCR="${1:?usage: run.sh <scratch-dir> <arm> [N]}"
ARM="${2:?arm: current | proposed | no-principle}"
N="${3:-3}"
MODEL="${MODEL:-opus}"
SRC="$(cd "$(dirname "$0")" && pwd)"

python "$SRC/build.py" >/dev/null || exit 1
mkdir -p "$SCR/cwd" "$SRC/runs"

for task in a b; do
  n=1
  while [ "$n" -le "$N" ]; do
    out="$SRC/runs/$ARM-$task-r$n.txt"
    if [ -s "$out" ]; then echo "[skip] $ARM-$task-r$n"; n=$((n + 1)); continue; fi
    (
      cd "$SCR/cwd" || exit 1
      CLAUDE_CODE_DISABLE_CLAUDE_MDS=1 claude -p --model "$MODEL" \
        --tools "" --strict-mcp-config --setting-sources project \
        < "$SRC/prompts/$ARM-$task.txt"
    ) > "$out" 2> "$SCR/$ARM-$task-r$n.err"
    echo "[$ARM-$task-r$n] exit=$? bytes=$(wc -c < "$out")"
    n=$((n + 1))
  done
done
