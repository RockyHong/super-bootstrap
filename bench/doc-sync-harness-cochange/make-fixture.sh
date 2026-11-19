#!/usr/bin/env bash
# make-fixture.sh — scratch consumer repo for the harness co-change case.
# Usage: bash bench/doc-sync-harness-cochange/make-fixture.sh <dir> <plugin-root>
#
# <plugin-root> holds the copy under test (plugins/super-bootstrap/...). Its claude-md-skeleton.md
# becomes the fixture's CLAUDE.md and, where the root ships one, its harness.md is placed at
# .claude/rules/harness.md, so the consumer's § Doc Sync is the one under test. § Doc Sync sits in
# harness.md since the ownership split and in the skeleton before it (the control root, an export of
# an older commit, has no harness.md); the guard below takes either and refuses neither or both.
# After: one base commit built with plumbing; the session's edit to docs/criteria.md (5 seconds ->
# 10 seconds and named aloud) sits uncommitted in the worktree. `.claude/skills/ep-prep/` is the
# repo's own skill and still narrates 5 seconds; `.claude/skills/clip-cut/` carries a `.served`
# marker and narrates it too.
set -eu
dir="${1:?usage: make-fixture.sh <dir> <plugin-root>}"
root="${2:?usage: make-fixture.sh <dir> <plugin-root>}"
here="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
rm -rf "$dir"
mkdir -p "$dir"
cp -R "$here/fixture/base/." "$dir/"
assets="$root/plugins/super-bootstrap/skills/harness-bootstrap/assets"
sed -e 's/{Project Name}/kettle/' "$assets/claude-md-skeleton.md" > "$dir/CLAUDE.md"
if [ -f "$assets/harness.md" ]; then
  mkdir -p "$dir/.claude/rules"
  tr -d '\r' < "$assets/harness.md" > "$dir/.claude/rules/harness.md"
fi
# the section under test exists in the fixture, once
n=0
for f in "$dir/CLAUDE.md" "$dir/.claude/rules/harness.md"; do
  [ -f "$f" ] && grep -q '^## Doc Sync' "$f" && n=$((n + 1))
done
[ "$n" -eq 1 ] || { echo "FATAL: § Doc Sync found in $n of CLAUDE.md / .claude/rules/harness.md, want 1" >&2; exit 1; }
cd "$dir"
git init -q -b main
git config user.name bench
git config user.email bench@example.invalid
git config core.autocrlf false
git add -A
git update-ref refs/heads/main "$(git commit-tree "$(git write-tree)" -m init)"
cp -R "$here/fixture/session/." "$dir/"
git status --short
