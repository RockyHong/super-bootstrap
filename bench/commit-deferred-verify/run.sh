#!/usr/bin/env bash
# One cold headless commit-door micro-test (no tools, no repo): does an autorun
# worker committing in deferred mode run the staged-tree verify?
#
# Builds a credentials-only CLAUDE_CONFIG_DIR at <dir>/coldcfg (no device
# CLAUDE.md / rules / plugins / hooks), cwd <dir>/empty (no repo CLAUDE.md),
# and asks the model, as an autorun worker in deferred mode whose repo declares
# a Staged-Tree Verify and whose git status lists an untracked file outside its
# session list, for the commands it runs. The skill text is the commit SKILL.md
# from `## Execution` up to `## Rules`.
#
# Writes bench/commit-deferred-verify/runs/<tag>.prompt.md and <tag>.result.txt.
#
# Env knobs:
#   SKILL_REF=<git rev>  take the skill text from that commit (e.g. HEAD for the
#                        pre-fix body) instead of the working tree
#
# Usage: bash run.sh <dir> <tag> [model]   (<dir> absolute, outside this repo)
set -u
FX="${1:?usage: run.sh <dir> <tag> [model]}"
TAG="${2:?tag}"
MODEL="${3:-haiku}"
SRC="$(cd "$(dirname "$0")" && pwd)"
SKILL="$SRC/../../plugins/super-bootstrap/skills/commit/SKILL.md"
mkdir -p "$SRC/runs" "$FX/coldcfg" "$FX/empty"
[ -f "$HOME/.claude/.credentials.json" ] && cp "$HOME/.claude/.credentials.json" "$FX/coldcfg/"
printf '{ "hooks": {}, "enabledPlugins": {}, "permissions": { "allow": [] } }\n' > "$FX/coldcfg/settings.json"
CFG="$FX/coldcfg"
command -v cygpath >/dev/null 2>&1 && CFG="$(cygpath -m "$CFG")"

P="$SRC/runs/$TAG.prompt.md"
{
  printf 'Do not use any tools. Answer from the text below only.\n\n'
  printf 'You are running the /super-bootstrap:commit skill. Its execution section reads:\n\n---\n'
  if [ -n "${SKILL_REF:-}" ]; then
    git -C "$SRC" show "$SKILL_REF:plugins/super-bootstrap/skills/commit/SKILL.md"
  else
    cat "$SKILL"
  fi | awk '/^## Execution/{on=1} /^## Rules/{on=0} on'
  printf -- '---\n\nYour situation: you are an autorun worker in the worktree `.claude/worktrees/autorun-bug-12/` on branch `autorun/bug-12`, committing in deferred mode (autorun-worktree isolated commit). Your session list is `src/parse.js` and `test/parse.test.js`, both file grain, every hunk yours. The repo'"'"'s `docs/techstack.md` declares a § Staged-Tree Verify block:\n\n```sh\nnpm test\n```\n\n`git status --porcelain` prints:\n\n```\n M src/parse.js\n M test/parse.test.js\n?? scratch.log\n```\n\n`scratch.log` is outside your session list.\n\nList, in order, the exact commands you run from here to the finished commit. Be concrete. Then say in one line whether you ran the staged-tree verify, and why.\n'
} > "$P"

(
  cd "$FX/empty" || exit 1
  CLAUDE_CONFIG_DIR="$CFG" timeout 300 claude -p --model "$MODEL" \
    --no-session-persistence < "$P"
) > "$SRC/runs/$TAG.result.txt" 2>&1
echo "exit=$?"
