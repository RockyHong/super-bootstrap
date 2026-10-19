#!/usr/bin/env bash
# repro-stale.sh — deterministic shell reproduction of the stale-entry mechanism, no model.
# Usage: bash bench/commit-guard/repro-stale.sh <dir> [--on-list]
# Builds the make-fixture-stale.sh repo, then runs the plain shared-index sequence with the
# readback skipped — `git add <session list>` + `git commit` — and runs `check.sh`. This is the
# mechanism the consumer hit, and the bite for `check.sh stale` / `stale-on-list`; it is not a
# run of current § 5, whose readback stops on the stale paths (README § Findings).
set -eu
here="$(cd "$(dirname "$0")" && pwd)"
dir="${1:?usage: repro-stale.sh <dir> [--on-list]}"
flag="${2:-}"
bash "$here/make-fixture-stale.sh" "$dir" $flag >/dev/null
kind=stale; list="a.md b.md"
if [ "$flag" = "--on-list" ]; then kind=stale-on-list; list="a.md b.md shared.md"; fi
(
  cd "$dir"
  # shellcheck disable=SC2086
  git add -- $list
  git commit -qm "docs: session work"
)
bash "$here/check.sh" "$kind" "$dir"
