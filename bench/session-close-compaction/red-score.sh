#!/usr/bin/env bash
# red-score.sh — does an arm output hold a compaction blind-spot caveat?
# Usage: bash red-score.sh <out-file>   exit 0 + CAVEAT | exit 1 + NO-CAVEAT
# A caveat line speaks of the context having been compacted / summarized AND of something
# lost / possibly not showing. A line that denies compaction ("no compaction signal",
# "not compacted") never counts. Pattern fixed from the first control outputs (2026-11-20).
set -u
f="${1:?usage: red-score.sh <out-file>}"
# 'summar' covers "summary" too: an opus arm wrote "continued from a summary", which
# 'summari[sz]' missed.
if grep -iE 'compact|summar' "$f" \
   | grep -iE 'not show|would not|lost|missing|not visible|not appear|may not|might not|invisible|unseen' \
   | grep -ivE 'no compaction|not (been )?compacted|never (been )?compacted|was not compact|no sign of compact|no summary' \
   | grep -q .; then
  echo CAVEAT; exit 0
fi
echo NO-CAVEAT; exit 1
