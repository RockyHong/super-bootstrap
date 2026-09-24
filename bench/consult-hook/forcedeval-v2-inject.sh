#!/usr/bin/env bash
# DEBT-119 candidate arm — forced-eval consult check, COMPACT catalog, no
# stated-output demand. Identical to forcedeval-compact-inject.sh (catalog,
# tail, trigger) except the forced-eval sentence: it keeps the evaluation
# moment ("judge which docs below bear on this prompt") and the Read
# instruction, and drops the demand to state YES or NO per doc in the reply.
# Isolates the one variable: does the stated per-doc enumeration carry recall/TN?
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
