#!/usr/bin/env bash
# DEBT-118 M4 — derive the two arm bodies from the shipped triage agent.
#
#   arm-current.md  agents/triage.md body as shipped (frontmatter stripped —
#                   a subagent's system prompt is the body, not the YAML)
#   arm-removed.md  the same body minus the one `Grep before reading.` bullet
#
# Both are copies inside this bench dir; nothing under plugins/ is touched.
# The script asserts the two arms differ by exactly that one line, so a later
# edit to agents/triage.md that moves or rewords the bullet fails loudly here
# instead of silently producing two identical arms.
#
# Usage: bash make-arms.sh
set -eu
SRC="$(cd "$(dirname "$0")" && pwd)"
AGENT="$SRC/../../plugins/super-bootstrap/agents/triage.md"
LINE='- **Grep before reading.** Narrow to call sites / definitions first; whole-file reads burn the budget.'

[ -f "$AGENT" ] || { echo "no agent at $AGENT" >&2; exit 1; }

# body = everything after the closing `---` of the frontmatter
awk 'BEGIN{n=0} n>=2{print; next} /^---$/{n++; next}' "$AGENT" > "$SRC/arm-current.md"

hits="$(grep -cxF -- "$LINE" "$SRC/arm-current.md" || true)"
[ "$hits" = "1" ] || { echo "expected exactly 1 grep-first line in the body, found $hits" >&2; exit 1; }

grep -vxF -- "$LINE" "$SRC/arm-current.md" > "$SRC/arm-removed.md"

# the arms must differ by that one deleted line and nothing else
d="$(diff "$SRC/arm-current.md" "$SRC/arm-removed.md" | grep -c '^[<>]' || true)"
[ "$d" = "1" ] || { echo "arms differ by $d lines, expected 1" >&2; exit 1; }
diff "$SRC/arm-current.md" "$SRC/arm-removed.md" || true
echo "arms written: arm-current.md ($(wc -l < "$SRC/arm-current.md") lines), arm-removed.md ($(wc -l < "$SRC/arm-removed.md") lines)"
