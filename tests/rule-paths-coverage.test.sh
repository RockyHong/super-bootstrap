#!/usr/bin/env bash
# L1 unit tests for rule-paths-coverage.sh — harness-bootstrap's doc-rule coverage
# warning for a repo's declared doc surface (`.claude/doc-surface`).
# Targets the PLUGIN ASSET (source of truth).
#
# Contract pinned here:
#   - `translate <glob>...` prints the `paths:` entries (gitignore-style, `*` stops at
#     `/`) that cover one declaration glob (`*` crosses `/`): no `*` -> the glob itself;
#     text before the first `*` empty or ending `/` -> `<pre>**/*<suf>`; otherwise two
#     entries `<pre>*<suf>` and `<pre>*/**/*<suf>` (pre = before first `*`, suf = after
#     last `*`).
#   - `check` (cwd = repo root): no `.claude/doc-surface` -> no output. Otherwise, per doc
#     rule present (`.claude/rules/dimension-discipline.md`, `.claude/rules/ssot-doc-link.md`)
#     and per declared `.md` glob, each translated entry no `paths:` entry covers prints one
#     line naming the rule, the glob and the entry to add. Writes nothing; exit 0.
#   - Coverage reads `paths:` gitignore-style: `**` crosses `/`, `*` and `?` do not, a
#     slash-free entry matches at any depth, a leading `/` pins root.
#
# Usage: bash tests/rule-paths-coverage.test.sh
set -uo pipefail

REPO="$(cd "$(dirname "$0")/.." && pwd)"
RPC="${RULE_PATHS_COVERAGE:-$REPO/plugins/super-bootstrap/skills/harness-bootstrap/assets/rule-paths-coverage.sh}"  # override = bite-check a mutant

pass=0; fail=0
ok()  { pass=$((pass+1)); echo "  ok: $1"; }
bad() { fail=$((fail+1)); echo "  FAIL: $1"; }
show() { printf '%s\n' "$1" | sed 's/^/        /'; }

TMP="$(mktemp -d)"
trap 'rm -rf "$TMP"' EXIT

[ -f "$RPC" ] || { echo "  FAIL: asset missing: $RPC"; echo; echo "RESULT: 0 passed, 1 failed"; exit 1; }

run() { local d="$1"; shift; out="$(cd "$d" && bash "$RPC" "$@" 2>"$TMP/err")"; rc=$?; err="$(cat "$TMP/err")"; }

# expect <label> <expected-output>  (uses $out / $rc from the last run)
expect() {
  if [ "$rc" -eq 0 ] && [ "$out" = "$2" ]; then ok "$1"
  else bad "$1 (rc=$rc)"; echo "      expected:"; show "$2"; echo "      got:"; show "$out"; show "$err"; fi
}

# rule <dir> <name> <tail-entry>...  — a placed doc rule: skeleton entries + consumer tail
rule() {
  local d="$1" n="$2"; shift 2
  mkdir -p "$d/.claude/rules"
  {
    echo '---'
    echo 'paths:'
    echo '  - "docs/**/*.md"'
    echo '  - "README.md"'
    echo '  - "plugins/*/README.md"'
    for e in "$@"; do echo "  - \"$e\""; done
    echo 'description: "x"'
    echo '---'
    echo
    echo '# Body'
    echo '  - "not/a/paths/entry.md"'
  } > "$d/.claude/rules/$n.md"
}
both() { local d="$1"; shift; rule "$d" dimension-discipline "$@"; rule "$d" ssot-doc-link "$@"; }
fixture() { local d="$TMP/$1"; rm -rf "$d"; mkdir -p "$d/.claude"; echo "$d"; }

DD=".claude/rules/dimension-discipline.md"
SL=".claude/rules/ssot-doc-link.md"
line() { printf "%s: doc-surface glob '%s' not covered -- add to paths:   - \"%s\"" "$1" "$2" "$3"; }

echo "== translate =="
run "$TMP" translate 'kinds/*.md'
expect "segment-leading * -> **/*" 'kinds/**/*.md'
run "$TMP" translate '*.md'
expect "root * -> **/*" '**/*.md'
run "$TMP" translate 'notes/draft-*.md'
expect "mid-segment * -> two entries" "$(printf 'notes/draft-*.md\nnotes/draft-*/**/*.md')"
run "$TMP" translate 'guide/intro.md'
expect "no * -> the glob itself" 'guide/intro.md'
run "$TMP" translate 'a/*/x/*.md'
expect "several * -> pre + **/* + suf" 'a/**/*.md'
run "$TMP" translate '*/README.md'
expect "suffix with / kept" '**/*/README.md'

echo "== check: no declaration =="
D="$(fixture none)"; both "$D"
run "$D" check
expect "no .claude/doc-surface -> no output" ''

echo "== check: uncovered glob warns per rule =="
D="$(fixture uncovered)"; both "$D"
printf 'kinds/*.md\n' > "$D/.claude/doc-surface"
run "$D" check
expect "both rules warn with the translated entry" "$(line "$DD" 'kinds/*.md' 'kinds/**/*.md'; echo; line "$SL" 'kinds/*.md' 'kinds/**/*.md')"
if [ "$(sed -n 6p "$D/$DD")" = 'description: "x"' ]; then ok "check writes nothing to the rule"; else bad "check writes nothing to the rule"; show "$(cat "$D/$DD")"; fi

echo "== check: consumer tail covers =="
D="$(fixture tail)"; both "$D" 'kinds/**/*.md'
printf 'kinds/*.md\n' > "$D/.claude/doc-surface"
run "$D" check
expect "translated tail entry -> covered" ''

echo "== check: verbatim declaration in tail is not coverage =="
D="$(fixture verbatim)"; both "$D" 'kinds/*.md'
printf 'kinds/*.md\n' > "$D/.claude/doc-surface"
run "$D" check
expect "tail 'kinds/*.md' misses subfolders -> warns" "$(line "$DD" 'kinds/*.md' 'kinds/**/*.md'; echo; line "$SL" 'kinds/*.md' 'kinds/**/*.md')"

echo "== check: single-segment * never covers ** =="
D="$(fixture segstar)"; both "$D" 'kinds/*/*.md'
printf 'kinds/*.md\n' > "$D/.claude/doc-surface"
run "$D" check
expect "tail 'kinds/*/*.md' does not cover 'kinds/**/*.md'" "$(line "$DD" 'kinds/*.md' 'kinds/**/*.md'; echo; line "$SL" 'kinds/*.md' 'kinds/**/*.md')"

echo "== check: skeleton entries and broader tails cover =="
D="$(fixture broad)"; both "$D" 'guide/**' 'README.md'
printf 'docs/extra/*.md\nguide/a/*.md\nsub/README.md\n' > "$D/.claude/doc-surface"
run "$D" check
expect "docs/**/*.md, guide/**, bare README.md cover" ''

echo "== check: mid-segment glob needs both entries =="
D="$(fixture mid)"; both "$D" 'notes/draft-*.md'
printf 'notes/draft-*.md\n' > "$D/.claude/doc-surface"
run "$D" check
expect "only the missing second entry warns" "$(line "$DD" 'notes/draft-*.md' 'notes/draft-*/**/*.md'; echo; line "$SL" 'notes/draft-*.md' 'notes/draft-*/**/*.md')"

echo "== check: declaration parsing =="
D="$(fixture parse)"; both "$D"
printf '# comment\n\n  ./kinds/*.md  \r\nassets/*.png\n' > "$D/.claude/doc-surface"
run "$D" check
expect "comments, blanks, non-.md skipped; CR, ./ and spaces dropped" "$(line "$DD" 'kinds/*.md' 'kinds/**/*.md'; echo; line "$SL" 'kinds/*.md' 'kinds/**/*.md')"

echo "== check: absent rule skipped =="
D="$(fixture onerule)"; rule "$D" ssot-doc-link
printf 'kinds/*.md\n' > "$D/.claude/doc-surface"
run "$D" check
expect "only the placed rule warns" "$(line "$SL" 'kinds/*.md' 'kinds/**/*.md')"

echo "== bad arguments =="
run "$TMP" bogus
if [ "$rc" -eq 2 ] && [ -z "$out" ] && [ -n "$err" ]; then ok "unknown mode: exit 2, usage on stderr"; else bad "unknown mode: exit 2, usage on stderr (rc=$rc)"; show "$out"; fi

echo
echo "RESULT: $pass passed, $fail failed"
[ "$fail" -eq 0 ]
