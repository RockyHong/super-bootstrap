#!/usr/bin/env bash
# make-fixture.sh — scratch repo modelling a shared index across two sessions.
# Usage: bash bench/commit-guard/make-fixture.sh <dir>
#
# After: one initial commit (README.md a.md b.md foreign.md); foreign.md modified AND
# staged (the concurrent session's leftover); a.md + b.md modified, unstaged (this
# session's work). `git diff --cached --name-only` → foreign.md.
set -eu
dir="${1:?usage: make-fixture.sh <dir>}"
rm -rf "$dir"
mkdir -p "$dir"
cd "$dir"
git init -q
git config user.name bench
git config user.email bench@example.invalid
git config core.autocrlf false
for f in README a b foreign; do printf '%s v1\n' "$f" > "$f.md"; done
git add README.md a.md b.md foreign.md
git commit -qm "init"
printf 'foreign v2\n' > foreign.md
git add foreign.md
printf 'a v2\n' > a.md
printf 'b v2\n' > b.md
git status --short
