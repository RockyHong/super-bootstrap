#!/usr/bin/env bash
# FROZEN docsync-gate v2 (A2 — pre-commit doc-sync gate).
# Primary filter: the `if: "Bash(git commit *)"` field on the merged settings
# entry (docsync-gate.hook.json) — verified against the official Claude Code
# hooks reference (PreToolUse `if` input-based filtering), 2026-07-06. Re-confirm
# if the hooks surface moves.
# Defense-in-depth: a CC version that ignores `if` would fire this on EVERY Bash
# call — so the command is re-checked in-script and anything that is not a
# `git commit` passes through untouched.
#
# Gate: .git/docsync-token must exist. The docsync-stamp PostToolUse hook writes
# it as a side-effect when /super-bootstrap:commit's doc-sync scan (docsync-scan.sh)
# runs — proof the scan ran for this session's commit. Present -> consume it
# (delete, one-shot) and allow. Missing -> deny with a one-line reason routing back
# to /super-bootstrap:commit (never a bare stamp command — that framing reads as a
# gate bypass to the permission classifier).

cmd=$(jq -r '.tool_input.command // empty')
case "$cmd" in
  *"git commit"*) ;;
  *) exit 0 ;;
esac

TOKEN="$CLAUDE_PROJECT_DIR/.git/docsync-token"

if [ -f "$TOKEN" ]; then
  rm -f "$TOKEN"
  exit 0
fi

cat <<'JSON'
{"hookSpecificOutput":{"hookEventName":"PreToolUse","permissionDecision":"deny","permissionDecisionReason":"doc-sync artifact missing — run /super-bootstrap:commit (its doc-sync scan clears this gate)."}}
JSON
exit 0
