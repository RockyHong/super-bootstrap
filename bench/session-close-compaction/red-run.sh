#!/usr/bin/env bash
# red-run.sh — one headless arm of the session-close compaction-caveat RED.
# Usage: bash bench/session-close-compaction/red-run.sh <control|arm> <tagonly|compacted> <fixture-dir> <out-file>
#
#   control — session-close SKILL.md as committed at HEAD (git show)
#   arm     — the working-tree SKILL.md
# Fixture: the inflight bench's make-fixture.sh (called, not copied). Pass an absolute, fresh
# <fixture-dir> with a Windows-form path (C:/...) outside the repo and outside %TEMP%/claude/.
set -eu
mode="${1:?usage: red-run.sh <control|arm> <tagonly|compacted> <fixture-dir> <out-file>}"
scen="${2:?tagonly|compacted}"
fx="${3:?fixture dir}"
out="${4:?out file}"
here="$(cd "$(dirname "$0")" && pwd)"
repo="$(cd "$here/../.." && pwd)"
skill_rel=plugins/super-bootstrap/skills/session-close/SKILL.md
case "$mode" in
  control) skill="$(git -C "$repo" show HEAD:"$skill_rel")" ;;
  arm)     skill="$(cat "$repo/$skill_rel")" ;;
  *) echo "unknown mode: $mode" >&2; exit 2 ;;
esac
case "$scen" in tagonly|compacted) ;; *) echo "unknown scenario: $scen" >&2; exit 2 ;; esac
bash "$here/../session-close-inflight/make-fixture.sh" "$fx" >/dev/null
prompt="$(cat "$here/red-prompt-$scen.txt")

----- SKILL.md (session-close) -----
$skill

----- <skill-base> of the session-close skill -----
$repo/plugins/super-bootstrap/skills/session-close"
# RED_MODEL picks the arm's model (default haiku); the live false caveats were printed by larger models.
( cd "$fx" && printf '%s\n' "$prompt" | claude -p --model "${RED_MODEL:-haiku}" --allowedTools Bash \
    --setting-sources project,local --permission-prompts none ) > "$out" 2>&1 || true
echo "--- fixture after run: $fx"
git -C "$fx" log --oneline
git -C "$fx" status --short
