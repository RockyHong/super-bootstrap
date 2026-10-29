#!/usr/bin/env bash
# run.sh — build one fixture and run its prompt headless, rooted at the fixture.
# Usage: bash bench/terminology-register/run.sh <dir> <control|arm> <recall|precision> [model]
# Output: <dir>.out.txt (the reply). `--setting-sources project,local` keeps user-level
# hooks out of the headless run (a user hook there hangs `claude -p`).
set -eu
usage="usage: run.sh <dir> <control|arm> <recall|precision> [model]"
dir="${1:?$usage}"
arm="${2:?$usage}"
case_="${3:?$usage}"
model="${4:-sonnet}"
HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
bash "$HERE/make-fixture.sh" "$dir" "$arm" "$case_"
cd "$dir"
claude -p --model "$model" --allowedTools Bash,Read,Grep,Glob \
  --setting-sources project,local --permission-prompts none \
  < "$dir.prompt.md" > "$dir.out.txt" 2>&1
echo "done: $dir.out.txt"
