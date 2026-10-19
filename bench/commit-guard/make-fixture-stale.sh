#!/usr/bin/env bash
# make-fixture-stale.sh — scratch repo whose shared index went stale under an out-of-door commit.
# Usage: bash bench/commit-guard/make-fixture-stale.sh <dir> [--on-list]
#
# After: commit `init` (README.md a.md b.md other.md shared.md), then a second commit made by
# another writer through a private GIT_INDEX_FILE (other.md v2, new file new.md; with --on-list
# also a line appended to shared.md). The shared .git/index still holds that commit's paths at
# their `init` blobs and lacks new.md; the worktree matches HEAD for them. This session's work:
# a.md + b.md modified, unstaged; with --on-list also a line of its own appended to shared.md,
# so the stale path sits on the session list (a.md, b.md, shared.md).
set -eu
dir="${1:?usage: make-fixture-stale.sh <dir> [--on-list]}"
on_list="${2:-}"
rm -rf "$dir"
mkdir -p "$dir"
cd "$dir"
git init -q
git config user.name bench
git config user.email bench@example.invalid
git config core.autocrlf false
for f in README a b other shared; do printf '%s v1\n' "$f" > "$f.md"; done
git add README.md a.md b.md other.md shared.md
git commit -qm "init"
# The other writer's commit, staged and committed through its own index only.
priv="$(git rev-parse --git-dir)/index-w2"
printf 'other v2\n' > other.md
printf 'new v1\n' > new.md
paths="other.md new.md"
if [ "$on_list" = "--on-list" ]; then
  printf 'other line\n' >> shared.md
  paths="$paths shared.md"
fi
GIT_INDEX_FILE="$priv" git read-tree HEAD
# shellcheck disable=SC2086
GIT_INDEX_FILE="$priv" git add -- $paths
GIT_INDEX_FILE="$priv" git commit -qm "docs: update other, add new"
rm -f "$priv"
# This session's work.
printf 'a v2\n' > a.md
printf 'b v2\n' > b.md
if [ "$on_list" = "--on-list" ]; then printf 'session line\n' >> shared.md; fi
git status --short
