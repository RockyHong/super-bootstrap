#!/usr/bin/env bash
# run.sh <scratch-dir> <tag> <ref> [model]
#   ref = HEAD (control: the committed rule text) | worktree (arm: the working-tree rule text)
# Builds <scratch-dir>/<tag>/repo from fixture/, runs one headless authoring task with the
# dimension-discipline rule text embedded verbatim in the prompt, scores the edited state doc.
set -eu
here=$(cd "$(dirname "$0")" && pwd)
root=$(git -C "$here" rev-parse --show-toplevel)
scratch=$1 tag=$2 ref=$3 model=${4:-sonnet}
rule=plugins/super-bootstrap/skills/harness-bootstrap/assets/rules-dimension-discipline-skeleton.md

case $ref in
  worktree) rule_text=$(cat "$root/$rule") ;;
  *)        rule_text=$(git -C "$root" show "$ref:$rule") ;;
esac

repo=$scratch/$tag/repo
rm -rf "$scratch/$tag"; mkdir -p "$repo"
cp -R "$here/fixture/." "$repo/"
git -C "$repo" init -q

mkdir -p "$here/runs"
prompt=$here/runs/$tag.prompt.md
{
  echo "You are editing the docs of a photo backup service. Follow this repo's doc-authoring rule, quoted in full:"
  echo
  echo '<rule>'
  printf '%s\n' "$rule_text"
  echo '</rule>'
  echo
  echo 'Task: add a `## Known limitations` section to `docs/specs/upload.md`, between `## Retries` and `## Storage`.'
  echo 'It says: a resumable upload over 2 GB restarts from byte zero after a dropped connection, instead of from the last chunk.'
  echo 'The fix is in progress and has an open card under `docs/work/`. People reading this spec run into the limitation and ask where the fix stands, so make that easy for them to find out.'
  echo 'One short paragraph. Edit only that file. Reply "done" when finished.'
} > "$prompt"

(cd "$repo" && claude -p --model "$model" --setting-sources project,local --permission-prompts none \
  --allowedTools "Read,Edit,Write,Glob,Grep" < "$prompt") > "$here/runs/$tag.result.txt" 2>&1 || true

doc=$repo/docs/specs/upload.md
section=$here/runs/$tag.section.md
awk '/^## Known limitations/{f=1; print; next} /^## /{f=0} f' "$doc" > "$section"
{
  echo "tag=$tag ref=$ref model=$model"
  echo "section-lines: $(grep -c . "$section" || true)"
  echo "states-limitation: $(grep -c -E '2 ?GB' "$section" || true)"
  echo "id-hits: $(grep -o -E '\b(BUG|DEBT|GAP|OUT|PARK)-[0-9a-z]+\b' "$doc" | tr '\n' ' ' || true)"
  echo "work-path-hits: $(grep -o -E 'docs/work|\.\./work' "$doc" | wc -l)"
  echo "git-grep-hits: $(grep -o -E 'git log --grep' "$doc" | wc -l)"
} | tee "$here/runs/$tag.score.txt"
