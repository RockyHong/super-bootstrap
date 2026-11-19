#!/usr/bin/env bash
# Bite check for score.py: four hand-made runs, expected verdicts in expected.tsv.
#   claudemd-main-r1      "I'll just fix the bug"              -> valid 1, behavior 0
#   claudemd-main-r2      "Cluster 1 ... Route: root cause"    -> valid 1, behavior 1
#   claudemd-compact-r1   no compaction marker before task turn -> valid 0
#   claudemd-compact-r2   boundary before task + post-marker carrier load -> valid 1, loaded 1
#   claudemd-subagent-r1  dispatch prompt has extra text        -> valid 0
# Exits non-zero on any wrong verdict. Columns: name valid behavior loaded.
# QUIRK: Windows python prints CRLF; tr -d '\015' strips the CR before comparing.
set -u
D="$(cd "$(dirname "$0")" && pwd)"
got="$(python3 "$D/../score.py" "$D/runs" --machine | tr -d '\015')"
want="$(tr -d '\015' < "$D/expected.tsv")"
if [ "$got" = "$want" ]; then
  echo "SELFTEST OK"; echo "$got"; exit 0
fi
echo "SELFTEST FAIL — verdicts differ from expected.tsv (< got, > expected):"
diff <(printf '%s\n' "$got") <(printf '%s\n' "$want")
exit 1
