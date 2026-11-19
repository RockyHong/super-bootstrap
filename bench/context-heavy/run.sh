#!/usr/bin/env bash
# run.sh — one headless run of the context-heavy micro-test.
# Usage: bash bench/context-heavy/run.sh <control|arm> <a|b|c|d> <fixture-dir> <out-file>
#
#   control — the surfaces as of 8cb9c9f, via git show
#   arm     — the working-tree surfaces (copy under test: this repo's dev copy)
#
# Builds a fresh fixture, embeds the surfaces verbatim in the prompt, runs with the fixture
# as cwd, writes stdout to <out-file>, then prints the fixture's tree state and the score.
set -eu
mode="${1:?usage: run.sh <control|arm> <a|b|c|d> <fixture-dir> <out-file>}"
scenario="${2:?scenario}"
fx="${3:?fixture dir}"
out="${4:?out file}"
here="$(cd "$(dirname "$0")" && pwd)"
repo="$(cd "$here/../.." && pwd)"
control_rev=8cb9c9f
claude_rel=CLAUDE.md
# The shipped copy of the two sections: assets/harness.md since the ownership split, the CLAUDE.md
# skeleton before it. control_rev predates the split, so the control arm still reads the skeleton.
assets_rel=plugins/super-bootstrap/skills/harness-bootstrap/assets
close_rel=plugins/super-bootstrap/skills/session-close/SKILL.md

case "$mode" in
  control) src() { git -C "$repo" show "$control_rev:$1"; }; shipped_rel="$assets_rel/claude-md-skeleton.md" ;;
  arm)     src() { cat "$repo/$1"; };                         shipped_rel="$assets_rel/harness.md" ;;
  *) echo "unknown mode: $mode" >&2; exit 64 ;;
esac
case "$scenario" in
  a|b|c|d) ;;
  *) echo "unknown scenario: $scenario" >&2; exit 64 ;;
esac

# The two sections by heading, wherever they sit: in root CLAUDE.md `## Rules` follows them, in
# harness.md `## Git Notes` does, so the slice ends at the next `## ` heading of any other name.
ambient() { src "$1" | tr -d '\r' | awk '/^## /{p = ($0 ~ /^## (Context Hygiene|Finding Triage)/)} p'; }
# dogfood side: this repo's root CLAUDE.md is still unsplit; it moves to .claude/rules/harness.md when the root file is split
hygiene="$(ambient "$claude_rel")"
shipped="$(ambient "$shipped_rel")"
if [ -z "$shipped" ]; then
  echo "parity: no § Context Hygiene / § Finding Triage in $shipped_rel ($mode)" >&2
  exit 3
fi
if [ "$hygiene" != "$shipped" ]; then
  echo "parity: CLAUDE.md and $shipped_rel differ in § Context Hygiene or § Finding Triage ($mode)" >&2
  exit 3
fi
shapes="$(src "$close_rel" | tr -d '\r' | awk '/^## Two terminal shapes/{p=1} /^## Ledger convention/{p=0} p')"

bash "$here/make-fixture.sh" "$fx" >/dev/null
prompt="$(cat "$here/prompt-$scenario.txt")

----- CLAUDE.md (excerpt) -----
$hygiene

----- skills/session-close/SKILL.md (excerpt) -----
$shapes"
( cd "$fx" && printf '%s\n' "$prompt" | claude -p --model haiku --allowedTools Bash \
    --setting-sources project,local --permission-prompts none ) > "$out" 2>&1 || true
echo "--- fixture after run: $fx"
git -C "$fx" log --oneline
git -C "$fx" status --short
echo "--- score"
bash "$here/score.sh" "$scenario" "$out" || true
