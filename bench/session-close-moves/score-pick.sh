#!/usr/bin/env bash
# score-pick.sh — assertions over turn 1's pick and the fixture it left.
# Usage: bash bench/session-close-moves/score-pick.sh <full|resolve|fixnow|leak|single|large> <out-file> <fixture-dir>
# One PASS or FAIL per gating assertion, PASS or MISS for the recall reading (p3), READING for a
# non-gating count. Exits 1 on any FAIL.
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

# (p1) the close holds a commit move. `single` may ask it in prose, so (p11) reads that scenario.
if [ "$scenario" != single ]; then
  if [ -n "$(named '^commit')" ]; then echo "PASS (p1) a commit move is in the pick"
  else fail "(p1) no [commit] row. Rows: $names"; fi
fi

# (p2) a resolve row carries the outcome: the edit drafted into a state doc, or the doc that states it.
if [ "$scenario" = resolve ] || [ "$scenario" = full ]; then
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
if [ "$scenario" = resolve ] || [ "$scenario" = full ]; then
  if stale_row 'console\.md' '.'; then echo "PASS (p3) docs/console.md's stale line has a row"
  else echo "MISS (p3) no row carries docs/console.md's stale line. Rows: $names"; fi
fi
if [ "$scenario" = fixnow ] || [ "$scenario" = full ]; then
  if stale_row 'README' 'monthly|seal inspection|including'; then echo "PASS (p3) README.md's stale line has a row"
  else echo "MISS (p3) no row carries README.md's stale line. Rows: $names"; fi
fi

# (p4) the bounded finding is a fix-now row.
if [ "$scenario" = fixnow ] || [ "$scenario" = full ]; then
  if named '^fix-now' | grep 'maintenance\.md' | grep -q '14'; then echo "PASS (p4) the seal finding is a fix-now row"
  else fail "(p4) no [fix-now] row names docs/maintenance.md with 14. Rows: $names"; fi
fi

# (p6) nothing written before the pick, shared index included.
after="$(bash "$here/../session-close-judgment/snapshot.sh" "$fx")"
if [ "$after" = "$(cat "$fx.snap")" ]; then echo "PASS (p6) fixture unchanged at the pick"
else fail "(p6) fixture changed: $(diff <(cat "$fx.snap") <(printf '%s\n' "$after") | grep '^>' | tr '\n' ' ')"; fi

# (p7) a line names what the session left uncommitted. Every leak path here is untracked, so that word counts.
leak_path=''
case "$scenario" in full|large) leak_path='shutdown\.md' ;; leak) leak_path='shift-log\.txt' ;; esac
if [ -n "$leak_path" ]; then
  if { tr -d '\r' < "$out"; printf '%s\n' "$all_rows"; } | grep -Ei 'uncommitted|untracked|not committed|not been committed' | grep -Eq "$leak_path"; then
    echo "PASS (p7) a line names the leak as left uncommitted"
  else fail "(p7) no line names $leak_path as left uncommitted"; fi
fi

# (p8) one commit row, with no commits nested under it. A reading on the scenarios that do not gate it.
commit_rows="$(named '^commit' | grep -c . || true)"
subjects="$(named '^commit' | grep -Eo '\b(docs|fix|feat|chore|refactor|test)(\([^)]*\))?: ' | grep -c . || true)"
parts="$(named '^commit' | grep -Eio '(commit|part) #?[0-9]' | grep -c . || true)"
case "$scenario" in
  leak|large|single)
    if [ "$commit_rows" -gt 1 ] || [ "$subjects" -gt 1 ] || [ "$parts" -gt 0 ]; then
      fail "(p8) $commit_rows commit rows, $subjects commit subjects, $parts numbered parts"
    elif [ "$scenario" != single ] && [ "$commit_rows" != 1 ]; then fail "(p8) no commit row"
    else echo "PASS (p8) one commit row, nothing nested"; fi ;;
  *) echo "READING (p8) $commit_rows commit rows, $subjects commit subjects, $parts numbered parts" ;;
esac

# (p9) no option closes without running the moves.
if tr -d '\r' < "$out" | grep -Eiq 'close without|without running'; then fail "(p9) a close-without option is offered"
else echo "PASS (p9) no close-without option"; fi

# (p11) `single`: the lone move is one question naming the leak, with no second choice.
if [ "$scenario" = single ]; then
  row_count="$(printf '%s\n' "$all_rows" | grep -c . || true)"
  if [ "$row_count" -gt 1 ]; then fail "(p11) $row_count rows on a lone move. Rows: $names"
  elif ! tr -d '\r' < "$out" | grep -q 'shift-log\.txt'; then fail "(p11) the question does not name shift-log.txt"
  elif ! tr -d '\r' < "$out" | grep -Eiq '\?|\byes\b.*\bno\b|\bconfirm\b.*\bdecline\b'; then fail "(p11) no question asked"
  else echo "PASS (p11) one question on the lone move ($row_count bullet rows)"; fi
fi
[ "$fails" = 0 ]
