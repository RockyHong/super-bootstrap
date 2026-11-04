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
- [commit] Left uncommitted: docs/operations.md docs/shutdown.md. Also lands docs/maintenance.md README.md docs/recovery.md docs/console.md docs/work/BUG-rt51.md docs/work/BUG-sd22.md
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
echo "== (p6) intent-to-add entry in the shared index"
pick; git -C "$pfx" add -N docs/shutdown.md; score

lx="$scratch/bite-leak"; bash "$here/make-fixture.sh" leak "$lx" >/dev/null
sx="$scratch/bite-single"; bash "$here/make-fixture.sh" single "$sx" >/dev/null
gx="$scratch/bite-large"; bash "$here/make-fixture.sh" large "$gx" >/dev/null
sc() { bash "$here/score-pick.sh" "$1" "$scratch/o.txt" "$2"; }
leakgood() { printf -- '- [commit] Left uncommitted: shift-log.txt\n- [prune] git branch -d topic-old\n'; }
echo "== leak baseline (all pass)"; leakgood > "$scratch/o.txt"; sc leak "$lx"
echo "== (p7) leak row does not name the leak as uncommitted"
printf -- '- [commit] shift-log.txt\n- [prune] git branch -d topic-old\n' > "$scratch/o.txt"; sc leak "$lx"
echo "== (p8) two commit rows"
printf -- '- [commit] Left uncommitted: shift-log.txt\n- [commit] docs/x.md\n- [prune] y\n' > "$scratch/o.txt"; sc leak "$lx"
echo "== (p8) commits nested under one row"
printf -- '- [commit] Left uncommitted: shift-log.txt\n  - commit 1: docs: a\n  - commit 2: chore: b\n- [prune] y\n' > "$scratch/o.txt"; sc leak "$lx"
echo "== (p9) a close-without option"
leakgood > "$scratch/o.txt"; echo '- [close] close without running it' >> "$scratch/o.txt"; sc leak "$lx"
echo "== single baseline (all pass)"; echo 'One move is open: commit shift-log.txt, left uncommitted. Run it?' > "$scratch/o.txt"; sc single "$sx"
echo "== (p11) a lone move with a second choice"
printf -- '- [commit] shift-log.txt\n- [other] x\n' > "$scratch/o.txt"; sc single "$sx"
echo "== (p11) no question"; echo 'Done: shift-log.txt is committed.' > "$scratch/o.txt"; sc single "$sx"
echo "== (p11) baseline: yes and no stated with no question mark"; echo 'Commit shift-log.txt. Yes commits it. No leaves it.' > "$scratch/o.txt"; sc single "$sx"
echo "== (p11) baseline: confirm or decline"; echo 'Confirm to commit shift-log.txt, or decline it.' > "$scratch/o.txt"; sc single "$sx"
echo "== (p7) baseline: untracked names the leak"; printf -- '- [commit] shift-log.txt, which this session left untracked\n- [prune] y\n' > "$scratch/o.txt"; sc leak "$lx"
echo "== (p7) untracked names another path only"; printf -- '- [commit] shift-log.txt\n- [prune] y\nAlso untracked: other.txt\n' > "$scratch/o.txt"; sc leak "$lx"
echo "== large baseline (all pass)"; echo '- [commit] Left uncommitted: docs/shutdown.md docs/operations.md tuning/. Splits into 2 commits.' > "$scratch/o.txt"; sc large "$gx"

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
echo "== (w1) no commit landed"
w="$scratch/bite-w1"; land "$w"
walk "$w"
echo "== (w1) one commit holds unrelated changes"
w="$scratch/bite-w1b"; land "$w"
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
