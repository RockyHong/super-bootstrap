#!/usr/bin/env bash
# run.sh — one headless run of the spike route micro-test.
# Usage: bash bench/spike-route/run.sh <control|arm> <fixture-dir>
#
#   control — CLAUDE.md § The envelope + § Cluster routing at CONTROL_REV
#   arm     — the same sections of the working-tree CLAUDE.md
#
# Isolated from the device: no settings source, no MCP, a stub system prompt. Writes the ordered tool
# calls to <dir>.stream.jsonl, then scores them.
set -u
mode="${1:?usage: run.sh <control|arm> <fixture-dir>}"
fx="${2:?fixture dir}"
here="$(cd "$(dirname "$0")" && pwd)"
repo="$(cd "$here/../.." && pwd)"
CONTROL_REV=bb069c4
case "$mode" in
  control) text="$(git -C "$repo" show "$CONTROL_REV:CLAUDE.md")" ;;
  arm)     text="$(cat "$repo/CLAUDE.md")" ;;
  *) echo "unknown mode: $mode" >&2; exit 2 ;;
esac
excerpt="$(printf '%s\n' "$text" | tr -d '\r' | awk '/^### The envelope/{on=1} /^### Framing/{on=0} on')"
bash "$here/make-fixture.sh" "$fx" >/dev/null || exit 2
fx="$(cd "$fx" && pwd)"
prompt="$(cat "$here/prompt.txt")

----- CLAUDE.md excerpt -----
$excerpt"
( cd "$fx" && printf '%s\n' "$prompt" | claude -p --model sonnet --allowedTools Bash,Read,Edit,Write \
    --setting-sources "" --strict-mcp-config --system-prompt "You are a coding agent. Follow the user's prompt." \
    --permission-prompts none --output-format stream-json --verbose ) > "$fx.stream.jsonl" 2>&1
echo "== $mode $fx"
python "$(cd "$here" && { pwd -W 2>/dev/null || pwd; })/score.py" "$(cd "$(dirname "$fx")" && { pwd -W 2>/dev/null || pwd; })/$(basename "$fx").stream.jsonl"
bash "$here/score-state.sh" "$fx"
