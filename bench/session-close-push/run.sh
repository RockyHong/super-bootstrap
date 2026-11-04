#!/usr/bin/env bash
# run.sh — one headless walk of session-close's push row: turn 1 stops at the pick, turn 2 runs it.
# Usage: bash bench/session-close-push/run.sh <control|arm> <ahead|noupstream|solo|reckon> <fixture-dir>
#
#   control — session-close, commit and doc-sync-scan at CONTROL_REV, exported beside the fixture
#   arm     — the working-tree copies (copy under test: this repo's dev copy)
#
# Isolated from the device: no settings source, no MCP, a stub system prompt, so a push ask comes from the
# embedded skill text and not from a user-level instruction file. Control and `solo` stop after turn 1:
# neither holds a row to run. Writes <dir>.turn1.txt, <dir>.turn2.txt and <dir>.trace.
set -u
mode="${1:?usage: run.sh <control|arm> <scenario> <fixture-dir>}"
scenario="${2:?scenario}"
fx="${3:?fixture dir}"
here="$(cd "$(dirname "$0")" && pwd)"
repo="$(cd "$here/../.." && pwd)"
CONTROL_REV=bb069c4
close_rel=plugins/super-bootstrap/skills/session-close/SKILL.md
commit_rel=plugins/super-bootstrap/skills/commit/SKILL.md
agent_rel=plugins/super-bootstrap/agents/doc-sync-scan.md
bash "$here/make-fixture.sh" "$scenario" "$fx" >/dev/null || exit 2
fx="$(cd "$fx" && pwd)"
rm -rf "$fx.plugin" "$fx.trace"
case "$mode" in
  control)
    mkdir -p "$fx.plugin"
    git -C "$repo" archive "$CONTROL_REV" plugins/super-bootstrap | tar -x -C "$fx.plugin"
    root="$fx.plugin" ;;
  arm) root="$repo" ;;
  *) echo "unknown mode: $mode" >&2; exit 2 ;;
esac
GIT_TRACE="$(cd "$(dirname "$fx")" && { pwd -W 2>/dev/null || pwd; })/$(basename "$fx").trace"
export GIT_TRACE
if [ "$scenario" = reckon ]; then
  prompt="$(cat "$here/prompt-reckon.txt")

----- SKILL.md (session-close) -----
$(cat "$root/$close_rel")

----- SKILL.md (commit) -----
$(cat "$root/$commit_rel")

----- agents/doc-sync-scan.md -----
$(cat "$root/$agent_rel")

----- <skill-base> of the commit skill -----
$root/plugins/super-bootstrap/skills/commit"
else
  prompt="$(cat "$here/prompt.txt")

----- SKILL.md (session-close) -----
$(cat "$root/$close_rel")"
fi
sys="You are a coding agent. Follow the user's prompt."
( cd "$fx" && printf '%s\n' "$prompt" | claude -p --model sonnet --allowedTools Bash --setting-sources "" \
    --strict-mcp-config --system-prompt "$sys" --permission-prompts none ) > "$fx.turn1.txt" 2>&1
echo "== pick $mode $scenario $fx"
bash "$here/score.sh" "$scenario" "$fx.turn1.txt" "$fx"
[ "$mode" = arm ] && [ "$scenario" != solo ] || exit 0
( cd "$fx" && claude -p --continue --model sonnet --allowedTools Bash,Read,Edit,Write --setting-sources "" \
    --strict-mcp-config --system-prompt "$sys" --permission-prompts none < "$here/prompt-turn2.txt" ) > "$fx.turn2.txt" 2>&1
echo "== walk $mode $scenario $fx"
bash "$here/score-walk.sh" "$scenario" "$fx"
