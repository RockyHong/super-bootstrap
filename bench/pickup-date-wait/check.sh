#!/usr/bin/env bash
# Mechanical assertions over one run.sh result. One PASS / FAIL line per
# expectation; exit 1 on any FAIL. Leading spaces, backticks, `*`, `-`, list
# numbers and `**` are stripped before matching.
#   needs-me:
#     GAP-31 line names "not yet due" (or "not due") and 2026-12-10, and is not sorted to "runs without you"
#     GAP-32 line reads "runs without you" and not "not (yet) due"
#     GAP-33 line reads "runs without you"
#     a carry line reads 3 carries with 1 stale
#   autorun:
#     GAP-31 on a skip: line, not on a run: line
#     GAP-32 and GAP-33 on run: lines
#
# Usage: bash check.sh <runs/<skill>-<tag>.result.txt> needs-me|autorun
set -u
F="${1:?usage: check.sh <file> needs-me|autorun}"
SK="${2:?skill}"
[ -f "$F" ] || { echo "FAIL: no file $F"; exit 1; }
T="$(sed -E -e 's/^[[:space:]*-]*([0-9]+\.[[:space:]]+)?//' -e 's/\*\*//g' -e 's/`//g' "$F")"
rc=0
line() { printf '%s\n' "$T" | grep -E "^$1([^0-9]|$)" | head -1; }
ok()  { echo "PASS $1"; }
bad() { echo "FAIL $1"; rc=1; }
if [ "$SK" = needs-me ]; then
  L31="$(line GAP-31)"; L32="$(line GAP-32)"; L33="$(line GAP-33)"
  if printf '%s' "$L31" | grep -Eiq 'not (yet )?due' && printf '%s' "$L31" | grep -q '2026-12-10'; then
    ok "GAP-31 not yet due with 2026-12-10"; else bad "GAP-31 not yet due with 2026-12-10 :: $L31"; fi
  if printf '%s' "$L31" | grep -Eiq '^GAP-31[^a-z]*(counted in )?"?(items )?runs? without you'; then
    bad "GAP-31 not runs without you :: $L31"; else ok "GAP-31 not runs without you"; fi
  if printf '%s' "$L32" | grep -Eiq 'runs? without you' && ! printf '%s' "$L32" | grep -Eiq 'not (yet )?due'; then
    ok "GAP-32 (past date) reads normal: runs without you"; else bad "GAP-32 (past date) reads normal: runs without you :: $L32"; fi
  if printf '%s' "$L33" | grep -Eiq 'runs? without you'; then
    ok "GAP-33 runs without you"; else bad "GAP-33 runs without you :: $L33"; fi
  if printf '%s\n' "$T" | grep -Eiq '3 carr[a-z]* *\(1 stale\)|3 carr[a-z]*[^0-9]+1 (is )?stale'; then
    ok "carry line 3 carries (1 stale)"; else bad "carry line 3 carries (1 stale) :: $(printf '%s\n' "$T" | grep -i carr | head -1)"; fi
else
  if printf '%s\n' "$T" | grep -Eiq '^skip:[[:space:]]+GAP-31'; then ok "GAP-31 on skip:"; else bad "GAP-31 on skip:"; fi
  if printf '%s\n' "$T" | grep -Eiq '^run:[[:space:]]+.*GAP-31'; then bad "GAP-31 not on run:"; else ok "GAP-31 not on run:"; fi
  if printf '%s\n' "$T" | grep -Eiq '^run:[[:space:]]+.*GAP-32'; then ok "GAP-32 (past date) on run:"; else bad "GAP-32 (past date) on run:"; fi
  if printf '%s\n' "$T" | grep -Eiq '^run:[[:space:]]+.*GAP-33'; then ok "GAP-33 on run:"; else bad "GAP-33 on run:"; fi
fi
exit $rc
