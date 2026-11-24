#!/usr/bin/env bash
# BUG-wnav — one cold headless batch landing against the doc-sync fixture.
#
# Builds <dir> with make-fixture-docsync.sh (g1 changes what tools/greet.sh prints,
# docs/usage.md still narrates the old output; g2 narrates nothing), snapshots the
# plugin's skills + agents into <dir>/plugin (from the working tree, or from
# SKILL_REF=<git rev>), and runs `claude -p --model <model>` cwd'd at <dir>/repo
# with the merge SKILL.md inline + the plugin root, so `/super-bootstrap:<name>`
# resolves to <dir>/plugin/skills/<name>/SKILL.md.
#
# Writes bench/merge-batch/runs/<tag>.prompt.md, <tag>.result.txt, <tag>.state.txt
# (graph, main's reflog, main:docs/usage.md, integrate/* branches, status, and the
# assert-docsync.sh verdict as its last line).
#
# Usage: bash run-docsync.sh <dir> <tag> [model]   (<dir> absolute, outside this repo)
set -u
FX="${1:?usage: run-docsync.sh <dir> <tag> [model]}"
TAG="${2:?tag}"
MODEL="${3:-haiku}"
SRC="$(cd "$(dirname "$0")" && pwd)"
TOP="$(cd "$SRC/../.." && pwd)"
mkdir -p "$SRC/runs"
bash "$SRC/make-fixture-docsync.sh" "$FX" >/dev/null || { echo "fixture build failed" >&2; exit 1; }
rm -rf "$FX/plugin"; mkdir -p "$FX/plugin"
if [ -n "${SKILL_REF:-}" ]; then
  git -C "$TOP" archive "$SKILL_REF" plugins/super-bootstrap/skills plugins/super-bootstrap/agents \
    | tar -x -C "$FX/plugin"
else
  mkdir -p "$FX/plugin/plugins/super-bootstrap"
  cp -r "$TOP/plugins/super-bootstrap/skills" "$TOP/plugins/super-bootstrap/agents" "$FX/plugin/plugins/super-bootstrap/"
fi
PR="$FX/plugin/plugins/super-bootstrap"
CFG="$FX/coldcfg"
if command -v cygpath >/dev/null 2>&1; then CFG="$(cygpath -m "$CFG")"; PRW="$(cygpath -m "$PR")"; else PRW="$PR"; fi

P="$SRC/runs/$TAG.prompt.md"
{
  printf 'You are running the merge skill below in this repository. Base branch: `main`.\n'
  printf 'Land the branches `g1` `g2` into `main` with `--batch`, in that order. I pre-confirm whatever merge strategy you recommend - execute it without waiting for a reply. Any other question the skill puts to me: print it and stop there (I cannot reply in this run). Finish by printing your final report (the skill'"'"'s step 7 summary, or where you stopped and why) as your final output.\n\n'
  printf 'Plugin root: `%s`. A skill named `/super-bootstrap:<name>` is the file `%s/skills/<name>/SKILL.md` - read it there and follow it; its `<skill-base>` is that file'"'"'s directory. Agents named in a skill are `%s/agents/<name>.md`.\n\n---\n\n' "$PRW" "$PRW" "$PRW"
  cat "$PR/skills/merge/SKILL.md"
} > "$P"

(
  cd "$FX/repo" || exit 1
  CLAUDE_CONFIG_DIR="$CFG" timeout 900 claude -p --model "$MODEL" \
    --allowedTools Bash,Read,Edit --no-session-persistence < "$P"
) > "$SRC/runs/$TAG.result.txt" 2> "$SRC/runs/$TAG.err.txt"
echo "exit=$?"
[ -s "$SRC/runs/$TAG.err.txt" ] || rm -f "$SRC/runs/$TAG.err.txt"

R="$FX/repo"
{
  echo "## git log --oneline --graph --all"; git -C "$R" log --oneline --graph --all
  echo "## reflog main"; git -C "$R" reflog -15 main
  echo "## integrate/* branches"; git -C "$R" for-each-ref --format='%(refname:short) %(objectname:short)' 'refs/heads/integrate/*'
  for b in g1 g2; do
    printf '## %s in main? ' "$b"; git -C "$R" merge-base --is-ancestor "$b" main && echo yes || echo no
  done
  echo "## main:docs/usage.md"; git -C "$R" show main:docs/usage.md
  echo "## status"; git -C "$R" status --short --branch
  echo "## assert"; bash "$SRC/assert-docsync.sh" "$R" "$SRC/runs/$TAG.result.txt"
} > "$SRC/runs/$TAG.state.txt" 2>&1
tail -n 1 "$SRC/runs/$TAG.state.txt"
