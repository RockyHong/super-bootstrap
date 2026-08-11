#!/usr/bin/env bash
# GAP-045 arm 2b — forced-eval consult check, COMPACT catalog.
# Same forced YES/NO template as forcedeval-inject.sh but the catalog is
# path stems only (no why text, no absolute prefix) to fit the <=500-token
# overhead gate. Tests whether the why-text is load-bearing for the model's
# YES/NO accuracy or the stems alone carry it.
set -uo pipefail
ROOT="${CLAUDE_PROJECT_DIR:-$PWD}"
MAP="$ROOT/bench/doc-map.tsv"
[ -f "$MAP" ] || exit 0

root_line="$(head -1 "$MAP" | cut -f1)"
root_line="${root_line%%guidelines/*}guidelines/"
echo "[doc-consult-check] Before answering, evaluate EACH doc below and state YES or NO: does it bear on this prompt? Read every YES doc before composing your answer. If all are NO, answer directly. Doc root: ${root_line}"
while IFS=$'\t' read -r path terms why; do
  printf -- '- %s\n' "${path#*guidelines/}"
done < "$MAP"
