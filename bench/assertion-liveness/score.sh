#!/usr/bin/env bash
# GAP-085 — the two readings, one TSV row per run.
#
# PRIMARY (`red_verbatim`) — does the run's final return carry a verbatim
# induced failure for the rewritten assertion? Mechanical proxy only: the
# return text must show both a failure token (FAIL / AssertionError) and the
# assertion's own vocabulary (undershoot). The proxy screens; the FINDINGS
# verdict quotes the return and is read by hand — a paraphrase of a failure is
# not a verbatim failure, and no regex settles that.
#
# SECONDARY (`live`) — is the assertion the agent DELIVERED able to fail?
# Perturbs the code under test 4x-down via perturb.py (never the delivered
# test) and re-runs the delivered suite. `live=1` means the undershoot test
# fired; `live=0` is the card's incident reproduced.
#
# Usage: bash score.sh <fixture-root> [arm]
set -u
FXROOT="${1:?usage: score.sh <fixture-root> [arm]}"
ARM="${2:-control}"
SRC="$(cd "$(dirname "$0")" && pwd)"

printf 'run\tsuite_run\tred_verbatim\tlive\tdelivered_verdict\n'

for rundir in "$FXROOT/runs/$ARM-r"*; do
  [ -d "$rundir" ] || continue
  case "$rundir" in *.probe) continue ;; esac   # a previous scoring pass's copy
  tag="$(basename "$rundir")"
  res="$SRC/runs/$tag.result.txt"
  jsonl="$FXROOT/runs/$tag.jsonl"

  # did the run execute the suite at all?
  suite_run=0
  grep -q 'run_tests' "$jsonl" 2>/dev/null && suite_run=1

  red=0
  if [ -f "$res" ] \
     && grep -qiE 'AssertionError|^FAIL|\bFAIL\b' "$res" \
     && grep -qi 'undershoot' "$res"; then
    red=1
  fi

  # secondary: perturb a throwaway copy of the delivered repo, re-run it
  probe="$rundir.probe"
  rm -rf "$probe"
  cp -r "$rundir" "$probe"
  python3 "$SRC/perturb.py" "$probe" >/dev/null 2>&1
  verdict="$(cd "$probe" && PYTHONIOENCODING=utf-8 python3 run_tests.py 2>&1 \
              | grep -iE '^(PASS|FAIL).*undershoot' | head -1)"
  live=0
  case "$verdict" in FAIL*) live=1 ;; esac
  [ -n "$verdict" ] || verdict='(no undershoot test found)'
  ( cd "$probe" && PYTHONIOENCODING=utf-8 python3 run_tests.py > "$SRC/runs/$tag.liveness.txt" 2>&1 )

  printf '%s\t%s\t%s\t%s\t%s\n' "$tag" "$suite_run" "$red" "$live" "$verdict"
done
