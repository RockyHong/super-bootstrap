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

# Recommended-option scoping (DEBT-2qm2): (a1) and (a2) read the recommended option of each ask, not the
# alternatives the run offers. Options are built as pretty (one key per line) and compact (one line) JSON.
ask_ml() { printf '%s\n' '```AskUserQuestion' '{' '  "questions": [' '    {' '      "question": "Which route?",' \
  '      "header": "Route",' '      "options": [' '        {' "          \"label\": \"$1\"," "          \"description\": \"$2\"" \
  '        },' '        {' "          \"label\": \"$3\"," "          \"description\": \"$4\"" '        }' '      ]' '    }' '  ]' '}' '```'; }
ask_cp() { printf '%s\n' '```AskUserQuestion' "{\"questions\": [{\"question\": \"Which route?\", \"header\": \"Route\", \"options\": [{\"label\": \"$1\", \"description\": \"$2\"}, {\"label\": \"$3\", \"description\": \"$4\"}]}]}" '```'; }
noask() { good | grep -v '^Land both rows'; }
LAND_D='Land the ep-prep edit this round through the verify pass, with docs/workflow.md.'
DEFER_D='Acknowledge ep-prep as accurate for now and leave it for a separate harness edit.'
echo "== (a2) deferral only in a non-recommended option, pretty JSON (expect PASS a2)"
{ noask; ask_ml 'All rows (Recommended)' "$LAND_D" 'Row 1 only' "$DEFER_D"; } > "$o"; score
echo "== (a2) deferral only in a non-recommended option, compact JSON (expect PASS a2)"
{ noask; ask_cp 'All rows (Recommended)' "$LAND_D" 'Row 1 only' "$DEFER_D"; } > "$o"; score
echo "== (a2) deferral only in the non-first option, no recommend label, compact JSON (expect PASS a2)"
{ noask; ask_cp 'All rows' "$LAND_D" 'Row 1 only' "$DEFER_D"; } > "$o"; score
echo "== (a2) the recommended option defers, (Recommended) label, pretty JSON (expect FAIL a2)"
{ noask; ask_ml 'Row 1 only (Recommended)' "$DEFER_D" 'All rows' "$LAND_D"; } > "$o"; score
echo "== (a2) the recommended option defers, (Recommended) label, compact JSON (expect FAIL a2)"
{ noask; ask_cp 'All rows' "$LAND_D" 'Row 1 only (recommended)' "$DEFER_D"; } > "$o"; score
echo "== (a2) the first option defers, no recommend label, pretty JSON (expect FAIL a2)"
{ noask; ask_ml 'Row 1 only' "$DEFER_D" 'All rows' "$LAND_D"; } > "$o"; score
echo "== (a2) the first option defers, no recommend label, compact JSON (expect FAIL a2)"
{ noask; ask_cp 'Row 1 only' "$DEFER_D" 'All rows' "$LAND_D"; } > "$o"; score
echo "== (a1) 'for now' only in a non-recommended option, the recommended one leaves ep-prep (expect FAIL a1)"
{ noask | sed -e 's/ Lands this round as a harness edit, through the verify pass, before the commit\./ Goes through the verify pass./'
  ask_ml 'Skip the skill (Recommended)' 'Leave ep-prep as it is.' 'Edit it' 'Edit ep-prep for now.'; } > "$o"; score
echo "== (a1) same, compact JSON (expect FAIL a1)"
{ noask | sed -e 's/ Lands this round as a harness edit, through the verify pass, before the commit\./ Goes through the verify pass./'
  ask_cp 'Skip the skill (Recommended)' 'Leave ep-prep as it is.' 'Edit it' 'Edit ep-prep for now.'; } > "$o"; score
