#!/usr/bin/env bash
# GAP-0cf5 — one cold headless merge run against a fresh batch-landing fixture.
#
# Builds <dir> with make-fixture.sh (f1/f2/f3 off init, f2 and f3 conflicting
# on the generated docs/roster.md once f1 is in), takes the merge SKILL.md
# whole (as it stands when the run fires), and runs
# `claude -p --model <model> --allowedTools Bash` cwd'd at <dir>/repo with that
# text + an instruction to land f1 f2 f3 into main and print the report.
#
# Writes bench/merge-batch/runs/<tag>.prompt.md (exact prompt),
#        <tag>.result.txt (final output), <tag>.state.txt (git state after:
#        graph, main's parents, branch ancestry, roster content vs a
#        regenerated roster, .bench-log, status), <tag>.err.txt when non-empty.
#
# Env knobs:
#   SKILL_REF=<git rev>  take the skill text from that commit (e.g. HEAD for the
#                        pre-batch body) instead of the working tree
#
# Usage: bash run.sh <dir> <tag> [model]   (<dir> absolute, outside this repo)
set -u
FX="${1:?usage: run.sh <dir> <tag> [model]}"
TAG="${2:?tag}"
MODEL="${3:-haiku}"
SRC="$(cd "$(dirname "$0")" && pwd)"
SKILL="$SRC/../../plugins/super-bootstrap/skills/merge/SKILL.md"
mkdir -p "$SRC/runs"
bash "$SRC/make-fixture.sh" "$FX" >/dev/null || { echo "fixture build failed" >&2; exit 1; }
CFG="$FX/coldcfg"
command -v cygpath >/dev/null 2>&1 && CFG="$(cygpath -m "$CFG")"

P="$SRC/runs/$TAG.prompt.md"
{
  printf 'You are running the merge skill below in this repository. Base branch: `main`.\n'
  printf 'Land the branches `f1` `f2` `f3` into `main`, in that order. I pre-confirm whatever strategy you recommend - execute it without waiting for a reply. Finish by printing your final report (the skill'"'"'s step 7 summary) as your final output.\n\n---\n\n'
  if [ -n "${SKILL_REF:-}" ]; then
    git -C "$SRC" show "$SKILL_REF:plugins/super-bootstrap/skills/merge/SKILL.md"
  else
    cat "$SKILL"
  fi
} > "$P"

(
  cd "$FX/repo" || exit 1
  CLAUDE_CONFIG_DIR="$CFG" timeout 600 claude -p --model "$MODEL" \
    --allowedTools Bash --no-session-persistence < "$P"
) > "$SRC/runs/$TAG.result.txt" 2> "$SRC/runs/$TAG.err.txt"
echo "exit=$?"
[ -s "$SRC/runs/$TAG.err.txt" ] || rm -f "$SRC/runs/$TAG.err.txt"

R="$FX/repo"
EXP="$FX/expected"
rm -rf "$EXP"; mkdir -p "$EXP/docs"
cp -r "$R/tools" "$EXP/"
git -C "$R" archive main features | tar -x -C "$EXP"
(cd "$EXP" && sh tools/roster.sh)
{
  echo "## git log --oneline --graph --all"; git -C "$R" log --oneline --graph --all
  echo "## main parents (first-parent chain)"; git -C "$R" rev-list --first-parent --parents main
  echo "## branches"; git -C "$R" branch -v
  for b in f1 f2 f3; do
    printf '## %s in main? ' "$b"; git -C "$R" merge-base --is-ancestor "$b" main && echo yes || echo no
  done
  echo "## main:docs/roster.md"; git -C "$R" show main:docs/roster.md
  printf '## roster equals regenerated from main:features? '
  git -C "$R" show main:docs/roster.md | diff -q - "$EXP/docs/roster.md" >/dev/null && echo yes || echo no
  echo "## .bench-log"; cat "$R/.bench-log" 2>/dev/null
  printf '## counts: roster=%s verify=%s\n' "$(grep -c '^roster$' "$R/.bench-log" 2>/dev/null)" "$(grep -c '^verify$' "$R/.bench-log" 2>/dev/null)"
  echo "## reflog main"; git -C "$R" reflog -15 main
  echo "## status"; git -C "$R" status --short --branch
} > "$SRC/runs/$TAG.state.txt" 2>&1
