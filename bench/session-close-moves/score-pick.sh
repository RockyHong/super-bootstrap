#!/usr/bin/env bash
# score-pick.sh — assertions over turn 1's pick and the fixture it left.
# Usage: bash bench/session-close-moves/score-pick.sh <full|resolve|fixnow> <out-file> <fixture-dir>
# One PASS or FAIL per gating assertion, PASS or MISS for the recall reading (p3). Exits 1 on any FAIL.
set -u
scenario="${1:?usage: score-pick.sh <scenario> <out-file> <fixture-dir>}"
out="${2:?out file}"
fx="${3:?fixture dir}"
here="$(cd "$(dirname "$0")" && pwd)"
fails=0
fail() { echo "FAIL $1"; fails=$((fails + 1)); }

# One line per pick row: name<TAB>row text. A row runs from its `[name]` bullet to the next row,
# or to the first unindented non-bullet line.
all_rows="$(tr -d '\r' < "$out" | awk '
  function flush() { if (name != "") print name "\t" text; name = ""; text = "" }
  {
    line = $0; probe = line
    sub(/^[ \t]*([-*]|[0-9]+\.)[ \t]+/, "", probe)
    if (probe != line) { gsub(/^\*+/, "", probe) }
    if (probe != line && probe ~ /^\[[^]]+\]/) {
      flush()
      name = probe; sub(/^\[/, "", name); sub(/\].*/, "", name)
      text = probe
      next
    }
    if (name != "" && (line ~ /^[ \t]/ || line == "")) { text = text " " line; next }
    flush()
  }
  END { flush() }')"
named() { printf '%s\n' "$all_rows" | awk -F'\t' -v k="$1" 'tolower($1) ~ k'; }
names="$(printf '%s\n' "$all_rows" | cut -f1 | tr '\n' ' ')"

# (p1) the close holds a commit move.
if [ -n "$(named '^commit')" ]; then echo "PASS (p1) a commit move is in the pick"
else fail "(p1) no [commit] row. Rows: $names"; fi

# (p2) a resolve row carries the outcome: the edit drafted into a state doc, or the doc that states it.
if [ "$scenario" != fixnow ]; then
  rt="$(named '^resolve' | grep 'BUG-rt51' | cut -f2)"
  sd="$(named '^resolve' | grep 'BUG-sd22' | cut -f2)"
  if [ -z "$rt" ]; then fail "(p2) no [resolve] row for BUG-rt51. Rows: $names"
  elif printf '%s\n' "$rt" | sed -e 's#docs/work/[^ ]*##g' | grep -Eq '(recovery|console|operations)\.md' && printf '%s\n' "$rt" | grep -q 'E7'; then
    echo "PASS (p2) the BUG-rt51 row carries its drafted outcome edit"
  else fail "(p2) the BUG-rt51 row carries no drafted edit: $(printf '%s' "$rt" | cut -c1-200)"; fi
  if [ -z "$sd" ]; then fail "(p2) no [resolve] row for BUG-sd22. Rows: $names"
  elif printf '%s\n' "$sd" | grep -q 'operations\.md'; then echo "PASS (p2) the BUG-sd22 row names the doc stating its outcome"
  else fail "(p2) the BUG-sd22 row names no doc: $(printf '%s' "$sd" | cut -c1-200)"; fi
  # A row's subject is its name plus its first sentence; a later sentence may name the card it leaves open.
  if named '^resolve' | sed -e 's/\. .*$//' | grep -q 'GAP-ff03'; then fail "(p2) GAP-ff03 is in motion and took a resolve row"; fi
fi

# (p3) the door's judgment reached the draft: a citer the draft makes stale carries a row. Recall reading.
stale_row() { printf '%s\n' "$all_rows" | grep -Eiv '^(commit|close)' | grep -E "$1" | grep -Eqi "$2"; }
if [ "$scenario" != fixnow ]; then
  if stale_row 'console\.md' '.'; then echo "PASS (p3) docs/console.md's stale line has a row"
  else echo "MISS (p3) no row carries docs/console.md's stale line. Rows: $names"; fi
fi
if [ "$scenario" != resolve ]; then
  if stale_row 'README' 'monthly|seal inspection|including'; then echo "PASS (p3) README.md's stale line has a row"
  else echo "MISS (p3) no row carries README.md's stale line. Rows: $names"; fi
fi

# (p4) the bounded finding is a fix-now row.
if [ "$scenario" != resolve ]; then
  if named '^fix-now' | grep 'maintenance\.md' | grep -q '14'; then echo "PASS (p4) the seal finding is a fix-now row"
  else fail "(p4) no [fix-now] row names docs/maintenance.md with 14. Rows: $names"; fi
fi

# (p5) the commit rows keep this session's work apart from the seal fix and the card's outcome.
if [ "$scenario" = full ]; then
  both="$(named '^commit' | grep 'shutdown\.md' | grep -E 'maintenance\.md|recovery\.md' | cut -f2 | cut -c1-200)"
  if [ -n "$(named '^commit' | grep 'shutdown\.md')" ] && [ -z "$both" ] && [ -n "$(named '^commit' | grep 'maintenance\.md')" ]; then
    echo "PASS (p5) the commit rows partition the list"
  else fail "(p5) the commit rows do not partition the list: ${both:-$(named '^commit' | cut -f2 | cut -c1-200)}"; fi
fi

# (p6) nothing written before the pick, shared index included.
after="$(bash "$here/../session-close-judgment/snapshot.sh" "$fx")"
if [ "$after" = "$(cat "$fx.snap")" ]; then echo "PASS (p6) fixture unchanged at the pick"
else fail "(p6) fixture changed: $(diff <(cat "$fx.snap") <(printf '%s\n' "$after") | grep '^>' | tr '\n' ' ')"; fi
[ "$fails" = 0 ]
