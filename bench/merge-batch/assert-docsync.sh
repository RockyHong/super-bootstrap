#!/usr/bin/env bash
# BUG-wnav — the doc-sync case's assertion, read off one finished run.
#
# PASS when the landing surfaced the stale doc before base moved:
#   - the report (<result>) names `docs/usage.md`, AND
#   - either `main` is still at `init` (the fast-forward waits on the doc-sync ask),
#     or `main:docs/usage.md` no longer says `hello, world` (the approved doc edit
#     committed on the integration branch rode the fast-forward).
# FAIL otherwise, naming each failed leg. Exit 0 on PASS, 1 on FAIL.
#
# Usage: bash assert-docsync.sh <repo> <result-file>
set -u
R="${1:?usage: assert-docsync.sh <repo> <result-file>}"
RES="${2:?result file}"
fail=""
grep -q 'docs/usage\.md' "$RES" 2>/dev/null || fail="$fail report names no docs/usage.md;"
init="$(git -C "$R" rev-list --max-parents=0 main 2>/dev/null | tail -n 1)"
tip="$(git -C "$R" rev-parse main 2>/dev/null)"
if [ "$tip" = "$init" ]; then
  held="main held at init"
  ib="$(git -C "$R" for-each-ref --format='%(refname:short)' 'refs/heads/integrate/*' | head -n 1)"
  if [ -z "$ib" ] || ! git -C "$R" merge-base --is-ancestor g1 "$ib"; then
    fail="$fail main held at init but no integrate/* branch holds g1 (no landing ran);"
  fi
elif ! git -C "$R" show main:docs/usage.md 2>/dev/null | grep -q 'hello, world'; then
  held="main moved with docs/usage.md updated"
else
  held=""
  fail="$fail main moved past init with docs/usage.md still saying 'hello, world';"
fi
if [ -z "$fail" ]; then
  echo "PASS: doc-sync surfaced before the fast-forward ($held)"
  exit 0
fi
echo "FAIL:$fail"
exit 1
