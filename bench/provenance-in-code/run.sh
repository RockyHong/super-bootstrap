#!/usr/bin/env bash
# run.sh <scratch-dir> <tag> <ref> [model]
#   ref = HEAD (control: the committed assets) | worktree (arm: the working-tree assets)
# Builds <scratch-dir>/<tag>/repo from fixture/, places the shipped doctrine and the
# dimension-discipline rule under .claude/rules/ as a bootstrapped repo holds them, runs one
# headless card-pickup task, and scores the added lines outside the tracker folder.
set -eu
here=$(cd "$(dirname "$0")" && pwd)
root=$(git -C "$here" rev-parse --show-toplevel)
scratch=$1 tag=$2 ref=$3 model=${4:-sonnet}
assets=plugins/super-bootstrap/skills/harness-bootstrap/assets

asset() {
  case $ref in
    worktree) cat "$root/$assets/$1" ;;
    *)        git -C "$root" show "$ref:$assets/$1" ;;
  esac
}

repo=$scratch/$tag/repo
rm -rf "$scratch/$tag"; mkdir -p "$repo/.claude/rules"
cp -R "$here/fixture/." "$repo/"
asset harness.md > "$repo/.claude/rules/harness.md"
asset rules-dimension-discipline-skeleton.md > "$repo/.claude/rules/dimension-discipline.md"
git -C "$repo" init -q
git -C "$repo" add -A
git -C "$repo" -c user.name=bench -c user.email=bench@example.invalid commit -q -m init

mkdir -p "$here/runs"
prompt=$here/runs/$tag.prompt.md
printf '%s\n' \
  'Pick up BUG-r4k8 and fix it, with tests. Run the tests.' \
  'Leave the card file in place and do not commit — I will review the diff first.' \
  'Reply "done" when finished.' > "$prompt"

(cd "$repo" && claude -p --model "$model" --setting-sources project,local --permission-prompts none \
  --allowedTools "Read,Edit,Write,Glob,Grep,Bash(python *),Bash(pytest *)" < "$prompt") \
  > "$here/runs/$tag.result.txt" 2>&1 || true

git -C "$repo" add -A
added=$here/runs/$tag.added.txt
git -C "$repo" diff --cached -U0 HEAD -- . ':(exclude)docs/work' \
  | awk '/^\+\+\+ /{f=$2; next} /^\+/{print f ": " substr($0,2)}' > "$added"

hits() { grep -i -E "$1" "$added" | wc -l | tr -d ' '; }
{
  echo "tag=$tag ref=$ref model=$model"
  echo "added-lines: $(wc -l < "$added" | tr -d ' ')"
  echo "files: $(cut -d: -f1 "$added" | sort -u | tr '\n' ' ')"
  echo "id-hits: $(hits '\b(BUG|DEBT|GAP|OUT|PARK)-[0-9a-z]+\b')"
  echo "date-hits: $(hits '\b20[0-9]{2}-[01][0-9]-[0-3][0-9]\b')"
  echo "precedent-hits: $(hits '\b(previously|used to|old go|last quarter|was (clamp|silent)|rejected|decided|decision|per the (card|design)|as of|fix(ed|es)? for|regression for)\b')"
  echo "card-path-hits: $(hits 'docs/work')"
} | tee "$here/runs/$tag.score.txt"
