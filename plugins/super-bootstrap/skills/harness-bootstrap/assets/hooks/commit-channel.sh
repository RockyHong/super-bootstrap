#!/usr/bin/env bash
# FROZEN commit-channel v1 (A6 — single-channel commit guard).
# Primary filter: the `if: "Bash(git commit *)"` field on the merged settings
# entry (commit-channel.hook.json). Defense-in-depth: the command is re-checked
# in-script; anything that is not a `git commit` passes through untouched.
#
# Gate: `agent_type` stdin field = the running subagent's frontmatter name
# (plugin agents may arrive namespaced, e.g. `super-bootstrap:commit`); absent
# for the main session -> "main". Raw `git commit` is confined to the commit
# agent + the orchestrator; every other subagent is routed back to the commit
# door. `git merge` (branch integration) and `git tag` (release stamp) are
# different verbs — orchestrator ops, unaffected. Drain worktree workers run as
# separate processes (agent_type absent -> "main") and pass.
command -v jq >/dev/null 2>&1 || exit 0

input="$(cat)"
cmd=$(printf '%s' "$input" | jq -r '.tool_input.command // empty')
[ -z "$cmd" ] && exit 0

# Match a `git commit` porcelain invocation (allows intervening global opts /
# compound `&&` segments); `commit-graph` / `commit-tree` excluded via the
# trailing boundary. Safe-fail: a rare over-match denies a non-commit worker
# call, never lets a commit through.
printf '%s' "$cmd" | grep -Eq '(^|[^[:alnum:]_-])git[[:space:]]+([^[:space:]]+[[:space:]]+)*commit([[:space:]]|$|;|&)' || exit 0

agent=$(printf '%s' "$input" | jq -r '.agent_type // "main"')
case "$agent" in
  commit|*:commit|main) exit 0 ;;
esac

reason="Single-channel commit: raw git commit runs only in the commit agent or the main session. Finish your task, report the work as built with the file list, and let the orchestrator fire /super-bootstrap:commit. (git merge / git tag are orchestrator ops, unaffected.)"
printf '{"hookSpecificOutput":{"hookEventName":"PreToolUse","permissionDecision":"deny","permissionDecisionReason":"%s"}}\n' "$reason"
exit 0
