#!/usr/bin/env bash
# make-fixture.sh — scratch consumer repo for the harness co-change case.
# Usage: bash bench/doc-sync-harness-cochange/make-fixture.sh <dir> <plugin-root>
#
# <plugin-root> holds the copy under test (plugins/super-bootstrap/...). Its claude-md-skeleton.md
# becomes the fixture's CLAUDE.md, so the consumer's § Doc Sync is the one under test.
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
sed -e 's/{Project Name}/kettle/' "$root/plugins/super-bootstrap/skills/harness-bootstrap/assets/claude-md-skeleton.md" > "$dir/CLAUDE.md"
cd "$dir"
git init -q -b main
git config user.name bench
git config user.email bench@example.invalid
git config core.autocrlf false
git add -A
git update-ref refs/heads/main "$(git commit-tree "$(git write-tree)" -m init)"
cp -R "$here/fixture/session/." "$dir/"
git status --short
