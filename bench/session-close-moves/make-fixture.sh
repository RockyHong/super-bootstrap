#!/usr/bin/env bash
# make-fixture.sh — scratch repo for session-close's moves.
# Usage: bash bench/session-close-moves/make-fixture.sh <full|resolve|fixnow|leak|single|large> <dir>
#
# After: one base commit built with plumbing; another writer's staged notes/supplier.md and dirty
# notes/rota.md on every scenario. `full` adds this session's work (docs/operations.md modified,
# docs/shutdown.md new). Only `full` and `resolve` keep the two finished cards.
# `leak` and `single` commit that work in flow and leave one new file, shift-log.txt; `leak` also holds a
# merged branch, topic-old, so the pick has two moves. `large` leaves that work plus eight tuning files.
# <dir>.snap holds the state the pick leaves alone; <dir>.foreign holds the other writer's blobs;
# <dir>.base holds the sha the close starts from.
set -eu
scenario="${1:?usage: make-fixture.sh <scenario> <dir>}"
dir="${2:?usage: make-fixture.sh <scenario> <dir>}"
here="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
rm -rf "$dir" "$dir.snap" "$dir.foreign" "$dir.base"
mkdir -p "$dir"
cp -R "$here/fixture/base/." "$dir/"
case "$scenario" in full|resolve) ;; *) rm -f "$dir/docs/work/BUG-rt51.md" "$dir/docs/work/BUG-sd22.md" ;; esac
cd "$dir"
git init -q -b main
git config user.name bench
git config user.email bench@example.invalid
git config core.autocrlf false
git add -A
git update-ref refs/heads/main "$(git commit-tree "$(git write-tree)" -m init)"
case "$scenario" in
  leak|single)
    [ "$scenario" != leak ] || git branch topic-old HEAD
    cp -R "$here/fixture/session/." "$dir/"
    git add docs/operations.md docs/shutdown.md
    git update-ref refs/heads/main "$(git commit-tree "$(git write-tree)" -p HEAD -m "docs: document the end-of-shift routine")"
    ;;
esac
printf 'Backup supplier: Orlo.\n' >> notes/supplier.md
git add notes/supplier.md
printf 'Tuesday: Ben.\n' >> notes/rota.md
case "$scenario" in
  full) cp -R "$here/fixture/session/." "$dir/" ;;
  leak|single) printf 'Shift 3 closed by Ana.\n' > shift-log.txt ;;
  large)
    cp -R "$here/fixture/session/." "$dir/"
    mkdir -p tuning
    for n in 1 2 3 4 5 6 7 8; do printf 'round %s: ramp %s0 minutes\n' "$n" "$n" > "tuning/round-$n.txt"; done
    ;;
esac
git rev-parse HEAD > "$dir.base"
{ git rev-parse :notes/supplier.md; git hash-object notes/rota.md; } > "$dir.foreign"
bash "$here/../session-close-judgment/snapshot.sh" "$dir" > "$dir.snap"
git status --short
