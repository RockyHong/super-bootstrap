#!/usr/bin/env bash
# bite.sh — shows each of score.sh's (b), (c), (d), (e) failing on a violating output or fixture.
# (a) bites on a control run. Zero LLM calls.
# Usage: bash bench/session-close-judgment/bite.sh <scratch-dir>
set -u
scratch="${1:?usage: bite.sh <scratch-dir>}"
here="$(cd "$(dirname "$0")" && pwd)"
mkdir -p "$scratch"
fx="$scratch/bite-fixture"
bash "$here/make-fixture.sh" "$fx" >/dev/null
good() { cat <<'ROWS'
- [fix-now] docs/maintenance.md: replace "every 30 days" with "every 14 days".
- [doc-update] docs/operations.md:3: delete "Power-loss recovery is not documented yet."
- [register] recovery ramp, docs/recovery.md:3
  **Recovery ramp**: The climb back to set points after a power loss.
- [log] brindle-firmware baud rate: another repo owns it.
- [log] humidity drift: the investigation would pull unrelated reads into this thread.
- [commit] docs/operations.md docs/recovery.md
ROWS
}
echo "== baseline (all pass)"
good > "$scratch/bite-good.txt"; bash "$here/score.sh" "$scratch/bite-good.txt" "$fx"
echo "== (b) no reason, session-load reason"
good | sed -e 's/another repo owns it/log it for later/' \
  -e 's/the investigation would pull unrelated reads into this thread/context is heavy/' > "$scratch/bite-b.txt"
bash "$here/score.sh" "$scratch/bite-b.txt" "$fx"
echo "== (c) register row for a general word, homonym row, recommended skip"
{ good
  echo '- [register] webhook, docs/recovery.md:9'
  echo '- [terminology] docs/recovery.md:7 Hold: link docs/terminology.md'
  echo 'I recommend skipping these, do you want to?'
} > "$scratch/bite-c.txt"
bash "$here/score.sh" "$scratch/bite-c.txt" "$fx"
echo "== (c) names a dropped candidate without asking: passes, counted"
{ good
  echo 'Dropped: "Hold the door" is a verb; webhook is a general word.'
} > "$scratch/bite-c-named.txt"
bash "$here/score.sh" "$scratch/bite-c-named.txt" "$fx"
echo "== (c) general words in a later sentence of a coined term's row: passes, counted"
good | sed -e 's/^- \[register\] recovery ramp, docs\/recovery.md:3$/- [register] recovery ramp, docs\/recovery.md:3. Words like webhook and backoff get no entry./' > "$scratch/bite-c-row.txt"
bash "$here/score.sh" "$scratch/bite-c-row.txt" "$fx"
echo "== (e) no doc-update row across a wording's three runs"
good | grep -v '^- \[doc-update\]' > "$scratch/bite-e.txt"
bash "$here/score-wording.sh" "$scratch/bite-e.txt" "$fx" "$scratch/bite-e.txt" "$fx" "$scratch/bite-good.txt" "$fx"
echo "== (d) intent-to-add entry in the shared index"
git -C "$fx" add -N docs/recovery.md
bash "$here/score.sh" "$scratch/bite-good.txt" "$fx"
