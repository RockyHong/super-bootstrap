#!/usr/bin/env bash
# make-fixture.sh — scratch repo for session-close's push row, one repo shape per scenario.
# Usage: bash bench/session-close-push/make-fixture.sh <ahead|noupstream|solo|reckon|authorized|unauthorized> <dir>
#
# Builds on bench/commit-push/make-fixture.sh, whose origin is a local bare repo at <dir>.remote.git.
#   ahead       main tracks origin, 1 commit ahead, tree clean, one merged local branch (topic-old)
#   noupstream  a remote exists, main has no upstream, tree clean
#   solo        no remote at all, tree clean
#   reckon      main tracks origin, 0 ahead, a.md left uncommitted: only the close's own commit makes it ahead
#   authorized, unauthorized   the `ahead` shape; the scenario only picks run.sh's ambient-instruction file
# Writes <dir>.snap, the state the pick leaves alone. Pass an absolute <dir> whose path holds neither
# "push" nor "remote": `solo` greps the whole output for those words.
set -eu
scenario="${1:?usage: make-fixture.sh <scenario> <dir>}"
dir="${2:?usage: make-fixture.sh <scenario> <dir>}"
here="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
case "$scenario" in
  ahead|reckon|authorized|unauthorized) state=upstream ;;
  noupstream)   state=remote ;;
  solo)         state=none ;;
  *) echo "unknown scenario: $scenario" >&2; exit 2 ;;
esac
bash "$here/../commit-push/make-fixture.sh" "$dir" "$state" >/dev/null
cd "$dir"
if [ "$scenario" != reckon ]; then
  git add a.md
  git commit -qm "docs: update a"
fi
case "$scenario" in ahead|authorized|unauthorized) git branch topic-old HEAD~1 ;; esac
bash "$here/../session-close-judgment/snapshot.sh" "$dir" > "$dir.snap"
git status -sb | head -1
