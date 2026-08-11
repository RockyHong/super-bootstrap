#!/usr/bin/env bash
# GAP-045 arm 1 — passive pointer inject (UserPromptSubmit).
# Match prompt (stdin JSON .prompt) against doc-map terms; emit up to 3 pointer
# lines (path + one-line why). Pointer-only, no doc body. Silent when no match.
set -uo pipefail
ROOT="${CLAUDE_PROJECT_DIR:-$PWD}"
MAP="$ROOT/bench/doc-map.tsv"
[ -f "$MAP" ] || exit 0
prompt="$(jq -r '.prompt // empty' 2>/dev/null | tr '[:upper:]' '[:lower:]')"
[ -n "$prompt" ] || exit 0

hits=""
n=0
while IFS=$'\t' read -r path terms why; do
  IFS='|' read -ra ts <<<"$terms"
  for t in "${ts[@]}"; do
    [ -n "$t" ] || continue
    if [[ "$prompt" == *"$t"* ]]; then
      hits+="- ${path} — ${why}"$'\n'
      n=$((n+1))
      break
    fi
  done
  [ "$n" -ge 3 ] && break
done < "$MAP"

[ -n "$hits" ] || exit 0
printf '[doc-pointer] Canonical docs likely relevant to this prompt — read before answering:\n%s' "$hits"
