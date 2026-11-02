#!/usr/bin/env bash
# make-fixture.sh — scratch repo for session-close's judgment seam.
# Usage: bash bench/session-close-judgment/make-fixture.sh <dir>
#
# After: one base commit (fixture/base), built with plumbing so a dispatched builder can run
# this script; fixture/session copied over it, unstaged and untracked: this session's work
# (docs/operations.md modified, docs/recovery.md new). The shared index holds the base tree
# only. <dir>.snap holds the state assertion (d) compares against.
set -eu
dir="${1:?usage: make-fixture.sh <dir>}"
here="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
rm -rf "$dir" "$dir.snap"
mkdir -p "$dir"
cp -R "$here/fixture/base/." "$dir/"
cd "$dir"
git init -q -b main
git config user.name bench
git config user.email bench@example.invalid
git config core.autocrlf false
git add -A
tree="$(git write-tree)"
base_commit="$(git commit-tree "$tree" -m init)"
git update-ref refs/heads/main "$base_commit"
cp -R "$here/fixture/session/." "$dir/"
bash "$here/snapshot.sh" "$dir" > "$dir.snap"
git status --short
