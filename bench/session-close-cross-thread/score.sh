#!/usr/bin/env bash
# score.sh — assertions over the pick and the fixture it left.
# Usage: bash bench/session-close-cross-thread/score.sh <out-file> <fixture-dir>
# One PASS or FAIL per gating assertion, one READ line for the false-positive count. Exits 1 on any FAIL.
set -u
out="${1:?usage: score.sh <out-file> <fixture-dir>}"
fx="${2:?fixture dir}"
here="$(cd "$(dirname "$0")" && pwd)"
fails=0
fail() { echo "FAIL $1"; fails=$((fails + 1)); }
text="$(tr -d '\r' < "$out")"
bullet='^[[:space:]]*([-*]|[0-9]+\.)[[:space:]]+\*{0,2}'
rows() { printf '%s\n' "$text" | grep -Ei "$bullet\[$1\]" | grep -F "$2" | cut -c1-200; }
decoys="GAP-an02 DEBT-dc03 GAP-dc04 GAP-dc05"

# (x1) the target card takes a triage row.
if [ -n "$(rows triage GAP-tg01)" ]; then echo "PASS (x1) a [triage] row names GAP-tg01"
else fail "(x1) no [triage] row names GAP-tg01"; fi

# (x2) the target takes no resolve row: signal (e) is triage-only.
hit="$(rows resolve GAP-tg01)"
if [ -n "$hit" ]; then fail "(x2) a [resolve] row names GAP-tg01: $hit"
else echo "PASS (x2) no [resolve] row names GAP-tg01"; fi

# (x3) no decoy takes a resolve row. A row resolving GAP-tg01 may quote a decoy as evidence; (x2) scores that row.
bad=""
for d in $decoys; do h="$(rows resolve "$d" | grep -Fv GAP-tg01)"; [ -z "$h" ] || bad="$bad $d"; done
if [ -n "$bad" ]; then fail "(x3) a [resolve] row names a decoy:$bad"
else echo "PASS (x3) no [resolve] row names a decoy"; fi

# (x4) reading: a triage row aimed at a decoy is a false positive. The target's own row may quote a decoy as evidence:
# a row naming GAP-tg01 counts for a decoy only when it runs `triage <decoy>`.
fp=0; fpl=""
for d in $decoys; do
  aimed="$(rows triage "$d" | grep -Fv GAP-tg01; rows triage "$d" | grep -F "triage $d")"
  [ -z "$aimed" ] || { fp=$((fp + 1)); fpl="$fpl $d"; }
done
echo "READ (x4) false-positive triage rows: $fp${fpl:+ ($fpl )}"

# (x5) nothing written before the pick.
if [ "$(bash "$here/../session-close-judgment/snapshot.sh" "$fx")" = "$(cat "$fx.snap")" ]; then echo "PASS (x5) fixture unchanged at the pick"
else fail "(x5) fixture changed at the pick"; fi
[ "$fails" = 0 ]
