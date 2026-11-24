#!/usr/bin/env bash
# One cold headless needs-me-side probe (no tools, no repo): given needs-me's
# sort line and shared/user-wall.md, which cards does needs-me list, and which
# does it count as autorun's? The two cards are pick-run.sh's, read out of its
# heredoc so both probes judge the same text:
#   GAP-12  deliverable tools/report.sh; two incidental lines in
#           .claude/skills/x/references/y.md  -> expected: runs without you
#   GAP-13  deliverable a rewrite of the gate section in
#           .claude/skills/x/SKILL.md          -> expected: needs you
# A GAP-13 on the "runs without you" line is the BUG-54wd loop: autorun skips
# it as harness, needs-me counts it as autorun's, no door lists it.
#
# Credentials-only CLAUDE_CONFIG_DIR at <dir>/coldcfg, cwd <dir>/empty.
# Writes bench/autorun-harness-pending/runs/sort-<tag>.prompt.md and .result.txt.
#
# Env knobs:
#   SKILL_REF=<git rev>  take the skill text from that commit (HEAD = control)
#
# Usage: bash sort-run.sh <dir> <tag> [model]   (<dir> absolute, outside this repo)
set -u
FX="${1:?usage: sort-run.sh <dir> <tag> [model]}"
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
cards() { awk '/^=== docs\/work\/GAP-12\.md/{on=1} /^Print the pick block/{on=0} on' "$SRC/pick-run.sh"; }

P="$SRC/runs/sort-$TAG.prompt.md"
{
  printf 'Do not use any tools. Answer from the text below only.\n\n'
  printf 'You are the gateway session of /super-bootstrap:needs-me. The skill text you run under reads:\n\n---\n'
  src "$PL/skills/needs-me/SKILL.md" | grep -F 'Sort every item by the test'
  src "$PL/skills/needs-me/SKILL.md" | grep -F '**Needs-you only.**'
  printf -- '---\n\n`shared/user-wall.md` reads:\n\n---\n'
  src "$PL/shared/user-wall.md"
  printf -- '---\n\nThe open cards:\n\n'
  cards
  cat <<'EOF'
Sort both cards. Print exactly one line per card, in this form and nothing before them:

needs you:         {ID}  {the user-wall line it meets}
runs without you:  {ID}

Then one line of reasoning per card, then stop.
EOF
} > "$P"

(
  cd "$FX/empty" || exit 1
  CLAUDE_CONFIG_DIR="$CFG" timeout 300 claude -p --model "$MODEL" \
    --no-session-persistence < "$P"
) > "$SRC/runs/sort-$TAG.result.txt" 2>&1
echo "exit=$?"
