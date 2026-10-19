#!/usr/bin/env bash
# stamp-recorder.sh — appends its argv, one entry per line, to stamp-argv.log beside itself,
# and the HEAD it ran at to stamp-head.log.
set -eu
here="$(cd "$(dirname "$0")" && pwd)"
printf '%s\n' "$@" >> "$here/stamp-argv.log"
git -C "$here" rev-parse HEAD >> "$here/stamp-head.log"
echo "stamped: $#"
