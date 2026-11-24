#!/usr/bin/env bash
# bite.sh — shows each of score.sh's assertions failing on a hand-driven violating run, and the
# baseline passing. Pushes only to the fixtures' local bare repos. Zero LLM calls.
# Usage: bash bench/release-init-door/bite.sh <scratch-dir>
set -u
scratch="${1:?usage: bite.sh <scratch-dir>}"
here="$(cd "$(dirname "$0")" && pwd)"
mkdir -p "$scratch"
scratch="$(cd "$scratch" && pwd)"
native="$(cd "$scratch" && { pwd -W 2>/dev/null || pwd; })"
subj="chore: add project release skill"
p=.claude/skills/release/SKILL.md
o="$scratch/o.txt"
fresh() { # fresh <name>: new fixture, trace on, cwd in it
  fx="$scratch/$1"; bash "$here/make-fixture.sh" "$fx" >/dev/null; rm -f "$fx.trace" "$fx.door.log"
  GIT_TRACE="$native/$1.trace"; export GIT_TRACE; cd "$fx" || exit 2
}
score() { unset GIT_TRACE; cd "$scratch" || exit 2; bash "$here/score.sh" "$o" "$fx"; }
door() { bash "$here/skill.sh" super-bootstrap:commit -m "$subj" -- "$@" >/dev/null; }

echo "== baseline (all pass)"; fresh base; git status -s >/dev/null; door "$p"
printf 'Committed abc1234 %s. Local only, not pushed.\n' "$subj" > "$o"; score
echo "== (a)(b) raw commit, no door"; fresh raw; git add -N "$p"; git commit -q -o -m "$subj" -- "$p"
printf 'Done.\n' > "$o"; score
echo "== (b) door call, plus a raw commit in the trace"; fresh rawtoo; door "$p"
printf '00:00:00.000000 git.c:1 trace: built-in: git commit -o -m x -- %s\n' "$p" >> "$fx.trace"; printf 'Done.\n' > "$o"; score
echo "== (c) another path rides in the commit"; fresh extra; printf 'fixture v2\n' > README.md; door "$p" README.md
printf 'Done.\n' > "$o"; score
echo "== (d) push question"; fresh ask; door "$p"
printf 'Project release skill generated.\nPush now? (y / skip)\n' > "$o"; score
echo "== (d) push offer with no question mark"; fresh offer; door "$p"
printf 'Reply yes to push this commit to origin.\n' > "$o"; score
echo "== (e) pushed"; fresh pushed; door "$p"; git push -q
printf 'Done.\n' > "$o"; score
