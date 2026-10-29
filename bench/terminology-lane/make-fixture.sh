#!/usr/bin/env bash
# make-fixture.sh — scratch repo + headless prompt for the commit door's terminology lane.
# Usage: bash bench/terminology-lane/make-fixture.sh <dir> <control|arm>
#
#   control — commit/SKILL.md + agents/doc-sync-scan.md at CONTROL_REV (before the lane),
#             with <skill-base> = that revision's commit skill, exported beside <dir>
#   arm     — the working-tree copies, with <skill-base> = this checkout's commit skill
#
# After: one base commit (docs/terminology.md, docs/operations.md, docs/maintenance.md);
# operations.md and maintenance.md modified, unstaged — the session's work. <dir>.prompt.md
# holds the prompt, the skill and agent text embedded verbatim. Zero LLM calls.
set -eu
dir="${1:?usage: make-fixture.sh <dir> <control|arm>}"
arm="${2:?usage: make-fixture.sh <dir> <control|arm>}"
HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT="$(git -C "$HERE" rev-parse --show-toplevel)"
CONTROL_REV=8267934
SKILL=plugins/super-bootstrap/skills/commit/SKILL.md
AGENT=plugins/super-bootstrap/agents/doc-sync-scan.md

rm -rf "$dir" "$dir.plugin" "$dir.prompt.md"
mkdir -p "$dir"
cp -R "$HERE/fixture/base/." "$dir/"
cd "$dir"
git init -q -b main
git config user.name bench
git config user.email bench@example.invalid
git config core.autocrlf false
git add -A
git commit -qm "init"
cp -R "$HERE/fixture/change/." "$dir/"

body() { awk 'NR==1 && /^---$/ {fm=1; next} fm && /^---$/ {fm=0; next} !fm'; }

case "$arm" in
  control)
    mkdir -p "$dir.plugin"
    git -C "$ROOT" archive "$CONTROL_REV" plugins/super-bootstrap | tar -x -C "$dir.plugin"
    base="$dir.plugin/plugins/super-bootstrap/skills/commit"
    skill_text="$(git -C "$ROOT" show "$CONTROL_REV:$SKILL" | body)"
    agent_text="$(git -C "$ROOT" show "$CONTROL_REV:$AGENT" | body)"
    copy="$CONTROL_REV (committed, before the terminology lane)" ;;
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
directory. This session edited two files, both file grain: \`docs/operations.md\` and
\`docs/maintenance.md\`. Run the commit skill below, sections 1 through 4 only, exactly
as written. \`<skill-base>\` is \`$base\` — run its scripts with \`bash\`.

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
