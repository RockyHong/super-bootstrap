#!/usr/bin/env bash
# Mechanical assertions over one run's output file. Prints one PASS / FAIL line
# per expectation, naming the card and the line it looked for; exits 1 on any FAIL.
#   pick   <runs/pick-<tag>.result.txt>  GAP-12 on a run: row, GAP-13 on a skip: row naming harness
#   sort   <runs/sort-<tag>.result.txt>  GAP-13 on the needs you: line, GAP-12 on the runs without you: line
#   worker <runs/<tag>.state.txt>        status is `DONE — harness pending`, no WALL status
#                                        (the incidental-harness worker does not stop on the wall)
# Leading spaces, backticks, `*` and `-` are stripped before matching, so a fenced
# or bulleted block reads the same as a bare one.
#
# Usage: bash check.sh <pick|sort|worker> <file>
set -u
MODE="${1:?usage: check.sh <pick|sort|worker> <file>}"
F="${2:?file}"
[ -f "$F" ] || { echo "FAIL $MODE: no file $F"; exit 1; }
T="$(sed -e 's/^[[:space:]`*-]*//' -e 's/\*\*//g' "$F")"
rc=0
has()  { if printf '%s\n' "$T" | grep -Eiq "$2"; then echo "PASS $1"; else echo "FAIL $1"; rc=1; fi; }
hasnt(){ if printf '%s\n' "$T" | grep -Eiq "$2"; then echo "FAIL $1"; rc=1; else echo "PASS $1"; fi; }
case "$MODE" in
  pick)
    has   "pick: GAP-12 on a run: row"             '^run:[[:space:]]+GAP-12'
    hasnt "pick: GAP-12 not on a skip: row"        '^skip:[[:space:]]+GAP-12'
    has   "pick: GAP-13 on a skip: row (harness)"  '^skip:[[:space:]]+GAP-13.*harness'
    hasnt "pick: GAP-13 not on a run: row"         '^run:[[:space:]]+GAP-13' ;;
  sort)
    has   "sort: GAP-13 on the needs you: line"          '^needs you:[[:space:]]+GAP-13'
    hasnt "sort: GAP-13 not on the runs without you: line" '^runs without you:[[:space:]]+GAP-13'
    has   "sort: GAP-12 on the runs without you: line"   '^runs without you:[[:space:]]+GAP-12'
    hasnt "sort: GAP-12 not on the needs you: line"      '^needs you:[[:space:]]+GAP-12' ;;
  worker)
    has   "worker: status DONE — harness pending" '^status:[[:space:]]+DONE — harness pending[[:space:]]*$'
    hasnt "worker: no WALL status"                '^status:[[:space:]]+WALL' ;;
  *) echo "unknown mode $MODE"; exit 2 ;;
esac
exit $rc
