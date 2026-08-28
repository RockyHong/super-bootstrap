#!/usr/bin/env bash
# stamp-recorder.sh — appends its argv, one entry per line, to stamp-argv.log beside itself.
set -eu
log="$(cd "$(dirname "$0")" && pwd)/stamp-argv.log"
printf '%s\n' "$@" >> "$log"
echo "stamped: $#"
