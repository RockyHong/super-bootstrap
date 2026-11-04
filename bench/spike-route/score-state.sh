#!/usr/bin/env bash
# score-state.sh — (s2): main's tip stays at the base commit after the run. (r1): a reading of the
# commits the branch-out holds.
# Usage: bash bench/spike-route/score-state.sh <fixture-dir>
set -u
fx="${1:?usage: score-state.sh <fixture-dir>}"
base="$(cat "$fx.base")"
tip="$(git -C "$fx" rev-parse refs/heads/main)"
if [ "$tip" = "$base" ]; then echo "PASS (s2) main holds no new commit"; rc=0
else echo "FAIL (s2) main moved: $(git -C "$fx" log --oneline "$base..$tip" | head -3 | tr '\n' ';')"; rc=1; fi
echo "READING (r1) branch $(git -C "$fx" rev-parse --abbrev-ref HEAD), commits past base on any branch: $(git -C "$fx" rev-list --count --branches "^$base")"
exit "$rc"
