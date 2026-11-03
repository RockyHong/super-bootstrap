#!/usr/bin/env bash
# run.sh — one headless two-turn walk of session-close: turn 1 stops at the pick, turn 2 runs it.
# Usage: bash bench/session-close-moves/run.sh <control|arm> <full|resolve|fixnow> <fixture-dir>
#
#   control — session-close + commit SKILL.md + doc-sync-scan at CONTROL_REV, exported beside the fixture
#   arm     — the working-tree copies (copy under test: this repo's dev copy)
#
# Writes <dir>.turn1.txt, <dir>.turn2.txt and <dir>.trace, git's own record of every command the run
# issued. Scores turn 1 before turn 2 runs. Pass a <fixture-dir> outside this repo.
set -u
mode="${1:?usage: run.sh <control|arm> <scenario> <fixture-dir>}"
scenario="${2:?scenario}"
fx="${3:?fixture dir}"
here="$(cd "$(dirname "$0")" && pwd)"
repo="$(cd "$here/../.." && pwd)"
CONTROL_REV=35b4c3e
close_rel=plugins/super-bootstrap/skills/session-close/SKILL.md
commit_rel=plugins/super-bootstrap/skills/commit/SKILL.md
agent_rel=plugins/super-bootstrap/agents/doc-sync-scan.md
bash "$here/make-fixture.sh" "$scenario" "$fx" >/dev/null || exit 2
fx="$(cd "$fx" && pwd)"
rm -rf "$fx.plugin" "$fx.trace"
case "$mode" in
  control)
    mkdir -p "$fx.plugin"
    git -C "$repo" archive "$CONTROL_REV" plugins/super-bootstrap | tar -x -C "$fx.plugin"
    root="$fx.plugin" ;;
  arm) root="$repo" ;;
  *) echo "unknown mode: $mode" >&2; exit 2 ;;
esac
# A native absolute path: git writes the trace to that file, so the run never sees it.
GIT_TRACE="$(cd "$(dirname "$fx")" && { pwd -W 2>/dev/null || pwd; })/$(basename "$fx").trace"
export GIT_TRACE
prompt="$(cat "$here/prompt-head.txt" "$here/prompt-$scenario.txt" "$here/prompt-tail.txt")

----- SKILL.md (session-close) -----
$(cat "$root/$close_rel")

----- SKILL.md (commit) -----
$(cat "$root/$commit_rel")

----- agents/doc-sync-scan.md -----
$(cat "$root/$agent_rel")

----- <skill-base> of the commit skill -----
$root/plugins/super-bootstrap/skills/commit"
flags="--model sonnet --allowedTools Bash --setting-sources project,local --permission-prompts none"
( cd "$fx" && printf '%s\n' "$prompt" | claude -p $flags ) > "$fx.turn1.txt" 2>&1
echo "== pick $mode $scenario $fx"
bash "$here/score-pick.sh" "$scenario" "$fx.turn1.txt" "$fx"
# Turn 2 writes the picked rows: Edit and Write join Bash, or a headless run has no way to land an edit.
flags2="--model sonnet --allowedTools Bash,Read,Edit,Write --setting-sources project,local --permission-prompts none"
( cd "$fx" && claude -p --continue $flags2 < "$here/prompt-turn2.txt" ) > "$fx.turn2.txt" 2>&1
echo "== walk $mode $scenario $fx"
bash "$here/score-walk.sh" "$scenario" "$fx"
