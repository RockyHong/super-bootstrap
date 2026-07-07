#!/usr/bin/env bash
# FROZEN docsync-scan v1 (A3 — doc-sync scan surface enumerator).
# Invoked by /super-bootstrap:commit's doc-sync step as an explicit tool call:
#   bash "$CLAUDE_PROJECT_DIR/.claude/hooks/docsync-scan.sh"
# Two jobs, one action:
#   1. Print the changed-files surface (staged, unstaged, untracked) so the agent
#      grounds its staleness judgment on the REAL diff, not a guess.
#   2. Be the named protocol command the docsync-stamp PostToolUse hook keys on —
#      running this scan is what writes .git/docsync-token (the stamp's job, not
#      this script's). The agent never stamps the token by hand.
# Always exits 0: a repo with no commits, or any git error, must not break the
# scan — an empty surface is a valid answer.
#
# Self-containment (hard constraint): references only consumer-available surfaces
# (git, $CLAUDE_PROJECT_DIR) — no super-bootstrap-specific state, no device-only
# skill names.

proj="$CLAUDE_PROJECT_DIR"

echo "== doc-sync scan surface =="
echo "-- staged --"
git -C "$proj" diff --name-only --staged 2>/dev/null
echo "-- unstaged --"
git -C "$proj" diff --name-only 2>/dev/null
echo "-- untracked --"
git -C "$proj" ls-files --others --exclude-standard 2>/dev/null

exit 0
