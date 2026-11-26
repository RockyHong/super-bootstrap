#!/usr/bin/env bash
# One cold headless card-append probe (no tools, no repo): the model is handed the
# shipped card Thread contract, the doctrine line that places settled design on the
# card thread, and one scenario (a small repo listing, the files it needs whole, and
# a task), then prints every file write it would make in a fixed shape.
#
# The contract is the shipped asset's § Thread contract
# (plugins/super-bootstrap/skills/harness-bootstrap/assets/work-readme-skeleton.md),
# extracted at run time; the doctrine line is assets/harness.md's
# "Settled design and step sequence land as ..." line, the same in both arms.
#
# Credentials-only CLAUDE_CONFIG_DIR at <dir>/coldcfg, cwd <dir>/empty.
# Writes runs/<scenario>-<tag>.prompt.md and .result.txt.
#
# Env knobs:
#   SKILL_REF=<git rev>  take the contract from that commit (HEAD before the edit = control)
#
# Usage: bash run.sh <dir> <scenario: s1|s2|s3> <tag> [model]   (<dir> absolute, outside this repo)
set -u
FX="${1:?usage: run.sh <dir> <scenario> <tag> [model]}"
SC="${2:?scenario}"
TAG="${3:?tag}"
MODEL="${4:-sonnet}"
SRC="$(cd "$(dirname "$0")" && pwd)"
ROOT="$SRC/../.."
A="plugins/super-bootstrap/skills/harness-bootstrap/assets"
SCF="$(ls "$SRC/scenarios/$SC"-*.md 2>/dev/null | head -1)"
[ -n "$SCF" ] || { echo "no scenario $SC"; exit 2; }
mkdir -p "$SRC/runs" "$FX/coldcfg" "$FX/empty"
[ -f "$HOME/.claude/.credentials.json" ] && cp "$HOME/.claude/.credentials.json" "$FX/coldcfg/"
printf '{ "hooks": {}, "enabledPlugins": {}, "permissions": { "allow": [] } }\n' > "$FX/coldcfg/settings.json"
CFG="$FX/coldcfg"
command -v cygpath >/dev/null 2>&1 && CFG="$(cygpath -m "$CFG")"

src() { if [ -n "${SKILL_REF:-}" ]; then git -C "$SRC" show "$SKILL_REF:$1"; else cat "$ROOT/$1"; fi; }
contract() { src "$A/work-readme-skeleton.md" | awk '/^## Thread contract/{on=1; print; next} on && /^## /{exit} on'; }

P="$SRC/runs/$SC-$TAG.prompt.md"
{
  printf 'Do not use any tools. Answer from the text below only.\n\n'
  printf 'You are a Claude Code session working in a repo that runs the super-bootstrap harness. Its workflow doctrine says, in part:\n\n---\n'
  grep -m1 '^Settled design and step sequence land as' "$ROOT/$A/harness.md"
  printf -- '---\n\n`docs/work/README.md` reads, in part:\n\n---\n'
  contract
  printf -- '---\n\n'
  cat "$SCF"
  printf '\nPrint every file write you would make, and nothing else, each in this shape:\n\n'
  printf '=== WRITE {repo-relative path} ===\n{the exact text you append or the full new section, as it would land in the file}\n=== END ===\n\n'
  printf 'Print one such block per file you touch. Touch only the files the task needs.\n'
} > "$P"

(
  cd "$FX/empty" || exit 1
  CLAUDE_CONFIG_DIR="$CFG" timeout 300 claude -p --model "$MODEL" \
    --no-session-persistence < "$P"
) > "$SRC/runs/$SC-$TAG.result.txt" 2>&1
echo "exit=$?"
