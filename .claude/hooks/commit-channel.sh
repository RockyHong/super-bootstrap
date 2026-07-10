#!/usr/bin/env bash
# FROZEN commit-channel v3 (A6 — single-channel commit guard; v2 command-position matcher DEBT-010; v3 gateway-inline commit door, no commit-agent carve-out, DEBT-019).
# Primary filter: the `if: "Bash(git commit *)"` field on the merged settings
# entry (commit-channel.hook.json). Defense-in-depth: the command is re-checked
# in-script; anything that is not a `git commit` passes through untouched.
#
# Gate: `agent_type` stdin field = the running subagent's frontmatter name
# (plugin agents may arrive namespaced, e.g. `super-bootstrap:commit`); absent
# for the main session -> "main". Raw `git commit` is confined to the main
# session (the gateway-inline commit door); every subagent is routed back to
# the door. `git merge` (branch integration) and `git tag` (release stamp) are
# different verbs — orchestrator ops, unaffected. Drain worktree workers run as
# separate processes (agent_type absent -> "main") and pass.
command -v jq >/dev/null 2>&1 || exit 0

input="$(cat)"
cmd=$(printf '%s' "$input" | jq -r '.tool_input.command // empty')
[ -z "$cmd" ] && exit 0

# Match a `git commit` porcelain INVOCATION at command position (whole-command
# start, or after ; & |), not a mention: bash `=~` anchors ^ to the whole command
# and [:blank:] gaps keep the match on one line, so a `git commit` substring inside
# a quoted arg / heredoc passes through untouched. Trailing boundary skips
# commit-tree / commit-graph. The safety property is preserved: a real commit
# invocation is always at command position, so it is still caught and routed to the
# door; only non-commit mentions that used to false-deny now pass.
_re='(^|[;&|])[[:blank:]]*git[[:blank:]]+([^[:space:]]+[[:blank:]]+)*commit([[:space:]]|$|;|&|\|)'
[[ "$cmd" =~ $_re ]] || exit 0

agent=$(printf '%s' "$input" | jq -r '.agent_type // "main"')
case "$agent" in
  main) exit 0 ;;
esac

reason="Single-channel commit: raw git commit runs only in the main session (the gateway-inline commit door). Finish your task, report the work as built with the file list, and let the gateway fire /super-bootstrap:commit. (git merge / git tag are orchestrator ops, unaffected.)"
printf '{"hookSpecificOutput":{"hookEventName":"PreToolUse","permissionDecision":"deny","permissionDecisionReason":"%s"}}\n' "$reason"
exit 0
