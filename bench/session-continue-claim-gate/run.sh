#!/usr/bin/env bash
# run.sh — one headless arm of the session-continue claim-gate micro-test.
# Usage: bash bench/session-continue-claim-gate/run.sh <control|arm> <fixture-dir> <out-file> [model]
#
#   control — session-continue SKILL.md as of 994bc12 (pre-gate), via git show
#   arm     — the working-tree SKILL.md (copy under test: this repo's dev copy)
#   model   — claude -p --model value (default haiku)
#
# Builds a fresh fixture, embeds the skill text verbatim in the prompt, runs the arm with
# the fixture as cwd, writes stdout to <out-file>, then prints the fixture's ledger listing.
set -eu
mode="${1:?usage: run.sh <control|arm> <fixture-dir> <out-file> [model]}"
fx="${2:?fixture dir}"
out="${3:?out file}"
model="${4:-haiku}"
here="$(cd "$(dirname "$0")" && pwd)"
repo="$(cd "$here/../.." && pwd)"
skill_rel=plugins/super-bootstrap/skills/session-continue/SKILL.md
case "$mode" in
  control) skill="$(git -C "$repo" show 994bc12:"$skill_rel")" ;;
  arm)     skill="$(cat "$repo/$skill_rel")" ;;
  *) echo "unknown mode: $mode" >&2; exit 2 ;;
esac
bash "$here/make-fixture.sh" "$fx" >/dev/null
prompt="$(cat "$here/prompt.txt")

----- SKILL.md (session-continue) -----
$skill"
( cd "$fx" && printf '%s\n' "$prompt" | claude -p --model "$model" --allowedTools Bash \
    --setting-sources project,local --permission-prompts none ) > "$out" 2>&1 || true
echo "--- ledger after run: $fx/SESSION-STATE"
ls "$fx/SESSION-STATE"
