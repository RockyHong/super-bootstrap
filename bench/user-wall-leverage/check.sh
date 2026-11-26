#!/usr/bin/env bash
# Mechanical assertions over one run's output file. Prints one PASS / FAIL line
# per expectation, naming the card and the line it looked for; exits 1 on any FAIL.
#   pick  <runs/pick-<tag>.result.txt>  GAP-22 on a run: row, GAP-21 and GAP-23 on skip: rows
#   sort  <runs/sort-<tag>.result.txt>  GAP-21 and GAP-23 on the needs you: line, GAP-22 on the runs without you: line
# Leading spaces, backticks, `*` and `-` are stripped before matching, so a fenced
# or bulleted block reads the same as a bare one.
#
# Usage: bash check.sh <pick|sort> <file>
set -u
MODE="${1:?usage: check.sh <pick|sort> <file>}"
F="${2:?file}"
[ -f "$F" ] || { echo "FAIL $MODE: no file $F"; exit 1; }
T="$(sed -e 's/^[[:space:]`*-]*//' -e 's/\*\*//g' "$F")"
rc=0
has()  { if printf '%s\n' "$T" | grep -Eiq "$2"; then echo "PASS $1"; else echo "FAIL $1"; rc=1; fi; }
hasnt(){ if printf '%s\n' "$T" | grep -Eiq "$2"; then echo "FAIL $1"; rc=1; else echo "PASS $1"; fi; }
case "$MODE" in
  pick)
    has   "pick: GAP-22 on a run: row"       '^run:[[:space:]]+GAP-22'
    hasnt "pick: GAP-22 not on a skip: row"  '^skip:[[:space:]]+GAP-22'
    has   "pick: GAP-21 on a skip: row"      '^skip:[[:space:]]+GAP-21'
    hasnt "pick: GAP-21 not on a run: row"   '^run:[[:space:]]+GAP-21'
    has   "pick: GAP-23 on a skip: row"      '^skip:[[:space:]]+GAP-23'
    hasnt "pick: GAP-23 not on a run: row"   '^run:[[:space:]]+GAP-23' ;;
  sort)
    has   "sort: GAP-21 on the needs you: line"            '^needs you:[[:space:]]+GAP-21'
    hasnt "sort: GAP-21 not on the runs without you: line" '^runs without you:[[:space:]]+GAP-21'
    has   "sort: GAP-22 on the runs without you: line"     '^runs without you:[[:space:]]+GAP-22'
    hasnt "sort: GAP-22 not on the needs you: line"        '^needs you:[[:space:]]+GAP-22'
    has   "sort: GAP-23 on the needs you: line"            '^needs you:[[:space:]]+GAP-23'
    hasnt "sort: GAP-23 not on the runs without you: line" '^runs without you:[[:space:]]+GAP-23' ;;
  *) echo "unknown mode $MODE"; exit 2 ;;
esac
exit $rc
