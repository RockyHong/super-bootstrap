#!/usr/bin/env bash
# BUG-szkd — one cold headless resolver micro-test (no tools, no repo).
#
# Builds a credentials-only CLAUDE_CONFIG_DIR at <dir>/coldcfg (no device
# CLAUDE.md / rules / plugins / hooks), cwd <dir>/empty (no repo CLAUDE.md),
# and asks the model, as the conflict-resolution agent the merge skill
# dispatched, for its next git commands and its report after resolving
# a.md and b.md. The skill text is the merge SKILL.md from `## Conflict
# Doctrine` up to `## Protocol`.
#
# Writes bench/merge-resolver/runs/<tag>.prompt.md and <tag>.result.txt.
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
SKILL="$SRC/../../plugins/super-bootstrap/skills/merge/SKILL.md"
mkdir -p "$SRC/runs" "$FX/coldcfg" "$FX/empty"
[ -f "$HOME/.claude/.credentials.json" ] && cp "$HOME/.claude/.credentials.json" "$FX/coldcfg/"
printf '{ "hooks": {}, "enabledPlugins": {}, "permissions": { "allow": [] } }\n' > "$FX/coldcfg/settings.json"
CFG="$FX/coldcfg"
command -v cygpath >/dev/null 2>&1 && CFG="$(cygpath -m "$CFG")"

P="$SRC/runs/$TAG.prompt.md"
{
  printf 'Do not use any tools. Answer from the text below only.\n\n'
  printf 'You are the conflict-resolution agent dispatched by the /super-bootstrap:merge skill. The merge skill'"'"'s conflict section reads:\n\n---\n'
  if [ -n "${SKILL_REF:-}" ]; then
    git -C "$SRC" show "$SKILL_REF:plugins/super-bootstrap/skills/merge/SKILL.md"
  else
    cat "$SKILL"
  fi | awk '/^## Conflict Doctrine/{on=1} /^## Protocol/{on=0} on'
  printf -- '---\n\nYour dispatch: branch `feature/x`, strategy Merge --no-ff into `main`, conflict files `a.md` and `b.md`. You have already re-run `git merge feature/x --no-ff` on `main` and edited `a.md` and `b.md` to remove every conflict marker with the correct combined content.\n\nState, in order, the exact git commands you run next (if any), and then the exact report you return. Be concrete.\n'
} > "$P"

(
  cd "$FX/empty" || exit 1
  CLAUDE_CONFIG_DIR="$CFG" timeout 300 claude -p --model "$MODEL" \
    --no-session-persistence < "$P"
) > "$SRC/runs/$TAG.result.txt" 2>&1
echo "exit=$?"
