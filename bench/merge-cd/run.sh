#!/usr/bin/env bash
# GAP-091 L6 — fire N cold headless merge runs of one arm on one model.
#
# Each rep gets a pristine copy of the fixture repo; `claude -p` runs cwd'd
# at that copy's root. The prompt mimics a skill invocation: the arm body,
# then `ARGUMENTS: feature/a feature/b`, then a one-line pre-confirmation
# (§4 otherwise waits for a reply a headless run cannot give). Nothing in the
# prompt mentions directories or cd.
#
#   tools  Bash, PowerShell, Read, Grep, Glob (both shells: a Windows
#          session has both, and a cd could land in either)
#   config CLAUDE_CONFIG_DIR = make-fixture.sh's cold dir
#
# Usage: bash run.sh <fixture-root> <arm> <model> [N]
#   arm    current | removed
#   model  e.g. claude-opus-5-5 | claude-sonnet-5
#
# Per rep: <fixture-root>/runs/<tag>.jsonl (transcript), and
#   bench/merge-cd/runs/<tag>.tools.tsv + .result.txt (extract.py)
set -u
FXROOT="${1:?usage: run.sh <fixture-root> <arm> <model> [N]}"
ARM="${2:?arm}"
MODEL="${3:?model}"
N="${4:-3}"
SRC="$(cd "$(dirname "$0")" && pwd)"
[ -d "$FXROOT/repo" ] || { echo "no fixture at $FXROOT/repo" >&2; exit 1; }
[ -f "$SRC/arm-$ARM.md" ] || { echo "no arm-$ARM.md — run make-arms.sh" >&2; exit 1; }

CFG="$FXROOT/coldcfg"
command -v cygpath >/dev/null 2>&1 && CFG="$(cygpath -m "$CFG")"
mkdir -p "$FXROOT/runs" "$SRC/runs"

n=1
while [ "$n" -le "$N" ]; do
  tag="$MODEL-$ARM-r$n"
  rundir="$FXROOT/runs/$tag"
  out="$FXROOT/runs/$tag.jsonl"
  if [ -s "$out" ]; then echo "[skip] $tag"; n=$((n + 1)); continue; fi
  rm -rf "$rundir"; cp -r "$FXROOT/repo" "$rundir"
  echo "[$tag]"
  {
    cat "$SRC/arm-$ARM.md"
    printf '\nARGUMENTS: feature/a feature/b\n\nI pre-confirm whatever strategy you recommend in step 4 - execute it without waiting for a reply.\n'
  } > "$FXROOT/runs/$tag.prompt.txt"
  (
    cd "$rundir" || exit 1
    CLAUDE_CONFIG_DIR="$CFG" claude \
      --model "$MODEL" \
      --tools "Bash,PowerShell,Read,Grep,Glob" \
      --no-session-persistence \
      --output-format stream-json --verbose \
      -p < "$FXROOT/runs/$tag.prompt.txt"
  ) > "$out" 2> "$out.err"
  echo "      exit=$? lines=$(wc -l < "$out")"
  PYTHONIOENCODING=utf-8 python3 "$SRC/extract.py" "$out" "$SRC/runs/$tag"
  n=$((n + 1))
done
