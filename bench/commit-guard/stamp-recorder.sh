#!/usr/bin/env bash
# stamp-recorder.sh — stub standing in for `harness-audit-pretool.sh --stamp`.
# Usage (planted at the fixture root, called as the arm's stamp step):
#   bash ./stamp-recorder.sh "<one-line verdict>" $(git diff --cached --name-only)
#
# Records its argv, one entry per line, to stamp-argv.log beside itself and exits 0.
# The real stamp fingerprints the staged blobs of exactly these paths as one
# all-or-nothing set, so the recorded argv IS the stamped set — the arm asserts a
# concurrent session's path never appears in it.
set -eu
log="$(cd "$(dirname "$0")" && pwd)/stamp-argv.log"
printf '%s\n' "$@" >> "$log"
echo "stamped: $#"
