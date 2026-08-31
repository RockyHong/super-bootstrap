#!/usr/bin/env bash
# Assemble the four arm prompts from parts/ into prompts/. Zero LLM calls.
#
# Byte-identity is the point. Within one fixture, cold and warm share the
# scanner body, the scan scope, the diff and the task line byte for byte; the
# only difference is the container — its framing header, its one eyes rule, and
# (warm only) the intent + session-read block the gateway would have held.
# run.sh re-runs this before every round so a prompt can never drift from parts.
set -uo pipefail

HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
P="$HERE/parts"
OUT="$HERE/prompts"
mkdir -p "$OUT"

emit() {   # emit <fixture> <container>
  local fx="$1" c="$2"
  cat "$P/container-$c.md"
  printf '\n'
  cat "$P/scanner-body.md"
  cat "$P/rule-$c.md"
  printf '\n---\n\n'
  cat "$P/$fx-scope.md"
  if [ "$c" = warm ]; then
    printf '\n'
    cat "$P/$fx-intent.md"
  fi
  printf '\n'
  cat "$P/$fx-diff.txt"
  printf '\n'
  cat "$P/$fx-task.md"
}

for fx in f1 f2; do
  for c in cold warm; do
    emit "$fx" "$c" > "$OUT/$fx-$c.txt"
    printf '   %-14s %5s bytes\n' "$fx-$c.txt" "$(wc -c < "$OUT/$fx-$c.txt" | tr -d ' ')"
  done
done

# The Opus control runs prompts/f1-cold.txt unchanged — tier is the only thing
# that moves. No third prompt file exists, so byte-identity cannot rot.
echo "DONE — prompts/ rebuilt from parts/"
