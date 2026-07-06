#!/usr/bin/env bash
# FROZEN harness-grounding hook (A1 — harness-edit grounding nudge).
# PreToolUse on Edit|Write (matcher, see harness-grounding.hook.json). Fires on
# EVERY Edit/Write in the session, so the non-match path must stay cheap: one jq
# parse + pure bash string match, no file reads. Non-blocking by design — this
# script only ever emits additionalContext or exits silently. It must never emit
# a deny/ask permissionDecision.
#
# Self-containment (hard constraint): the injected text below may reference ONLY
# surfaces harness-bootstrap itself stamps (.claude/rules/, docs/) — never
# device-only skills such as /load-harness-principles, which does not exist on
# consumer repos.

fp=$(jq -r '.tool_input.file_path // empty')

# Normalize backslashes (native Windows paths) to forward slashes for matching.
fp="${fp//\\//}"
proj="${CLAUDE_PROJECT_DIR//\\//}"

case "$fp" in
  "$proj/CLAUDE.md"|CLAUDE.md|*/.claude/rules/*|.claude/rules/*|*/.claude/skills/*|.claude/skills/*|*/.claude/agents/*|.claude/agents/*)
    cat <<'JSON'
{"hookSpecificOutput":{"hookEventName":"PreToolUse","additionalContext":"Harness edit detected. Before editing: check git log for prior work on this surface; read the repo's .claude/rules/index.md (or the rule file matching this path); harness edits carry a verify pass after this one."}}
JSON
    exit 0
    ;;
  *)
    exit 0
    ;;
esac
