#!/usr/bin/env bash
# run.sh <control|arm> <scenario-number> <out-file>
# Fills scenario-<n>.md's {EXCERPT} line with excerpt-<arm>.md and runs one headless trial.
set -eu
here=$(cd "$(dirname "$0")" && pwd)
arm=$1 n=$2 out=$3
awk -v ex="$here/excerpt-$arm.md" '
  $0 == "{EXCERPT}" { while ((getline l < ex) > 0) print l; close(ex); next }
  { print }
' "$here/scenario-$n.md" |
  claude -p --model "${MODEL:-haiku}" --tools "" --strict-mcp-config --setting-sources "" > "$out"
