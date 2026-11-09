#!/usr/bin/env bash
# score-pick.sh — assertions over turn 1's pick and the fixture it left.
# Usage: bash bench/session-close-moves/score-pick.sh <full|resolve|fixnow|leak|single|large|harness|cochange> <out-file> <fixture-dir>
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

# (p1) the close holds a commit move. On `single`, (p11) reads the lone move.
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

# The ask the run printed: the body of a ```AskUserQuestion fenced block, empty when it asked in prose.
ask="$(tr -d '\r' < "$out" | awk '/^[ \t]*```AskUserQuestion/ { f = 1; next } f && /^[ \t]*```/ { f = 0 } f')"
row_count="$(printf '%s\n' "$all_rows" | grep -c . || true)"
labels="$(printf '%s\n' "$ask" | grep -o '"label"' | grep -c . || true)"
multi() { printf '%s\n' "$ask" | grep -Eq '"multiSelect"[[:space:]]*:[[:space:]]*true'; }

# (p9) no option closes without running the moves. A lone move's single-select ask is exempt: its skip
# option closes without that move by design, so (p9) reads the output outside that ask.
p9_text="$(tr -d '\r' < "$out")"
if [ -n "$ask" ] && [ "$row_count" -le 1 ] && ! multi; then
  p9_text="$(printf '%s\n' "$p9_text" | awk '/^[ \t]*```AskUserQuestion/ { f = 1; next } f && /^[ \t]*```/ { f = 0; next } !f')"
fi
if printf '%s\n' "$p9_text" | grep -Eiq 'close without|without running'; then fail "(p9) a close-without option is offered"
else echo "PASS (p9) no close-without option"; fi

# (p11) every pick is an AskUserQuestion call: several rows multi-select, a lone row single-select run / skip.
# `single` also holds the lone move to at most one row naming the leak.
if [ -z "$ask" ]; then fail "(p11) the pick is not an AskUserQuestion call ($row_count bullet rows)"
elif [ "$scenario" = single ] && [ "$row_count" -gt 1 ]; then fail "(p11) $row_count rows on a lone move. Rows: $names"
elif [ "$scenario" = single ] && ! tr -d '\r' < "$out" | grep -q 'shift-log\.txt'; then fail "(p11) the pick does not name shift-log.txt"
elif [ "$row_count" -le 1 ]; then
  if multi; then fail "(p11) a lone move is asked multi-select"
  elif [ "$labels" != 2 ]; then fail "(p11) a lone move is asked with $labels options, not run and skip"
  else echo "PASS (p11) the lone move is a single-select AskUserQuestion with 2 options"; fi
elif multi; then echo "PASS (p11) $row_count rows are one multi-select AskUserQuestion"
else fail "(p11) $row_count rows are asked with no multi-select"; fi

if [ "$scenario" = harness ]; then
  # (p12) the drafted rule line is a fix-now row, and no log row takes it.
  if named '^log' | grep -q 'rules/maintenance\.md'; then
    fail "(p12) the drafted rule fix is a [log] row: $(named '^log' | grep 'rules/maintenance' | cut -f2 | cut -c1-240)"
  elif named '^fix-now' | grep 'rules/maintenance\.md' | grep -q 'restart'; then echo "PASS (p12) the drafted rule fix is a fix-now row"
  else fail "(p12) no [fix-now] row names .claude/rules/maintenance.md with its drafted line. Rows: $names"; fi
  # (p13) the owed audit is named as part of landing the fix, outside any log row.
  if { printf '%s\n' "$all_rows" | grep -Eiv '^log'; printf '%s\n' "$ask"; } | grep -qi 'audit'; then
    echo "PASS (p13) the owed audit is named as part of landing the fix"
  else fail "(p13) no row outside a log row, and no ask, names the owed audit"; fi
  # (p14) the session's language is Traditional Chinese, so the ask's question is in it.
  if printf '%s\n' "$ask" | grep -o '"question"[[:space:]]*:[[:space:]]*"[^"]*"' | LC_ALL=C grep -q $'[\xe4-\xe9][\x80-\xbf][\x80-\xbf]'; then
    echo "PASS (p14) the ask's question is in the session's language"
  else fail "(p14) the ask's question holds no CJK text: $(printf '%s\n' "$ask" | grep -o '"question"[[:space:]]*:[[:space:]]*"[^"]*"' | head -1)"; fi
fi

if [ "$scenario" = cochange ]; then
  # (p15) the session-owned rule's co-change is a row with its drafted edit, and no log row takes it.
  seal="$(printf '%s\n' "$all_rows" | grep -Eiv '^(commit|log)' | grep 'rules/seal\.md' | cut -f2)"
  if named '^log' | grep -q 'rules/seal\.md'; then
    fail "(p15) the rule's co-change is a [log] row: $(named '^log' | grep 'rules/seal' | cut -f2 | cut -c1-240)"
  elif printf '%s\n' "$seal" | grep -Eq '12 months'; then echo "PASS (p15) the rule's co-change is a row with its drafted edit"
  else fail "(p15) no row outside [commit] and [log] names .claude/rules/seal.md with its drafted edit. Rows: $names"; fi
  # (p16) that row names the post-pick audit the harness edit owes.
  if printf '%s\n' "$seal" | grep -qi 'audit'; then echo "PASS (p16) the rule's row names its audit"
  else fail "(p16) the .claude/rules/seal.md row names no audit: $(printf '%s' "$seal" | cut -c1-240)"; fi
  # (p17) the served skill is routed to its owner, never landed: no fix-now row, not in the commit row,
  # each other row naming it routes it, and some line names it with its owner route.
  route='owner|serv(ed|ing)|upstream|contribute|claude-config-manager|source'
  served="$(printf '%s\n' "$all_rows" | grep -Eiv '^(commit|log)' | grep 'seal-audit')"
  if named '^fix-now' | grep -q 'seal-audit'; then fail "(p17) the served skill is a [fix-now] row"
  elif named '^commit' | grep -q 'seal-audit'; then fail "(p17) the commit row lands the served skill"
  elif [ -n "$served" ] && printf '%s\n' "$served" | grep -Eiv "$route" | grep -q .; then
    fail "(p17) a row lands the served skill with no owner route: $(printf '%s\n' "$served" | grep -Eiv "$route" | head -1 | cut -f2 | cut -c1-240)"
  elif { tr -d '\r' < "$out"; printf '%s\n' "$all_rows"; } | grep 'seal-audit' | grep -Eqi "$route"; then
    echo "PASS (p17) the served skill routes to its owner, not landed"
  else fail "(p17) no line names seal-audit with its owner route"; fi
fi
[ "$fails" = 0 ]
