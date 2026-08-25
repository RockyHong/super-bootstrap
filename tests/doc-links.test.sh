#!/usr/bin/env bash
# L1 unit tests for doc-links.sh: sed-dialect portability + anchor-slug behavior.
# Targets the PLUGIN ASSET (source of truth) — BUG-040: `\+` is a GNU BRE
# extension that POSIX/BSD sed (macOS) reads as a literal `+`, so heading
# prefixes survive and every anchored link reports broken.
#
# Usage: bash tests/doc-links.test.sh
set -uo pipefail

REPO="$(cd "$(dirname "$0")/.." && pwd)"
LINKS="$REPO/plugins/super-bootstrap/skills/commit/assets/doc-links.sh"

pass=0; fail=0
ok()   { pass=$((pass+1)); echo "  ok: $1"; }
bad()  { fail=$((fail+1)); echo "  FAIL: $1"; }
check() { # check <desc> <expr...>
  local desc="$1"; shift
  if "$@"; then ok "$desc"; else bad "$desc"; fi
}

TMP="$(mktemp -d)"
trap 'rm -rf "$TMP"' EXIT

echo "== doc-links: BUG-040 — no GNU-only BRE escape in any sed BRE expression =="
# Scope: lines invoking sed in BRE mode (no -E/-r). GNU-only escapes are
# \+ \? \| — POSIX BRE reads each as the literal character.
sed_bre_lines="$(grep -nE '(^|[^a-zA-Z0-9_-])sed ' "$LINKS" | grep -vE 'sed +-[Er]' || true)"
gnu_hits="$(printf '%s\n' "$sed_bre_lines" | grep -E '\\[+?|]' || true)"
if [ -z "$gnu_hits" ]; then
  ok "no GNU-only BRE escape (\\+ \\? \\|) in sed BRE expressions"
else
  bad "GNU-only BRE escape in sed BRE expression(s):"
  printf '%s\n' "$gnu_hits" | sed 's/^/        /'
fi

echo "== doc-links: BUG-042 — no interval expression in any awk regex =="
# mawk 1.3.4-20200120 (Debian/Ubuntu default awk) and one-true-awk builds before
# 2019 (macOS) read `{3,}` as literal braces, so the fence toggle never fires and
# every path inside a fenced block reports as a broken link. The host awk (GNU)
# accepts intervals, so this is a construct grep, not a behavior test — the
# cross-awk behavior check runs under Docker (see docs/techstack.md § Coding Patterns).
interval_hits="$(grep -nE '\{[0-9]+(,[0-9]*)?\}' "$LINKS" || true)"
if [ -z "$interval_hits" ]; then
  ok "no interval expression ({n,} / {n,m}) in the asset"
else
  bad "interval expression in awk regex:"
  printf '%s\n' "$interval_hits" | sed 's/^/        /'
fi

echo "== doc-links: anchor slugs resolve (behavior lock — guards against over-stripping) =="
mkdir -p "$TMP/ok/docs"
cat > "$TMP/ok/docs/a.md" <<'EOF'
# Doc A

## Tests

See [x](a.md#tests).

### Edit Discipline

See [y](#edit-discipline).
EOF

out="$(cd "$TMP/ok" && bash "$LINKS" check 2>&1)"; rc=$?
check "positive fixture: check exits 0" [ "$rc" -eq 0 ]
if [ -z "$out" ]; then
  ok "positive fixture: check output empty"
else
  bad "positive fixture: check output empty"
  printf '%s\n' "$out" | sed 's/^/        /'
fi

mkdir -p "$TMP/bad/docs"
cat > "$TMP/bad/docs/a.md" <<'EOF'
# Doc A

## Tests

See [z](a.md#nonexistent).
EOF

out="$(cd "$TMP/bad" && bash "$LINKS" check 2>&1)"; rc=$?
check "negative fixture: missing anchor -> non-zero exit" [ "$rc" -ne 0 ]

echo "== doc-links: BUG-043 — fence close honors opener char/run-length (nesting) =="
# (a) An outer longer-run fence wrapping an inner ```-fence: the toggle closed the
# outer block at the inner opener, so the inner body's link leaked out as a real
# target. Also covers an inner opener carrying an info string at the OUTER run
# length — a closer never carries an info string, so it must not close the outer.
mkdir -p "$TMP/nest/docs"
: > "$TMP/nest/docs/realA.md"
: > "$TMP/nest/docs/realA2.md"
cat > "$TMP/nest/docs/a.md" <<'EOF'
# Doc A

Before [p](./realA.md).

````
```
See [inner](./insideInner.md).
```
````bash
See [inner2](./insideInner2.md).
````

After [q](./realA2.md).
EOF

out="$(cd "$TMP/nest" && bash "$LINKS" check 2>&1)"; rc=$?
if [ "$rc" -eq 0 ] && [ -z "$out" ]; then
  ok "nested longer-run fence: inner body links stay unchecked, check exits 0"
else
  bad "nested longer-run fence: inner body links stay unchecked, check exits 0 (rc=$rc)"
  printf '%s\n' "$out" | sed 's/^/        /'
fi

# (b) Odd fence-line count inside a wrapped block (a doc showing what an opener
# looks like): the toggle left in_fence set past the true outer closer, silently
# swallowing every later prose link instead of checking it.
mkdir -p "$TMP/odd/docs"
cat > "$TMP/odd/docs/b.md" <<'EOF'
# Doc B

````
```
````

After [r](./realB.md).
EOF

out="$(cd "$TMP/odd" && bash "$LINKS" check 2>&1)"; rc=$?
if [ "$rc" -ne 0 ] && printf '%s' "$out" | grep -q 'docs/realB.md'; then
  ok "odd fence count in wrapped block: link after outer closer is still checked"
else
  bad "odd fence count in wrapped block: link after outer closer is still checked (rc=$rc)"
  printf '%s\n' "$out" | sed 's/^/        /'
fi
echo
echo "RESULT: $pass passed, $fail failed"
[ "$fail" -eq 0 ]
