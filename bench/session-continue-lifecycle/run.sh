#!/usr/bin/env bash
# run.sh — one headless arm of the session-continue lifecycle micro-test.
# Usage: bash bench/session-continue-lifecycle/run.sh <control|arm> <fixture-dir> <out-file> [model] [control-rev]
#
#   control — session-continue SKILL.md at <control-rev> (default HEAD), via git show
#   arm     — the working-tree SKILL.md (copy under test: this repo's dev copy)
#   model   — claude -p --model value (default sonnet)
#
# Builds a fresh fixture, embeds the skill text verbatim in the prompt, runs the arm with the
# fixture as cwd, writes stdout to <out-file>, then runs check.sh on the output and the ledger.
set -eu
mode="${1:?usage: run.sh <control|arm> <fixture-dir> <out-file> [model] [control-rev]}"
fx="${2:?fixture dir}"
out="${3:?out file}"
model="${4:-sonnet}"
rev="${5:-HEAD}"
here="$(cd "$(dirname "$0")" && pwd)"
repo="$(cd "$here/../.." && pwd)"
skill_rel=plugins/super-bootstrap/skills/session-continue/SKILL.md
case "$mode" in
  control) skill="$(git -C "$repo" show "$rev":"$skill_rel")" ;;
  arm)     skill="$(cat "$repo/$skill_rel")" ;;
  *) echo "unknown mode: $mode" >&2; exit 2 ;;
esac
bash "$here/make-fixture.sh" "$fx" >/dev/null
prompt="$(cat "$here/prompt.txt")

----- SKILL.md (session-continue) -----
$skill"
( cd "$fx" && printf '%s\n' "$prompt" | claude -p --model "$model" --allowedTools Bash \
    --setting-sources project,local --permission-prompts none ) > "$out" 2>&1 || true
bash "$here/check.sh" "$fx" "$out"
