#!/usr/bin/env bash
# repro-concurrent.sh — deterministic shell reproduction of arm (b), no model in the loop.
# Usage: bash bench/commit-guard/repro-concurrent.sh <dir>
# Builds the make-fixture.sh repo, runs current § 5 as written up to its stop (`git add` of the
# session list, then the readback, which finds foreign.md and stops), lets other-writer.sh commit,
# then runs `check.sh concurrent`.
set -eu
here="$(cd "$(dirname "$0")" && pwd)"
dir="${1:?usage: repro-concurrent.sh <dir>}"
bash "$here/make-fixture.sh" "$dir" >/dev/null
(
  cd "$dir"
  git add a.md b.md
  foreign="$(git diff --cached --name-only | grep -vxF -e a.md -e b.md || true)"
  if [ -n "$foreign" ]; then
    echo "readback: stop and surface — staged outside the session list: $foreign"
  fi
)
bash "$here/other-writer.sh" "$dir"
bash "$here/check.sh" concurrent "$dir"
