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

# The printed AskUserQuestion call: askm a multi-select pick, asks <question> a single-select run / skip.
askm() {
  echo '```AskUserQuestion'
  echo '{"questions":[{"question":"Run which moves?","header":"Close","multiSelect":true,"options":[{"label":"all rows","description":"every row above"}]}]}'
  echo '```'
}
asks() {
  echo '```AskUserQuestion'
  echo "{\"questions\":[{\"question\":\"$1\",\"header\":\"Close\",\"multiSelect\":false,\"options\":[{\"label\":\"Run\",\"description\":\"run it\"},{\"label\":\"Skip\",\"description\":\"leave it\"}]}]}"
  echo '```'
}

good() { cat <<'ROWS'
- [fix-now] docs/maintenance.md: replace "every 30 days" with "every 14 days".
- [doc-update] README.md: replace "the monthly seal inspection" with "the seal inspection".
- [doc-update] docs/console.md: replace "keeps retrying until it succeeds" with "retries up to 5 times".
- [resolve] BUG-rt51: Progress reports every Plan step done. Delete the card. Outcome edit, docs/recovery.md:
  After 5 failed retries the controller drops the report and the panel shows fault E7.
- [resolve] BUG-sd22: Progress reports every Plan step done. Delete the card. Outcome already stated at docs/operations.md:12.
- [commit] Left uncommitted: docs/operations.md docs/shutdown.md. Also lands docs/maintenance.md README.md docs/recovery.md docs/console.md docs/work/BUG-rt51.md docs/work/BUG-sd22.md
ROWS
askm
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
leakgood() { printf -- '- [commit] Left uncommitted: shift-log.txt\n- [prune] git branch -d topic-old\n'; askm; }
echo "== leak baseline (all pass)"; leakgood > "$scratch/o.txt"; sc leak "$lx"
echo "== (p7) leak row does not name the leak as uncommitted"
{ printf -- '- [commit] shift-log.txt\n- [prune] git branch -d topic-old\n'; askm; } > "$scratch/o.txt"; sc leak "$lx"
echo "== (p8) two commit rows"
{ printf -- '- [commit] Left uncommitted: shift-log.txt\n- [commit] docs/x.md\n- [prune] y\n'; askm; } > "$scratch/o.txt"; sc leak "$lx"
echo "== (p8) commits nested under one row"
{ printf -- '- [commit] Left uncommitted: shift-log.txt\n  - commit 1: docs: a\n  - commit 2: chore: b\n- [prune] y\n'; askm; } > "$scratch/o.txt"; sc leak "$lx"
echo "== (p9) a close-without option"
leakgood > "$scratch/o.txt"; echo '- [close] close without running it' >> "$scratch/o.txt"; sc leak "$lx"
singlegood() { echo '- [commit] Left uncommitted: shift-log.txt'; asks 'Commit shift-log.txt?'; }
echo "== single baseline (all pass)"; singlegood > "$scratch/o.txt"; sc single "$sx"
echo "== (p9) baseline: a lone move's skip option closes without it"
singlegood | sed -e 's/"leave it"/"Close without the commit."/' > "$scratch/o.txt"; sc single "$sx"
echo "== (p9) a lone move with a close-without line outside its ask"
{ singlegood; echo 'Or close without running it.'; } > "$scratch/o.txt"; sc single "$sx"
echo "== (p9) several moves whose ask offers a close-without option"
leakgood | sed -e 's/"every row above"/"or close without running them"/' > "$scratch/o.txt"; sc leak "$lx"
echo "== (p11) a lone move with a second choice"
{ printf -- '- [commit] shift-log.txt\n- [other] x\n'; askm; } > "$scratch/o.txt"; sc single "$sx"
echo "== (p11) a lone move asked in prose, the old shape"
echo 'One move is open: commit shift-log.txt, left uncommitted. Run it?' > "$scratch/o.txt"; sc single "$sx"
echo "== (p11) a lone move asked multi-select"
{ echo '- [commit] Left uncommitted: shift-log.txt'; askm; } > "$scratch/o.txt"; sc single "$sx"
echo "== (p11) a lone move asked with one option"
singlegood | sed -e 's/,{"label":"Skip","description":"leave it"}//' > "$scratch/o.txt"; sc single "$sx"
echo "== (p11) several rows asked single-select"
{ leakgood | grep -v '^[`{]'; asks 'Run these?'; } > "$scratch/o.txt"; sc leak "$lx"
echo "== (p7) baseline: untracked names the leak"; { printf -- '- [commit] shift-log.txt, which this session left untracked\n- [prune] y\n'; askm; } > "$scratch/o.txt"; sc leak "$lx"
echo "== (p7) untracked names another path only"; { printf -- '- [commit] shift-log.txt\n- [prune] y\nAlso untracked: other.txt\n'; askm; } > "$scratch/o.txt"; sc leak "$lx"
echo "== large baseline (all pass)"; { echo '- [commit] Left uncommitted: docs/shutdown.md docs/operations.md tuning/. Splits into 2 commits.'; asks 'Run the commit move?'; } > "$scratch/o.txt"; sc large "$gx"

hx="$scratch/bite-harness"; bash "$here/make-fixture.sh" harness "$hx" >/dev/null
harnessgood() {
  echo '- [fix-now] .claude/rules/maintenance.md: append "The controller reads config/cabinet.toml only at boot, so a changed value takes effect after the next restart." Its harness audit runs after the edit, before the commit.'
  echo '- [commit] Lands .claude/rules/maintenance.md.'
  echo '```AskUserQuestion'
  echo '{"questions":[{"question":"要執行哪些收尾動作？","header":"收尾","multiSelect":true,"options":[{"label":"修正規則","description":"附加一行"},{"label":"提交","description":"提交規則"}]}]}'
  echo '```'
}
echo "== harness baseline (all pass)"; harnessgood > "$scratch/o.txt"; sc harness "$hx"
echo "== (p12) the drafted rule fix routed to log, its reason the owed audit"
harnessgood | sed -e 's/^- \[fix-now\]/- [log]/' -e 's/Its harness audit runs after the edit, before the commit./Needs a harness audit first./' > "$scratch/o.txt"; sc harness "$hx"
echo "== (p13) no line names the owed audit"
harnessgood | sed -e 's/ Its harness audit runs after the edit, before the commit.//' > "$scratch/o.txt"; sc harness "$hx"
echo "== (p14) the ask's question drifts out of the session's language"
harnessgood | sed -e 's/要執行哪些收尾動作？/Run which closeout moves?/' > "$scratch/o.txt"; sc harness "$hx"

cx="$scratch/bite-cochange"; bash "$here/make-fixture.sh" cochange "$cx" >/dev/null
cochangegood() {
  echo '- [harness] .claude/rules/seal.md: replace "A door seal is replaced only when it shows a crack." with "A door seal is replaced every 12 months, or sooner when it shows a crack." Its harness audit runs after the edit, before the commit.'
  echo '- [harness] .claude/skills/seal-audit/SKILL.md: a served copy; routes to its owner, claude-config-manager. Nothing written here.'
  echo '- [commit] Left uncommitted: docs/maintenance.md. Also lands .claude/rules/seal.md.'
  askm
}
echo "== cochange baseline (all pass)"; cochangegood > "$scratch/o.txt"; sc cochange "$cx"
echo "== (p15) the rule's co-change routed to log"
cochangegood | sed -e '1s/^- \[harness\]/- [log]/' > "$scratch/o.txt"; sc cochange "$cx"
echo "== (p15) the rule's row carries no drafted edit"
cochangegood | sed -e '1s/: replace .* Its harness/: update it to the new policy. Its harness/' > "$scratch/o.txt"; sc cochange "$cx"
echo "== (p16) the rule's row names no audit"
cochangegood | sed -e '1s/ Its harness audit runs after the edit, before the commit.//' > "$scratch/o.txt"; sc cochange "$cx"
echo "== (p17) the served skill landed as a fix-now row"
cochangegood | sed -e '2s/.*/- [fix-now] .claude\/skills\/seal-audit\/SKILL.md: replace "Replace a seal only when it shows a crack." with "Replace a seal every 12 months."/' > "$scratch/o.txt"; sc cochange "$cx"
echo "== (p17) the commit row lands the served skill"
cochangegood | sed -e '3s/$/ And .claude\/skills\/seal-audit\/SKILL.md./' > "$scratch/o.txt"; sc cochange "$cx"
echo "== (p17) a harness row lands the served skill"
cochangegood | sed -e '2s/.*/- [harness] .claude\/skills\/seal-audit\/SKILL.md: replace "Replace a seal only when it shows a crack." with "Replace a seal every 12 months." This round./' > "$scratch/o.txt"; sc cochange "$cx"
echo "== (p17) the served skill is named nowhere"
cochangegood | sed -e '2d' > "$scratch/o.txt"; sc cochange "$cx"

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
