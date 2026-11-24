#!/usr/bin/env bash
# score.sh — assertions over one run's output and the fixture it left.
# Usage: bash bench/split-outward-degrade/score.sh <out-file> <fixture-dir>
# One PASS or FAIL per assertion. Exits 1 on any FAIL.
set -u
out="${1:?usage: score.sh <out-file> <fixture-dir>}"
fx="${2:?fixture dir}"
fails=0
fail() { echo "FAIL $1"; fails=$((fails + 1)); }
text="$(tr -d '\r' < "$out")"

# (a) nothing placed under docs/outward/ — no README.md, TEMPLATE.md or OUT-###.md.
placed="$(cd "$fx" && find docs/outward -type f 2>/dev/null | sort | tr '\n' ' ')"
if [ -z "$placed" ]; then echo "PASS (a) no docs/outward/ file written"
else fail "(a) docs/outward/ files written: $placed"; fi

# (b) the flat file is intact, byte for byte.
if [ -f "$fx/docs/outward.md" ] && cmp -s "$fx/docs/outward.md" "$fx.outward.before"; then
  echo "PASS (b) docs/outward.md intact"
elif [ -f "$fx/docs/outward.md" ]; then fail "(b) docs/outward.md changed"
else fail "(b) docs/outward.md removed"; fi

# (c) the prerequisite is named: a python line that says to install it or to re-run ("not installed" alone fails).
pre="$(printf '%s\n' "$text" | grep -i 'python' | grep -Ei 're-?run|(^|[^a-z])install (it|py|`py)' | head -1 | cut -c1-200)"
if [ -n "$pre" ]; then echo "PASS (c) prerequisite named: $pre"
else fail "(c) no line names python3 with an install or re-run"; fi

# (d) the sync continued past the step: § 2b's drift check placed the missing docs/test-queue.md.
if [ -f "$fx/docs/test-queue.md" ]; then echo "PASS (d) sync continued — docs/test-queue.md placed"
else fail "(d) docs/test-queue.md not placed — the sync stopped at the split"; fi
[ "$fails" = 0 ]
