#!/usr/bin/env bash
# run.sh — one headless arm of the session-close in-flight micro-test.
# Usage: bash bench/session-close-inflight/run.sh <control|arm> <fixture-dir> <out-file>
#
#   control — session-close SKILL.md as of c033fa9 (pre-gate), via git show
#   arm     — the working-tree SKILL.md (copy under test: this repo's dev copy)
#
# Builds a fresh fixture, embeds the skill text verbatim in the prompt, runs the arm with
# the fixture as cwd, writes stdout to <out-file>, then prints the fixture's tree state.
set -eu
mode="${1:?usage: run.sh <control|arm> <fixture-dir> <out-file>}"
fx="${2:?fixture dir}"
out="${3:?out file}"
here="$(cd "$(dirname "$0")" && pwd)"
repo="$(cd "$here/../.." && pwd)"
skill_rel=plugins/super-bootstrap/skills/session-close/SKILL.md
case "$mode" in
  control) skill="$(git -C "$repo" show c033fa9:"$skill_rel")" ;;
  arm)     skill="$(cat "$repo/$skill_rel")" ;;
  *) echo "unknown mode: $mode" >&2; exit 2 ;;
esac
bash "$here/make-fixture.sh" "$fx" >/dev/null
prompt="$(cat "$here/prompt.txt")

----- SKILL.md (session-close) -----
$skill"
( cd "$fx" && printf '%s\n' "$prompt" | claude -p --model haiku --allowedTools Bash \
    --setting-sources project,local --permission-prompts none ) > "$out" 2>&1 || true
echo "--- fixture after run: $fx"
git -C "$fx" log --oneline
git -C "$fx" status --short
