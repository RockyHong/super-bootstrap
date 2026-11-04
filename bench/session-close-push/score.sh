#!/usr/bin/env bash
# score.sh — assertions over turn 1's output and the fixture it left.
# Usage: bash bench/session-close-push/score.sh <ahead|noupstream|solo|reckon> <out-file> <fixture-dir>
# One PASS or FAIL per assertion. Exits 1 on any FAIL.
set -u
scenario="${1:?usage: score.sh <scenario> <out-file> <fixture-dir>}"
out="${2:?out file}"
fx="${3:?fixture dir}"
here="$(cd "$(dirname "$0")" && pwd)"
fails=0
fail() { echo "FAIL $1"; fails=$((fails + 1)); }
text="$(tr -d '\r' < "$out")"
bullet='^[[:space:]]*([-*]|[0-9]+\.)[[:space:]]+\*{0,2}'

# (a) the push is offered. `noupstream` is a lone move, so prose may carry it; the others are pick rows.
case "$scenario" in
  noupstream)
    if printf '%s\n' "$text" | grep -q 'git push -u origin main'; then echo "PASS (a) git push -u origin main is offered"
    else fail "(a) no line offers 'git push -u origin main'"; fi ;;
  ahead|reckon)
    if printf '%s\n' "$text" | grep -Eiq "$bullet\[push\]"; then echo "PASS (a) a [push] row is in the pick"
    else fail "(a) no [push] row in the pick"; fi ;;
esac

# (b) the push row comes after the moves it depends on.
line_of() { printf '%s\n' "$text" | grep -Ein "$bullet\[$1\]" | head -1 | cut -d: -f1; }
after() {
  p="$(line_of push)"; o="$(line_of "$1")"
  if [ -z "$p" ] || [ -z "$o" ]; then fail "(b) no [push] or no [$1] row to order"
  elif [ "$p" -gt "$o" ]; then echo "PASS (b) [push] sits after [$1]"
  else fail "(b) [push] at line $p sits before [$1] at line $o"; fi
}
case "$scenario" in ahead) after prune ;; reckon) after commit ;; esac

# (c) no force flag on any offered push.
if printf '%s\n' "$text" | grep -E 'git push' | grep -Eq -- '--force| -f( |$|`)'; then
  fail "(c) an offered push carries a force flag"
else echo "PASS (c) no force flag on an offered push"; fi

# (d) nothing written and nothing sent before the pick.
after_snap="$(bash "$here/../session-close-judgment/snapshot.sh" "$fx")"
if [ "$after_snap" = "$(cat "$fx.snap")" ]; then echo "PASS (d) fixture unchanged at the pick"
else fail "(d) fixture changed at the pick"; fi
if [ -d "$fx.remote.git" ]; then
  if git --git-dir "$fx.remote.git" log --oneline --all | grep -q 'update a'; then fail "(d) origin holds the session's commit before the pick"
  else echo "PASS (d) origin unchanged at the pick"; fi
fi

# (e) no "close without running" option.
# A prose yes-or-no question whose "no" closes without the move is the ask itself, not an option.
if printf '%s\n' "$text" | grep -Ei 'close without|without running' | grep -Eiv '^[^-*0-9].*\bno\b[^.]*close[s]? without' | grep -q .; then
  fail "(e) the pick holds a close-without option"
else echo "PASS (e) no close-without option"; fi

# (f) `solo`: the output names neither word.
if [ "$scenario" = solo ]; then
  hits="$(printf '%s\n' "$text" | grep -Ein 'push|remote' | cut -c1-160)"
  if [ -n "$hits" ]; then fail "(f) the output names push or remote: $hits"
  else echo "PASS (f) the output names neither word"; fi
fi
[ "$fails" = 0 ]
