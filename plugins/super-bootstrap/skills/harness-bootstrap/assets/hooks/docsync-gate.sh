#!/usr/bin/env bash
# FROZEN docsync-gate v4 (A2 — pre-commit doc-sync gate; TTL + session-key,
# worktree-aware).
# Primary filter: the `if: "Bash(git commit *)"` field on the merged settings
# entry (docsync-gate.hook.json) — verified against the official Claude Code
# hooks reference (PreToolUse `if` input-based filtering), 2026-07-06. Re-confirm
# if the hooks surface moves.
# Defense-in-depth: a CC version that ignores `if` would fire this on EVERY Bash
# call — so the command is re-checked in-script and anything that is not a
# `git commit` passes through untouched.
#
# Checks, in order, for a `git commit` command:
#   1. Drain-managed worktree -> pass (drain's free-commit contract: its worktree
#      agents commit without the token dance). Scoped to drain's actual footprint:
#      a linked worktree (`--git-dir` != `--git-common-dir`) whose toplevel sits
#      under .claude/worktrees/. Any other worktree is gated normally.
#   2. Token missing -> deny.
#   3. Token stale (mtime older than 30 min) -> deny, DISTINCT reason (the scan
#      is stale — re-run it).
#   4. Session mismatch: token content vs stdin `.session_id`, both non-empty
#      and unequal -> deny, DISTINCT reason (scan ran in a different session).
#      Either side empty -> skip this check (graceful TTL-only degradation).
#      `session_id` is a common hook-input field on every event, incl. PreToolUse
#      — verified against the official Claude Code hooks reference, 2026-07-07.
#   5. Otherwise -> pass, consume the token (delete, one-shot).
#
# Token path = the MAIN repo's git-common-dir — matches docsync-scan.sh's write
# location (same resolution, same $CLAUDE_PROJECT_DIR fallback) so scan and gate
# agree even when invoked from a linked worktree.
#
# Deny messages never name a bare token-write command — that framing reads as a
# gate bypass to the permission classifier. Every deny carries $REMEDY (below),
# which names both legitimate paths and why the scan must be its own call.

input="$(cat)"
cmd=$(printf '%s' "$input" | jq -r '.tool_input.command // empty')
# Gate a real `git commit` INVOCATION, not a mention. Match `git` at command
# position (whole-command start, or after ; & |) with `commit` as its same-line
# subcommand: bash `=~` anchors ^ to the whole command, and [:blank:] gaps keep
# the match on one line, so a space-separated "git commit" inside a quoted arg or
# heredoc passes through. (A bare ;/&/| wedged right before the phrase still
# trips — a rare, accepted miss under the bias below.) Trailing boundary skips
# commit-tree/-graph. Defense-in-depth: missing an exotic form (subshell /
# newline-split) is acceptable; a false deny blocking unrelated Bash work is the
# harm here.
_re='(^|[;&|])[[:blank:]]*git[[:blank:]]+([^[:space:]]+[[:blank:]]+)*commit([[:space:]]|$|;|&|\|)'
[[ "$cmd" =~ $_re ]] || exit 0

proj="${CLAUDE_PROJECT_DIR:-}"
if [ -z "$proj" ]; then
  proj="$(git rev-parse --show-toplevel 2>/dev/null)"
fi

gitdir="$(git -C "$proj" rev-parse --path-format=absolute --git-dir 2>/dev/null)"
commondir="$(git -C "$proj" rev-parse --path-format=absolute --git-common-dir 2>/dev/null)"

# 1. Drain-managed worktree -> pass (drain's free-commit contract, scoped to
#    drain's footprint: linked worktree under .claude/worktrees/ only).
if [ -n "$gitdir" ] && [ -n "$commondir" ] && [ "$gitdir" != "$commondir" ]; then
  toplevel="$(git -C "$proj" rev-parse --show-toplevel 2>/dev/null)"
  case "$toplevel" in
    */.claude/worktrees/*) exit 0 ;;
  esac
fi

TOKEN="${commondir:-$proj/.git}/docsync-token"

deny() {
  printf '{"hookSpecificOutput":{"hookEventName":"PreToolUse","permissionDecision":"deny","permissionDecisionReason":"%s"}}\n' "$1"
  exit 0
}

REMEDY="run /super-bootstrap:commit, or run the doc-sync scan (bash .claude/hooks/docsync-scan.sh as its own Bash call, separate from the commit), resolve findings, then commit."

# 2. Token missing -> deny.
if [ ! -f "$TOKEN" ]; then
  deny "doc-sync scan artifact missing — $REMEDY"
fi

# 3. Token stale (mtime older than 30 min) -> deny.
now=$(date +%s)
mtime=$(stat -c %Y "$TOKEN" 2>/dev/null || stat -f %m "$TOKEN" 2>/dev/null)
if [ -n "$mtime" ]; then
  age=$(( now - mtime ))
  if [ "$age" -gt 1800 ]; then
    deny "doc-sync scan is stale (ran more than 30 min ago) — $REMEDY"
  fi
fi

# 4. Session mismatch -> deny (graceful degrade to TTL-only if either side empty).
token_sid="$(cat "$TOKEN" 2>/dev/null)"
stdin_sid=$(printf '%s' "$input" | jq -r '.session_id // empty')
if [ -n "$token_sid" ] && [ -n "$stdin_sid" ] && [ "$token_sid" != "$stdin_sid" ]; then
  deny "doc-sync scan ran in a different session — $REMEDY"
fi

# 5. Pass -> consume (one-shot).
rm -f "$TOKEN"
exit 0
