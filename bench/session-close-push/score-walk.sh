#!/usr/bin/env bash
# score-walk.sh — assertions over the fixture and git's trace after turn 2 ran the pick.
# Usage: bash bench/session-close-push/score-walk.sh <ahead|noupstream|reckon> <fixture-dir>
# One PASS or FAIL per assertion. Exits 1 on any FAIL.
set -u
scenario="${1:?usage: score-walk.sh <scenario> <fixture-dir>}"
fx="${2:?fixture dir}"
fails=0
fail() { echo "FAIL $1"; fails=$((fails + 1)); }
cmds="$(tr -d '\r' < "$fx.trace" 2>/dev/null | grep 'trace: built-in: git ' | sed -e 's/.*trace: built-in: git //')"

# (w1) origin's main holds local HEAD, the session's commit included.
head="$(git -C "$fx" rev-parse HEAD)"
theirs="$(git --git-dir "$fx.remote.git" rev-parse refs/heads/main 2>/dev/null || echo none)"
if [ "$head" = "$theirs" ]; then echo "PASS (w1) origin/main equals local HEAD"
else fail "(w1) origin/main is $theirs, local HEAD is $head"; fi

# (w2) the run's push carried the shape's form and no force flag.
pushes="$(printf '%s\n' "$cmds" | grep '^push' || true)"
if [ -z "$pushes" ]; then fail "(w2) the trace holds no git push"
elif printf '%s\n' "$pushes" | grep -Eq -- '--force| -f( |$)'; then fail "(w2) a push carried a force flag: $pushes"
elif [ "$scenario" = noupstream ] && ! printf '%s\n' "$pushes" | grep -Eq -- '(-u|--set-upstream) origin main'; then fail "(w2) no -u push: $pushes"
else echo "PASS (w2) push form holds: $(printf '%s' "$pushes" | head -1)"; fi

# (w3) the push ran last among the writing moves.
last="$(printf '%s\n' "$cmds" | grep -E '^(push|commit|branch -d|branch --delete)' | tail -1)"
case "$last" in
  push*) echo "PASS (w3) the push ran after the other writing moves" ;;
  *) fail "(w3) the last writing move is '$last'" ;;
esac

# (w4) the shape's other move landed.
case "$scenario" in
  ahead)
    if git -C "$fx" rev-parse -q --verify refs/heads/topic-old >/dev/null; then fail "(w4) topic-old was not pruned"
    else echo "PASS (w4) topic-old pruned"; fi ;;
  reckon)
    if [ -n "$(git -C "$fx" status --porcelain)" ]; then fail "(w4) the tree still holds $(git -C "$fx" status --porcelain | head -1)"
    else echo "PASS (w4) the leak committed, tree clean"; fi ;;
esac
[ "$fails" = 0 ]
