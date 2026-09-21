#!/usr/bin/env bash
# GAP-085 — fire N cold headless runs of one arm against the fixture.
#
# Each rep gets its own pristine copy of the fixture repo, so a run never sees
# another run's edits. The runner is `claude -p` cwd'd inside that copy, with
# CLAUDE_CONFIG_DIR pointed at the credentials-only cold config dir — the
# runner this repo already uses for control arms (285dc98).
#
# Usage: bash run.sh <fixture-root> [arm] [N]
#   <fixture-root>  the dir `make-fixture.sh` was pointed at
#   arm             default `control`
#   N               default 3 (BUG-064 precedent, docs/decisions.md)
#
# Env: MODEL (default sonnet)
#
# Outputs, per rep:
#   <fixture-root>/runs/<arm>-r<n>/            the run's repo, left as delivered
#   <fixture-root>/runs/<arm>-r<n>.jsonl       full stream-json transcript
#   bench/assertion-liveness/runs/<arm>-r<n>.result.txt   the run's final return
#   bench/assertion-liveness/runs/<arm>-r<n>.delivered.py the delivered test file
#
# The transcripts stay in the scratch tree; the returns and the delivered
# assertions are the evidence and land in the repo.
set -u
FXROOT="${1:?usage: run.sh <fixture-root> [arm] [N]}"
ARM="${2:-control}"
N="${3:-3}"
MODEL="${MODEL:-sonnet}"
SRC="$(cd "$(dirname "$0")" && pwd)"

[ -d "$FXROOT/repo" ] || { echo "no fixture at $FXROOT/repo — run make-fixture.sh first" >&2; exit 1; }
PROMPT="$(cat "$SRC/task-prompt.txt")"
CFG="$FXROOT/coldcfg"
command -v cygpath >/dev/null 2>&1 && CFG="$(cygpath -m "$FXROOT/coldcfg")"

mkdir -p "$FXROOT/runs" "$SRC/runs"

n=1
while [ "$n" -le "$N" ]; do
  tag="$ARM-r$n"
  rundir="$FXROOT/runs/$tag"
  out="$FXROOT/runs/$tag.jsonl"
  if [ -s "$out" ]; then
    echo "[skip] $tag"
    n=$((n + 1))
    continue
  fi
  rm -rf "$rundir"
  cp -r "$FXROOT/repo" "$rundir"
  echo "[$tag] model=$MODEL cwd=$rundir"
  (
    cd "$rundir" || exit 1
    CLAUDE_CONFIG_DIR="$CFG" claude \
      --model "$MODEL" \
      --settings "$SRC/arm-$ARM.json" \
      --output-format stream-json --verbose \
      -p -- "$PROMPT"
  ) > "$out" 2> "$out.err"
  echo "      exit=$? lines=$(wc -l < "$out" 2>/dev/null)"

  # the run's final return — the primary reading's whole evidence
  python3 - "$out" "$SRC/runs/$tag.result.txt" <<'PY'
import io, json, sys
src, dst = sys.argv[1], sys.argv[2]
text = ""
for line in io.open(src, encoding="utf-8", errors="replace"):
    line = line.strip()
    if not line:
        continue
    try:
        ev = json.loads(line)
    except ValueError:
        continue
    if ev.get("type") == "result":
        text = ev.get("result") or ""
io.open(dst, "w", encoding="utf-8").write(text)
PY
  cp "$rundir/tests/test_decimate.py" "$SRC/runs/$tag.delivered.py" 2>/dev/null || true
  n=$((n + 1))
done
echo "DONE — $N runs of arm '$ARM' under $FXROOT/runs/"
