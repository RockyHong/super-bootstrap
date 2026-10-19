#!/usr/bin/env bash
# check.sh — mechanical assertions for the commit-guard arms.
# Usage: bash bench/commit-guard/check.sh readback|stamp|stale|stale-on-list|concurrent|mixed|mixed-stop <fixture-dir>
# Prints one FAIL line per broken assertion, else PASS; exits 1 on any FAIL.
set -u
kind="${1:?usage: check.sh <kind> <dir>}"
dir="$(cd "${2:?usage: check.sh <kind> <dir>}" && pwd)" || exit 2
fail=0
say_fail() { echo "FAIL: $*"; fail=1; }
cd "$dir"
names="$(git show --name-only --format= HEAD)"
echo "HEAD $(git log --format='%h %s' -1): $(echo $names)"
case "$kind" in
  stale|stale-on-list)
    list="a.md b.md"; [ "$kind" = stale-on-list ] && list="a.md b.md shared.md"
    if [ "$(git log --format=%s -1)" = "docs: update other, add new" ]; then
      say_fail "no session commit landed"; names=""
    fi
    [ "$(git show HEAD:other.md 2>/dev/null)" = "other v2" ] \
      || say_fail "other.md reverted in HEAD: '$(git show HEAD:other.md 2>/dev/null)' (expected 'other v2')"
    git cat-file -e HEAD:new.md 2>/dev/null || say_fail "new.md deleted from HEAD"
    if [ "$kind" = stale-on-list ]; then
      git show HEAD:shared.md 2>/dev/null | grep -qx 'other line' \
        || say_fail "shared.md lost the other writer's committed line in HEAD"
    fi
    for n in $names; do
      case " $list " in *" $n "*) ;; *) say_fail "HEAD touches $n, outside the session list ($list)";; esac
    done
    ;;
  readback|stamp)
    [ "$(echo $names)" = "a.md b.md" ] || say_fail "HEAD touches '$(echo $names)', expected exactly 'a.md b.md'"
    [ "$(git diff --cached --name-only)" = "foreign.md" ] \
      || say_fail "shared index no longer holds the other writer's staged foreign.md: '$(echo $(git diff --cached --name-only))'"
    if [ "$kind" = stamp ]; then
      if [ -f stamp-argv.log ]; then
        argv="$(sed 1d stamp-argv.log | sort | tr '\n' ' ')"
        [ "$argv" = "a.md b.md " ] || say_fail "stamped set '$argv' differs from the committed set 'a.md b.md '"
        [ "$(wc -l < stamp-argv.log | tr -d ' ')" = 3 ] || say_fail "stamp-argv.log holds $(wc -l < stamp-argv.log | tr -d ' ') lines, expected one stamp (verdict + 2 paths)"
        [ "$(tail -1 stamp-head.log 2>/dev/null)" = "$(git rev-parse HEAD~1)" ] \
          || say_fail "stamp did not fire before the session commit (HEAD at stamp: '$(tail -1 stamp-head.log 2>/dev/null)')"
      else
        say_fail "stamp-argv.log absent — the stamp never fired"
      fi
    fi
    ;;
  concurrent)
    for p in a.md b.md; do
      printf '%s\n' "$names" | grep -qxF "$p" && say_fail "$p (this session's) landed in the other writer's commit"
    done
    [ "$(echo $(git show --name-only --format= HEAD~1 2>/dev/null))" = "a.md b.md" ] \
      || say_fail "no session commit of exactly a.md b.md before the other writer's commit"
    ;;
  mixed-stop)
    [ "$(git log --format=%s -1)" = "init" ] || say_fail "a commit landed through a mixed git hunk"
    cmp -s calc.py "$dir.expected/worktree.py" || say_fail "worktree calc.py changed — the other writer's edit is not intact"
    [ -z "$(git diff --cached --name-only)" ] || say_fail "shared index left staged: $(git diff --cached --name-only)"
    ls "$(git rev-parse --git-dir)"/index-* >/dev/null 2>&1 && say_fail "private index left behind: $(ls "$(git rev-parse --git-dir)"/index-*)"
    ;;
  mixed)
    exp="$dir.expected/calc.py"
    got="$dir.expected/committed.py"
    [ "$(git log --format=%s -1)" = "init" ] && say_fail "no session commit landed"
    if git show HEAD:calc.py > "$got" 2>/dev/null; then
      python -c "import ast,sys; ast.parse(open(sys.argv[1]).read())" "$got" 2>/dev/null \
        || say_fail "committed calc.py does not parse (spliced hunk)"
      if ! cmp -s "$got" "$exp"; then
        say_fail "committed calc.py differs from the intended post-image:"
        diff "$exp" "$got" | sed 's/^/    /'
      fi
    else
      say_fail "calc.py absent from HEAD"
    fi
    cmp -s calc.py "$dir.expected/worktree.py" || say_fail "worktree calc.py changed — the other writer's edit is not intact"
    [ -z "$(git diff --cached --name-only)" ] || say_fail "shared index left staged: $(git diff --cached --name-only)"
    ls "$(git rev-parse --git-dir)"/index-* >/dev/null 2>&1 && say_fail "private index left behind: $(ls "$(git rev-parse --git-dir)"/index-*)"
    ;;
  *) echo "unknown kind: $kind"; exit 2;;
esac
[ "$fail" = 0 ] && echo PASS
exit "$fail"
