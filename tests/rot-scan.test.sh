#!/usr/bin/env bash
# L1 unit tests for rot-scan.sh — harness-bootstrap's § 2b rot scan instrument: find
# rename-map.md `old` literals in the scope files under one token boundary, and fail
# loudly rather than read as a clean scan.
# Targets the PLUGIN ASSET (source of truth); the real map is parsed too.
#
# Contract pinned here:
#   - rows: `- \`old\` → \`new\`` bullets in any section; every `- \`old\`` bullet under
#     `## Retired files`, new column `(retired)`.
#   - boundary: no word char, `/`, `.`, `-`, `:` before; no word char, `-`, `/`, or
#     `:`+word char after. Line start/end, space, backtick, punctuation, `: ` are hits.
#   - output: `file<TAB>line<TAB>old<TAB>new` per hit line, then `literals N files M hits K`,
#     exit 0.
#   - unreadable map / zero rows / missing scope file / bad args -> stderr, exit 2,
#     empty stdout (no summary line).
#   - the whole suite runs twice: with the host awk, then with `awk` shimmed to
#     `gawk --posix` (when gawk exists) to catch gawk-only constructs.
#
# Usage: bash tests/rot-scan.test.sh
set -uo pipefail

REPO="$(cd "$(dirname "$0")/.." && pwd)"
RS="${ROT_SCAN:-$REPO/plugins/super-bootstrap/skills/harness-bootstrap/assets/rot-scan.sh}"  # override = bite-check a mutant
REAL_MAP="$REPO/plugins/super-bootstrap/skills/harness-bootstrap/assets/rename-map.md"

pass=0; fail=0
ok()  { pass=$((pass+1)); echo "  ok: $1"; }
bad() { fail=$((fail+1)); echo "  FAIL: $1"; }
show() { printf '%s\n' "$1" | sed 's/^/        /'; }

TMP="$(mktemp -d)"
trap 'rm -rf "$TMP"' EXIT

[ -f "$RS" ] || { echo "  FAIL: asset missing: $RS"; echo; echo "RESULT: 0 passed, 1 failed"; exit 1; }

# run <map> <stdin-list>
run() { out="$(printf '%s' "$2" | bash "$RS" "$1" 2>"$TMP/err")"; rc=$?; err="$(cat "$TMP/err")"; }

# expect <label> <rc> <expected-stdout>
expect() {
  if [ "$rc" -eq "$2" ] && [ "$out" = "$3" ]; then ok "$1"
  else bad "$1 (rc=$rc, want $2)"; echo "      expected:"; show "$3"; echo "      got:"; show "$out"; show "$err"; fi
}
# expect_fail <label> — exit 2, stderr names an error, no stdout (so no summary line)
expect_fail() {
  if [ "$rc" -eq 2 ] && [ -z "$out" ] && [ -n "$err" ]; then ok "$1"
  else bad "$1 (rc=$rc, want 2 + empty stdout)"; echo "      stdout:"; show "$out"; echo "      stderr:"; show "$err"; fi
}

w() { local f="$1"; shift; printf -- "$@" > "$f"; }
T="$(printf '\t')"

# a small map in the real map's shape: sections, rename rows with and without reasons,
# a non-row bullet, a Retired files section, a scan-guidance bullet
M="$TMP/map.md"
cat > "$M" <<'EOF'
# Skeleton Rename Map

Format per entry: `` `old` `` → `` `new` `` — brief reason.

## Slash commands

- `/commit` → `/super-bootstrap:commit`
- `/log` → `/super-bootstrap:log`
- `/triage` → `/super-bootstrap:triage`
- `/triage-report` → `/super-bootstrap:triage-report`
- `/super-bootstrap` → `/super-bootstrap:setup` — entry renamed
- `/notarow` is mentioned but carries no arrow

## Retired files

Placed files whose skeleton no longer ships.

- `.claude/rules/venue-map.md` — the phase map; gone.
- `.claude/rules/old-thing.md`

## Scan guidance

- Match the `old` form under the token boundary.
EOF

suite() {
echo "== map parsing =="
F="$TMP/empty.md"; w "$F" ''
run "$M" "$F"$'\n'
expect "7 rows: 5 renames + 2 retired - 1 arrowless bullet" 0 "literals 7 files 1 hits 0"
run "$REAL_MAP" "$F"$'\n'
if [ "$rc" -eq 0 ] && [ -n "$out" ] && [ "${out#literals }" != "$out" ] && [ "${out#literals 0 }" = "$out" ]; then ok "real rename-map.md parses >0 literals ($out)"
else bad "real rename-map.md (rc=$rc)"; show "$out"; show "$err"; fi
MC="$TMP/crlf-map.md"; sed 's/$/\r/' "$M" > "$MC"
run "$MC" "$F"$'\n'
expect "CRLF map parses the same rows" 0 "literals 7 files 1 hits 0"

echo "== false hits (must NOT match) =="
F="$TMP/false.md"
cat > "$F" <<'EOF'
Run /super-bootstrap:log to file it.
Entry is /super-bootstrap:setup now.
Drain with /triage-report today.
See https://x/y/commit/abc for the change.
Lives in plugins/super-bootstrap/ tree.
Also /super-bootstrap:commit, end.
a/log and x.log and -log and :log
/commitment and /logs and /commit-msg
EOF
run "$M" "$F"$'\n'
# line 3 is a true hit for the `/triage-report` row only: the `/triage` row must not hit it
expect "namespaced, hyphen-extended, URL and path forms are not hits" 0 "$(printf '%s\n' \
  "$F${T}3${T}/triage-report${T}/super-bootstrap:triage-report" \
  "literals 7 files 1 hits 1")"

echo "== true hits (MUST match) =="
F="$TMP/true.md"
cat > "$F" <<'EOF'
Use `/super-bootstrap` to start.
run /commit: now
finish with /log
text /triage here
/commit at line start
(see /log).
EOF
run "$M" "$F"$'\n'
expect "backtick, ': ' follower, line end, whitespace-led mid-line, line start, punctuation" 0 "$(printf '%s\n' \
  "$F${T}1${T}/super-bootstrap${T}/super-bootstrap:setup" \
  "$F${T}2${T}/commit${T}/super-bootstrap:commit" \
  "$F${T}3${T}/log${T}/super-bootstrap:log" \
  "$F${T}4${T}/triage${T}/super-bootstrap:triage" \
  "$F${T}5${T}/commit${T}/super-bootstrap:commit" \
  "$F${T}6${T}/log${T}/super-bootstrap:log" \
  "literals 7 files 1 hits 6")"

F="$TMP/mixed.md"
printf 'x /super-bootstrap:log then /super-bootstrap end\n/commit /commit twice\r\n' > "$F"
run "$M" "$F"$'\n'
expect "false occurrence before a true one on the same line still hits; one row per line; CR stripped" 0 "$(printf '%s\n' \
  "$F${T}1${T}/super-bootstrap${T}/super-bootstrap:setup" \
  "$F${T}2${T}/commit${T}/super-bootstrap:commit" \
  "literals 7 files 1 hits 2")"

F="$TMP/retired.md"
printf -- '- `.claude/rules/venue-map.md` lists venues\nsee x/.claude/rules/venue-map.md\n' > "$F"
run "$M" "$F"$'\n'
expect "retired row hits with new column (retired); path-prefixed form does not" 0 "$(printf '%s\n' \
  "$F${T}1${T}.claude/rules/venue-map.md${T}(retired)" \
  "literals 7 files 1 hits 1")"

echo "== scope list =="
mkdir -p "$TMP/with space"
S1="$TMP/with space/a doc.md"; printf 'go /log\n' > "$S1"
S2="$TMP/two.md"; printf 'none\n/commit\n' > "$S2"
run "$M" "$S1"$'\n\n'"$S2"$'\r\n'
expect "path with a space, blank line and CRLF in the list; list order kept" 0 "$(printf '%s\n' \
  "$S1${T}1${T}/log${T}/super-bootstrap:log" \
  "$S2${T}2${T}/commit${T}/super-bootstrap:commit" \
  "literals 7 files 2 hits 2")"
run "$M" "$S2"
expect "last list entry without a trailing newline is still read" 0 "$(printf '%s\n' \
  "$S2${T}2${T}/commit${T}/super-bootstrap:commit" \
  "literals 7 files 1 hits 1")"
run "$M" ""
expect "empty scope list -> files 0, exit 0" 0 "literals 7 files 0 hits 0"

echo "== loud failure (exit 2, no summary) =="
run "$M" "$S2"$'\n'"$TMP/does-not-exist.md"$'\n'
expect_fail "scope file that does not exist (after a readable one with a hit)"
run "$M" "$TMP"$'\n'
expect_fail "scope entry that is a directory"
Z="$TMP/zero.md"; printf '# Map\n\n## Slash commands\n\n- no backtick rows here\n- `/x` without arrow\n' > "$Z"
run "$Z" "$S2"$'\n'
expect_fail "map with zero parseable rows"
run "$TMP/no-map.md" "$S2"$'\n'
expect_fail "map that does not exist"
out="$(printf '' | bash "$RS" 2>"$TMP/err")"; rc=$?; err="$(cat "$TMP/err")"
expect_fail "no map argument"
out="$(printf '' | bash "$RS" "$M" extra 2>"$TMP/err")"; rc=$?; err="$(cat "$TMP/err")"
expect_fail "too many arguments"
}

echo "### host awk: $(awk --version 2>/dev/null | head -n 1 || echo unknown)"
suite

if command -v gawk >/dev/null 2>&1; then
  SHIM="$TMP/shim"; mkdir -p "$SHIM"
  printf '#!/bin/sh\nexec gawk --posix "$@"\n' > "$SHIM/awk"; chmod +x "$SHIM/awk"
  echo
  echo "### awk shimmed to gawk --posix"
  OLDPATH="$PATH"; export PATH="$SHIM:$PATH"
  suite
  export PATH="$OLDPATH"
else
  echo "### gawk absent - posix-shim pass skipped"
fi

echo
echo "RESULT: $pass passed, $fail failed"
[ "$fail" -eq 0 ]
