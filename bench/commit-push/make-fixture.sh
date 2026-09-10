#!/usr/bin/env bash
# make-fixture.sh — scratch repo in one of three push-surface states.
# Usage: bash bench/commit-push/make-fixture.sh <dir> <none|remote|upstream>
#
#   none      — no git remote at all
#   remote    — a remote (local bare repo beside <dir>) but the branch has no upstream
#   upstream  — the same remote with the branch tracking it
#
# After: one initial commit (README.md a.md); a.md modified, unstaged (this session's work).
set -eu
dir="${1:?usage: make-fixture.sh <dir> <none|remote|upstream>}"
state="${2:?usage: make-fixture.sh <dir> <none|remote|upstream>}"
rm -rf "$dir" "$dir.remote.git"
mkdir -p "$dir"
cd "$dir"
git init -q -b main
git config user.name bench
git config user.email bench@example.invalid
git config core.autocrlf false
for f in README a; do printf '%s v1\n' "$f" > "$f.md"; done
git add README.md a.md
git commit -qm "init"
case "$state" in
  none) ;;
  remote|upstream)
    git init -q --bare "$dir.remote.git"
    git remote add origin "$dir.remote.git"
    if [ "$state" = upstream ]; then git push -q -u origin main; fi
    ;;
  *) echo "unknown state: $state" >&2; exit 2 ;;
esac
printf 'a v2\n' > a.md
echo "remote: $(git remote)"; echo "upstream: $(git rev-parse --abbrev-ref --symbolic-full-name '@{u}' 2>/dev/null || echo none)"
git status --short
