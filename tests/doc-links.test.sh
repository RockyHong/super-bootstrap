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

echo
echo "RESULT: $pass passed, $fail failed"
[ "$fail" -eq 0 ]
