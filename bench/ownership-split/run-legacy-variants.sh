#!/usr/bin/env bash
# DEBT-ymdg — the legacy-variant round: the `legacy` walk once per starting CLAUDE.md
# (current, v2.22.0, v5.10.6, v6.0.1, edited), each two-phase with ANSWER=y, then the score.
# Usage: bash run-legacy-variants.sh <outdir>
# Each variant is two headless turns (the confirm prompt, then `y`), so a full round starts
# 10 claude processes — printed up front, and under DRY=1 nothing starts. Finished variants
# (their stream.jsonl exists) are skipped by run.sh and not counted. Directories:
# <outdir>/legacy-<variant>/. Env as run.sh (MODEL, PERM_MODE, DRY); VARIANTS="v2.22.0 edited"
# narrows the round. Scored against the shipped assets/harness.md, else standin/harness-shipped.md.
set -u
OUT="${1:?usage: run-legacy-variants.sh <outdir>}"
SRC="$(cd "$(dirname "$0")" && pwd)"
W() { if command -v cygpath >/dev/null 2>&1; then cygpath -m "$1"; else printf '%s\n' "$1"; fi; }
ASSET="$SRC/../../plugins/super-bootstrap/skills/harness-bootstrap/assets/harness.md"
[ -f "$ASSET" ] || ASSET="$SRC/standin/harness-shipped.md"
VARIANTS="${VARIANTS:-current v2.22.0 v5.10.6 v6.0.1 edited}"
n=0; todo=""
for v in $VARIANTS; do
  if [ -s "$OUT/legacy-$v/stream.jsonl" ]; then continue; fi
  n=$((n + 2)); todo="$todo $v"
done
if [ "${DRY:-}" = 1 ]; then
  echo "[dry] the round would start $n claude process(es) (2 turns for each of:${todo:- none})"
else
  echo "round: $n claude process(es) (2 turns for each of:${todo:- none})"
fi
echo "asset: $ASSET"
for v in $VARIANTS; do
  ANSWER=y LEGACY_VARIANT="$v" SHIPPED="$ASSET" bash "$SRC/run.sh" "$OUT" legacy "$v" || echo "run failed: legacy-$v"
done
[ "${DRY:-}" = 1 ] && exit 0
PYTHONIOENCODING=utf-8 python3 "$(W "$SRC/score.py")" "$(W "$OUT")" --asset "$(W "$ASSET")"
