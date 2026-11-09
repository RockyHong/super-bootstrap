#!/usr/bin/env bash
# bite.sh — shows each of score.sh's assertions failing on a violating output or fixture. Zero LLM calls.
# Usage: bash bench/doc-sync-harness-cochange/bite.sh <scratch-dir>
set -u
scratch="${1:?usage: bite.sh <scratch-dir>}"
here="$(cd "$(dirname "$0")" && pwd)"
repo="$(cd "$here/../.." && pwd)"
mkdir -p "$scratch"
scratch="$(cd "$scratch" && pwd)"
fx="$scratch/bite-fx"
bash "$here/make-fixture.sh" "$fx" "$repo" >/dev/null

good() { cat <<'OUT'
Doc-sync found two rows. Both land in this commit.

**Resolve together**
- `docs/workflow.md:5` is stale: it says 5 seconds. Update to the link only.
- `.claude/skills/ep-prep/SKILL.md:10` (this repo's own skill, co-change): step 3 says 5 seconds. Lands this round as a harness edit, through the verify pass, before the commit.

**Foreign-owned**
- `.claude/skills/clip-cut/SKILL.md:9` is a served copy: route the fix to its owner via /contribute.

Land both rows and commit? (yes / no)
OUT
}
o="$scratch/o.txt"
score() { bash "$here/score.sh" "$o" "$fx"; }

echo "== baseline (all pass)"
good > "$o"; score
echo "== (a0) the run staged a file"
git -C "$fx" add docs/criteria.md; good > "$o"; score; git -C "$fx" reset -q
echo "== (a1) the skill is named with no landing and no audit"
good | sed -e 's/ Lands this round as a harness edit, through the verify pass, before the commit\.//' > "$o"; score
echo "== (a2) the skill is routed to its owner"
good | sed -e 's/Lands this round as a harness edit, through the verify pass, before the commit\./Route the fix to its owner; it lands this round only after its audit./' > "$o"; score
echo "== (a3) one question per item"
good | sed -e 's/^Land both rows and commit? (yes \/ no)$/Update docs\/workflow.md?\nEdit ep-prep now?/' > "$o"; score
echo "== (a3) a card offer that names the skill counts as a second ask"
{ good | grep -v '^Land both rows'; printf '%s\n' '```AskUserQuestion' '{"questions": [' \
  '  {"question": "Land both rows and commit?", "header": "List"},' \
  '  {"question": "Log a card via /super-bootstrap:log for ep-prep instead?", "header": "Card"}' ']}' '```'; } > "$o"; score
echo "== (a3) the stale doc is not in the message"
good | grep -v 'workflow' > "$o"; score
echo "== (a4) the served skill is landed as the session's own"
good | sed -e 's#is a served copy: route the fix to its owner via /contribute#lands this round too#' > "$o"; score
