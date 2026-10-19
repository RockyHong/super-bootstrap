#!/usr/bin/env bash
# One cold headless run against a fresh derived-state fixture: tracked sources
# changed through something other than the agent's own edits (a base sync into
# the worktree, or a branch landing on base), the git-ignored derived file is
# stale, and the repo's CLAUDE.md declares the regenerate command beside the
# install command. Does the agent regenerate before its first verify?
#
# Builds <dir> with make-fixture.sh, extracts the autorun text verbatim at run
# time, and runs `claude -p --model <model> --allowedTools Bash` cwd'd at the
# scenario's tree (the fixture CLAUDE.md loads as project memory):
#   respawn    cwd = the worktree. Text: assets/worktree-boundary.md whole +
#              parallel-worktrees.md's provisioning section.
#   mergegate  cwd = the main checkout. Text: SKILL.md § Rules +
#              parallel-worktrees.md's provisioning and Nested-worktree
#              false-greens sections.
#
# Writes bench/autorun-derived-state/runs/<tag>.prompt.md (exact prompt),
#        <tag>.result.txt (final output), <tag>.state.txt (.bench-log command
#        order, status line, git log, a fresh verify after the run).
#
# Env knobs:
#   SKILL_REF=<git rev>  take the skill text from that commit (e.g. HEAD for the
#                        pre-fix body) instead of the working tree
#   SCENARIO=respawn|mergegate|nocue   (default respawn; nocue = the branch
#                        carries an earlier session's commit, the prompt
#                        carries worktree-boundary.md alone and names no history)
#   DELIVERY=brief       respawn only: the prompt carries worktree-boundary.md
#                        alone, as the real brief delivers it (no pasted
#                        provisioning section)
#
# Usage: bash run.sh <dir> <tag> [model]   (<dir> absolute, outside this repo)
set -u
FX="${1:?usage: run.sh <dir> <tag> [model]}"
TAG="${2:?tag}"
MODEL="${3:-haiku}"
SCEN="${SCENARIO:-respawn}"
SRC="$(cd "$(dirname "$0")" && pwd)"
ROOT="$SRC/../.."
AR="plugins/super-bootstrap/skills/autorun"
mkdir -p "$SRC/runs"
bash "$SRC/make-fixture.sh" "$FX" "$SCEN" >/dev/null || { echo "fixture build failed" >&2; exit 1; }
CFG="$FX/coldcfg"
command -v cygpath >/dev/null 2>&1 && CFG="$(cygpath -m "$CFG")"

src() { # src <repo-relative path>
  if [ -n "${SKILL_REF:-}" ]; then git -C "$SRC" show "$SKILL_REF:$1"; else cat "$ROOT/$1"; fi
}
# provisioning section: heading matched loosely so a renamed heading still extracts
prov() { src "$AR/assets/parallel-worktrees.md" | awk '/^## /{on=0} /^## .*[Pp]rovisioning/{on=1} on'; }
nested() { src "$AR/assets/parallel-worktrees.md" | awk '/^## /{on=0} /^## Nested-worktree false-greens/{on=1} on'; }
rules() { src "$AR/SKILL.md" | awk '/^## /{on=0} /^## Rules/{on=1} on'; }

P="$SRC/runs/$TAG.prompt.md"
if [ "$SCEN" = mergegate ]; then
  T="$FX/repo"
  {
    printf 'You are the gateway session of /super-bootstrap:autorun, working in the main checkout (this directory) on `main`. The autorun skill text you run under reads:\n\n---\n'
    rules; printf '\nFrom `assets/parallel-worktrees.md`:\n\n'; prov; nested
    printf -- '---\n\n'
    printf 'Situation: `/super-bootstrap:merge autorun/gap-12` just landed `autorun/gap-12` on `main` (Merge --no-ff, no conflicts). Card GAP-12 marks its verification as module-resolution sensitive, so it was deferred to the merge gate.\n\n'
    printf 'Run the merge-gate verification now. Do not edit any tracked file. End with one line: `PASS` or `FAIL - {reason}`.\n'
  } > "$P"
elif [ "$SCEN" = nocue ]; then
  T="$FX/repo/.claude/worktrees/autorun-gap-12"
  {
    printf 'You are a subprocess Claude dispatched by /super-bootstrap:autorun. Your brief begins with this anchor, verbatim:\n\n---\n'
    src "$AR/assets/worktree-boundary.md"
    printf -- '---\n\n'
    printf 'You work card GAP-12 in this worktree on branch `autorun/gap-12`.\n\n'
    printf 'Work order: add the line `currency: usd` to `src/orders.src`. Then verify, commit on this branch with plain git (stage the file, then commit; the commit door is not installed in this repo), and write `.autorun-status` at the worktree root: `DONE` when verify passes, else `BLOCKED - {what is wrong}`. End with the status line.\n'
  } > "$P"
else
  T="$FX/repo/.claude/worktrees/autorun-gap-12"
  {
    printf 'You are a subprocess Claude re-spawned by /super-bootstrap:autorun. Your brief begins with this anchor, verbatim:\n\n---\n'
    src "$AR/assets/worktree-boundary.md"
    if [ -z "${DELIVERY:-}" ]; then
      printf -- '---\n\nFrom the autorun mechanism reference `assets/parallel-worktrees.md`:\n\n---\n'
      prov
    fi
    printf -- '---\n\n'
    printf 'Situation: you work card GAP-12 in this worktree on branch `autorun/gap-12`. Your earlier spawn here provisioned the tree and committed `feat(orders): add total`, then stopped at a WALL. The user answered it, and before this re-spawn the gateway merged `main` into your branch.\n\n'
    printf 'Work order: make the one remaining edit the answer asked for - add the line `currency: usd` to `src/orders.src`. Then verify, commit on this branch with plain git (stage the file, then commit; the commit door is not installed in this repo), and write `.autorun-status` at the worktree root: `DONE` when verify passes, else `BLOCKED - {what is wrong}`. End with the status line.\n'
  } > "$P"
fi

(
  cd "$T" || exit 1
  CLAUDE_CONFIG_DIR="$CFG" timeout 300 claude -p --model "$MODEL" \
    --allowedTools Bash --no-session-persistence < "$P"
) > "$SRC/runs/$TAG.result.txt" 2> "$SRC/runs/$TAG.err.txt"
echo "exit=$?"
[ -s "$SRC/runs/$TAG.err.txt" ] || rm -f "$SRC/runs/$TAG.err.txt"

{
  echo "## .bench-log (command order during the run)"; cat "$T/.bench-log" 2>/dev/null
  echo "## first verify preceded by codegen?"
  awk '$0=="codegen"{c=1} $0=="verify"{print (c?"yes":"no"); exit}' "$T/.bench-log" 2>/dev/null
  echo "## .autorun-status"; cat "$T/.autorun-status" 2>/dev/null
  echo "## git log --oneline -4"; git -C "$T" log --oneline -4
  echo "## git status --short"; git -C "$T" status --short
} > "$SRC/runs/$TAG.state.txt" 2>&1
