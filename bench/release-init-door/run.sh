#!/usr/bin/env bash
# run.sh — one headless run of release-init § 9 to its end, on a fresh fixture.
# Usage: bash bench/release-init-door/run.sh <control|arm> <fixture-dir> [model]
#
#   control — release-init/SKILL.md at SKILL_REF (default HEAD): the text before the fix
#   arm     — the working-tree copy (copy under test: this repo's dev copy)
#
# Isolated from the device: no settings source, no MCP, a stub system prompt, so a push ask or a door
# call comes from the embedded skill text and not from a user-level instruction file or hook.
# Writes <dir>.out.txt, <dir>.trace (the agent's own git calls) and <dir>.door.log (skill.sh calls).
set -u
mode="${1:?usage: run.sh <control|arm> <fixture-dir> [model]}"
fx="${2:?fixture dir}"
model="${3:-haiku}"
here="$(cd "$(dirname "$0")" && pwd)"
repo="$(cd "$here/../.." && pwd)"
skill_rel=plugins/super-bootstrap/skills/release-init/SKILL.md
bash "$here/make-fixture.sh" "$fx" >/dev/null || exit 2
fx="$(cd "$fx" && pwd)"
rm -f "$fx.trace" "$fx.door.log" "$fx.out.txt"
case "$mode" in
  control) text="$(git -C "$repo" show "${SKILL_REF:-HEAD}:$skill_rel")" || exit 2 ;;
  arm) text="$(cat "$repo/$skill_rel")" ;;
  *) echo "unknown mode: $mode" >&2; exit 2 ;;
esac
prompt="$(sed "s|{{SKILL_SH}}|$here/skill.sh|" "$here/prompt.txt")

----- SKILL.md (release-init) -----
$text"
GIT_TRACE="$(cd "$(dirname "$fx")" && { pwd -W 2>/dev/null || pwd; })/$(basename "$fx").trace"
export GIT_TRACE
sys="You are a coding agent. Follow the user's prompt."
( cd "$fx" && printf '%s\n' "$prompt" | claude -p --model "$model" --allowedTools Bash --setting-sources "" \
    --strict-mcp-config --system-prompt "$sys" --permission-prompts none ) > "$fx.out.txt" 2>&1
unset GIT_TRACE
echo "== $mode $fx"
bash "$here/score.sh" "$fx.out.txt" "$fx"
