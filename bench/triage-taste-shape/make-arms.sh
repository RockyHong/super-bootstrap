#!/usr/bin/env bash
# BUG-084 — snapshot the two contracts under test as one labelled arm pair.
#
#   arm-agent-<label>.md    agents/triage.md body, frontmatter stripped
#                           (a subagent's system prompt is the body)
#   arm-gateway-<label>.md  skills/triage/SKILL.md body, frontmatter stripped
#
# Run with label `control` before the prose edit, `treatment` after it.
# Refuses to overwrite an existing label, so a frozen control survives.
#
# Usage: bash make-arms.sh <label>
set -eu
LABEL="${1:?usage: make-arms.sh <label>}"
SRC="$(cd "$(dirname "$0")" && pwd)"
PLUGIN="$SRC/../../plugins/super-bootstrap"

strip() { awk 'NR==1 && /^---$/ {fm=1; next} fm && /^---$/ {fm=0; next} !fm' "$1"; }

for pair in "agent:$PLUGIN/agents/triage.md" "gateway:$PLUGIN/skills/triage/SKILL.md"; do
  name="${pair%%:*}"
  file="${pair#*:}"
  out="$SRC/arm-$name-$LABEL.md"
  [ -e "$out" ] && { echo "exists: $out — not overwriting" >&2; exit 1; }
  strip "$file" > "$out"
  echo "wrote $out ($(wc -l < "$out") lines)"
done
