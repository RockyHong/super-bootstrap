#!/usr/bin/env bash
# L1 unit tests for the autorun PreToolUse(Read) worktree guard.
# Zero session dependency: extracts the command string from the plugin asset
# (source of truth; the .claude/settings.json entry is a deep-equal copy),
# pipes fake hook-input JSON through it, and checks the exit code.
#
# Usage: bash tests/read-hook.test.sh
set -u

REPO="$(cd "$(dirname "$0")/.." && pwd)"
ASSET="$REPO/plugins/super-bootstrap/skills/autorun/assets/read-hook.json"
CMD=$(jq -r '.hooks[0].command' "$ASSET")

MAIN_DIR="/x/repo"
WT_DIR="/x/repo/.claude/worktrees/autorun-ab12"
WT_FILE="/x/repo/.claude/worktrees/autorun-ab12/src/a.md"
OTHER_FILE="/x/repo/src/a.md"

pass=0; fail=0
run_hook() { # <project_dir> <file_path> [agent_id] ; echoes exit code
  local pd="$1" fp="$2" aid="${3:-}" payload
  if [ -n "$aid" ]; then
    payload=$(jq -cn --arg f "$fp" --arg a "$aid" \
      '{tool_name:"Read", tool_input:{file_path:$f}, agent_id:$a, agent_type:"general-purpose"}')
  else
    payload=$(jq -cn --arg f "$fp" '{tool_name:"Read", tool_input:{file_path:$f}}')
  fi
  printf '%s' "$payload" | CLAUDE_PROJECT_DIR="$pd" bash -c "$CMD" 2>/dev/null
  echo $?
}
expect() { # <desc> <want> <got>
  if [ "$2" = "$3" ]; then pass=$((pass+1)); echo "  ok: $1"
  else fail=$((fail+1)); echo "  FAIL: $1 (want exit $2, got exit $3)"; fi
}

echo "== read-hook: worktree Read guard =="
expect "(a) main session Read under .claude/worktrees/ -> blocked" 2 "$(run_hook "$MAIN_DIR" "$WT_FILE")"
expect "(b) subagent (agent_id present) Read under .claude/worktrees/ -> passes" 0 "$(run_hook "$MAIN_DIR" "$WT_FILE" "agent-123")"
expect "(c) main session Read outside worktrees -> passes" 0 "$(run_hook "$MAIN_DIR" "$OTHER_FILE")"
expect "(d) CLAUDE_PROJECT_DIR inside a worktree -> passes" 0 "$(run_hook "$WT_DIR" "$WT_FILE")"
expect "(e) Windows-style backslash worktree path, main session -> blocked" 2 "$(run_hook 'C:\x\repo' 'C:\x\repo\.claude\worktrees\autorun-ab12\a.md')"
empty_aid=$(jq -cn --arg f "$WT_FILE" '{tool_name:"Read", tool_input:{file_path:$f}, agent_id:""}' \
  | CLAUDE_PROJECT_DIR="$MAIN_DIR" bash -c "$CMD" 2>/dev/null; echo $?)
expect "(f) empty agent_id reads as main session, Read under .claude/worktrees/ -> blocked" 2 "$empty_aid"

echo "== dogfood copy =="
pick='.hooks.PreToolUse[] | select(.matcher == "Read") | {matcher, hooks}'
if [ "$(jq -cS "$pick" "$REPO/.claude/settings.json")" = "$(jq -cS '{matcher, hooks}' "$ASSET")" ]; then
  pass=$((pass+1)); echo "  ok: (g) .claude/settings.json Read entry deep-equals the asset"
else
  fail=$((fail+1)); echo "  FAIL: (g) .claude/settings.json Read entry differs from the asset"
fi

echo "== $pass passed, $fail failed =="
[ "$fail" -eq 0 ]
