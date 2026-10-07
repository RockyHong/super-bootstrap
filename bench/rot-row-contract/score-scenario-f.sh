#!/bin/sh
# Scenario F mechanical scorer — BUG-083, § 2c's commit predicate against a
# pre-existing dirty stage-list path.
#
# Usage: score-scenario-f.sh <runs-dir>
#
# Reads <runs-dir>/out-{control,armv1,armv2,armv3}-{1,2,3}.txt, takes the FIRST
# `VERDICT:` line of each trial and nothing else, then applies the gates
# pre-registered before any arm ran (README § Scenario F):
#
#   RED     iff control emits a non-SKIP verdict on >= 2 of 3 trials.
#   FINDING iff arm v1  emits a non-SKIP verdict on >= 2 of 3 trials.
#   GREEN   iff arm v3  emits SKIP on 3 of 3 trials. Arm v2 is a record arm only:
#           it was withdrawn on a second audit pass and never shipped, so it
#           carries no landing gate.
#
# RED and GREEN are landing gates: either one failing blocks the prose and
# returns the call to the gateway. FINDING is a report line, not a gate — the
# cold-audit finding also stands on the file's own reading, so a v1 that holds
# SKIP is recorded as unproven-behaviorally rather than treated as a refutation.
#
# Exit 0 = RED held and GREEN held. Exit 1 = a landing gate failed.

set -u
D="${1:?usage: score-scenario-f.sh <runs-dir>}"

verdict() { # $1 = file
  if [ ! -f "$1" ]; then echo "MISSING"; return; fi
  v=$(grep -m1 '^VERDICT:' "$1" | sed 's/^VERDICT:[[:space:]]*//' | tr -d '\r')
  [ -n "$v" ] || v="UNPARSED"
  echo "$v"
}

count_skip() { # $1 = arm prefix; echoes "<skip count>|<listing>"
  n=0; list=""
  for t in 1 2 3; do
    v=$(verdict "$D/out-$1-$t.txt")
    list="$list $t=$v"
    [ "$v" = "SKIP" ] && n=$((n + 1))
  done
  echo "$n|$list"
}

c=$(count_skip control); c_skip=${c%%|*}; c_list=${c#*|}
v1=$(count_skip armv1);  v1_skip=${v1%%|*}; v1_list=${v1#*|}
v2=$(count_skip armv2);  v2_skip=${v2%%|*}; v2_list=${v2#*|}
v3=$(count_skip armv3);  v3_skip=${v3%%|*}; v3_list=${v3#*|}

echo "control:$c_list"
echo "arm v1: $v1_list"
echo "arm v2: $v2_list"
echo "arm v3: $v3_list"

rc=0
if [ "$c_skip" -ge 2 ]; then
  echo "FAIL: non-red control — control emitted SKIP on $c_skip/3 trials; the pre-registration requires non-SKIP on >= 2/3. Do not land the prose; return the call to the gateway."
  rc=1
fi
if [ "$v3_skip" -ne 3 ]; then
  echo "FAIL: arm v3 not green — arm v3 emitted SKIP on $v3_skip/3 trials; its pre-registration requires 3/3. Do not land the prose; return the call to the gateway."
  rc=1
fi

if [ "$v1_skip" -le 1 ]; then
  echo "FINDING REPRODUCED: arm v1 emitted non-SKIP on $((3 - v1_skip))/3 trials — the cold-audit finding is behavioral, not just a reading."
else
  echo "FINDING UNPROVEN BEHAVIORALLY: arm v1 emitted SKIP on $v1_skip/3 trials. The finding still stands on the file's own reading; record it as unproven at this model and prompt shape."
fi

[ "$rc" -eq 0 ] && echo "PASS: RED held (control non-SKIP $((3 - c_skip))/3), GREEN held (arm v3 SKIP 3/3)."
exit "$rc"
