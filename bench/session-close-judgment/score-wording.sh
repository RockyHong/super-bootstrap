#!/usr/bin/env bash
# score-wording.sh — the pass condition over one wording's three runs: (a)-(d) on 3 of 3, (e) on
# 2 of 3.
# Usage: bash bench/session-close-judgment/score-wording.sh <out1> <fx1> <out2> <fx2> <out3> <fx3>
set -u
[ "$#" -eq 6 ] || { echo "usage: score-wording.sh <out1> <fx1> <out2> <fx2> <out3> <fx3>" >&2; exit 2; }
here="$(cd "$(dirname "$0")" && pwd)"
gate=0
stale=0
recall=0
while [ "$#" -gt 0 ]; do
  reading="$(bash "$here/score.sh" "$1" "$2")" || gate=$((gate + 1))
  printf '%s\n--\n' "$reading"
  case "$reading" in *"PASS (e)"*) stale=$((stale + 1)) ;; esac
  case "$reading" in *"register recall: hit"*) recall=$((recall + 1)) ;; esac
  shift 2
done
echo "INFO (a) register recall: $recall of 3"
[ "$gate" = 0 ] || echo "FAIL (a)-(d) in $gate of 3 runs"
[ "$stale" -ge 2 ] || echo "FAIL (e) stale row in $stale of 3 runs, 2 needed"
if [ "$gate" = 0 ] && [ "$stale" -ge 2 ]; then
  echo "PASS wording: (a)-(d) 3 of 3, (e) $stale of 3"
else
  exit 1
fi
