#!/usr/bin/env bash
# make-fixture.sh — scratch repo for session-close's moves.
# Usage: bash bench/session-close-moves/make-fixture.sh <full|resolve|fixnow> <dir>
#
# After: one base commit built with plumbing; another writer's staged notes/supplier.md and dirty
# notes/rota.md on every scenario. `full` adds this session's work (docs/operations.md modified,
# docs/shutdown.md new). `fixnow` drops the two finished cards. <dir>.snap holds the state the pick
# leaves alone; <dir>.foreign holds the other writer's blobs; <dir>.base holds the base sha.
set -eu
scenario="${1:?usage: make-fixture.sh <full|resolve|fixnow> <dir>}"
dir="${2:?usage: make-fixture.sh <full|resolve|fixnow> <dir>}"
here="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
rm -rf "$dir" "$dir.snap" "$dir.foreign" "$dir.base"
mkdir -p "$dir"
cp -R "$here/fixture/base/." "$dir/"
[ "$scenario" != fixnow ] || rm -f "$dir/docs/work/BUG-rt51.md" "$dir/docs/work/BUG-sd22.md"
cd "$dir"
git init -q -b main
git config user.name bench
git config user.email bench@example.invalid
git config core.autocrlf false
git add -A
git update-ref refs/heads/main "$(git commit-tree "$(git write-tree)" -m init)"
printf 'Backup supplier: Orlo.\n' >> notes/supplier.md
git add notes/supplier.md
printf 'Tuesday: Ben.\n' >> notes/rota.md
if [ "$scenario" = full ]; then cp -R "$here/fixture/session/." "$dir/"; fi
git rev-parse HEAD > "$dir.base"
{ git rev-parse :notes/supplier.md; git hash-object notes/rota.md; } > "$dir.foreign"
bash "$here/../session-close-judgment/snapshot.sh" "$dir" > "$dir.snap"
git status --short
