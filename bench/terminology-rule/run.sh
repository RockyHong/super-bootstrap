#!/usr/bin/env bash
# run.sh <scratch-dir> <tag> <ref> [model]
#   ref = HEAD (control: the committed rule text) | worktree (arm: the working-tree rule text)
# Builds <scratch-dir>/<tag>/repo from fixture/, runs one headless authoring task with the
# ssot-doc-link rule text embedded verbatim in the prompt, scores the authored section.
set -eu
here=$(cd "$(dirname "$0")" && pwd)
root=$(git -C "$here" rev-parse --show-toplevel)
scratch=$1 tag=$2 ref=$3 model=${4:-sonnet}
rule=.claude/rules/ssot-doc-link.md

case $ref in
  worktree) rule_text=$(cat "$root/$rule") ;;
  *)        rule_text=$(git -C "$root" show "$ref:$rule") ;;
esac

repo=$scratch/$tag/repo
rm -rf "$scratch/$tag"; mkdir -p "$repo"
cp -R "$here/fixture/." "$repo/"
case ${VARIANT:-a} in b|c) cp -R "$here/fixture-b/." "$repo/" ;; esac
[ "${VARIANT:-a}" = c ] && cp -R "$here/fixture-c/." "$repo/"
git -C "$repo" init -q && git -C "$repo" add -A && git -C "$repo" -c user.name=bench -c user.email=bench@local commit -qm fixture

mkdir -p "$here/runs"
prompt=$here/runs/$tag.prompt.md
{
  echo "You are editing the docs of a recipe-scaling app. Follow this repo's doc-authoring rule, quoted in full:"
  echo
  echo '<rule>'
  printf '%s\n' "$rule_text"
  echo '</rule>'
  echo
  echo 'Task: add a `## Generation` section to `docs/specs/shopping-list.md`, between the intro line and `## Display`.'
  echo 'It says: when the cook scales a recipe run, the list is built from every deficit against their inventory;'
  echo 'an ingredient the inventory already covers is left off; deficits from two runs of the same ingredient merge into one item.'
  echo 'One short paragraph. Edit only that file. Reply "done" when finished.'
} > "$prompt"

(cd "$repo" && claude -p --model "$model" --setting-sources project,local --permission-prompts none \
  --allowedTools "Read,Edit,Write,Glob,Grep" < "$prompt") > "$here/runs/$tag.result.txt" 2>&1 || true

section=$here/runs/$tag.section.md
awk '/^## Generation/{f=1} /^## Display/{f=0} f' "$repo/docs/specs/shopping-list.md" > "$section"
{
  echo "tag=$tag ref=$ref model=$model variant=${VARIANT:-a}"
  echo "links-terminology: $(grep -o 'terminology\.md' "$section" | wc -l)"
  echo "links-pantry-spec: $(grep -o 'pantry\.md' "$section" | wc -l)"
  echo "avoid-words: $(grep -o -i -w -E 'deficits?|inventory|stock list|missing items?|runs?|scaled recipes?' "$section" | tr '\n' ' ')"
  echo "registered-terms: $(grep -o -w -E 'Batch(es)?|Pantry|Shortfalls?' "$section" | tr '\n' ' ')"
} | tee "$here/runs/$tag.score.txt"
