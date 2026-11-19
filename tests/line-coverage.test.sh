#!/usr/bin/env bash
# L1 unit tests for line-coverage.sh — harness-bootstrap's CLAUDE.md migration check:
# every non-blank line of the old CLAUDE.md must sit in the new pair (new CLAUDE.md +
# placed harness.md) or on the user-seen drop list.
# Targets the PLUGIN ASSET (source of truth).
#
# Contract pinned here:
#   - normalisation (all four inputs): strip CR, trim leading/trailing space+tab, mask each
#     markdown link target `](...)` -> `]()`; comparison is literal, never a pattern.
#   - all covered -> one stdout line `line-coverage: N lines — M in the new pair, K on the
#     drop list`, exit 0 (a line in both pair and drop list counts under the pair).
#   - uncovered -> `uncovered: <old line no>: <original line, CR stripped>` per line in file
#     order, then `line-coverage: U of N lines uncovered`, exit 1.
#   - wrong arg count / missing or unreadable old|new|harness / missing named drop list ->
#     one stderr line, exit 2, empty stdout.
#
# Usage: bash tests/line-coverage.test.sh
set -uo pipefail

REPO="$(cd "$(dirname "$0")/.." && pwd)"
LC="${LINE_COVERAGE:-$REPO/plugins/super-bootstrap/skills/harness-bootstrap/assets/line-coverage.sh}"  # override = bite-check a mutant

pass=0; fail=0
ok()  { pass=$((pass+1)); echo "  ok: $1"; }
bad() { fail=$((fail+1)); echo "  FAIL: $1"; }
show() { printf '%s\n' "$1" | sed 's/^/        /'; }

TMP="$(mktemp -d)"
trap 'rm -rf "$TMP"' EXIT

[ -f "$LC" ] || { echo "  FAIL: asset missing: $LC"; echo; echo "RESULT: 0 passed, 1 failed"; exit 1; }

run() { out="$(bash "$LC" "$@" 2>"$TMP/err")"; rc=$?; err="$(cat "$TMP/err")"; }

# expect <label> <rc> <expected-stdout>
expect() {
  if [ "$rc" -eq "$2" ] && [ "$out" = "$3" ]; then ok "$1"
  else bad "$1 (rc=$rc, want $2)"; echo "      expected:"; show "$3"; echo "      got:"; show "$out"; show "$err"; fi
}

# fixtures: old/new/harness/drop written with printf so CR and spacing stay exact
O="$TMP/old.md"; N="$TMP/new.md"; H="$TMP/harness.md"; D="$TMP/drop.txt"
w() { local f="$1"; shift; printf -- "$@" > "$f"; }  # `--`: a format starting with `-` is otherwise read as an option

echo "== all covered by the pair =="
w "$O" 'alpha\nbeta\n'
w "$N" 'alpha\n'
w "$H" 'beta\n'
run "$O" "$N" "$H"
expect "pair covers every line" 0 'line-coverage: 2 lines — 2 in the new pair, 0 on the drop list'

echo "== drop list =="
w "$O" 'alpha\ngone\n'
w "$N" 'alpha\n'; w "$H" 'x\n'; w "$D" 'gone\n'
run "$O" "$N" "$H" "$D"
expect "line covered only by drop list -> K=1" 0 'line-coverage: 2 lines — 1 in the new pair, 1 on the drop list'
w "$D" 'alpha\ngone\n'
run "$O" "$N" "$H" "$D"
expect "line in pair and drop list counts under the pair" 0 'line-coverage: 2 lines — 1 in the new pair, 1 on the drop list'
w "$D" ''
run "$O" "$N" "$H" "$D"
expect "empty drop list -> no drops" 1 "$(printf 'uncovered: 2: gone\nline-coverage: 1 of 2 lines uncovered')"

echo "== uncovered =="
w "$O" 'alpha\nlost one\nbeta\nlost two\n'
w "$N" 'alpha\nbeta\n'; w "$H" 'x\n'
run "$O" "$N" "$H"
expect "names line number + text, in order, then summary" 1 "$(printf 'uncovered: 2: lost one\nuncovered: 4: lost two\nline-coverage: 2 of 4 lines uncovered')"

echo "== normalisation =="
w "$O" 'See [the doc](docs/a.md) now\n'
w "$N" 'See [the doc](../x/b.md#h) now\n'; w "$H" 'x\n'
run "$O" "$N" "$H"
expect "differs only in link target -> covered" 0 'line-coverage: 1 lines — 1 in the new pair, 0 on the drop list'
w "$N" 'See [the docs](docs/a.md) now\n'
run "$O" "$N" "$H"
expect "differs in link TEXT -> uncovered" 1 "$(printf 'uncovered: 1: See [the doc](docs/a.md) now\nline-coverage: 1 of 1 lines uncovered')"
w "$O" '  - bullet text\t \r\n\tsecond\r\n'
w "$N" '- bullet text\nsecond  \n'
run "$O" "$N" "$H"
expect "CRLF and leading/trailing whitespace ignored" 0 'line-coverage: 2 lines — 2 in the new pair, 0 on the drop list'
w "$O" 'keep\r\ngone  \r\n'
w "$N" 'keep\n'
run "$O" "$N" "$H"
expect "uncovered line printed with CR stripped, otherwise untrimmed" 1 "$(printf 'uncovered: 2: gone  \nline-coverage: 1 of 2 lines uncovered')"
w "$O" 'a\n  \n\t\n\nb\n'
w "$N" 'a\nb\n'
run "$O" "$N" "$H"
expect "blank lines ignored (N counts non-blank only)" 0 'line-coverage: 2 lines — 2 in the new pair, 0 on the drop list'

echo "== duplicates =="
w "$O" 'dup\nok\ndup\n'
w "$N" 'ok\n'
run "$O" "$N" "$H"
expect "duplicate old line with no match -> reported on each line number" 1 "$(printf 'uncovered: 1: dup\nuncovered: 3: dup\nline-coverage: 2 of 3 lines uncovered')"

echo "== literal comparison =="
w "$O" 'open ](broken and *.md [x] a\\b | c & d\n'
w "$N" 'open ](broken and *.md [x] a\\b | c & d\n'
run "$O" "$N" "$H"
expect "unclosed ]( and regex-special characters compare literally" 0 'line-coverage: 1 lines — 1 in the new pair, 0 on the drop list'
w "$N" 'open ](broken and X.md [x] a\\b | c & d\n'
run "$O" "$N" "$H"
expect "* in old is not a wildcard" 1 "$(printf 'uncovered: 1: open ](broken and *.md [x] a\\b | c & d\nline-coverage: 1 of 1 lines uncovered')"
w "$O" 'a.c\n'; w "$N" 'abc\n'
run "$O" "$N" "$H"
expect ". in old is not a wildcard" 1 "$(printf 'uncovered: 1: a.c\nline-coverage: 1 of 1 lines uncovered')"
w "$O" 'x [a](b) and [c](d)\n'; w "$N" 'x [a]() and [c](zzz)\n'
run "$O" "$N" "$H"
expect "several links on one line all masked" 0 'line-coverage: 1 lines — 1 in the new pair, 0 on the drop list'

echo "== bad arguments =="
w "$O" 'a\n'; w "$N" 'a\n'; w "$H" 'a\n'
run "$O" "$N"
if [ "$rc" -eq 2 ] && [ -z "$out" ] && [ -n "$err" ]; then ok "too few args: exit 2, stderr only"; else bad "too few args (rc=$rc)"; show "$out"; fi
run "$O" "$N" "$H" "$D" extra
if [ "$rc" -eq 2 ] && [ -z "$out" ] && [ -n "$err" ]; then ok "too many args: exit 2, stderr only"; else bad "too many args (rc=$rc)"; show "$out"; fi
for which in old new harness; do
  case "$which" in
    old) run "$TMP/nope" "$N" "$H" ;;
    new) run "$O" "$TMP/nope" "$H" ;;
    harness) run "$O" "$N" "$TMP/nope" ;;
  esac
  if [ "$rc" -eq 2 ] && [ -z "$out" ] && [ -n "$err" ]; then ok "missing $which: exit 2, empty stdout"; else bad "missing $which (rc=$rc)"; show "$out"; fi
done
run "$O" "$N" "$H" "$TMP/nodrop"
if [ "$rc" -eq 2 ] && [ -z "$out" ] && [ -n "$err" ]; then ok "named drop list missing: exit 2, empty stdout"; else bad "named drop list missing (rc=$rc)"; show "$out"; fi

echo
echo "RESULT: $pass passed, $fail failed"
[ "$fail" -eq 0 ]
