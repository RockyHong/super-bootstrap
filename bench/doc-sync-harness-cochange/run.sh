#!/usr/bin/env bash
# run.sh — one headless gateway walk of the commit door's §3–§4 on the co-change fixture.
# Usage: bash bench/doc-sync-harness-cochange/run.sh <control|arm> <fixture-dir>
#
#   control — commit SKILL.md, doc-sync-scan.md and claude-md-skeleton.md at CONTROL_REV
#   arm     — the working-tree copies (copy under test: this repo's dev copy)
#
# Writes <dir>.out.txt and scores it. Pass a <fixture-dir> outside this repo.
set -u
mode="${1:?usage: run.sh <control|arm> <fixture-dir>}"
fx="${2:?fixture dir}"
here="$(cd "$(dirname "$0")" && pwd)"
repo="$(cd "$here/../.." && pwd)"
CONTROL_REV=5c5c165
commit_rel=plugins/super-bootstrap/skills/commit/SKILL.md
agent_rel=plugins/super-bootstrap/agents/doc-sync-scan.md
mkdir -p "$fx"
fx="$(cd "$fx" && pwd)"
case "$mode" in
  control)
    rm -rf "$fx.plugin"; mkdir -p "$fx.plugin"
    git -C "$repo" archive "$CONTROL_REV" plugins/super-bootstrap | tar -x -C "$fx.plugin"
    root="$fx.plugin" ;;
  arm) root="$repo" ;;
  *) echo "unknown mode: $mode" >&2; exit 2 ;;
esac
bash "$here/make-fixture.sh" "$fx" "$root" >/dev/null || exit 2
prompt="$(cat "$here/prompt.txt")

----- SKILL.md (commit) -----
$(cat "$root/$commit_rel")

----- agents/doc-sync-scan.md -----
$(cat "$root/$agent_rel")

----- <skill-base> of the commit skill -----
$root/plugins/super-bootstrap/skills/commit"
flags="--model sonnet --allowedTools Bash,Read,Grep,Glob --setting-sources project,local --permission-prompts none"
( cd "$fx" && printf '%s\n' "$prompt" | claude -p $flags ) > "$fx.out.txt" 2>&1
echo "== $mode $fx"
bash "$here/score.sh" "$fx.out.txt" "$fx"
