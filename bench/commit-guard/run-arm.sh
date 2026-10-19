#!/usr/bin/env bash
# run-arm.sh — one headless run of an arm against the shipped § 5: build the fixture, pipe
# arm-prompt.sh's prompt to `claude -p` with the fixture as cwd, then run check.sh.
# Usage: bash bench/commit-guard/run-arm.sh <arm> <dir> [model]
#   arm: readback (also runs the concurrent arm: other-writer.sh after the session's turn) |
#        stamp | stale | stale-on-list | mixed | mixed-adjacent | mixed-interleaved
# The model transcript lands in <dir>.turn1.txt (and <dir>.turn2.txt when a second turn ran).
# A second turn (`--continue`, granting the say-so) runs only for readback / stamp / stale arms
# whose first turn landed no commit; a mixed arm's stop is its answer, so it gets no second turn.
set -u
here="$(cd "$(dirname "$0")" && pwd)"
arm="${1:?usage: run-arm.sh <arm> <dir> [model]}"
dir="${2:?usage: run-arm.sh <arm> <dir> [model]}"
model="${3:-haiku}"
case "$arm" in
  readback|stamp) bash "$here/make-fixture.sh" "$dir" >/dev/null; prompt_kind="$arm" ;;
  stale) bash "$here/make-fixture-stale.sh" "$dir" >/dev/null; prompt_kind=stale ;;
  stale-on-list) bash "$here/make-fixture-stale.sh" "$dir" --on-list >/dev/null; prompt_kind=stale-on-list ;;
  mixed) bash "$here/make-fixture-mixed.sh" "$dir" >/dev/null; prompt_kind=mixed ;;
  mixed-adjacent) bash "$here/make-fixture-mixed.sh" "$dir" --adjacent >/dev/null; prompt_kind=mixed ;;
  mixed-interleaved) bash "$here/make-fixture-mixed.sh" "$dir" --interleaved >/dev/null; prompt_kind=mixed ;;
  mixed-verify-pass|mixed-verify-fail) bash "$here/make-fixture-mixed.sh" "$dir" >/dev/null; prompt_kind=mixed ;;
  *) echo "unknown arm: $arm" >&2; exit 2 ;;
esac
[ "$arm" = stamp ] && cp "$here/stamp-recorder.sh" "$dir/"
dir="$(cd "$dir" && pwd)"
case "$arm" in
  mixed-verify-*)
    # Declare a staged-tree verify command in a committed docs/techstack.md. -pass parses
    # calc.py; -fail also demands the other writer's area() guard, which only the working
    # tree holds — green there, red on the tree about to commit. Each run logs its cwd.
    log="$(cd "$dir" && { pwd -W 2>/dev/null || pwd; }).verify.log"  # native path: python opens it
    cmd="python -c \"import ast,os; ast.parse(open('calc.py').read()); open(r'$log','a').write(os.getcwd()+chr(10))\""
    [ "$arm" = mixed-verify-fail ] && cmd="$cmd && grep -q 'negative size' calc.py"
    mkdir -p "$dir/docs"
    printf '# Tech Stack\n\n## Staged-Tree Verify\n\n```sh\n%s\n```\n' "$cmd" > "$dir/docs/techstack.md"
    git -C "$dir" add docs/techstack.md
    git -C "$dir" -c core.hooksPath=/dev/null commit -qm "init" ;;
esac
start="$(git -C "$dir" rev-parse HEAD)"
bash "$here/arm-prompt.sh" "$prompt_kind" \
  | (cd "$dir" && claude -p --model "$model" --allowedTools Bash) > "$dir.turn1.txt" 2>&1
case "$arm" in
  mixed*) ;;
  *)
    if [ "$(git -C "$dir" rev-parse HEAD)" = "$start" ]; then
      echo "The user's say-so: continue with the procedure's remedy and finish the commit." \
        | (cd "$dir" && claude -p --continue --model "$model" --allowedTools Bash) > "$dir.turn2.txt" 2>&1
    fi
    ;;
esac
case "$arm" in
  readback)
    bash "$here/check.sh" readback "$dir"
    bash "$here/other-writer.sh" "$dir" || echo "other-writer: nothing to commit"
    bash "$here/check.sh" concurrent "$dir" ;;
  stamp) bash "$here/check.sh" stamp "$dir" ;;
  stale|stale-on-list) bash "$here/check.sh" "$arm" "$dir" ;;
  mixed|mixed-verify-pass) bash "$here/check.sh" mixed "$dir" ;;
  mixed-*) bash "$here/check.sh" mixed-stop "$dir" ;;
esac
case "$arm" in
  mixed-verify-*)
    if [ -s "$dir.verify.log" ]; then echo "verify ran in: $(tr '\n' ' ' < "$dir.verify.log")"
    else echo "FAIL: the declared verify command never ran"; fi ;;
esac
