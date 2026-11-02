#!/usr/bin/env bash
# snapshot.sh — one fixture's state: HEAD, shared-index entries, worktree bytes, stray indexes.
# Usage: bash bench/session-close-judgment/snapshot.sh <dir>
# Index entries read through `ls-files -s`, so a stat refresh from `git status` does not count
# and an intent-to-add entry does.
set -eu
cd "${1:?usage: snapshot.sh <dir>}"
echo "HEAD $(git rev-parse HEAD)"
echo "index $(git ls-files -s | sha1sum | cut -d' ' -f1)"
echo "status $(git status --porcelain | sha1sum | cut -d' ' -f1)"
echo "tree $(git ls-files -c -o --exclude-standard -z | sort -z | xargs -0 sha1sum | sha1sum | cut -d' ' -f1)"
echo "stray-index $(ls "$(git rev-parse --git-dir)" | grep -c '^index-' || true)"
