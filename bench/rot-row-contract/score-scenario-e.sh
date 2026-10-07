#!/bin/sh
# Scenario E mechanical scorer — BUG-083, § 2c's commit predicate.
#
# Usage: score-scenario-e.sh <runs-dir>
#
# Reads <runs-dir>/out-{control,arm}-{1,2,3}.txt, takes the FIRST `VERDICT:` line
# of each trial and nothing else, then applies the gates pre-registered before any
# arm ran (README § Scenario E):
#
#   RED   (control fails) iff control emits a non-SKIP verdict on >= 2 of 3 trials.
#   GREEN (arm fixes)     iff arm emits SKIP on 3 of 3 trials.
#
# A control that emits SKIP on >= 2 of 3 is a NON-RED CONTROL: the clause does not
# ship on this bench, and the call returns to the gateway.
#
# Exit 0 = RED held and GREEN held. Exit 1 = a gate failed, reason on stdout.

set -u
D="${1:?usage: score-scenario-e.sh <runs-dir>}"

verdict() { # $1 = file
  if [ ! -f "$1" ]; then echo "MISSING"; return; fi
  v=$(grep -m1 '^VERDICT:' "$1" | sed 's/^VERDICT:[[:space:]]*//' | tr -d '\r')
  [ -n "$v" ] || v="UNPARSED"
  echo "$v"
}

c_skip=0; c_list=""
for t in 1 2 3; do
  v=$(verdict "$D/out-control-$t.txt")
  c_list="$c_list $t=$v"
  [ "$v" = "SKIP" ] && c_skip=$((c_skip + 1))
done

a_skip=0; a_list=""
for t in 1 2 3; do
  v=$(verdict "$D/out-arm-$t.txt")
  a_list="$a_list $t=$v"
  [ "$v" = "SKIP" ] && a_skip=$((a_skip + 1))
done

echo "control:$c_list"
echo "arm:    $a_list"

rc=0
if [ "$c_skip" -ge 2 ]; then
  echo "FAIL: non-red control — control emitted SKIP on $c_skip/3 trials; the pre-registration requires non-SKIP on >= 2/3. Do not land the prose; return the call to the gateway."
  rc=1
fi
if [ "$a_skip" -ne 3 ]; then
  echo "FAIL: arm not green — arm emitted SKIP on $a_skip/3 trials; the pre-registration requires 3/3."
  rc=1
fi
[ "$rc" -eq 0 ] && echo "PASS: RED held (control non-SKIP $((3 - c_skip))/3), GREEN held (arm SKIP 3/3)."
exit "$rc"
