#!/usr/bin/env bash
# FROZEN docsync-stamp v1 (A4 — doc-sync token side-effect writer).
# PostToolUse on Bash (matcher, see docsync-stamp.hook.json). Writes
# .git/docsync-token ONLY when the Bash call that just ran INVOKED the doc-sync
# scan (`bash …/docsync-scan.sh`) — making the token a genuine side-effect of
# running the scan, not something the agent stamps by hand.
#
# Invocation vs mention: the match is anchored to a `bash …docsync-scan.sh`
# invocation shape, NOT a bare substring. A command that merely NAMES the file
# (cat/grep/echo, or a subagent reading it) does not stamp — else any incidental
# mention would silently plant the one-shot gate pass.
#
# Filtering: the `if: "Bash(*docsync-scan.sh*)"` field on the merged settings
# entry is a coarse pre-filter (PostToolUse `if` is supported — verified against
# the official Claude Code hooks reference, 2026-07-07). The IN-SCRIPT match below
# is AUTHORITATIVE: it does the precise invocation-shape check the permission glob
# can't express (quote handling), and it holds even if a CC build fires this on
# every Bash call. PostToolUse hooks receive `.tool_input.command` (same ref) and
# cannot deny — this hook only ever writes the file or does nothing. Cheap on the
# no-match path: one jq parse, no file reads.
#
# Self-containment (hard constraint): references only consumer-available surfaces
# (jq, git dir under $CLAUDE_PROJECT_DIR) — no super-bootstrap-specific state, no
# device-only skill names.

cmd=$(jq -r '.tool_input.command // empty')

# Normalize: drop trailing whitespace, then one trailing quote — so the skill's
# quoted invocation (bash "…/docsync-scan.sh") matches the same as an unquoted one.
cmd="${cmd%"${cmd##*[![:space:]]}"}"
cmd="${cmd%[\"\']}"

# Stamp only on an actual `bash …docsync-scan.sh` invocation (leading `bash `,
# scan basename as the final token). A bare mention fails both anchors.
case "$cmd" in
  bash\ *docsync-scan.sh) : > "$CLAUDE_PROJECT_DIR/.git/docsync-token" ;;
  *) ;;
esac
exit 0
