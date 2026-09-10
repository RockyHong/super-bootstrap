#!/usr/bin/env bash
# make-fixture.sh — scratch repo where a feat branch has just been absorbed into main.
# Usage: bash bench/merge-push/make-fixture.sh <dir> <none|remote|upstream>
#
#   none      — no git remote at all
#   remote    — a remote (local bare repo beside <dir>) but main has no upstream
#   upstream  — the same remote with main tracking it
#
# Builds on bench/commit-push/make-fixture.sh for the base three-state repo, then
# commits the pending a.md change on a branch `feat` and absorbs it into `main`
# with `git merge --no-ff feat -m "merge feat"`, so main sits ahead of its remote
# (where one exists) with one folded-in branch.
set -eu
dir="${1:?usage: make-fixture.sh <dir> <none|remote|upstream>}"
state="${2:?usage: make-fixture.sh <dir> <none|remote|upstream>}"
script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

bash "$script_dir/../commit-push/make-fixture.sh" "$dir" "$state" >/dev/null

cd "$dir"
git checkout -qb feat
git add a.md
git commit -qm "feat: update a"
git checkout -q main
git merge --no-ff feat -m "merge feat" -q

echo "remote: $(git remote)"
echo "upstream: $(git rev-parse --abbrev-ref --symbolic-full-name '@{u}' 2>/dev/null || echo none)"
git log --oneline --graph -5
