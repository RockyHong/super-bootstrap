#!/usr/bin/env bash
# DEBT-118 M1+M2 — bite check: every scoring assertion must fail on an induced bad board.
#
# Each case mutates the golden board (or the reads log) in exactly one way and scores it.
# The row prints the targeted reading first, then the full score row; a case bites when
# its targeted reading drops below the golden's own score (printed first as `control`).
#
# Usage: bash bite.sh <fixture-root>
set -u
FX="${1:?usage: bite.sh <fixture-root>}"
SRC="$(cd "$(dirname "$0")" && pwd)"
PY=$(command -v python3 || command -v python)
T="$(mktemp -d)"
printf 'MISSING\tRead\tclassify-actionable.md\n' > "$T/noread.txt"          # no spec Read
printf 'Read\t/x/plugin/shared/classify-actionable.md\n' > "$T/read.txt"   # spec Read once

case_() {  # <name> <target> <mode> <sed-script> [reads]
  local name="$1" target="$2" mode="$3" script="$4" reads="${5:-$T/read.txt}"
  sed -e "$script" "$FX/golden/$mode.md" > "$T/$name.md"
  printf '%-22s %-9s ' "$name" "$target"
  "$PY" "$SRC/score.py" "$mode" "$FX/golden/$mode.md" "$T/$name.md" "$reads"
}

printf '%-22s %-9s ' case target
"$PY" "$SRC/score.py" needme "$FX/golden/needme.md" "$FX/golden/needme.md" --header | head -1
case_ control-needme   -        needme 's/^$/&/'
case_ control-full     -        full   's/^$/&/'
# classification — wrong intent bucket (Discuss row filed as Device), wrong verb, wrong stage,
# wrong blocker (the flat board's intent signal), drained-row count, hard-block count
case_ wrong-group      rows     needme '/GAP-102/d; /^## Device-bound/,/^$/ s/^| 1 | GAP-105/| 0 | GAP-102 | Decide: export command shape unsettled — triage verdict | 0 | quick-pop | — |\n&/'
case_ wrong-verb       rows     needme 's/| GAP-104 | Approve design:/| GAP-104 | Settle design:/'
case_ wrong-stage      rows     full   '/BUG-103/ s/| triaged |/| aimed |/'
case_ wrong-blocker    rows     full   '/BUG-111/ s/| user |/| none |/'
case_ wrong-drain      drain    needme 's/^Drainable: 4/Drainable: 5/'
case_ wrong-pending    pending  needme 's/^pending unblock: 2/pending unblock: 3/'
# shape
case_ bad-title        title    needme '1 s/.*/# Todo board/'
case_ renamed-heading  heads    needme 's/^## Harness$/## Engine/'
case_ merged-groups    heads    needme '/^## Device-bound$/,/^| -- /d'
case_ bad-columns      cols     needme 's/| unblocks | Impact |/| fan-out | Impact |/'
case_ invented-row     invented full   's/^| 12 | BUG-112 .*/&\n| 13 | BUG-999 | Triage: something the cards never said | raw | — | none | quick-pop | local |/'
case_ duplicated-row   invented full   's/^| 12 | BUG-112 .*/&\n&/'
case_ recommendation   reco     needme 's/^more: \/super-bootstrap:help$/Recommend starting with GAP-104.\n&/'
case_ lost-footer      footer   needme '/^flat list:/d'
case_ spec-not-read    spec     needme 's/^$/&/' "$T/noread.txt"
rm -rf "$T"
