#!/usr/bin/env bash
# DEBT-ymdg — one round: the four walks once each, then the score.
# Usage: bash run-round.sh <outdir> [label]
# Four headless runs (fresh, legacy, stale, fork), finished walks skipped. The
# asset the round is built and scored against: the shipped assets/harness.md
# when it exists, else standin/harness-shipped.md (the control on a skill text
# that ships no owned file). Env as run.sh (MODEL, PERM_MODE, ANSWER, DRY).
set -u
OUT="${1:?usage: run-round.sh <outdir> [label]}"; LABEL="${2:-}"
SRC="$(cd "$(dirname "$0")" && pwd)"
W() { if command -v cygpath >/dev/null 2>&1; then cygpath -m "$1"; else printf '%s\n' "$1"; fi; }
ASSET="$SRC/../../plugins/super-bootstrap/skills/harness-bootstrap/assets/harness.md"
[ -f "$ASSET" ] || ASSET="$SRC/standin/harness-shipped.md"
echo "asset: $ASSET"
for walk in fresh legacy stale fork; do
  SHIPPED="$ASSET" bash "$SRC/run.sh" "$OUT" "$walk" "$LABEL" || echo "run failed: $walk"
done
[ "${DRY:-}" = 1 ] && exit 0
PYTHONIOENCODING=utf-8 python3 "$(W "$SRC/score.py")" "$(W "$OUT")" --asset "$(W "$ASSET")"
