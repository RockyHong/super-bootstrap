#!/usr/bin/env bash
# GAP-045 arm 2 — forced-eval consult check (UserPromptSubmit).
# Anthropic skill-activation template transplanted to docs: every prompt gets
# the full catalog + a forced YES/NO relevance evaluation. No matching logic —
# the model is the classifier, the injection forces the evaluation moment.
set -uo pipefail
ROOT="${CLAUDE_PROJECT_DIR:-$PWD}"
MAP="$ROOT/bench/doc-map.tsv"
[ -f "$MAP" ] || exit 0

echo "[doc-consult-check] Before answering, evaluate EACH doc below and state YES or NO: does it bear on this prompt? Read every YES doc before composing your answer. If all are NO, answer directly. Docs live under .claude/guidelines/."
while IFS=$'\t' read -r path terms why; do
  printf -- '- %s — %.45s\n' "${path#.claude/guidelines/}" "$why"
done < "$MAP"
