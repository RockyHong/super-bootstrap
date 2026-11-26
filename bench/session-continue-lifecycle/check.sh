#!/usr/bin/env bash
# check.sh — grade one session-continue lifecycle run.
# Usage: bash bench/session-continue-lifecycle/check.sh <fixture-dir> <out-file>
#
# Prints one PASS/FAIL line per assertion, with the output line that decided it:
#   A1 held    — a line names GAP-wt01 as held with its future date; no option line offers resume of it
#   A2b/c/d    — a line offers retire for BUG-x9z1, GAP-dn02, and the older GAP-dup3 carry (dddd4444)
#   A3 resume  — a line offers resume of GAP-lv05
#   A4 ledger  — all six carries still on disk, names unchanged (nothing claimed, nothing deleted)
set -u
fx="${1:?fixture dir}"
out="${2:?out file}"
fut="$(cat "$fx/.git/bench-future" 2>/dev/null || echo NO-DATE)"
say() { if [ -n "$3" ]; then echo "PASS $1 | $3"; else echo "FAIL $1 | $2"; fi; }

l="$(grep -i -E 'wt01' "$out" | grep -F "$fut" | grep -i -m1 -E 'held')"
# an option line (list item) offering resume of wt01; a free-text hint ("you can also type …") is the
# skill's own named-label path, not an option
bad="$(grep -E '^[[:space:]]*([-*]|[0-9]+\.)[[:space:]]' "$out" | grep -i -E 'resume' | grep -i -E 'wt01' | grep -i -v -E 'held|not before|until|wait' | head -1)"
if [ -n "$l" ] && [ -z "$bad" ]; then echo "PASS A1 held | $l"
elif [ -n "$bad" ]; then echo "FAIL A1 held | resume offered: $bad"
else echo "FAIL A1 held | no line names GAP-wt01 held with $fut: $(grep -i -m1 wt01 "$out")"; fi

say "A2b retire gone-card" "no retire line for BUG-x9z1: $(grep -i -m1 x9z1 "$out")" \
  "$(grep -i -E 'retire' "$out" | grep -i -m1 -E 'x9z1')"
say "A2c retire passed" "no retire line for GAP-dn02: $(grep -i -m1 dn02 "$out")" \
  "$(grep -i -E 'retire' "$out" | grep -i -m1 -E 'dn02|cccc3333')"
say "A2d retire older dup" "no retire line for GAP-dup3 older: $(grep -i -m1 -E 'dddd4444|dup3' "$out")" \
  "$(grep -i -E 'retire' "$out" | grep -i -E 'dddd4444|dup3.*(older|12 ?d)' | head -1)"
say "A3 resume live" "no resume line for GAP-lv05: $(grep -i -m1 lv05 "$out")" \
  "$(grep -i -E 'resume' "$out" | grep -i -m1 -E 'lv05')"

want="BUG-x9z1-bbbb2222.md GAP-dn02-cccc3333.md GAP-dup3-dddd4444.md GAP-dup3-eeee5555.md GAP-lv05-ffff6666.md GAP-wt01-aaaa1111.md"
have="$(ls "$fx/SESSION-STATE" 2>/dev/null | sort | tr '\n' ' ' | sed 's/ $//')"
if [ "$have" = "$want" ]; then echo "PASS A4 ledger | $have"; else echo "FAIL A4 ledger | $have"; fi
