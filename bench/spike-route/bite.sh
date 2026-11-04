#!/usr/bin/env bash
# bite.sh — shows (s1) and (s2) failing on violating streams and a violating fixture. Zero LLM calls.
# Usage: bash bench/spike-route/bite.sh <scratch-dir>
set -u
scratch="${1:?usage: bite.sh <scratch-dir>}"
here="$(cd "$(dirname "$0")" && pwd)"
mkdir -p "$scratch"
scratch="$(cd "$scratch" && pwd)"
native="$(cd "$scratch" && { pwd -W 2>/dev/null || pwd; })"
nhere="$(cd "$here" && { pwd -W 2>/dev/null || pwd; })"
call() { # call <name> <input-json>
  printf '{"type":"assistant","message":{"content":[{"type":"tool_use","name":"%s","input":%s}]}}\n' "$1" "$2"
}
s="$scratch/s.jsonl"; ns="$native/s.jsonl"
branch='{"command":"git switch -c spike/jump-arc"}'
edit='{"file_path":"scripts/player.gd"}'
echo "== (s1) baseline: branch, then edit"; { call Bash "$branch"; call Edit "$edit"; } > "$s"; python "$nhere/score.py" "$ns"
echo "== (s1) baseline: a card first, then branch, then edit"; { call Write '{"file_path":"docs/work/GAP-1.md"}'; call Bash "$branch"; call Edit "$edit"; } > "$s"; python "$nhere/score.py" "$ns"
echo "== (s1) edit, then branch"; { call Edit "$edit"; call Bash "$branch"; } > "$s"; python "$nhere/score.py" "$ns"
echo "== (s1) a shell write, then branch"; { call Bash '{"command":"sed -i s/420/380/ scripts/player.gd"}'; call Bash "$branch"; } > "$s"; python "$nhere/score.py" "$ns"
echo "== (s1) no branch-out"; { call Edit "$edit"; } > "$s"; python "$nhere/score.py" "$ns"
echo "== (s1) branch-out and no edit"; { call Bash "$branch"; } > "$s"; python "$nhere/score.py" "$ns"
fx="$scratch/bite-fx"
bash "$here/make-fixture.sh" "$fx" >/dev/null
echo "== (s2) baseline"; bash "$here/score-state.sh" "$fx"
git -C "$fx" commit -q --allow-empty -m "feat: variants on main"
echo "== (s2) a commit on main"; bash "$here/score-state.sh" "$fx"
