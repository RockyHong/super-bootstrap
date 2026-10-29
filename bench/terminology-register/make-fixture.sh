#!/usr/bin/env bash
# make-fixture.sh — scratch repo + headless prompt for the doc-sync term-registration lane.
# Usage: bash bench/terminology-register/make-fixture.sh <dir> <control|arm> <recall|precision>
#
#   control — commit/SKILL.md + agents/doc-sync-scan.md at CONTROL_REV (before the lane),
#             with <skill-base> = that revision's commit skill, exported beside <dir>
#   arm     — the working-tree copies, with <skill-base> = this checkout's commit skill
#
# After: one base commit (fixture/base), built with plumbing (write-tree + commit-tree +
# update-ref) so a dispatched builder can run this script; the case's post-image copied
# over it, unstaged — the session's work. <dir>.prompt.md holds the prompt, the skill and
# agent text embedded verbatim. Zero LLM calls.
set -eu
usage="usage: make-fixture.sh <dir> <control|arm> <recall|precision>"
dir="${1:?$usage}"
arm="${2:?$usage}"
case_="${3:?$usage}"
HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT="$(git -C "$HERE" rev-parse --show-toplevel)"
CONTROL_REV=290121e
SKILL=plugins/super-bootstrap/skills/commit/SKILL.md
AGENT=plugins/super-bootstrap/agents/doc-sync-scan.md

case "$case_" in
  recall)    edited=docs/operations.md ;;
  precision) edited=docs/maintenance.md ;;
  *) echo "unknown case: $case_" >&2; exit 2 ;;
esac

rm -rf "$dir" "$dir.plugin" "$dir.prompt.md"
mkdir -p "$dir"
cp -R "$HERE/fixture/base/." "$dir/"
cd "$dir"
git init -q -b main
git config user.name bench
git config user.email bench@example.invalid
git config core.autocrlf false
git add -A
tree="$(git write-tree)"
base_commit="$(git commit-tree "$tree" -m init)"
git update-ref refs/heads/main "$base_commit"
cp -R "$HERE/fixture/$case_/." "$dir/"

body() { awk 'NR==1 && /^---$/ {fm=1; next} fm && /^---$/ {fm=0; next} !fm'; }

case "$arm" in
  control)
    mkdir -p "$dir.plugin"
    git -C "$ROOT" archive "$CONTROL_REV" plugins/super-bootstrap | tar -x -C "$dir.plugin"
    base="$dir.plugin/plugins/super-bootstrap/skills/commit"
    skill_text="$(git -C "$ROOT" show "$CONTROL_REV:$SKILL" | body)"
    agent_text="$(git -C "$ROOT" show "$CONTROL_REV:$AGENT" | body)"
    copy="$CONTROL_REV (committed, before the registration lane)" ;;
  arm)
    base="$ROOT/plugins/super-bootstrap/skills/commit"
    skill_text="$(body < "$ROOT/$SKILL")"
    agent_text="$(body < "$ROOT/$AGENT")"
    copy="working tree of $ROOT" ;;
  *) echo "unknown arm: $arm" >&2; exit 2 ;;
esac

{
cat <<EOF
You are the gateway session at the commit door of the repository in your current
directory. This session edited one file, file grain: \`$edited\`. Run the commit skill
below, sections 1 through 4 only, exactly as written. \`<skill-base>\` is \`$base\` —
run its scripts with \`bash\`.

Stop before section 5: do not commit, do not stage, and do not edit any file. Where the
skill says to surface something to the user, or to resolve it with the user, write it
into your reply instead. End your reply with a section headed \`## Surfaced to the user\`
that lists every item the door would surface for this commit, one bullet each, or
\`(none)\`.

## commit/SKILL.md

\`\`\`\`markdown
$skill_text
\`\`\`\`

## agents/doc-sync-scan.md

\`\`\`\`markdown
$agent_text
\`\`\`\`
EOF
} > "$dir.prompt.md"

echo "copy under test: $copy"
git status --short
