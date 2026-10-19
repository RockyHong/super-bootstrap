#!/usr/bin/env bash
# One cold headless micro-test (no tools, no repo): before verify, does the
# agent run the consumer-declared regenerate command after tracked sources
# changed through something other than its own edits?
#
# Builds a credentials-only CLAUDE_CONFIG_DIR at <dir>/coldcfg (no device
# CLAUDE.md / rules / plugins / hooks), cwd <dir>/empty (no repo CLAUDE.md).
# The prompt carries the autorun text verbatim, extracted at run time, plus a
# consumer CLAUDE.md Commands block that declares install, regenerate and
# verify commands side by side.
#
# Scenarios (SCENARIO env, default respawn):
#   respawn    - a worker re-spawned in its worktree after the gateway synced
#                base into the branch. Text: assets/worktree-boundary.md whole
#                + parallel-worktrees.md's provisioning section.
#   mergegate  - the gateway after landing an autorun branch on main, about to
#                run the card's resolution-sensitive verify on the base tree.
#                Text: SKILL.md § Rules + parallel-worktrees.md's provisioning
#                and Nested-worktree false-greens sections.
#
# Writes bench/autorun-derived-state/runs/text-<tag>.prompt.md and .result.txt.
#
# Env knobs:
#   SKILL_REF=<git rev>  take the skill text from that commit (e.g. HEAD for the
#                        pre-fix body) instead of the working tree
#   SCENARIO=respawn|mergegate
#   LEAN=1               the situation names no changed file and no import
#                        chain - only that sources arrived from elsewhere
#
# Usage: bash text-run.sh <dir> <tag> [model]   (<dir> absolute, outside this repo)
set -u
FX="${1:?usage: text-run.sh <dir> <tag> [model]}"
TAG="${2:?tag}"
MODEL="${3:-haiku}"
SCEN="${SCENARIO:-respawn}"
SRC="$(cd "$(dirname "$0")" && pwd)"
ROOT="$SRC/../.."
AR="plugins/super-bootstrap/skills/autorun"
mkdir -p "$SRC/runs" "$FX/coldcfg" "$FX/empty"
[ -f "$HOME/.claude/.credentials.json" ] && cp "$HOME/.claude/.credentials.json" "$FX/coldcfg/"
printf '{ "hooks": {}, "enabledPlugins": {}, "permissions": { "allow": [] } }\n' > "$FX/coldcfg/settings.json"
CFG="$FX/coldcfg"
command -v cygpath >/dev/null 2>&1 && CFG="$(cygpath -m "$CFG")"

src() { # src <repo-relative path>
  if [ -n "${SKILL_REF:-}" ]; then git -C "$SRC" show "$SKILL_REF:$1"; else cat "$ROOT/$1"; fi
}
# provisioning section: heading matched loosely so a renamed heading still extracts
prov() { src "$AR/assets/parallel-worktrees.md" | awk '/^## /{on=0} /^## .*[Pp]rovisioning/{on=1} on'; }
nested() { src "$AR/assets/parallel-worktrees.md" | awk '/^## /{on=0} /^## Nested-worktree false-greens/{on=1} on'; }
rules() { src "$AR/SKILL.md" | awk '/^## /{on=0} /^## Rules/{on=1} on'; }

COMMANDS='The repository'"'"'s CLAUDE.md `## Commands` block reads:

```bash
npm ci              # install dependencies
npm run codegen     # regenerate src/generated/ (git-ignored) from schemas/*.graphql
npm test            # verify: typecheck + unit tests
```
'

P="$SRC/runs/text-$TAG.prompt.md"
{
  printf 'Do not use any tools. Answer from the text below only.\n\n'
  if [ "$SCEN" = mergegate ]; then
    printf 'You are the gateway session of /super-bootstrap:autorun, working in the main checkout on `main`. The autorun skill text you run under reads:\n\n---\n'
    rules; printf '\nFrom `assets/parallel-worktrees.md`:\n\n'; prov; nested
    printf -- '---\n\n%s\n' "$COMMANDS"
    if [ -n "${LEAN:-}" ]; then
      WHAT='6 commits, 11 files changed'
    else
      WHAT='The branch added `schemas/order.graphql` and `src/orders.ts`, which imports from `src/generated/order.ts`'
    fi
    printf 'Situation: `/super-bootstrap:merge autorun/gap-12` just landed `autorun/gap-12` on `main` (Merge --no-ff, no conflicts). %s. Card GAP-12 marks its verification as module-resolution sensitive, so it was deferred to the merge gate. This checkout has `node_modules/` and `src/generated/` from earlier work on `main`.\n\n' "$WHAT"
  else
    printf 'You are a subprocess Claude re-spawned by /super-bootstrap:autorun. Your brief begins with this anchor, verbatim:\n\n---\n'
    src "$AR/assets/worktree-boundary.md"
    printf -- '---\n\nFrom the autorun mechanism reference `assets/parallel-worktrees.md`:\n\n---\n'
    prov
    printf -- '---\n\n%s\n' "$COMMANDS"
    if [ -n "${LEAN:-}" ]; then
      WHAT='that merge brought in 6 commits from `main`.'
    else
      WHAT='that merge added `schemas/invoice.graphql` and `src/billing.ts`, which imports from `src/generated/invoice.ts`.'
    fi
    printf 'Situation: you work card GAP-12 in worktree `.claude/worktrees/autorun-gap-12` on branch `autorun/gap-12`. Your earlier spawn here ran the install command, built, and committed `src/orders.ts`. It stopped at a WALL; the user answered it, and before this re-spawn the gateway merged `main` into your branch. `git log -1` shows `Merge branch '"'"'main'"'"' into autorun/gap-12`; %s You have now made the one remaining edit the answer asked for, in `src/orders.ts`.\n\n' "$WHAT"
  fi
  printf 'State, in order, the exact shell commands you run from now up to and including the verify command, each with a one-line reason. Be concrete.\n'
} > "$P"

(
  cd "$FX/empty" || exit 1
  CLAUDE_CONFIG_DIR="$CFG" timeout 300 claude -p --model "$MODEL" \
    --no-session-persistence < "$P"
) > "$SRC/runs/text-$TAG.result.txt" 2>&1
echo "exit=$?"
