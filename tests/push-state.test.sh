#!/usr/bin/env bash
# L1 unit tests for push-state.sh — the check behind session-close's push move.
# Targets the PLUGIN ASSET (source of truth). Remotes are local bare repos under a temp dir.
#
# Contract pinned here:
#   - `push-state.sh move [--landing]` prints exactly one line, the command to offer, or nothing:
#     no remote or detached HEAD -> nothing; an upstream and ahead above 0 -> `git push`; no upstream ->
#     `git push -u <remote> <branch>`, <remote> being the only remote, or `origin` among several, else
#     nothing. `--landing` makes an in-sync branch with an upstream print `git push`. Behind with 0 ahead
#     prints nothing, with or without it. A force flag never appears.
#   - `push-state.sh state` prints `ahead N` or `no upstream`, or nothing with no remote or a detached HEAD.
#   - Every repo state exits 0 with empty stderr. A bad argument exits 2 with usage on stderr.
#
# Usage: bash tests/push-state.test.sh           the assertions
#        bash tests/push-state.test.sh --bite    runs them on one mutant per rule, prints each FAIL line,
#                                                and fails unless every assertion failed on some mutant
set -uo pipefail

REPO="$(cd "$(dirname "$0")/.." && pwd)"
ASSET="$REPO/plugins/super-bootstrap/skills/session-close/assets/push-state.sh"
PS="${PUSH_STATE:-$ASSET}"  # override = bite-check a mutant

TMP="$(mktemp -d)"
trap 'rm -rf "$TMP"' EXIT

if [ "${1:-}" = "--bite" ]; then
  [ -f "$ASSET" ] || { echo "  FAIL: asset missing: $ASSET"; exit 1; }
  labels="$(bash "$0" | sed -n 's/^  ok: //p')"
  : > "$TMP/hit"
  bites=0; dead=0
  mutant() { # mutant <name> <sed expression>
    sed -e "$2" "$ASSET" > "$TMP/mutant.sh"
    echo "== mutant: $1"
    if cmp -s "$ASSET" "$TMP/mutant.sh"; then echo "  MUTANT DID NOT APPLY"; dead=$((dead+1)); return; fi
    PUSH_STATE="$TMP/mutant.sh" bash "$0" > "$TMP/out" 2>&1
    grep -E '^  FAIL: |^RESULT: ' "$TMP/out"
    if grep -q '^  FAIL: ' "$TMP/out"; then
      bites=$((bites+1))
      sed -n 's/^  FAIL: //p' "$TMP/out" | sed 's/ (rc=[0-9]*)$//' >> "$TMP/hit"
    else
      dead=$((dead+1)); echo "  MUTANT SURVIVED"
    fi
  }
  mutant "no-remote guard gone"        's/^\[ -n "\$remotes" \] || exit 0$/:/'
  mutant "detached guard gone"         's/^branch="\$(git symbolic-ref -q --short HEAD 2>\/dev\/null)" || exit 0$/branch="$(git symbolic-ref -q --short HEAD 2>\/dev\/null)" || branch=HEAD/'
  mutant "unborn guard gone"           's/^git rev-parse -q --verify HEAD >\/dev\/null 2>&1 || exit 0$/:/'
  mutant "not-a-repo exits non-zero"   's/^remotes="\$(git remote 2>\/dev\/null)" || exit 0$/remotes="$(git remote 2>\/dev\/null)" || exit 3/'
  mutant "not-a-repo leaks stderr"     's/^remotes="\$(git remote 2>\/dev\/null)" || exit 0$/remotes="$(git remote)" || exit 0/'
  mutant "in sync reads as ahead"      's/\[ "\$ahead" -gt 0 \]/[ "$ahead" -ge 0 ]/'
  mutant "ahead reads as in sync"      's/\[ "\$ahead" -gt 0 \]/[ "$ahead" -gt 999 ]/'
  mutant "--landing ignored"           's/^  2:move:--landing) landing=1 ;;$/  2:move:--landing) landing=0 ;;/'
  mutant "--landing ignores behind"    's/\[ "\$landing" = 1 \] && \[ "\$behind" = 0 \]/[ "$landing" = 1 ]/'
  mutant "force flag on the plain push" "s/echo 'git push'/echo 'git push --force'/"
  mutant "force flag on the -u push"   "s/'git push -u %s %s/'git push --force -u %s %s/"
  mutant "-u dropped"                  "s/'git push -u %s %s/'git push %s %s/"
  mutant "one remote assumed origin"   's/\*) remote="\$remotes" ;;/*) remote=origin ;;/'
  mutant "several: first, not origin"  's/\*"\${nl}origin\${nl}"\*) remote=origin ;;/*"${nl}origin${nl}"*) remote="${remotes%%"$nl"*}" ;;/'
  mutant "several, no origin: assumed" 's/^      \*) exit 0 ;;$/      *) remote=origin ;;/'
  mutant "state counts the wrong side" 's/echo "ahead \$ahead"/echo "ahead $behind"/'
  mutant "state drops the count"       's/echo "ahead \$ahead"/echo "ahead"/'
  mutant "state says something else"   's/echo "no upstream"/echo "none"/'
  mutant "state offers the move"       's/^\[ "\$mode" = state \] && { echo "no upstream"; exit 0; }$/:/'
  mutant "branch left unquoted"        's/^    \*\[!A-Za-z0-9._\/@+-\]\*) .*$/    *[!A-Za-z0-9._\/@+-]*) printf "%s" "$1" ;;/'
  mutant "bad argument accepted"       's/^  exit 2$/  exit 0/'
  echo
  echo "$labels" | sort -u > "$TMP/want"
  sort -u "$TMP/hit" > "$TMP/got"
  uncovered="$(comm -23 "$TMP/want" "$TMP/got")"
  if [ -n "$uncovered" ]; then echo "UNCOVERED assertions:"; printf '%s\n' "$uncovered" | sed 's/^/  /'; fi
  echo "BITE: $bites mutants bit, $dead did not, $(printf '%s\n' "$uncovered" | grep -c .) assertions uncovered of $(wc -l < "$TMP/want" | tr -d ' ')"
  [ "$dead" = 0 ] && [ -z "$uncovered" ]
  exit
fi

pass=0; fail=0
ok()  { pass=$((pass+1)); echo "  ok: $1"; }
bad() { fail=$((fail+1)); echo "  FAIL: $1"; }
show() { printf '%s\n' "$1" | sed 's/^/        /'; }

[ -f "$PS" ] || { echo "  FAIL: asset missing: $PS"; echo; echo "RESULT: 0 passed, 1 failed"; exit 1; }

export GIT_CONFIG_GLOBAL=/dev/null GIT_CONFIG_NOSYSTEM=1
export GIT_AUTHOR_NAME=t GIT_AUTHOR_EMAIL=t@t GIT_COMMITTER_NAME=t GIT_COMMITTER_EMAIL=t@t

# chk <label> <dir> <exact stdout> <args...>: exit 0, exact stdout, nothing on stderr.
chk() {
  local label="$1" d="$2" want="$3"; shift 3
  local out err rc
  out="$(cd "$d" && bash "$PS" "$@" 2>"$TMP/err")"; rc=$?
  err="$(cat "$TMP/err")"
  if [ "$rc" -eq 0 ] && [ "$out" = "$want" ] && [ -z "$err" ]; then
    ok "$label"
  else
    bad "$label (rc=$rc)"; show "want: [$want]"; show "got:  [$out]"; [ -z "$err" ] || show "stderr: $err"
  fi
}

bare() { git init -q --bare "$TMP/$1.git"; }                    # bare <name>
repo() { mkdir -p "$TMP/$1"; git -C "$TMP/$1" init -q -b main; } # repo <name>: unborn main
work() { git -C "$TMP/$1" commit -q --allow-empty -m "$2"; }     # work <name> <subject>
tracked() { # tracked <name>: one commit, sent to its own bare `origin`, tracking it
  repo "$1"; work "$1" one; bare "$1-origin"
  git -C "$TMP/$1" remote add origin "$TMP/$1-origin.git"
  git -C "$TMP/$1" push -q -u origin main
}
loose() { # loose <name> <remote>...: one commit, the named remotes, no upstream
  local n="$1"; shift
  repo "$n"; work "$n" one
  for r in "$@"; do bare "$n-$r"; git -C "$TMP/$n" remote add "$r" "$TMP/$n-$r.git"; done
}

echo "== no remote =="
repo noremote; work noremote one; work noremote two
chk "no remote: move prints nothing"           "$TMP/noremote" "" move
chk "no remote: move --landing prints nothing" "$TMP/noremote" "" move --landing
chk "no remote: state prints nothing"          "$TMP/noremote" "" state

echo "== ahead =="
tracked ahead; work ahead two; work ahead three
chk "ahead: move offers git push"              "$TMP/ahead" "git push" move
chk "ahead: move --landing offers git push"    "$TMP/ahead" "git push" move --landing
chk "ahead: state counts 2"                    "$TMP/ahead" "ahead 2" state

echo "== in sync =="
tracked insync
chk "in sync: move prints nothing"             "$TMP/insync" "" move
chk "in sync: move --landing offers git push"  "$TMP/insync" "git push" move --landing
chk "in sync: state says ahead 0"              "$TMP/insync" "ahead 0" state

echo "== behind and diverged =="
tracked behind; work behind two; git -C "$TMP/behind" push -q; git -C "$TMP/behind" reset -q --hard HEAD~1
chk "behind: move prints nothing"              "$TMP/behind" "" move
chk "behind: move --landing prints nothing"    "$TMP/behind" "" move --landing
chk "behind: state says ahead 0"               "$TMP/behind" "ahead 0" state
tracked diverged; work diverged two; git -C "$TMP/diverged" push -q; git -C "$TMP/diverged" reset -q --hard HEAD~1; work diverged other
chk "diverged: move offers git push, no force" "$TMP/diverged" "git push" move
chk "diverged: state counts 1"                 "$TMP/diverged" "ahead 1" state

echo "== no upstream =="
loose noup origin
chk "no upstream: move offers -u origin main"  "$TMP/noup" "git push -u origin main" move
chk "no upstream: --landing offers the same"   "$TMP/noup" "git push -u origin main" move --landing
chk "no upstream: state says so"               "$TMP/noup" "no upstream" state
loose fork fork
chk "one remote, not origin: move names it"    "$TMP/fork" "git push -u fork main" move
git -C "$TMP/fork" switch -q -c feature/x
chk "feature branch: move names the branch"    "$TMP/fork" "git push -u fork feature/x" move
git -C "$TMP/fork" switch -q -c 'odd;name'
chk "branch with a shell character is quoted"  "$TMP/fork" "git push -u fork 'odd;name'" move

echo "== detached HEAD =="
tracked detached; work detached two; git -C "$TMP/detached" checkout -q --detach
chk "detached: move prints nothing"            "$TMP/detached" "" move
chk "detached: move --landing prints nothing"  "$TMP/detached" "" move --landing
chk "detached: state prints nothing"           "$TMP/detached" "" state

echo "== two remotes =="
loose twoorigin fork origin
chk "two remotes with origin: move picks it"   "$TMP/twoorigin" "git push -u origin main" move
chk "two remotes with origin: state"           "$TMP/twoorigin" "no upstream" state
loose twonone fork mirror
chk "two remotes, no origin: move prints nothing"         "$TMP/twonone" "" move
chk "two remotes, no origin: --landing prints nothing"    "$TMP/twonone" "" move --landing
chk "two remotes, no origin: state"            "$TMP/twonone" "no upstream" state
tracked twotracked; bare twotracked-fork; git -C "$TMP/twotracked" remote add fork "$TMP/twotracked-fork.git"; work twotracked two
chk "two remotes, tracking one: git push"      "$TMP/twotracked" "git push" move
chk "two remotes, tracking one: state"         "$TMP/twotracked" "ahead 1" state

echo "== nothing to send, or no repo =="
repo unborn; bare unborn-origin; git -C "$TMP/unborn" remote add origin "$TMP/unborn-origin.git"
chk "unborn branch: move prints nothing"       "$TMP/unborn" "" move
chk "unborn branch: state prints nothing"      "$TMP/unborn" "" state
mkdir -p "$TMP/plain"
chk "not a repo: move prints nothing, exit 0"  "$TMP/plain" "" move
chk "not a repo: state prints nothing, exit 0" "$TMP/plain" "" state

echo "== bad arguments =="
badarg() { # badarg <label> <args...>
  local label="$1" out err rc; shift
  out="$(cd "$TMP/ahead" && bash "$PS" "$@" 2>"$TMP/err")"; rc=$?
  err="$(cat "$TMP/err")"
  if [ "$rc" -eq 2 ] && [ -z "$out" ] && printf '%s' "$err" | grep -qi usage; then
    ok "$label"
  else
    bad "$label (rc=$rc)"; show "$out"; show "$err"
  fi
}
badarg "no mode: exit 2 with usage"
badarg "unknown mode: exit 2 with usage" sideways
badarg "unknown flag: exit 2 with usage" move --force
badarg "state takes no flag: exit 2 with usage" state --landing

echo
echo "RESULT: $pass passed, $fail failed"
[ "$fail" -eq 0 ]
