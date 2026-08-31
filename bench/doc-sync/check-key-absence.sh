#!/usr/bin/env bash
# Fail if any answer-key leak literal reaches an arm prompt or its parts.
# Literals come from SCORING.md's ```leak-literals fence — one source, so the
# key and its guard cannot drift apart. Zero LLM calls.
set -uo pipefail

HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SHEET="$HERE/SCORING.md"
[ -f "$SHEET" ] || { echo "FAIL: SCORING.md missing" >&2; exit 1; }

lits="$(awk '/^```leak-literals$/{f=1;next} f&&/^```$/{f=0} f' "$SHEET" \
        | grep -v '^[[:space:]]*#' | grep -v '^[[:space:]]*$')"
[ -n "$lits" ] || { echo "FAIL: no leak literals parsed from SCORING.md" >&2; exit 1; }

targets=""
for d in prompts parts; do
  [ -d "$HERE/$d" ] || continue
  for f in "$HERE/$d"/*; do [ -f "$f" ] && targets="$targets $f"; done
done
[ -n "$targets" ] || { echo "FAIL: nothing to scan — run assemble-prompts.sh first" >&2; exit 1; }

bad=0
n=0
while IFS= read -r lit; do
  n=$((n + 1))
  hits="$(grep -Fn -- "$lit" $targets 2>/dev/null)"
  if [ -n "$hits" ]; then
    bad=$((bad + 1))
    echo "LEAK: '$lit'" >&2
    printf '%s\n' "$hits" | sed 's/^/      /' >&2
  fi
done <<EOF
$lits
EOF

if [ "$bad" -gt 0 ]; then
  echo "FAIL: $bad of $n leak literals reached an arm prompt" >&2
  exit 1
fi
echo "ok — $n leak literals, none present in prompts/ or parts/"
