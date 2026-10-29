#!/usr/bin/env bash
# make-fixture.sh — scratch repo for the session-close in-flight gate.
# Usage: bash bench/session-close-inflight/make-fixture.sh <dir>
#
# After: one initial commit (README.md, a.md); a.md modified, unstaged (this session's
# delivered work, so the tree holds a commit move). No remote, no cards, no ledger.
set -eu
dir="${1:?usage: make-fixture.sh <dir>}"
rm -rf "$dir"
mkdir -p "$dir"
cd "$dir"
git init -q -b main
git config user.name bench
git config user.email bench@example.invalid
git config core.autocrlf false
for f in README a; do printf '%s v1\n' "$f" > "$f.md"; done
git add README.md a.md
git commit -qm "init"
printf 'a v2\n' > a.md
git status --short
