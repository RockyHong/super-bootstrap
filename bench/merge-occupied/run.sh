#!/usr/bin/env bash
# BUG-g6at — one cold headless merge run against a fresh occupied-branch fixture.
#
# Builds <dir> with make-fixture.sh (feature/x checked out in a second worktree),
# extracts the merge skill's Conflict Doctrine through § 7 verbatim from the
# shipped SKILL.md (as it stands when the run fires), and runs
# `claude -p --model <model> --allowedTools Bash` cwd'd at <dir>/repo with that
# text + an instruction to land feature/x into main and print the § 7 report.
#
# Writes bench/merge-occupied/runs/<tag>.prompt.md (exact prompt),
#        <tag>.result.txt (final output), <tag>.state.txt (git state after).
#
# Env knobs:
#   SKILL_REF=<git rev>  take the skill text from that commit (e.g. HEAD for the
#                        pre-fix body) instead of the working tree
#   FORCE=rebase         pre-confirm the Rebase + fast-forward form for feature/x,
#                        so the run meets the failing command and must route it
#
# Usage: bash run.sh <dir> <tag> [model]   (<dir> absolute, outside this repo)
set -u
FX="${1:?usage: run.sh <dir> <tag> [model]}"
TAG="${2:?tag}"
MODEL="${3:-haiku}"
SRC="$(cd "$(dirname "$0")" && pwd)"
SKILL="$SRC/../../plugins/super-bootstrap/skills/merge/SKILL.md"
mkdir -p "$SRC/runs"
bash "$SRC/make-fixture.sh" "$FX" >/dev/null || { echo "fixture build failed" >&2; exit 1; }
CFG="$FX/coldcfg"
command -v cygpath >/dev/null 2>&1 && CFG="$(cygpath -m "$CFG")"

P="$SRC/runs/$TAG.prompt.md"
{
  printf 'You are running the merge procedure below in this repository. Base branch: `main`.\n'
  if [ "${FORCE:-}" = rebase ]; then
    printf 'Land the branch `feature/x` into `main`. I pre-confirm the Rebase + fast-forward strategy for `feature/x` - execute it without waiting for a reply. Finish by printing the step 7 report as your final output.\n\n'
  else
    printf 'Land the branch `feature/x` into `main`. I pre-confirm whatever strategy you recommend in step 4 - execute it without waiting for a reply. Finish by printing the step 7 report as your final output.\n\n'
  fi
  if [ -n "${SKILL_REF:-}" ]; then
    git -C "$SRC" show "$SKILL_REF:plugins/super-bootstrap/skills/merge/SKILL.md"
  else
    cat "$SKILL"
  fi | awk '/^## Conflict Doctrine/{on=1} /^### 8\./{on=0} on'
} > "$P"

(
  cd "$FX/repo" || exit 1
  CLAUDE_CONFIG_DIR="$CFG" timeout 300 claude -p --model "$MODEL" \
    --allowedTools Bash --no-session-persistence < "$P"
) > "$SRC/runs/$TAG.result.txt" 2> "$SRC/runs/$TAG.err.txt"
echo "exit=$?"
[ -s "$SRC/runs/$TAG.err.txt" ] || rm -f "$SRC/runs/$TAG.err.txt"

R="$FX/repo"
{
  echo "## git log --oneline --graph --all"; git -C "$R" log --oneline --graph --all
  echo "## main parents"; git -C "$R" rev-list --parents -n 1 main
  echo "## feature/x in main?"; git -C "$R" merge-base --is-ancestor feature/x main && echo yes || echo no
  echo "## worktree list"; git -C "$R" worktree list
  echo "## wt-x feature/x reflog"; git -C "$FX/wt-x" reflog -3 feature/x
  echo "## status"; git -C "$R" status --short --branch
} > "$SRC/runs/$TAG.state.txt" 2>&1
