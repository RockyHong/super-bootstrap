#!/bin/sh
# code-presence-scope mechanical scorer — DEBT-127, § Code presence's scan surface.
#
# Usage: score.sh <runs-dir>
#
# Reads <runs-dir>/out-{1,2,3}.txt, takes the FIRST `VERDICT:` line of each trial
# and nothing else, then applies the gate pre-registered before any arm ran
# (README § Protocol): red on ANY trial answering `code present`.
#
# Both reads are results, not failures — they pick a branch:
#   exit 0 = RED   (>= 1 trial `code present`): the clause is earned; author it.
#   exit 2 = GREEN (3 of 3 `docs-only`):        the clause is unearned; close it.
#   exit 1 = instrument failure (a trial missing, unparsed, or off-vocabulary):
#            re-run that trial, never score around it.

set -u
D="${1:?usage: score.sh <runs-dir>}"

red=0; bad=0; list=""
for t in 1 2 3; do
  f="$D/out-$t.txt"
  if [ ! -f "$f" ]; then v="MISSING"
  else
    v=$(grep -m1 '^VERDICT:' "$f" | sed 's/^VERDICT:[[:space:]]*//' | tr -d '\r')
    [ -n "$v" ] || v="UNPARSED"
  fi
  list="$list $t=$v"
  case "$v" in
    "code present") red=$((red + 1)) ;;
    "docs-only") ;;
    *) bad=$((bad + 1)) ;;
  esac
done

echo "trials:$list"
if [ "$bad" -gt 0 ]; then
  echo "INSTRUMENT FAILURE: $bad trial(s) missing, unparsed, or off-vocabulary. Re-run them; no read is taken."
  exit 1
fi
if [ "$red" -ge 1 ]; then
  echo "RED: $red/3 trials read the docs-only repo as code present — the scan-surface clause is earned."
  exit 0
fi
echo "GREEN: 3/3 trials read the repo as docs-only — the clause is unearned at this model and prompt shape."
exit 2
