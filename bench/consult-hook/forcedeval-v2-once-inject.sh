#!/usr/bin/env bash
# DEBT-122 arm (b) — forced-eval consult check, injected ONCE per session.
# Byte-for-byte the forcedeval-v2-inject.sh block (same sentence, same compact
# catalog render); only the wiring differs: arm-forcedeval-v2-once.json fires
# it on SessionStart (startup|resume|clear|compact) with no UserPromptSubmit
# entry. Isolates the one variable: injection frequency (every prompt vs once
# per session, refreshed only on a SessionStart re-fire).
set -uo pipefail
ROOT="${CLAUDE_PROJECT_DIR:-$PWD}"
MAP="$ROOT/bench/doc-map.tsv"
[ -f "$MAP" ] || exit 0

root_line="$(head -1 "$MAP" | cut -f1)"
root_line="${root_line%%guidelines/*}guidelines/"
echo "[doc-consult-check] Before answering, judge which docs below bear on this prompt, and Read each one that does before composing your answer. If none does, answer directly. Doc root: ${root_line}"
while IFS=$'\t' read -r path terms why; do
  printf -- '- %s\n' "${path#*guidelines/}"
done < "$MAP"
