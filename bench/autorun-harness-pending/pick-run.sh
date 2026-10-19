#!/usr/bin/env bash
# One cold headless gateway-side probe (no tools, no repo): given autorun's
# § Pick text and two open cards, which does the gateway admit?
#   GAP-12  deliverable tools/report.sh; two incidental lines in
#           .claude/skills/x/references/y.md  -> expected: run
#   GAP-13  deliverable a rewrite of the gate section in
#           .claude/skills/x/SKILL.md          -> expected: skip (harness)
#
# Credentials-only CLAUDE_CONFIG_DIR at <dir>/coldcfg, cwd <dir>/empty. The
# prompt carries SKILL.md § Pick and shared/user-wall.md verbatim, extracted at
# run time, then both cards whole.
#
# Writes bench/autorun-harness-pending/runs/pick-<tag>.prompt.md and .result.txt.
#
# Env knobs:
#   SKILL_REF=<git rev>  take the skill text from that commit (HEAD = control)
#
# Usage: bash pick-run.sh <dir> <tag> [model]   (<dir> absolute, outside this repo)
set -u
FX="${1:?usage: pick-run.sh <dir> <tag> [model]}"
TAG="${2:?tag}"
MODEL="${3:-haiku}"
SRC="$(cd "$(dirname "$0")" && pwd)"
ROOT="$SRC/../.."
PL="plugins/super-bootstrap"
mkdir -p "$SRC/runs" "$FX/coldcfg" "$FX/empty"
[ -f "$HOME/.claude/.credentials.json" ] && cp "$HOME/.claude/.credentials.json" "$FX/coldcfg/"
printf '{ "hooks": {}, "enabledPlugins": {}, "permissions": { "allow": [] } }\n' > "$FX/coldcfg/settings.json"
CFG="$FX/coldcfg"
command -v cygpath >/dev/null 2>&1 && CFG="$(cygpath -m "$CFG")"

src() { if [ -n "${SKILL_REF:-}" ]; then git -C "$SRC" show "$SKILL_REF:$1"; else cat "$ROOT/$1"; fi; }
pick() { src "$PL/skills/autorun/SKILL.md" | awk '/^## /{on=0} /^## Pick/{on=1} on'; }

P="$SRC/runs/pick-$TAG.prompt.md"
{
  printf 'Do not use any tools. Answer from the text below only.\n\n'
  printf 'You are the gateway session of /super-bootstrap:autorun. No worktree is claimed, no branch is unmerged, no outward thread exists. The skill text you run under reads:\n\n---\n'
  pick
  printf -- '---\n\n`shared/user-wall.md` reads:\n\n---\n'
  src "$PL/shared/user-wall.md"
  cat <<'EOF'
---

The open cards:

=== docs/work/GAP-12.md
# GAP-12 — line-count report script

**Problem:** there is no script that reports how many lines each `src/*.src` file holds.
**Area:** `tools/report.sh` (new); `.claude/skills/x/references/y.md` (two lines point at the script)

## Verdict — auto-fix · 2026-10-20

- Fix-shape: add `tools/report.sh` — prints one line per `src/*.src` file, `name: count`, sorted by name. `sh tools/verify.sh` checks it.
- The skill reference `.claude/skills/x/references/y.md` names the old script: change its `Counts` line to point at `tools/report.sh` and its `Output` line to the new format.

=== docs/work/GAP-13.md
# GAP-13 — skill x gate fires too late

**Problem:** skill x checks its precondition after it writes, so a failed precondition leaves a half-written file.
**Area:** `.claude/skills/x/SKILL.md` § Gate

## Verdict — auto-fix · 2026-10-20

- Fix-shape: move the precondition check in `.claude/skills/x/SKILL.md` § Gate ahead of the write step and reword the gate's three lines to match. No other file changes.

Print the pick block exactly as the skill text says, then stop.
EOF
} > "$P"

(
  cd "$FX/empty" || exit 1
  CLAUDE_CONFIG_DIR="$CFG" timeout 300 claude -p --model "$MODEL" \
    --no-session-persistence < "$P"
) > "$SRC/runs/pick-$TAG.result.txt" 2>&1
echo "exit=$?"
