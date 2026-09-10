#!/usr/bin/env bash
# FROZEN commit-channel v6 (single-channel commit guard)
# Spawn pre-filter: the merged settings entry matches `Bash|PowerShell` and carries
# one hook element per tool — `if: "Bash(git *)"` and `if: "PowerShell(git *)"` —
# because a foreign-tool `if` never spawns. Both anchor on the bare `git` command:
# a sub-command-anchored pattern misses git global-flag forms (`git -C <dir> commit`,
# `git --no-pager commit`). Either tool delivers its command as `.tool_input.command`,
# so one script serves both lanes. The real commit filter is the in-script regex
# below; non-commit git calls exit 0.
#
# Gate: `agent_type` stdin field = the running subagent's frontmatter name
# (plugin agents may arrive namespaced, e.g. `super-bootstrap:commit`); absent
# for the main session -> "main". Raw `git commit` is confined to the main
# session (the gateway-inline commit door); every subagent is routed back to
# the door. `git merge` (branch integration) and `git tag` (release stamp) are
# different verbs — orchestrator ops, unaffected. Separate-process workers
# (agent_type absent -> "main") pass.
command -v jq >/dev/null 2>&1 || exit 0

input="$(cat)"
cmd=$(printf '%s' "$input" | jq -r '.tool_input.command // empty')
[ -z "$cmd" ] && exit 0

# Match a `git commit` porcelain INVOCATION at command position (whole-command
# start, or after ; & | or a newline), not a mention: the [:blank:] gaps keep the
# `git`…`commit` span on one line, so a `git commit` substring inside a quoted arg
# on that same line still passes through untouched. A newline is a separator
# because bash `=~` anchors ^ to the whole command only — without it every line
# after the first reads as a mention, and a multi-line payload's `git commit` line
# passes silently. The trade that buys: a heredoc body line beginning `git commit`
# now denies — a visible, recoverable outcome (the worker reads the deny text and
# routes to the door) in place of a silent pass. The trailing boundary
# ([[:space:]] covers newline) skips commit-tree / commit-graph.
_nl=$'\n'
_re='(^|[;&|'"$_nl"'])[[:blank:]]*git[[:blank:]]+([^[:space:]]+[[:blank:]]+)*commit([[:space:]]|$|;|&|\|)'
[[ "$cmd" =~ $_re ]] || exit 0

agent=$(printf '%s' "$input" | jq -r '.agent_type // "main"')
case "$agent" in
  main) exit 0 ;;
esac

reason="Single-channel commit: raw git commit runs only in the main session (the gateway-inline commit door). Finish your task, report the work as built with the file list, and let the gateway fire /super-bootstrap:commit. (git merge / git tag are orchestrator ops, unaffected.)"
printf '{"hookSpecificOutput":{"hookEventName":"PreToolUse","permissionDecision":"deny","permissionDecisionReason":"%s"}}\n' "$reason"
exit 0
