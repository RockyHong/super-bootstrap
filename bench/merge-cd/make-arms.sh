#!/usr/bin/env bash
# GAP-091 L6 — derive the two arm bodies from the shipped merge skill.
#
#   arm-current.md  skills/merge/SKILL.md body as shipped (frontmatter
#                   stripped — an invoked skill reaches the model as its body)
#   arm-removed.md  the same body minus the one `cd` line
#
# Nothing under plugins/ is touched. Asserts the arms differ by exactly that
# line, so a later reword of the line fails loudly here.
#
# Usage: bash make-arms.sh
set -eu
SRC="$(cd "$(dirname "$0")" && pwd)"
SKILL="$SRC/../../plugins/super-bootstrap/skills/merge/SKILL.md"
LINE='- Working directory is already correct; `cd` is unnecessary.'

[ -f "$SKILL" ] || { echo "no skill at $SKILL" >&2; exit 1; }
awk 'BEGIN{n=0} n>=2{print; next} /^---$/{n++; next}' "$SKILL" > "$SRC/arm-current.md"

hits="$(grep -cxF -- "$LINE" "$SRC/arm-current.md" || true)"
[ "$hits" = "1" ] || { echo "expected exactly 1 cd line in the body, found $hits" >&2; exit 1; }
grep -vxF -- "$LINE" "$SRC/arm-current.md" > "$SRC/arm-removed.md"

d="$(diff "$SRC/arm-current.md" "$SRC/arm-removed.md" | grep -c '^[<>]' || true)"
[ "$d" = "1" ] || { echo "arms differ by $d lines, expected 1" >&2; exit 1; }
diff "$SRC/arm-current.md" "$SRC/arm-removed.md" || true
echo "arms written: arm-current.md ($(wc -l < "$SRC/arm-current.md") lines), arm-removed.md ($(wc -l < "$SRC/arm-removed.md") lines)"
