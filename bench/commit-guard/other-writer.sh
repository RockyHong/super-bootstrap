#!/usr/bin/env bash
# other-writer.sh — the concurrent writer of arm (b): a plain `git commit` on the shared index.
# Usage: bash bench/commit-guard/other-writer.sh <fixture-dir>
# Run it after this session's `git add` and before its `git commit` — in a two-turn arm, between
# turn 1 (stopped at the readback) and turn 2. It commits whatever the shared index holds, as any
# plain `git commit` does. Lives here, never copied into the fixture.
set -eu
cd "${1:?usage: other-writer.sh <fixture-dir>}"
git commit -qm "docs: update foreign"
git log --oneline -1
