#!/usr/bin/env bash
# Mechanical assertions over one sort-run.sh output file. Prints one PASS / FAIL
# line per expectation, naming the card and the line it looked for; exits 1 on any FAIL.
#   GAP-21 (Design body `waiting on`, later Progress)  on the needs you: line
#   GAP-22 (Design with no approval line)              on the needs you: line
#   GAP-23 (plain runnable)                            on the runs without you: line
# Leading spaces, backticks, `*` and `-` are stripped before matching, so a fenced
# or bulleted block reads the same as a bare one.
#
# Usage: bash check.sh <runs/sort-<tag>.result.txt>
set -u
F="${1:?usage: check.sh <file>}"
[ -f "$F" ] || { echo "FAIL: no file $F"; exit 1; }
T="$(sed -e 's/^[[:space:]`*-]*//' -e 's/\*\*//g' "$F")"
rc=0
has()  { if printf '%s\n' "$T" | grep -Eiq "$2"; then echo "PASS $1"; else echo "FAIL $1"; rc=1; fi; }
hasnt(){ if printf '%s\n' "$T" | grep -Eiq "$2"; then echo "FAIL $1"; rc=1; else echo "PASS $1"; fi; }
has   "GAP-21 on the needs you: line"               '^needs you:[[:space:]]+GAP-21'
hasnt "GAP-21 not on the runs without you: line"    '^runs without you:[[:space:]]+GAP-21'
has   "GAP-22 on the needs you: line"               '^needs you:[[:space:]]+GAP-22'
hasnt "GAP-22 not on the runs without you: line"    '^runs without you:[[:space:]]+GAP-22'
has   "GAP-23 on the runs without you: line"        '^runs without you:[[:space:]]+GAP-23'
hasnt "GAP-23 not on the needs you: line"           '^needs you:[[:space:]]+GAP-23'
exit $rc
