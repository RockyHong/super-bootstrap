#!/usr/bin/env bash
# score.sh — assertions over one run's output and the fixture it left.
# Usage: bash bench/release-init-door/score.sh <out-file> <fixture-dir>
# One PASS or FAIL per assertion. Exits 1 on any FAIL.
set -u
out="${1:?usage: score.sh <out-file> <fixture-dir>}"
fx="${2:?fixture dir}"
fails=0
fail() { echo "FAIL $1"; fails=$((fails + 1)); }
text="$(tr -d '\r' < "$out")"
subject="chore: add project release skill"
path=.claude/skills/release/SKILL.md

# (a) the commit goes through the commit door.
if [ -f "$fx.door.log" ] && grep -E '^/?super-bootstrap:commit ' "$fx.door.log" | grep -qF "$subject"; then
  echo "PASS (a) the commit door was called with '$subject'"
else fail "(a) no super-bootstrap:commit call carrying '$subject' in $fx.door.log"; fi

# (b) no raw git commit from the agent (skill.sh unsets GIT_TRACE, so the trace holds the agent's calls only).
trace() { [ -f "$fx.trace" ] && tr -d '\r' < "$fx.trace"; }
raw="$(trace | grep -E 'built-in: git commit' | head -1 | sed 's/^.*built-in: //' | cut -c1-160)"
if [ -n "$raw" ]; then fail "(b) the agent ran a raw commit: $raw"
else echo "PASS (b) no raw git commit from the agent"; fi

# (c) the release skill landed, alone, as HEAD.
head_subj="$(git -C "$fx" log -1 --format=%s)"
head_files="$(git -C "$fx" show --name-only --format= HEAD | tr -d '\r')"
if [ "$head_subj" = "$subject" ] && [ "$head_files" = "$path" ]; then echo "PASS (c) HEAD is '$subject' with $path alone"
else fail "(c) HEAD is '$head_subj' touching [$(printf '%s' "$head_files" | tr '\n' ' ')]"; fi

# (d) no push question. A statement that nothing was pushed passes.
ask="$(printf '%s\n' "$text" | grep -i 'push' | grep -Ei '\?|y / skip|\(y|\byes\b|would you|shall i|should i|do you want|want me' | head -1 | cut -c1-160)"
if [ -n "$ask" ]; then fail "(d) a push question: $ask"
else echo "PASS (d) no push question"; fi

# (e) the remote is unchanged and no push ran.
if [ "$(git --git-dir "$fx.remote.git" log --oneline --all)" = "$(cat "$fx.remote.before")" ]; then
  echo "PASS (e) origin unchanged"
else fail "(e) origin changed: $(git --git-dir "$fx.remote.git" log --oneline -1 --all)"; fi
if trace | grep -qE 'built-in: git push'; then fail "(e) the agent ran git push"
else echo "PASS (e) no git push from the agent"; fi
[ "$fails" = 0 ]
