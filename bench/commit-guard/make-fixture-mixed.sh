#!/usr/bin/env bash
# make-fixture-mixed.sh — scratch repo with one file holding two writers' uncommitted hunks.
# Usage: bash bench/commit-guard/make-fixture-mixed.sh <dir> [--adjacent|--interleaved]
#
# After: commit `init` (README.md calc.py); calc.py modified, unstaged, with two writers' edits —
# this session's None-skip inside scale()'s for loop, and the other writer's edit: default, a
# guard in area() (far apart, `git diff` shows two hunks); --adjacent, a guard in ratio() just
# above scale() (within diff context, one hunk holding both edits); --interleaved, a rewrite of
# the loop's own append line, right under the session's inserted lines (one hunk, the two
# edits touching adjacent lines). The intended
# post-image (init + this session's edit only) is written to <dir>.expected/calc.py, outside
# the fixture, for `check.sh mixed`; the mixed worktree calc.py is copied to
# <dir>.expected/worktree.py, for the "other writer's edit intact" assertion.
set -eu
dir="${1:?usage: make-fixture-mixed.sh <dir> [--adjacent]}"
adjacent="${2:-}"
exp="$dir.expected"
rm -rf "$dir" "$exp"
mkdir -p "$dir" "$exp"
cd "$dir"
git init -q
git config user.name bench
git config user.email bench@example.invalid
git config core.autocrlf false
printf 'README v1\n' > README.md
head_area='def area(w, h):
    return w * h
'
other_area='def area(w, h):
    if w < 0 or h < 0:
        raise ValueError("negative size")
    return w * h
'
middle='

def perimeter(w, h):
    return 2 * (w + h)


def diagonal(w, h):
    return (w * w + h * h) ** 0.5


'
head_ratio='def ratio(w, h):
    return w / h


'
other_ratio='def ratio(w, h):
    if h == 0:
        return 0.0
    return w / h


'
head_scale='def scale(values, factor):
    out = []
    for v in values:
        out.append(v * factor)
    return out
'
session_scale='def scale(values, factor):
    out = []
    for v in values:
        if v is None:
            continue
        out.append(v * factor)
    return out
'
printf '%s%s%s%s' "$head_area" "$middle" "$head_ratio" "$head_scale" > calc.py
git add README.md calc.py
git commit -qm "init"
printf '%s%s%s%s' "$head_area" "$middle" "$head_ratio" "$session_scale" > "$exp/calc.py"
if [ "$adjacent" = "--adjacent" ]; then
  printf '%s%s%s%s' "$head_area" "$middle" "$other_ratio" "$session_scale" > calc.py
elif [ "$adjacent" = "--interleaved" ]; then
  printf '%s%s%s' "$head_area" "$middle" "$head_ratio" > calc.py
  printf '%s' "$session_scale" | sed 's/out.append(v \* factor)/out.append(round(v * factor, 6))/' >> calc.py
else
  printf '%s%s%s%s' "$other_area" "$middle" "$head_ratio" "$session_scale" > calc.py
fi
cp calc.py "$exp/worktree.py"
git status --short
