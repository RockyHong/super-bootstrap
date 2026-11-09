#!/usr/bin/env bash
# run.sh — one headless trial of the doc-rule `paths:` tail micro-test.
# Usage: bash bench/rule-paths-tail/run.sh <control|arm> <out-file> <neutral-cwd>
#
#   control — harness-bootstrap/SKILL.md as of e34057d (pre-change)
#   arm     — the working-tree SKILL.md (copy under test: this repo's dev copy)
#
# Excerpts lifted from the chosen SKILL.md, verbatim, by line prefix:
#   - every bullet that starts "- `.claude/rules/ssot-doc-link.md`" except the § 2c stage
#     line (Pipeline-owned in both arms; Project-owned in the arm)
#   - the § 2b "- **Exists, drifted in pipeline-owned section**" bullet
#   - the § 2a placement paragraph "`.claude/rules/` machinery is **always** scaffolded"
#   - the Phase 3 paragraph starting "**Doc-rule coverage" (arm only; absent in control)
# The agent runs with no tools in <neutral-cwd> (outside this repo, so it cannot read the
# answer off CLAUDE.md or the commit log). stdout goes to <out-file>.
set -eu
mode="${1:?usage: run.sh <control|arm> <out-file> <neutral-cwd>}"
out="${2:?out file}"
cwd="${3:?neutral cwd}"
here="$(cd "$(dirname "$0")" && pwd)"
repo="$(cd "$here/../.." && pwd)"
skill_rel=plugins/super-bootstrap/skills/harness-bootstrap/SKILL.md
case "$mode" in
  control) src="$(git -C "$repo" show e34057d:"$skill_rel")" ;;
  arm)     src="$(cat "$repo/$skill_rel")" ;;
  *) echo "unknown mode: $mode" >&2; exit 2 ;;
esac
ex="$(printf '%s\n' "$src" | awk '
  /^- `\.claude\/rules\/ssot-doc-link\.md`/ && !/if newly written/ {print; print ""; next}
  /^- \*\*Exists, drifted in pipeline-owned section\*\*/ {print; print ""; next}
  /^`\.claude\/rules\/` machinery is \*\*always\*\* scaffolded/ {print; print ""; next}
  /^\*\*Doc-rule coverage/ {on=1}
  on && /^$/ {on=0; print ""; next}
  on {print}
')"
[ -n "$ex" ] || { echo "excerpts not found" >&2; exit 3; }
mkdir -p "$cwd"
prompt="$(EX="$ex" awk '{ if ($0 == "@EXCERPTS@") print ENVIRON["EX"]; else print }' "$here/prompt.txt")"
( cd "$cwd" && printf '%s\n' "$prompt" | claude -p --model "${MODEL:-haiku}" --tools "" \
    --setting-sources project,local --permission-prompts none ) > "$out" 2>&1 || true
cat "$out"
