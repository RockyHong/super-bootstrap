#!/usr/bin/env bash
# run.sh — one headless run of the session-close judgment micro-test.
# Usage: bash bench/session-close-judgment/run.sh <control|arm> <fixture-dir> <out-file>
#
#   control — session-close + commit SKILL.md + doc-sync-scan at CONTROL_REV, with <skill-base>
#             = that revision's commit skill, exported beside the fixture
#   arm     — the working-tree copies (copy under test: this repo's dev copy)
#
# Builds a fresh fixture, embeds the text verbatim in the prompt, runs with the fixture as cwd,
# writes stdout to <out-file>, then scores the run with score.sh.
set -eu
mode="${1:?usage: run.sh <control|arm> <fixture-dir> <out-file>}"
fx="${2:?fixture dir}"
out="${3:?out file}"
here="$(cd "$(dirname "$0")" && pwd)"
repo="$(cd "$here/../.." && pwd)"
CONTROL_REV=8cb9c9f
close_rel=plugins/super-bootstrap/skills/session-close/SKILL.md
commit_rel=plugins/super-bootstrap/skills/commit/SKILL.md
agent_rel=plugins/super-bootstrap/agents/doc-sync-scan.md
bash "$here/make-fixture.sh" "$fx" >/dev/null
rm -rf "$fx.plugin"
case "$mode" in
  control)
    mkdir -p "$fx.plugin"
    git -C "$repo" archive "$CONTROL_REV" plugins/super-bootstrap | tar -x -C "$fx.plugin"
    root="$fx.plugin" ;;
  arm) root="$repo" ;;
  *) echo "unknown mode: $mode" >&2; exit 2 ;;
esac
prompt="$(cat "$here/prompt.txt")

----- SKILL.md (session-close) -----
$(cat "$root/$close_rel")

----- SKILL.md (commit) -----
$(cat "$root/$commit_rel")

----- agents/doc-sync-scan.md -----
$(cat "$root/$agent_rel")

----- <skill-base> of the session-close skill -----
$root/plugins/super-bootstrap/skills/session-close

----- <skill-base> of the commit skill -----
$root/plugins/super-bootstrap/skills/commit"
( cd "$fx" && printf '%s\n' "$prompt" | claude -p --model sonnet --allowedTools Bash \
    --setting-sources project,local --permission-prompts none ) > "$out" 2>&1 || true
bash "$here/score.sh" "$out" "$fx" || true
