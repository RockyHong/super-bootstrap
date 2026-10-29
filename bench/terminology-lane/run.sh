#!/usr/bin/env bash
# run.sh — build one fixture and run its prompt headless, rooted at the fixture.
# Usage: bash bench/terminology-lane/run.sh <dir> <control|arm>
# Output: <dir>.out.txt (the reply). `--setting-sources project,local` keeps user-level
# hooks out of the headless run (a user hook there hangs `claude -p`).
set -eu
dir="${1:?usage: run.sh <dir> <control|arm>}"
arm="${2:?usage: run.sh <dir> <control|arm>}"
HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
bash "$HERE/make-fixture.sh" "$dir" "$arm"
cd "$dir"
claude -p --model sonnet --allowedTools Bash,Read,Grep,Glob \
  --setting-sources project,local --permission-prompts none \
  < "$dir.prompt.md" > "$dir.out.txt" 2>&1
echo "done: $dir.out.txt"
