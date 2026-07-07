#!/usr/bin/env bash
# FROZEN docsync-scan v2 (A3 — doc-sync scan surface enumerator + self-stamp).
# Invoked as its own Bash call (not chained with the commit):
#   bash "$CLAUDE_PROJECT_DIR/.claude/hooks/docsync-scan.sh"
# Running the scan IS the stamp — no separate stamp hook exists. The skill
# (this script) produces the artifact; the gate only checks.
# Two jobs, one action:
#   1. Print the changed-files surface (staged, unstaged, untracked) so the agent
#      grounds its staleness judgment on the REAL diff, not a guess.
#   2. Write .git/docsync-token as an internal side-effect of executing — proof
#      the scan ran, carrying the session id for the gate's session check.
#      $CLAUDE_CODE_SESSION_ID is undocumented in the official env-vars reference
#      but live-verified equal to the hook-input session_id (2026-07-07); when
#      absent the token is empty and the gate degrades to TTL-only.
# Always exits 0: a repo with no commits, or any git error, must not break the
# scan — an empty surface is a valid answer.
#
# Root resolution: $CLAUDE_PROJECT_DIR when set, else `git rev-parse
# --show-toplevel` from cwd (fixes a live exit-127 bug — agent-issued Bash calls
# don't always inherit $CLAUDE_PROJECT_DIR).
# Token path: the MAIN repo's git dir (`git rev-parse --path-format=absolute
# --git-common-dir`, falling back to `--git-dir`) — so the token lands in one
# place regardless of whether the scan is invoked from a linked worktree.
#
# Self-containment (hard constraint): references only consumer-available surfaces
# (git, $CLAUDE_PROJECT_DIR) — no super-bootstrap-specific state, no device-only
# skill names.

proj="${CLAUDE_PROJECT_DIR:-}"
if [ -z "$proj" ]; then
  proj="$(git rev-parse --show-toplevel 2>/dev/null)"
fi

echo "== doc-sync scan surface =="
echo "-- staged --"
git -C "$proj" diff --name-only --staged 2>/dev/null
echo "-- unstaged --"
git -C "$proj" diff --name-only 2>/dev/null
echo "-- untracked --"
git -C "$proj" ls-files --others --exclude-standard 2>/dev/null

gitdir="$(git -C "$proj" rev-parse --path-format=absolute --git-common-dir 2>/dev/null)"
if [ -z "$gitdir" ]; then
  gitdir="$(git -C "$proj" rev-parse --path-format=absolute --git-dir 2>/dev/null)"
fi
if [ -n "$gitdir" ]; then
  printf '%s' "${CLAUDE_CODE_SESSION_ID:-}" > "$gitdir/docsync-token"
fi

exit 0
