#!/usr/bin/env bash
# repro-release.sh — deterministic shell reproduction of the /release step 5 race, no model.
# Usage: bash bench/commit-guard/repro-release.sh add|pathspec <dir>
# Builds a scratch repo: two version files (pkg/plugin.json, marketplace.json) bumped 1.0.0 →
# 1.0.1, unstaged, and foreign.md modified and staged by another writer. Runs release-init's
# step 5 in one of two forms up to its tag, lets other-writer.sh commit the shared index, then
# asserts. `add` — `git add` of the version files, `--cached` readback, which finds foreign.md
# and stops. `pathspec` — `git diff HEAD --name-only` readback, then `git commit -o`.
# Prints one FAIL line per broken assertion, else PASS; exits 1 on any FAIL.
set -eu
here="$(cd "$(dirname "$0")" && pwd)"
mode="${1:?usage: repro-release.sh add|pathspec <dir>}"
dir="${2:?usage: repro-release.sh add|pathspec <dir>}"
vfiles="pkg/plugin.json marketplace.json"
rm -rf "$dir"
mkdir -p "$dir/pkg"
(
  cd "$dir"
  git init -q
  git config user.name bench
  git config user.email bench@example.invalid
  git config core.autocrlf false
  printf '{ "version": "1.0.0" }\n' > pkg/plugin.json
  printf '{ "plugins": [] }\n' > marketplace.json
  printf 'foreign v1\n' > foreign.md
  git add pkg/plugin.json marketplace.json foreign.md
  git commit -qm "init"
  printf 'foreign v2\n' > foreign.md
  git add foreign.md
  printf '{ "version": "1.0.1" }\n' > pkg/plugin.json
  printf '{ "plugins": [ { "description": "v1.0.1" } ] }\n' > marketplace.json
)
(
  cd "$dir"
  case "$mode" in
    add)
      git add $vfiles
      foreign="$(git diff --cached --name-only | grep -vxF -e pkg/plugin.json -e marketplace.json || true)"
      if [ -n "$foreign" ]; then
        echo "readback: stop and surface — staged outside the version files: $foreign"
      else
        git commit -qm "chore: release v1.0.1"
        git tag -a v1.0.1 --cleanup=verbatim -m "release notes"
      fi
      ;;
    pathspec)
      got="$(echo $(git diff HEAD --name-only -- $vfiles))"
      if [ "$got" != "marketplace.json pkg/plugin.json" ]; then
        echo "readback: stop — version files without a change: '$got'"
      else
        git commit -qo -m "chore: release v1.0.1" -- $vfiles
        git tag -a v1.0.1 --cleanup=verbatim -m "release notes"
      fi
      ;;
    *) echo "unknown mode: $mode" >&2; exit 2 ;;
  esac
)
bash "$here/other-writer.sh" "$dir" >/dev/null
cd "$dir"
fail=0
say_fail() { echo "FAIL: $*"; fail=1; }
writer="$(echo $(git show --name-only --format= HEAD))"
echo "other writer's commit: $writer"
for p in $vfiles; do
  case " $writer " in *" $p "*) say_fail "$p (the release's) landed in the other writer's commit";; esac
done
[ "$writer" = "foreign.md" ] || say_fail "other writer's commit holds '$writer', expected exactly 'foreign.md'"
if git rev-parse -q --verify refs/tags/v1.0.1 >/dev/null; then
  tagged="$(echo $(git show --name-only --format= v1.0.1^{commit}))"
  [ "$tagged" = "marketplace.json pkg/plugin.json" ] \
    || say_fail "release commit holds '$tagged', expected exactly 'marketplace.json pkg/plugin.json'"
  [ "$(git rev-parse v1.0.1^{commit})" = "$(git rev-parse HEAD~1)" ] \
    || say_fail "release commit is not the one before the other writer's commit"
else
  say_fail "no release commit tagged v1.0.1"
fi
[ "$fail" -eq 0 ] && echo PASS
exit "$fail"
