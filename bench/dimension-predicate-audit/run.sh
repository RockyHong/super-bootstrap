#!/usr/bin/env bash
# run.sh <scratch-dir> <tag> <ref|worktree> [model]
# One headless audit of fixture.md against the predicate at <ref>, or the working tree.
set -eu
here=$(cd "$(dirname "$0")" && pwd)
root=$(git -C "$here" rev-parse --show-toplevel)
scratch=$1 tag=$2 ref=$3 model=${4:-sonnet}
asset=plugins/super-bootstrap/skills/check-docs-consistency/assets/dimension-predicate.md

case $ref in
  worktree) predicate=$(cat "$root/$asset") ;;
  *)        predicate=$(git -C "$root" show "$ref:$asset") ;;
esac

dir=$scratch/$tag
mkdir -p "$dir"
{
  echo 'Audit the state doc below against the predicate. The doc is a state doc in docs/specs/.'
  echo
  echo '<predicate>'
  printf '%s\n' "$predicate"
  echo '</predicate>'
  echo
  echo '<doc>'
  cat "$here/fixture.md"
  echo '</doc>'
  echo
  echo 'For each of L1, L2 and L3: FLAG if the predicate says the line must change or leave the doc, KEEP if the line may stay.'
  echo 'Print exactly three lines and nothing after them, in the form `L1: FLAG` or `L1: KEEP`.'
} > "$dir/prompt.md"

(cd "$dir" && claude -p --model "$model" --setting-sources project,local --permission-prompts none \
  < prompt.md) > "$dir/out.txt" 2>&1 || true

verdicts=$(tr -d '\r*`' < "$dir/out.txt" | grep -E '^L[123]: (FLAG|KEEP)' | tr '\n' ' ')
case "$verdicts" in
  'L1: FLAG L2: KEEP L3: FLAG '*) result=PASS ;;
  *) result=FAIL ;;
esac
printf '%s %s %s\n' "$tag" "$result" "$verdicts"
