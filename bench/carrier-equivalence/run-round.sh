#!/usr/bin/env bash
# DEBT-ymdg — the 20-run round: {claudemd,rules,import} x {main,subagent,compact} x reps 1-2,
# plus none x main x 2. `compact` = one process, three stream-json turns (resume-compact is out of the round). Sequential; a run whose output exists is skipped. Then scores.
# Usage: bash run-round.sh <outdir>
set -u
OUT="${1:?usage: run-round.sh <outdir>}"; SRC="$(cd "$(dirname "$0")" && pwd)"
for rep in 1 2; do
  for arm in claudemd rules import; do
    for ctx in main subagent compact; do bash "$SRC/run.sh" "$OUT" "$arm" "$ctx" "$rep"; done
  done
  bash "$SRC/run.sh" "$OUT" none main "$rep"
done
python3 "$SRC/score.py" "$OUT/runs"
