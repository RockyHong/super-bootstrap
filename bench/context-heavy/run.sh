#!/usr/bin/env bash
# run.sh — one headless run of the context-heavy micro-test.
# Usage: bash bench/context-heavy/run.sh <control|arm> <a|b> <fixture-dir> <out-file>
#
#   control — the surfaces as of 8cb9c9f, via git show
#   arm     — the working-tree surfaces (copy under test: this repo's dev copy)
#
# Builds a fresh fixture, embeds the surfaces verbatim in the prompt, runs with the fixture
# as cwd, writes stdout to <out-file>, then prints the fixture's tree state and the score.
set -eu
mode="${1:?usage: run.sh <control|arm> <a|b> <fixture-dir> <out-file>}"
scenario="${2:?scenario}"
fx="${3:?fixture dir}"
out="${4:?out file}"
here="$(cd "$(dirname "$0")" && pwd)"
repo="$(cd "$here/../.." && pwd)"
control_rev=8cb9c9f
claude_rel=CLAUDE.md
skeleton_rel=plugins/super-bootstrap/skills/harness-bootstrap/assets/claude-md-skeleton.md
close_rel=plugins/super-bootstrap/skills/session-close/SKILL.md

case "$mode" in
  control) src() { git -C "$repo" show "$control_rev:$1"; } ;;
  arm)     src() { cat "$repo/$1"; } ;;
  *) echo "unknown mode: $mode" >&2; exit 64 ;;
esac
case "$scenario" in
  a|b) ;;
  *) echo "unknown scenario: $scenario" >&2; exit 64 ;;
esac

ambient() { src "$1" | tr -d '\r' | awk '/^## Context Hygiene/{p=1} /^## Rules/{p=0} p'; }
hygiene="$(ambient "$claude_rel")"
if [ "$hygiene" != "$(ambient "$skeleton_rel")" ]; then
  echo "parity: CLAUDE.md and the skeleton differ in § Context Hygiene or § Finding Triage ($mode)" >&2
  exit 3
fi
shapes="$(src "$close_rel" | tr -d '\r' | awk '/^## Two terminal shapes/{p=1} /^## Ledger convention/{p=0} p')"

bash "$here/make-fixture.sh" "$fx" >/dev/null
prompt="$(cat "$here/prompt-$scenario.txt")

----- CLAUDE.md (excerpt) -----
$hygiene

----- skills/session-close/SKILL.md (excerpt) -----
$shapes"
( cd "$fx" && printf '%s\n' "$prompt" | claude -p --model haiku --allowedTools Bash \
    --setting-sources project,local --permission-prompts none ) > "$out" 2>&1 || true
echo "--- fixture after run: $fx"
git -C "$fx" log --oneline
git -C "$fx" status --short
echo "--- score"
bash "$here/score.sh" "$scenario" "$out" || true
