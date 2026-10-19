#!/usr/bin/env bash
# FROZEN commit-channel v8 (single-channel commit guard)
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
# for the main session -> "main". Three verbs — `git commit`, `git merge
# --continue`, `git rebase --continue` — are confined to the main session (the
# gateway-inline commit door); every subagent is routed back to the door. A
# conflict resolver leaves the merge or rebase staged and reports; the
# orchestrator concludes it. Every other git verb passes — merge/rebase start
# and `--abort`, `cherry-pick`, `revert`, `am`, `tag`. Separate-process workers
# (agent_type absent -> "main") pass.
command -v jq >/dev/null 2>&1 || exit 0

input="$(cat)"
cmd=$(printf '%s' "$input" | jq -r '.tool_input.command // empty')
[ -z "$cmd" ] && exit 0

# Match a commit-writing git INVOCATION — `commit`, `merge --continue`,
# `rebase --continue` — at command position (whole-command start, or after ; & |
# or a newline, past any leading `VAR=value` assignments such as
# `GIT_EDITOR=true`), not a mention: the [:blank:] gaps keep the
# `git`…`commit` span on one line, so a `git commit` substring inside a quoted arg
# on that same line still passes through untouched. A newline is a separator
# because bash `=~` anchors ^ to the whole command only — without it every line
# after the first reads as a mention, and a multi-line payload's `git commit` line
# passes silently. The trade that buys: a heredoc body line beginning `git commit`
# now denies — a visible, recoverable outcome (the worker reads the deny text and
# routes to the door) in place of a silent pass. The trailing boundary
# ([[:space:]] covers newline) skips commit-tree / commit-graph. The global-flag
# walker stops at `; & |` (the same three characters the leading separator
# alternation treats as boundaries), so it never reaches past a chain or pipe
# into a later `commit` mention on the same line — a git-anchored read-only line
# that later mentions "commit" (in a grep pattern, an echo label, …) is not an
# invocation and passes. Accepted residual of that stop: a real invocation whose
# global-flag value carries one of the three characters (`git -c "x;y" commit`)
# is not walked and passes silently — an exotic form no run has produced. The
# assignment walker has the same residual: a quoted value with a space
# (`GIT_EDITOR="vim -f" git merge --continue`) and the `env X=y git …` form are
# not walked and pass silently.
_nl=$'\n'
_re='(^|[;&|'"$_nl"'])[[:blank:]]*([A-Za-z_][A-Za-z0-9_]*=[^[:space:];&|]*[[:blank:]]+)*git[[:blank:]]+([^[:space:];&|]+[[:blank:]]+)*(commit|merge[[:blank:]]+--continue|rebase[[:blank:]]+--continue)([[:space:]]|$|;|&|\|)'
[[ "$cmd" =~ $_re ]] || exit 0

agent=$(printf '%s' "$input" | jq -r '.agent_type // "main"')
case "$agent" in
  main) exit 0 ;;
esac

reason="Single-channel commit: git commit, git merge --continue and git rebase --continue run only in the main session (the gateway-inline commit door). Finish your task, report the work as built with the file list, and let the gateway fire /super-bootstrap:commit. Resolving a merge or rebase conflict: leave the resolution staged and report; the orchestrator concludes it."
printf '{"hookSpecificOutput":{"hookEventName":"PreToolUse","permissionDecision":"deny","permissionDecisionReason":"%s"}}\n' "$reason"
exit 0
