#!/usr/bin/env bash
# Derive the arm bodies from the triage agent. Frontmatter is stripped (a
# subagent's system prompt is the body, not the YAML); nothing under plugins/
# is touched.
#
#   arm-current.md  DEBT-118 M4 — agents/triage.md body as shipped before M4
#   arm-removed.md  the same body minus the one `Grep before reading.` bullet
#                   (M4 shipped this removal, so both are frozen snapshots:
#                   they regenerate only while the agent still carries the
#                   bullet)
#   arm-floor.md    DEBT-121 option A — arm-removed.md (the body DEBT-121 was
#                   benched against) with the command-list Bash floor sentence
#                   restated per action
#
# Each derivation asserts its arm differs from its parent by exactly one line,
# so a later edit that moves or rewords the target text fails loudly here
# instead of silently producing identical arms.
#
# Usage: bash make-arms.sh
set -eu
SRC="$(cd "$(dirname "$0")" && pwd)"
AGENT="$SRC/../../plugins/super-bootstrap/agents/triage.md"
LINE='- **Grep before reading.** Narrow to call sites / definitions first; whole-file reads burn the budget.'
FLOOR_OLD='Bash stays read-only (`git status/diff/log`, `ls`).'
FLOOR_NEW='Each action has its tool: the verdict append goes through Edit (anchor on the card'"'"'s final lines, re-emit them followed by the block); file reads and searches go through Read, Grep, Glob; Bash carries `git status/diff/log`, `ls`, and the `§ Probes` commands the consumer'"'"'s `docs/techstack.md` names — no redirect, heredoc, or interpreter call of your own.'

[ -f "$AGENT" ] || { echo "no agent at $AGENT" >&2; exit 1; }

one_line_diff() {  # <a> <b> — assert the two files differ by exactly one changed/deleted line
  d="$(diff "$1" "$2" | grep -c '^[<>]' || true)"
  [ "$d" = "$3" ] || { echo "$(basename "$2") differs from $(basename "$1") by $d diff lines, expected $3" >&2; exit 1; }
}

# --- DEBT-118 M4 arms (regenerate only while the bullet is still shipped) ---
body="$(mktemp)"
awk 'BEGIN{n=0} n>=2{print; next} /^---$/{n++; next}' "$AGENT" > "$body"
hits="$(grep -cxF -- "$LINE" "$body" || true)"
if [ "$hits" = "1" ]; then
  cp "$body" "$SRC/arm-current.md"
  grep -vxF -- "$LINE" "$SRC/arm-current.md" > "$SRC/arm-removed.md"
  one_line_diff "$SRC/arm-current.md" "$SRC/arm-removed.md" 1
  echo "M4 arms regenerated from the agent"
else
  echo "M4 arms frozen (agent no longer carries the grep-first bullet)"
fi
rm -f "$body"

# --- DEBT-121 option A arm ---
hits="$(grep -cF -- "$FLOOR_OLD" "$SRC/arm-removed.md" || true)"
[ "$hits" = "1" ] || { echo "expected exactly 1 floor sentence in arm-removed.md, found $hits" >&2; exit 1; }
: > "$SRC/arm-floor.md"
while IFS= read -r l || [ -n "$l" ]; do
  printf '%s\n' "${l/"$FLOOR_OLD"/"$FLOOR_NEW"}" >> "$SRC/arm-floor.md"
done < "$SRC/arm-removed.md"
one_line_diff "$SRC/arm-removed.md" "$SRC/arm-floor.md" 2
echo "arms: current $(wc -l < "$SRC/arm-current.md") · removed $(wc -l < "$SRC/arm-removed.md") · floor $(wc -l < "$SRC/arm-floor.md") lines"
