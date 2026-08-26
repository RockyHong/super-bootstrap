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

# ---------------------------------------------------------------------------
# BUG-045 — one-pass slug table + fork-free resolve path.
# Three locks: (a) output parity across the four finding classes plus `.`/`..`
# normalization, (b) the constructs whose per-link forks caused the blow-up,
# (c) a wall-clock ceiling on a synthetic 50-doc surface. The ceiling is
# deliberately generous: fork cost is platform-bound (msys ~10-20 ms, Linux far
# less), so the lock asserts an order of magnitude, never a tight number.
# ---------------------------------------------------------------------------

echo "== doc-links: BUG-045 — finding-class parity (missing path / target anchor / intradoc anchor / . + .. normalization) =="
mkdir -p "$TMP/parity/docs/sub"
cat > "$TMP/parity/docs/real.md" <<'EOF'
# Real Target

## Known Section

Body.
EOF
cat > "$TMP/parity/docs/a.md" <<'EOF'
# Doc A

## Alpha Section

Missing path: [m](./missing.md).
Missing target anchor: [n](real.md#no-such).
Missing intradoc anchor: [o](#nope).
Good intradoc: [p](#alpha-section).
Good rel: [q](./real.md#known-section).
Good up-down: [r](../docs/sub/b.md#beta-section).
EOF
cat > "$TMP/parity/docs/sub/b.md" <<'EOF'
# Doc B

## Beta Section

Up-link: [s](../real.md#known-section).
Dotted: [t](./../real.md).
EOF
cat > "$TMP/parity/README.md" <<'EOF'
# Readme

## Top

Good: [u](docs/real.md#known-section).
Bad: [v](docs/real.md#ghost).
EOF

expected_findings="README.md:6: docs/real.md#ghost — anchor not found in target
docs/a.md:5: docs/missing.md — path not found
docs/a.md:6: docs/real.md#no-such — anchor not found in target
docs/a.md:7: #nope — anchor not found in same file"

out="$(cd "$TMP/parity" && bash "$LINKS" check 2>"$TMP/parity.err")"; rc=$?
got="$(printf '%s\n' "$out" | LC_ALL=C sort)"
check "parity fixture: check exits 1" [ "$rc" -eq 1 ]
if [ "$got" = "$expected_findings" ]; then
  ok "parity fixture: exact finding lines, all four classes + ./ and ../ resolve"
else
  bad "parity fixture: exact finding lines, all four classes + ./ and ../ resolve"
  printf 'expected:\n%s\ngot:\n%s\n' "$expected_findings" "$got" | sed 's/^/        /'
fi
check "parity fixture: summary count on stderr" grep -qxF '4 broken link(s)' "$TMP/parity.err"

echo "== doc-links: BUG-045 — CJK / diacritic / punctuation heading slug still resolves =="
mkdir -p "$TMP/cjk/docs"
cat > "$TMP/cjk/docs/c.md" <<'EOF'
# Doc C

## 測試 Café — Setup!

Intradoc: [w](#-caf--setup).
EOF
cat > "$TMP/cjk/docs/d.md" <<'EOF'
# Doc D

Cross-file: [x](c.md#-caf--setup).
EOF
out="$(cd "$TMP/cjk" && bash "$LINKS" check 2>&1)"; rc=$?
if [ "$rc" -eq 0 ] && [ -z "$out" ]; then
  ok "CJK/diacritic heading: slug resolves intradoc + cross-file, check exits 0"
else
  bad "CJK/diacritic heading: slug resolves intradoc + cross-file, check exits 0 (rc=$rc)"
  printf '%s\n' "$out" | sed 's/^/        /'
fi

echo "== doc-links: BUG-045 — no per-link fork in the resolve path, no per-heading slugify loop =="
fn_body() { # fn_body <name> — print the body lines of a top-level shell function
  awk -v fn="$1" '
    $0 ~ ("^" fn "\\(\\) \\{") { inb = 1; next }
    inb && /^\}/ { inb = 0 }
    inb { print }
  ' "$LINKS"
}
fork_hits=""
for fn in do_check do_refs do_index; do
  h="$(fn_body "$fn" | grep -nE '\$\(resolve_target|cut +-f' | sed "s/^/$fn:/" || true)"
  if [ -n "$h" ]; then
    fork_hits="$fork_hits$h
"
  fi
done
if [ -z "$fork_hits" ]; then
  ok "do_check/do_refs/do_index: no \$(resolve_target …) substitution, no cut -f"
else
  bad "do_check/do_refs/do_index: no \$(resolve_target …) substitution, no cut -f"
  printf '%s' "$fork_hits" | sed 's/^/        /'
fi

ae_flat="$(fn_body anchor_exists | tr '\n' ' ')"
if printf '%s' "$ae_flat" | grep -qE 'while[^;]*read[^;]*; *do[^;]*slugify'; then
  bad "anchor_exists: per-heading slugify shell loop is gone"
else
  ok "anchor_exists: per-heading slugify shell loop is gone"
fi

echo "== doc-links: BUG-045 — whole-surface check under a generous wall-clock ceiling =="
now_ns="$(date +%s%N 2>/dev/null || true)"
case "$now_ns" in
  ''|*[!0-9]*)
    echo "  note: skipped — 'date +%s%N' unavailable on this host (no nanosecond clock)" ;;
  *)
    mkdir -p "$TMP/perf/docs/gen"
    i=1
    while [ "$i" -le 50 ]; do
      f="$(printf 'f%02d' "$i")"
      {
        printf '# %s\n\n' "$f"
        j=1
        while [ "$j" -le 30 ]; do
          printf '## Section %02d\n\nBody %s %s.\n\n' "$j" "$f" "$j"
          j=$((j + 1))
        done
        k=1
        while [ "$k" -le 20 ]; do
          t=$(( (i + k) % 50 + 1 ))
          printf 'Link %s: [l](../gen/%s.md#section-%02d).\n' "$k" "$(printf 'f%02d' "$t")" "$k"
          k=$((k + 1))
        done
      } > "$TMP/perf/docs/gen/$f.md"
      i=$((i + 1))
    done
    ceiling_s=30
    t0="$(date +%s%N)"
    if command -v timeout >/dev/null 2>&1; then
      (cd "$TMP/perf" && timeout "$ceiling_s" bash "$LINKS" check) >/dev/null 2>&1; prc=$?
    else
      (cd "$TMP/perf" && bash "$LINKS" check) >/dev/null 2>&1; prc=$?
    fi
    t1="$(date +%s%N)"
    elapsed_ms=$(( (t1 - t0) / 1000000 ))
    if [ "$prc" -eq 0 ] && [ "$elapsed_ms" -lt $((ceiling_s * 1000)) ]; then
      ok "50 docs x 30 headings x 20 anchored cross-links: check in ${elapsed_ms}ms (< ${ceiling_s}s)"
    else
      bad "50 docs x 30 headings x 20 anchored cross-links: check took ${elapsed_ms}ms (ceiling ${ceiling_s}s, rc=$prc)"
    fi
    ;;
esac
echo
echo "RESULT: $pass passed, $fail failed"
[ "$fail" -eq 0 ]
