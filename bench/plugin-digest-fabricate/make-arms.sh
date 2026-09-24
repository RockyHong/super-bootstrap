#!/usr/bin/env bash
# GAP-091 L2 — derive the two arm bodies from the shipped plugin-digest agent.
#
#   arm-A.md  agents/plugin-digest.md body as shipped (frontmatter stripped —
#             a subagent's system prompt is the body, not the YAML)
#   arm-B.md  the same body minus the one Rules-list `Never fabricate.` bullet
#             (Step 3's "Never fabricate a digest field ..." sentence stays)
#   arm-C.md  positive control: B minus Step 3's "Never fabricate ..." sentence
#             too (no fabrication guard left) — checks the fixture can elicit
#             fabrication at all, so a zero-vs-zero A/B is not a blind probe
#
# Nothing under plugins/ is touched. Asserts the arms differ by exactly that
# one line, so a later reword of the agent fails loudly here.
#
# Usage: bash make-arms.sh
set -eu
SRC="$(cd "$(dirname "$0")" && pwd)"
AGENT="$SRC/../../plugins/super-bootstrap/agents/plugin-digest.md"
LINE='- **Never fabricate.** Absent or unparseable source → `unresolved`, not a best-guess digest.'

[ -f "$AGENT" ] || { echo "no agent at $AGENT" >&2; exit 1; }
awk 'BEGIN{n=0} n>=2{print; next} /^---$/{n++; next}' "$AGENT" > "$SRC/arm-A.md"

hits="$(grep -cxF -- "$LINE" "$SRC/arm-A.md" || true)"
[ "$hits" = "1" ] || { echo "expected exactly 1 Rules-list line, found $hits" >&2; exit 1; }
grep -vxF -- "$LINE" "$SRC/arm-A.md" > "$SRC/arm-B.md"

d="$(diff "$SRC/arm-A.md" "$SRC/arm-B.md" | grep -c '^[<>]' || true)"
[ "$d" = "1" ] || { echo "arms differ by $d lines, expected 1" >&2; exit 1; }
grep -c 'Never fabricate' "$SRC/arm-B.md" | grep -qx 1 || { echo "arm-B lost the Step 3 instance" >&2; exit 1; }
diff "$SRC/arm-A.md" "$SRC/arm-B.md" || true

# arm C: strip Step 3's sentence (from "Never fabricate" to end of that line)
sed 's/ Never fabricate a digest field.*$//' "$SRC/arm-B.md" > "$SRC/arm-C.md"
grep -q 'Never fabricate' "$SRC/arm-C.md" && { echo "arm-C still carries Never fabricate" >&2; exit 1; }
d="$(diff "$SRC/arm-B.md" "$SRC/arm-C.md" | grep -c '^[<>]' || true)"
[ "$d" = "2" ] || { echo "arm-C differs from B by $d lines, expected 2 (one changed line)" >&2; exit 1; }
diff "$SRC/arm-B.md" "$SRC/arm-C.md" || true
echo "arms written: arm-A.md ($(wc -l < "$SRC/arm-A.md") lines), arm-B.md ($(wc -l < "$SRC/arm-B.md") lines), arm-C.md"
