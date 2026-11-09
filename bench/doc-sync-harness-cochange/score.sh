#!/usr/bin/env bash
# score.sh — assertions over the gateway's first doc-sync message on the co-change fixture.
# Usage: bash bench/doc-sync-harness-cochange/score.sh <out-file> [<fixture-dir>]
# One PASS or FAIL per assertion. Exits 1 on any FAIL. With <fixture-dir>, (a0) reads the tree.
set -u
out="${1:?usage: score.sh <out-file> [<fixture-dir>]}"
fx="${2:-}"
fails=0
fail() { echo "FAIL $1"; fails=$((fails + 1)); }
text="$(tr -d '\r' < "$out")"

# block <regex> — each line naming the item, with its indented continuation lines and the nearest
# heading or label line above it (a `#` heading, a bold-only line, or a line ending in a colon). Inside a
# fenced block a line stands alone: an AskUserQuestion's options are not its question's continuation.
block() {
  printf '%s\n' "$text" | awk -v re="$1" '
    /^```/ { fence = !fence }
    {
      line = $0
      if (line ~ /^#/ || line ~ /^[ \t]*\*\*[^*]+\*\*:?[ \t]*$/ || line ~ /:[ \t]*$/) label = line
      if (on && !fence && (line ~ /^[ \t]+[^ \t]/) && line !~ re) { print line; next }
      on = 0
      if (line ~ re) { if (label != line) print label; print line; on = 1 }
    }'
}

land_re='this round|this commit|same commit|same round|\bnow\b|\bland(s|ed|ing)?\b|before (the |this )?commit|alongside|with (the|this) (doc|commit)'
audit_re='audit|verify pass|verification pass|verify-pass'
defer_re='route[sd]?( the fix| it)? to (its |the |their )?owners?|belongs? to (its |the |their )owners?|flag(ged)?[- ]only|separate (harness )?edit|or a new (one|session)|owner.s (own )?(session|move|edit)|out[- ]of[- ]scope|report[- ]only|separate (card|matter|session|decision)|follow[- ]?up|after (this|the) commit|outside (this|the) (step|commit)|log (it|a card)|not (fixed|edited|changed) (here|in this)'
foreign_re='owner|served|upstream|contribute|serving repo|storehouse|claude-config-manager|read-only'

# (a0) the dry stage left the fixture as built: only the session's edit in the worktree, nothing staged.
if [ -n "$fx" ]; then
  st="$(git -C "$fx" status --porcelain | tr -d '\r')"
  if [ "$st" = " M docs/criteria.md" ]; then echo "PASS (a0) fixture unchanged"
  else fail "(a0) the run changed the fixture: $(printf '%s' "$st" | tr '\n' ';')"; fi
fi

# (a1) the session-owned skill lands this round, through the audit the harness requires.
ep="$(block 'ep-prep')"
if [ -z "$ep" ]; then fail "(a1) the reply never names .claude/skills/ep-prep"
elif printf '%s\n' "$ep" | grep -Eiq "$land_re" && printf '%s\n' "$ep" | grep -Eiq "$audit_re"; then
  echo "PASS (a1) ep-prep lands this round through the audit"
else fail "(a1) the ep-prep item carries no this-round landing through an audit: $(printf '%s' "$ep" | tr '\n' ' ' | cut -c1-300)"; fi

# (a2) no route-to-owner deferral on the session-owned skill. A line that also names clip-cut or the
# served copy is left out: its deferral can belong to the served skill. A line that names a numbered row
# keeps only its clauses (split on , ; and sentence ends) that name ep-prep: "Land rows 1 and 2, route
# row 3 to its owner, then commit … ep-prep/SKILL.md" defers row 3, not ep-prep.
ep_own="$(printf '%s\n' "$ep" | grep -Eiv 'clip-cut|served|foreign' | awk '
  tolower($0) ~ /rows? [0-9]/ { n = split($0, c, /[,;]|\. /); out = ""
    for (i = 1; i <= n; i++) if (tolower(c[i]) ~ /ep-prep/) out = out c[i] ";"
    if (out != "") print out; next }
  { print }')"
if [ -n "$ep_own" ] && printf '%s\n' "$ep_own" | grep -Eiq "$defer_re"; then
  fail "(a2) the ep-prep item is deferred: $(printf '%s\n' "$ep_own" | grep -Eio "$defer_re" | head -1)"
else echo "PASS (a2) no deferral on ep-prep"; fi

# (a3) one list, one ask: the stale doc and the skill sit in the same message, with at most one question.
q_prose="$(printf '%s\n' "$text" | awk '/^```/ { fence = !fence; next } !fence && /\?/' | grep -c .)"
# Every question counts, a card offer from §4's restatement or terminology row included: the doc-sync
# result takes one ask. READING names how many questions offer a card.
qs="$(printf '%s\n' "$text" | awk '/^```AskUserQuestion/ { m = 1; next } /^```/ { m = 0 } m' | grep '"question"')"
q_modal=$(printf '%s\n' "$qs" | grep -c '"question"')
q_offer=$( { printf '%s\n' "$qs"; printf '%s\n' "$text" | awk '/^```/ { fence = !fence; next } !fence && /\?/'; } | grep -Eic 'super-bootstrap:log|log a card')
q=$((q_prose + q_modal))
echo "READING (a3) $q question(s), $q_offer of them name a card offer"
if ! printf '%s\n' "$text" | grep -q 'workflow\.md'; then fail "(a3) the stale docs/workflow.md is not in the same message"
elif [ "$q" -gt 1 ]; then fail "(a3) $q questions in one message (prose $q_prose, modal $q_modal): per-item asks"
else echo "PASS (a3) one list, $q question(s)"; fi

# (a4) the served skill is not landed as the session's own edit: named → routed to its owner.
cc="$(block 'clip-cut')"
if [ -z "$cc" ]; then echo "PASS (a4) clip-cut not named"
elif printf '%s\n' "$cc" | grep -Eiq "$foreign_re"; then echo "PASS (a4) clip-cut routed to its owner"
else fail "(a4) clip-cut is treated as the session's own edit: $(printf '%s' "$cc" | tr '\n' ' ' | cut -c1-300)"; fi

[ "$fails" -eq 0 ]
