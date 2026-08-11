#!/usr/bin/env bash
# v2-oracle injector — simulates PERFECT typed-edge selection: inline ONLY the
# one hard-edge neighbor's constraint sentence (drawn from the neighbor doc),
# nothing else. Control probe (no hard-edge neighbor) → inject nothing. This is
# the ceiling arm: it measures whether inlined hard-edge text beats baseline /
# v1-pointer, with zero over-fetch tax. Exits 0 on every path (UserPromptSubmit
# erase-prompt safety).
set -uo pipefail

input="$(cat)"
prompt="$(printf '%s' "$input" | jq -r '.prompt // empty' 2>/dev/null)"
[ -n "$prompt" ] || exit 0

ctx=""
case "$prompt" in
  *"reviews to actually run"*|*"run /code-review in parallel"*)
    # P1 keyed neighbor: subprocess-tool-gates.md (hard-edge sentence)
    ctx="Bundled CLI skills (e.g. /code-review, /security-review) invoked in a \`claude -p\` subprocess route through the permission-gated Skill tool and are DENIED without an allow-rule (3 consecutive / 20 total denials abort the run). A denied call silently diverts to any fallback path, so the contract weakens with no visible error. Fix: add --allowedTools \"Skill\" (or Skill(*) in the spawn settings) plus grants for the tools the skill itself needs (Read/Edit/Bash). Project skills in .claude/skills/ are auto-trusted but version-fragile." ;;
  *"only writes inside its own worktree"*)
    # P2 keyed neighbor: hook-agent-type.md (hard-edge sentence)
    ctx="Per-subagent enforcement of the Edit/Write boundary is a PreToolUse(Edit|Write) hook that reads agent_id / agent_type / cwd off the stdin JSON and allows or denies by actor+path. The OS sandbox is per-PROCESS (not per-subagent), and permissions.deny does not catch writes routed through a Bash subprocess. A hard OS boundary requires separate \`claude -p --worktree\` processes." ;;
  *"CLAUDE_FILE_PATH"*)
    # P3 control: no hard-edge neighbor — perfect selection injects nothing.
    exit 0 ;;
esac

[ -n "$ctx" ] || exit 0
jq -cn --arg c "[doc-graph v2] authored hard-edge constraint for this task -- treat as ground truth:
$ctx" '{hookSpecificOutput:{hookEventName:"UserPromptSubmit",additionalContext:$c}}' 2>/dev/null
exit 0
