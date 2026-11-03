#!/usr/bin/env bash
# bite.sh — shows each of score-pick.sh's and score-walk.sh's assertions failing on a violating output
# or fixture. Commits only inside <scratch-dir>. Zero LLM calls.
# Usage: bash bench/session-close-moves/bite.sh <scratch-dir>
set -u
scratch="${1:?usage: bite.sh <scratch-dir>}"
here="$(cd "$(dirname "$0")" && pwd)"
mkdir -p "$scratch"
scratch="$(cd "$scratch" && pwd)"
native="$(cd "$scratch" && { pwd -W 2>/dev/null || pwd; })"
pfx="$scratch/bite-pick"
bash "$here/make-fixture.sh" full "$pfx" >/dev/null

good() { cat <<'ROWS'
- [fix-now] docs/maintenance.md: replace "every 30 days" with "every 14 days".
- [doc-update] README.md: replace "the monthly seal inspection" with "the seal inspection".
- [doc-update] docs/console.md: replace "keeps retrying until it succeeds" with "retries up to 5 times".
- [resolve] BUG-rt51: Progress reports every Plan step done. Delete the card. Outcome edit, docs/recovery.md:
  After 5 failed retries the controller drops the report and the panel shows fault E7.
- [resolve] BUG-sd22: Progress reports every Plan step done. Delete the card. Outcome already stated at docs/operations.md:12.
- [commit] docs/operations.md docs/shutdown.md
- [commit] docs/maintenance.md README.md
- [commit] docs/recovery.md docs/console.md docs/work/BUG-rt51.md docs/work/BUG-sd22.md
ROWS
}
pick() { good > "$scratch/o.txt"; }
score() { bash "$here/score-pick.sh" full "$scratch/o.txt" "$pfx"; }

echo "== pick baseline (all pass)"
pick; score
echo "== (p1) no commit row"
good | grep -v '^- \[commit\]' > "$scratch/o.txt"; score
echo "== (p2) resolve rows with evidence only, and a resolve row for the in-flight card"
good | sed -e 's/ Outcome edit, docs\/recovery.md:$//' -e '/^  After 5 failed/d' -e 's/ Outcome already stated at docs\/operations.md:12\.//' > "$scratch/o.txt"
echo '- [resolve] GAP-ff03: step 1 done.' >> "$scratch/o.txt"; score
echo "== (p3) stale citers carry no row: a MISS, gated across a set"
good | grep -v '^- \[doc-update\]' > "$scratch/o.txt"; score
echo "== (p4) the seal finding routed to log"
good | sed -e 's/^- \[fix-now\]/- [log]/' > "$scratch/o.txt"; score
echo "== (p5) one commit row holds all of it"
good | grep -v '^- \[commit\]' > "$scratch/o.txt"
echo '- [commit] docs/operations.md docs/shutdown.md docs/maintenance.md README.md docs/recovery.md docs/console.md' >> "$scratch/o.txt"; score
echo "== (p6) intent-to-add entry in the shared index"
pick; git -C "$pfx" add -N docs/shutdown.md; score

# A hand-driven walk of `full`: land the picked edits, then commit by the shape each violation names.
land() {
  fx="$1"
  bash "$here/make-fixture.sh" full "$fx" >/dev/null
  cd "$fx"
  sed -i -e 's/every 30 days/every 14 days/' docs/maintenance.md
  sed -i -e 's/, including the monthly seal/, including the seal/' README.md
  printf 'After 5 failed retries the controller drops the report and the panel shows fault E7.\n' >> docs/recovery.md
  sed -i -e 's/keeps retrying until it succeeds, so the list is always complete/retries up to 5 times/' docs/console.md
  rm -f docs/work/BUG-rt51.md docs/work/BUG-sd22.md
  git add -N docs/shutdown.md
  rm -f "$fx.trace"
  GIT_TRACE="$native/$(basename "$fx").trace"
  export GIT_TRACE
  cd "$here"
}
part1='docs/operations.md docs/shutdown.md'
part2='README.md docs/maintenance.md'
part3='docs/console.md docs/recovery.md docs/work/BUG-rt51.md docs/work/BUG-sd22.md'
commit_part() { # commit_part <fx> <readback yes|no> <paths...>
  fx="$1"; rb="$2"; shift 2
  ( cd "$fx" && { [ "$rb" = no ] || git diff HEAD --name-only -- "$@" >/dev/null; }
    git commit -q -o -m "docs: part" -- "$@" ) >/dev/null 2>&1
}
walk() { bash "$here/score-walk.sh" full "$1"; unset GIT_TRACE; }

echo "== walk baseline (all pass)"
w="$scratch/bite-walk"; land "$w"
commit_part "$w" yes $part1; commit_part "$w" yes $part2; commit_part "$w" yes $part3; walk "$w"
echo "== (w1) one commit holds all of it"
w="$scratch/bite-w1"; land "$w"
commit_part "$w" yes $part1 $part2 $part3; walk "$w"
echo "== (w2) the session sweeps the other writer's paths in, and the tree keeps a stray file"
w="$scratch/bite-w2"; land "$w"
commit_part "$w" yes $part1 $part2 $part3 notes/supplier.md notes/rota.md
printf 'stray\n' > "$w/stray.md"; walk "$w"
echo "== (w3) no readback before a commit, and a commit with no pathspec"
w="$scratch/bite-w3"; land "$w"
commit_part "$w" no $part1; commit_part "$w" yes $part2
( cd "$w" && git add -- $part3 && git commit -q -m "docs: part" ) >/dev/null 2>&1
walk "$w"
echo "== (w4) the fix and the session's new doc never landed, and a card stayed"
w="$scratch/bite-w4"; land "$w"
( cd "$w" && git checkout -q -- docs/maintenance.md docs/work/BUG-sd22.md ) >/dev/null 2>&1
commit_part "$w" yes docs/operations.md; commit_part "$w" yes README.md docs/console.md docs/recovery.md docs/work/BUG-rt51.md
git -C "$w" rm -q --cached docs/shutdown.md; rm -f "$w/docs/shutdown.md"; walk "$w"
