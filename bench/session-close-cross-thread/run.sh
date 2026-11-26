#!/usr/bin/env bash
# run.sh — one headless turn of session-close's finished-card sweep, stopped at the pick.
# Usage: bash bench/session-close-cross-thread/run.sh <control|arm> <fixture-dir>
#
#   control — session-close at CONTROL_REV (env, default HEAD), exported beside the fixture
#   arm     — the working-tree copy (copy under test: this repo's dev copy)
#
# Isolated from the device: no settings source, no MCP, a stub system prompt. Writes <dir>.turn1.txt.
set -u
mode="${1:?usage: run.sh <control|arm> <fixture-dir>}"
fx="${2:?fixture dir}"
here="$(cd "$(dirname "$0")" && pwd)"
repo="$(cd "$here/../.." && pwd)"
CONTROL_REV="${CONTROL_REV:-HEAD}"
close_rel=plugins/super-bootstrap/skills/session-close/SKILL.md
bash "$here/make-fixture.sh" "$fx" >/dev/null || exit 2
fx="$(cd "$fx" && pwd)"
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

----- <skill-base> of the session-close skill -----
$root/plugins/super-bootstrap/skills/session-close"
sys="You are a coding agent. Follow the user's prompt."
( cd "$fx" && printf '%s\n' "$prompt" | claude -p --model sonnet --allowedTools Bash --setting-sources "" \
    --strict-mcp-config --system-prompt "$sys" --permission-prompts none ) > "$fx.turn1.txt" 2>&1
echo "== pick $mode $fx"
bash "$here/score.sh" "$fx.turn1.txt" "$fx"
