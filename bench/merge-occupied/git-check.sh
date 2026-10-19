#!/usr/bin/env bash
# BUG-g6at — mechanism pin: the two git forms merge § 5 can take on an occupied branch.
#
# Builds a fresh fixture (make-fixture.sh) under <dir>, then on <dir>/repo:
#   detect   `git worktree list --porcelain` names feature/x under a worktree
#            other than the current one
#   rebase   `git rebase main feature/x` (§ 5's rebase form) exits non-zero
#            with "already used by worktree" (older git: "is already checked out at"), and leaves no unmerged paths,
#            no rebase in progress, a clean tree, and main checked out
#   no-ff    `git merge feature/x --no-ff` exits 0, lands feature/x in main
#            as a two-parent merge commit, and leaves wt-x on feature/x
# Prints PASS/FAIL per assertion; exits 1 on any FAIL.
#
# Usage: bash git-check.sh <dir>   (absolute path outside this repo)
set -u
FX="${1:?usage: git-check.sh <dir>}"
SRC="$(cd "$(dirname "$0")" && pwd)"
bash "$SRC/make-fixture.sh" "$FX" >/dev/null || { echo "FAIL fixture build" >&2; exit 1; }
R="$FX/repo"
fails=0
check() { if [ "$1" = 0 ]; then echo "PASS $2"; else echo "FAIL $2"; fails=$((fails + 1)); fi; }

top="$(git -C "$R" rev-parse --show-toplevel)"
occupied="$(git -C "$R" worktree list --porcelain | awk -v top="$top" '
  /^worktree /{wt=substr($0,10)} /^branch refs\/heads\//{ if (wt != top) print substr($0,19) }')"
echo "occupied by another worktree: ${occupied:-<none>}"
[ "$occupied" = "feature/x" ]; check $? "detect: porcelain names feature/x as occupied"

out="$(git -C "$R" rebase main feature/x 2>&1)"; rc=$?
echo "rebase exit=$rc: $out"
[ "$rc" != 0 ]; check $? "rebase: exits non-zero"
case "$out" in *"already used by worktree"*|*"is already checked out at"*) r=0 ;; *) r=1 ;; esac; check $r "rebase: refuses as checked out in another worktree"
[ -z "$(git -C "$R" diff --name-only --diff-filter=U)" ]; check $? "rebase: no unmerged paths (nothing to resolve)"
gd="$(git -C "$R" rev-parse --absolute-git-dir)"
[ ! -d "$gd/rebase-merge" ] && [ ! -d "$gd/rebase-apply" ]; check $? "rebase: no rebase in progress (nothing to abort)"
[ -z "$(git -C "$R" status --porcelain)" ] && [ "$(git -C "$R" branch --show-current)" = main ]; check $? "rebase: tree clean, main still checked out"

out="$(git -C "$R" merge feature/x --no-ff -m "merge feature/x" 2>&1)"; rc=$?
echo "merge --no-ff exit=$rc: $out"
[ "$rc" = 0 ]; check $? "no-ff: exits 0"
git -C "$R" merge-base --is-ancestor feature/x main; check $? "no-ff: feature/x is in main"
[ "$(git -C "$R" rev-list --parents -n 1 main | wc -w | tr -d ' ')" = 3 ]; check $? "no-ff: main HEAD is a two-parent merge commit"
[ "$(git -C "$FX/wt-x" branch --show-current)" = feature/x ]; check $? "no-ff: wt-x still holds feature/x"

echo "fails=$fails"
[ "$fails" = 0 ]
