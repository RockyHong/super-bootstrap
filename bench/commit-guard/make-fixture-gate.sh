#!/usr/bin/env bash
# make-fixture-gate.sh — scratch repo for the hunk-grain gate arm: one harness file holding two
# writers' uncommitted hunks, plus another writer's dirty harness file.
# Usage: bash bench/commit-guard/make-fixture-gate.sh <dir>
#
# After: commit `init` (README.md CLAUDE.md .claude/rules/r.md); r.md modified, unstaged, with
# this session's `session line` after line 2 and the other writer's `other line` after line 18
# (far apart: `git diff` shows two hunks); CLAUDE.md modified, unstaged, by the other writer
# only. Both are paths the harness-audit gate watches (`.claude/rules/*`, `CLAUDE.md`).
set -eu
dir="${1:?usage: make-fixture-gate.sh <dir>}"
rm -rf "$dir"
mkdir -p "$dir/.claude/rules"
cd "$dir"
git init -q
git config user.name bench
git config user.email bench@example.invalid
git config core.autocrlf false
printf 'README v1\n' > README.md
printf 'CLAUDE v1\n' > CLAUDE.md
i=1; : > .claude/rules/r.md
while [ "$i" -le 20 ]; do printf 'rule line %s\n' "$i" >> .claude/rules/r.md; i=$((i+1)); done
git add README.md CLAUDE.md .claude/rules/r.md
git commit -qm "init"
sed -e '2a\
session line' -e '18a\
other line' .claude/rules/r.md > .claude/rules/r.md.new
mv .claude/rules/r.md.new .claude/rules/r.md
printf 'CLAUDE v1\nother writer line\n' > CLAUDE.md
git status --short
