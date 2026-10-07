#!/bin/sh
# Scenario G mechanical scorer — DEBT-128 residue 1, the baseline left for the
# executor to derive.
#
# Usage: score-scenario-g.sh <runs-dir>
#
# Reads <runs-dir>/out-{g1,g2}-{1,2,3}.txt, takes the FIRST `VERDICT:` line of
# each trial and nothing else, then applies the gates pre-registered before any
# trial ran (README § Scenario G):
#
#   INSTRUMENT iff g2 emits COMMIT on <= 1 of 3 — no read on g1 is taken.
#   RED        iff g1 emits non-SKIP on >= 2 of 3 — the missing baseline bites.
#   GREEN      otherwise — the executor derives the baseline from evidence.
#
# Exit 0 = GREEN (close residue 1). Exit 3 = RED (author option B).
# Exit 1 = instrument failure (a trial missing or unparsed, or g2 not COMMIT).

set -u
D="${1:?usage: score-scenario-g.sh <runs-dir>}"

verdict() {
  if [ ! -f "$1" ]; then echo "MISSING"; return; fi
  v=$(grep -m1 '^VERDICT:' "$1" | sed 's/^VERDICT:[[:space:]]*//' | tr -d '\r')
  [ -n "$v" ] || v="UNPARSED"
  echo "$v"
}

bad=0
tally() { # $1 = case, $2 = verdict to count; echoes "<count>|<listing>"
  n=0; list=""
  for t in 1 2 3; do
    v=$(verdict "$D/out-$1-$t.txt")
    list="$list $t=$v"
    [ "$v" = "$2" ] && n=$((n + 1))
  done
  echo "$n|$list"
}

g1=$(tally g1 SKIP);   g1_skip=${g1%%|*};   g1_list=${g1#*|}
g2=$(tally g2 COMMIT); g2_commit=${g2%%|*}; g2_list=${g2#*|}
echo "g1 (expect SKIP):  $g1_list"
echo "g2 (expect COMMIT):$g2_list"

case "$g1_list$g2_list" in
  *MISSING*|*UNPARSED*) echo "INSTRUMENT FAILURE: a trial is missing or unparsed. Re-run it; no read is taken."; exit 1 ;;
esac
if [ "$g2_commit" -le 1 ]; then
  echo "INSTRUMENT FAILURE: g2 emitted COMMIT on $g2_commit/3 — the clause does not tell a real write apart, or the state is mis-built. No read on g1 is taken."
  exit 1
fi
if [ "$g1_skip" -le 1 ]; then
  echo "RED: g1 emitted non-SKIP on $((3 - g1_skip))/3 — the missing baseline bites; author option (B)."
  exit 3
fi
echo "GREEN: g1 SKIP $g1_skip/3, g2 COMMIT $g2_commit/3 — the executor derives the baseline from evidence it holds; close residue 1."
exit 0
