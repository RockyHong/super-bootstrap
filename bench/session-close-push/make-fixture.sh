#!/usr/bin/env bash
# make-fixture.sh — scratch repo for session-close's push stance.
# Usage: bash bench/session-close-push/make-fixture.sh <dir>
#
# Builds on bench/commit-push/make-fixture.sh in the `upstream` state (local bare repo
# beside <dir> as origin, main tracking it), then commits the pending a.md change, so the
# tree is clean and main sits 1 commit ahead of origin/main. No cards, no ledger.
set -eu
dir="${1:?usage: make-fixture.sh <dir>}"
script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
bash "$script_dir/../commit-push/make-fixture.sh" "$dir" upstream >/dev/null
cd "$dir"
git add a.md
git commit -qm "docs: update a"
git status -sb | head -1
