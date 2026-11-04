#!/usr/bin/env bash
# push-state.sh — reads the repo's shape for session-close: whether commits can go out, and how many wait.
#
# Usage (run from the repo root):
#   bash push-state.sh move [--landing]   the command to offer as one line, or nothing
#   bash push-state.sh state              `ahead N` or `no upstream`, or nothing
#
# `--landing`: the close holds a commit or merge move, so an in-sync branch will be ahead once it lands.
# Empty output is the answer, not a gap: no remote, a detached HEAD, a branch with no commits, no remote to
# pick among several, or outside a repo. A push that would be rejected (behind, diverged) still prints when
# ahead is above 0, and the rejection surfaces at run time. A behind branch with ahead 0 prints nothing, even
# under `--landing`: its push would be rejected, so the close offers none. No output ever carries a force flag.
# Exit 0 for every repo state; exit 2 on a bad argument.
set -u

usage() {
  echo "usage: push-state.sh move [--landing] | push-state.sh state" >&2
  exit 2
}

landing=0
mode="${1:-}"
case "$#:$mode:${2:-}" in
  1:move:|1:state:) ;;
  2:move:--landing) landing=1 ;;
  *) usage ;;
esac

remotes="$(git remote 2>/dev/null)" || exit 0
[ -n "$remotes" ] || exit 0
branch="$(git symbolic-ref -q --short HEAD 2>/dev/null)" || exit 0
git rev-parse -q --verify HEAD >/dev/null 2>&1 || exit 0

# A printed line gets run, and a ref name may hold shell characters.
shell_word() {
  case "$1" in
    *[!A-Za-z0-9._/@+-]*) printf "'%s'" "$(printf '%s' "$1" | sed "s/'/'\\\\''/g")" ;;
    *) printf '%s' "$1" ;;
  esac
}

# `<behind><TAB><ahead>`; fails when @{u} does not resolve.
if counts="$(git rev-list --left-right --count '@{u}...HEAD' 2>/dev/null)"; then
  behind="${counts%%[!0-9]*}"
  ahead="${counts##*[!0-9]}"
  if [ "$mode" = state ]; then
    echo "ahead $ahead"
  elif [ "$ahead" -gt 0 ]; then
    echo 'git push'
  elif [ "$landing" = 1 ] && [ "$behind" = 0 ]; then
    echo 'git push'
  fi
  exit 0
fi

[ "$mode" = state ] && { echo "no upstream"; exit 0; }

nl='
'
case "$remotes" in
  *"$nl"*)
    case "$nl$remotes$nl" in
      *"${nl}origin${nl}"*) remote=origin ;;
      *) exit 0 ;;
    esac ;;
  *) remote="$remotes" ;;
esac
printf 'git push -u %s %s\n' "$(shell_word "$remote")" "$(shell_word "$branch")"
