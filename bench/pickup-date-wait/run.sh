#!/usr/bin/env bash
# One cold headless probe (no tools, no repo): does the pickup skill read a
# card's `not before YYYY-MM-DD` date wait, and (needs-me) count stale carries?
# Today is fixed at 2026-11-26 in the prompt.
#   GAP-31  auto-fix work; latest Progress says `not before 2026-12-10` (future)
#           -> needs-me: not yet due, with its date; autorun: skipped
#   GAP-32  same shape, `not before 2026-11-01` (past, decoy)
#           -> reads as a normal card: runs without you / run
#   GAP-33  plain auto-fix card, no date      -> runs without you / run
#   SESSION-STATE/ (needs-me only): 3 carries; GAP-29-*.md points at a deleted
#           card -> count line reads 3 carries, 1 stale
#
# The prompt carries the skill's SKILL.md whole, shared/user-wall.md whole and
# docs/work/README.md § Thread contract (working tree in both arms: the contract
# half already names the marker), extracted at run time, then the cards whole.
# With no tools the model sees every byte, so it is told to judge only on the
# parts the skill says to read.
#
# Credentials-only CLAUDE_CONFIG_DIR at <dir>/coldcfg, cwd <dir>/empty.
# Writes runs/<skill>-<tag>.prompt.md and .result.txt.
#
# Env knobs:
#   SKILL_REF=<git rev>  take SKILL.md + user-wall.md from that commit (HEAD = control)
#   NOCONTRACT=1         leave the § Thread contract excerpt out (probe: does the
#                        control read the date wait off the contract alone?)
#
# Usage: bash run.sh <dir> <tag> needs-me|autorun [model]   (<dir> absolute, outside this repo)
set -u
FX="${1:?usage: run.sh <dir> <tag> needs-me|autorun [model]}"
TAG="${2:?tag}"
SK="${3:?skill: needs-me|autorun}"
MODEL="${4:-sonnet}"
case "$SK" in needs-me|autorun) ;; *) echo "skill must be needs-me or autorun" >&2; exit 2;; esac
SRC="$(cd "$(dirname "$0")" && pwd)"
ROOT="$SRC/../.."
PL="plugins/super-bootstrap"
mkdir -p "$SRC/runs" "$FX/coldcfg" "$FX/empty"
[ -f "$HOME/.claude/.credentials.json" ] && cp "$HOME/.claude/.credentials.json" "$FX/coldcfg/"
printf '{ "hooks": {}, "enabledPlugins": {}, "permissions": { "allow": [] } }\n' > "$FX/coldcfg/settings.json"
CFG="$FX/coldcfg"
command -v cygpath >/dev/null 2>&1 && CFG="$(cygpath -m "$CFG")"

src() { if [ -n "${SKILL_REF:-}" ]; then git -C "$SRC" show "$SKILL_REF:$1"; else cat "$ROOT/$1"; fi; }
contract() { [ -n "${NOCONTRACT:-}" ] && { echo "(section omitted)"; return; }; awk '/^## Thread contract/{on=1; print; next} on && /^## /{exit} on' "$ROOT/docs/work/README.md"; }

P="$SRC/runs/$SK-$TAG.prompt.md"
{
  printf 'Do not use any tools. Answer from the text below only. Today is 2026-11-26.\n\n'
  printf 'You are the gateway session of /super-bootstrap:%s. The skill text you run under (`SKILL.md`) reads:\n\n---\n' "$SK"
  src "$PL/skills/$SK/SKILL.md"
  printf -- '---\n\n`${CLAUDE_PLUGIN_ROOT}/shared/user-wall.md` reads:\n\n---\n'
  src "$PL/shared/user-wall.md"
  printf -- '---\n\n`docs/work/README.md` reads, in part:\n\n---\n'
  contract
  printf -- '---\n\n'
  if [ "$SK" = needs-me ]; then
    printf 'The repo holds no `docs/test-queue.md`, no `docs/outward/`, no `docs/parked.md`. `docs/work/` holds `README.md`, `GAP-31.md`, `GAP-32.md`, `GAP-33.md`. Root `SESSION-STATE/` holds three files, shown below; a part the skill does not read does not exist for you.\n\n'
  else
    printf 'The repo holds no `docs/outward/`, no `.claude/worktrees/autorun-*` worktree, and `git branch --no-merged main` prints nothing. No card carries a `## Harness edits` block. Pre-flight passed.\n\n'
  fi
  cat "$SRC/cards.md"
  if [ "$SK" = needs-me ]; then
    cat "$SRC/carries.md"
    printf '%s\n' 'Run § Scan and the sort only — no lens question, no recommendation rows. Judge each card and carry only on the parts the skill says to read. Print, and nothing before it:' '' \
      '1. the SESSION-STATE pointer line exactly as the skill says to print it;' \
      "2. one line per card: \`{ID} → {where this card shows up in needs-me's output, in the skill's own words} — {one-line reason}\`;" \
      '3. any count lines § Recommend would print under its rows.' '' 'Then stop.'
  else
    printf '%s\n' 'Run § Pick only and print the pick block exactly as § Pick shows it (header, one `run:` or `skip:` line per card), nothing before it. Then stop.'
  fi
} > "$P"

(
  cd "$FX/empty" || exit 1
  CLAUDE_CONFIG_DIR="$CFG" timeout 300 claude -p --model "$MODEL" \
    --no-session-persistence < "$P"
) > "$SRC/runs/$SK-$TAG.result.txt" 2>&1
echo "exit=$?"
