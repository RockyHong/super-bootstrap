#!/usr/bin/env bash
# run.sh — one headless run of harness-bootstrap § 2a-scale + the scale members of § 2b, python3 hidden.
# Usage: bash bench/split-outward-degrade/run.sh <control|arm> <fixture-dir> [model]
#
#   control — harness-bootstrap/SKILL.md at SKILL_REF (default HEAD): the text before the fix
#   arm     — the working-tree copy (copy under test: this repo's dev copy)
#
# python3 is hidden: PATH drops every entry naming python / conda / WindowsApps; HOME points at an empty
# dir, so the Bash tool's login profile cannot re-add them; a shim first on PATH answers `py` (the launcher
# in C:/Windows, which PATH keeps) with `command not found` (exit 127). The scale
# assets are copied to <dir>.plugin, so the run never reads or writes the repo. No settings source, no
# MCP, a stub system prompt. Writes <dir>.out.txt.
set -u
mode="${1:?usage: run.sh <control|arm> <fixture-dir> [model]}"
fx="${2:?fixture dir}"
model="${3:-haiku}"
here="$(cd "$(dirname "$0")" && pwd)"
repo="$(cd "$here/../.." && pwd)"
skill_rel=plugins/super-bootstrap/skills/harness-bootstrap/SKILL.md
bash "$here/make-fixture.sh" "$fx" >/dev/null || exit 2
fx="$(cd "$fx" && pwd)"
rm -f "$fx.out.txt"
case "$mode" in
  control) git -C "$repo" show "${SKILL_REF:-HEAD}:$skill_rel" > "$fx.skill.md" || exit 2 ;;
  arm) cp "$repo/$skill_rel" "$fx.skill.md" ;;
  *) echo "unknown mode: $mode" >&2; exit 2 ;;
esac
plug="$fx.plugin"
rm -rf "$plug" "$fx.shim" "$fx.home"
mkdir -p "$plug/skills/harness-bootstrap/assets" "$fx.shim"
cp -r "$repo/plugins/super-bootstrap/skills/harness-bootstrap/assets/scale" "$plug/skills/harness-bootstrap/assets/"
for n in py; do
  printf '#!/usr/bin/env bash\necho "bash: %s: command not found" >&2\nexit 127\n' "$n" > "$fx.shim/$n"
  chmod +x "$fx.shim/$n"
done
path="$(printf '%s' "$PATH" | tr ':' '\n' | grep -viE 'python|conda|WindowsApps' | paste -sd: -)"
prompt="$(sed "s|{{PLUGIN_ROOT}}|$plug|" "$here/prompt.txt")

----- SKILL.md (harness-bootstrap — Phase 2 intro and § 2a-scale) -----
$(bash "$here/extract.sh" "$fx.skill.md")"
sys="You are a coding agent. Follow the user's prompt."
mkdir -p "$fx.home"
( cd "$fx" && export PATH="$fx.shim:$path" HOME="$fx.home" CLAUDE_PLUGIN_ROOT="$plug" && printf '%s\n' "$prompt" | \
    claude -p --model "$model" --allowedTools "Bash Read Write Edit Glob Grep" --setting-sources "" \
    --strict-mcp-config --system-prompt "$sys" --permission-prompts none ) > "$fx.out.txt" 2>&1
echo "== $mode $fx"
bash "$here/score.sh" "$fx.out.txt" "$fx"
