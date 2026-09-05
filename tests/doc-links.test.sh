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

echo "== doc-links: BUG-045+BUG-053 — CJK / diacritic / punctuation heading slugs the GitHub way (unicode letters kept, punctuation stripped) =="
mkdir -p "$TMP/cjk/docs"
cat > "$TMP/cjk/docs/c.md" <<'EOF'
# Doc C

## 測試 Café — Setup!

Intradoc: [w](#測試-café--setup).
EOF
cat > "$TMP/cjk/docs/d.md" <<'EOF'
# Doc D

Cross-file: [x](c.md#測試-café--setup).
EOF
out="$(cd "$TMP/cjk" && bash "$LINKS" check 2>&1)"; rc=$?
if [ "$rc" -eq 0 ] && [ -z "$out" ]; then
  ok "CJK/diacritic heading: slug resolves intradoc + cross-file, check exits 0"
else
  bad "CJK/diacritic heading: slug resolves intradoc + cross-file, check exits 0 (rc=$rc)"
  printf '%s\n' "$out" | sed 's/^/        /'
fi

echo "== doc-links: BUG-053 — numbered CJK heading: slug keeps the letters, check + anchors agree =="
# `## 3. 後台數據` slugged to `3-` (ASCII-only strip class), so every CJK anchor a
# consumer wrote per GitHub's rule reported broken on each commit. GitHub keeps
# unicode letters: `3-後台數據`. Both readers of SLUG_AWK are asserted — `check`
# resolving the link and `anchors` printing the slug it accepts.
mkdir -p "$TMP/cjk2/docs"
cat > "$TMP/cjk2/docs/e.md" <<'EOF2'
# Doc E

## 3. 後台數據

Intradoc: [y](#3-後台數據).

## Plain ASCII (still-fine)

Control: [z](#plain-ascii-still-fine).
EOF2
cat > "$TMP/cjk2/docs/f.md" <<'EOF2'
# Doc F

Cross-file: [x](e.md#3-後台數據).
EOF2
out="$(cd "$TMP/cjk2" && bash "$LINKS" check 2>&1)"; rc=$?
if [ "$rc" -eq 0 ] && [ -z "$out" ]; then
  ok "numbered CJK heading: intradoc + cross-file anchor resolve, ASCII control unchanged, check exits 0"
else
  bad "numbered CJK heading: intradoc + cross-file anchor resolve, ASCII control unchanged, check exits 0 (rc=$rc)"
  printf '%s\n' "$out" | sed 's/^/        /'
fi
slug="$(cd "$TMP/cjk2" && bash "$LINKS" anchors docs/e.md +5)"
check "anchors prints the GitHub slug for the CJK heading (got: $slug)" [ "$slug" = "3-後台數據" ]

echo "== doc-links: BUG-055 — non-ASCII punctuation/symbols GitHub strips are stripped =="
# §/°/×/→ survived into the slug, so links written in GitHub's own anchor form
# reported broken on every commit (four field reports: GH #57/#58/#59/#60). The
# portable-awk dialect rules out a unicode-category class (SLUG_AWK's own header),
# so the alternation is extended per character — every one of them locked here,
# with a CJK control so an over-broad fix fails at the point of change.
MARKS="× ÷ ± § ° ¶ • → ← ↔ ≠ ≈ ′ ″"
mkdir -p "$TMP/marks/docs"
{
  echo "# Marks"
  echo
  echo "## m0 中文 z"
  echo
  i=0
  for m in $MARKS; do
    i=$((i+1))
    printf '## m%s %s z\n\n' "$i" "$m"
  done
} > "$TMP/marks/docs/m.md"
{
  echo "# Citer"
  echo
  echo "See [m0](m.md#m0-中文-z)."
  i=0
  for m in $MARKS; do
    i=$((i+1))
    echo "See [m$i](m.md#m$i--z)."
  done
} > "$TMP/marks/docs/c.md"

out="$(cd "$TMP/marks" && bash "$LINKS" check 2>&1)"; rc=$?
if [ "$rc" -eq 0 ] && [ -z "$out" ]; then
  ok "GitHub-form anchors over the reported mark set resolve, check exits 0"
else
  bad "GitHub-form anchors over the reported mark set resolve, check exits 0 (rc=$rc)"
  printf '%s\n' "$out" | sed 's/^/        /'
fi

slug="$(cd "$TMP/marks" && bash "$LINKS" anchors docs/m.md +3)"
check "CJK control: unicode letters kept (got: $slug)" [ "$slug" = "m0-中文-z" ]
i=0
for m in $MARKS; do
  i=$((i+1))
  slug="$(cd "$TMP/marks" && bash "$LINKS" anchors docs/m.md "+$((2*i+3))")"
  check "mark '$m' dropped from slug (got: $slug)" [ "$slug" = "m$i--z" ]
done

echo "== doc-links: BUG-055 follow-on — a strip-list gap names itself on the miss path =="
# The gap class is open by construction: the strip list is an enumeration, so
# the next unlisted mark GitHub drops repeats the same false positive. What the
# operator could not do before was tell that false positive from a real break —
# four field reports were the only detector. On a miss, a computed slug whose
# non-ASCII bytes stripped equals the requested anchor is that gap, and the hint
# names the slug to extend the list with. `†` (U+2020) stands in as unlisted.
mkdir -p "$TMP/gap/docs"
cat > "$TMP/gap/docs/t.md" <<'EOF'
# T

## gap † mark

## plain heading
EOF
cat > "$TMP/gap/docs/c.md" <<'EOF'
# Citer

Gap link: [g](t.md#gap--mark).
Real break: [r](t.md#totally-absent).
EOF

out="$(cd "$TMP/gap" && bash "$LINKS" check 2>&1)"; rc=$?
check "strip-list gap still fails the check (rc=$rc)" [ "$rc" -ne 0 ]
gapline="$(printf '%s\n' "$out" | grep -F 'gap--mark')"
if printf '%s' "$gapline" | grep -qF "strip list is missing"; then
  ok "gap link carries the strip-list hint"
else
  bad "gap link carries the strip-list hint (got: $gapline)"
fi
if printf '%s' "$gapline" | grep -qF "gap-†-mark"; then
  ok "hint names the computed slug to extend the list with"
else
  bad "hint names the computed slug to extend the list with (got: $gapline)"
fi
realline="$(printf '%s\n' "$out" | grep -F 'totally-absent')"
if printf '%s' "$realline" | grep -qF "strip list is missing"; then
  bad "genuinely broken link stays unhinted (got: $realline)"
else
  ok "genuinely broken link stays unhinted"
fi

# CJK control: a heading whose anchor legitimately carries unicode letters must
# never be read as a strip-list gap — stripping its letters matches no anchor.
mkdir -p "$TMP/gapcjk/docs"
cat > "$TMP/gapcjk/docs/t.md" <<'EOF'
# T

## 後台數據
EOF
cat > "$TMP/gapcjk/docs/c.md" <<'EOF'
# Citer

Typo: [x](t.md#-).
EOF
out="$(cd "$TMP/gapcjk" && bash "$LINKS" check 2>&1)"; rc=$?
check "CJK broken link still fails the check (rc=$rc)" [ "$rc" -ne 0 ]
if printf '%s' "$out" | grep -qF "strip list is missing"; then
  bad "CJK heading never reads as a strip-list gap (got: $out)"
else
  ok "CJK heading never reads as a strip-list gap"
fi

# The intradoc miss takes its own slug_gap_hint call with different arguments;
# a swapped pair there yields an empty table and no hint, which no rc-only
# assertion would catch.
mkdir -p "$TMP/gapself/docs"
cat > "$TMP/gapself/docs/s.md" <<'EOF'
# S

## gap † mark

Self link: [g](#gap--mark).
EOF
out="$(cd "$TMP/gapself" && bash "$LINKS" check 2>&1)"; rc=$?
check "intradoc gap still fails the check (rc=$rc)" [ "$rc" -ne 0 ]
if printf '%s' "$out" | grep -qF "same file" && printf '%s' "$out" | grep -qF "gap-†-mark"; then
  ok "intradoc miss path carries the hint naming the computed slug"
else
  bad "intradoc miss path carries the hint naming the computed slug (got: $out)"
fi

# Known boundary, locked so a future change trips it: a mixed CJK+ASCII heading
# has an ASCII residue, and an anchor written as that residue draws the hint
# even though the link is wrong rather than the strip list short. Separating the
# two needs the unicode-category knowledge this awk dialect cannot carry, so the
# shape is recorded here instead of discriminated in the script.
mkdir -p "$TMP/gapmixed/docs"
cat > "$TMP/gapmixed/docs/t.md" <<'EOF'
# T

## 中文 section
EOF
cat > "$TMP/gapmixed/docs/c.md" <<'EOF'
# Citer

Wrong anchor: [x](t.md#-section).
EOF
out="$(cd "$TMP/gapmixed" && bash "$LINKS" check 2>&1)"; rc=$?
check "mixed CJK heading: a wrong anchor still fails the check (rc=$rc)" [ "$rc" -ne 0 ]
if printf '%s' "$out" | grep -qF "strip list is missing"; then
  ok "mixed CJK residue draws the hint (known boundary, see comment above)"
else
  bad "mixed CJK residue draws the hint (boundary moved — update this lock and the SLUG_AWK comment) (got: $out)"
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

# ---------------------------------------------------------------------------
# BUG-046 — `closure <path>` enumerates the premise-closure set: the doc surface
# CLAUDE.md § Doc Sync defines (docs/**/*.md + root README.md +
# plugins/*/README.md) minus consumables (docs/work/{BUG,DEBT}-*.md,
# docs/work/TEMPLATE.md) minus the anchor itself. Registry/index docs
# (decisions.md, parked.md, agents/*) are reachable by construction — the
# reverse-link index never named them.
# ---------------------------------------------------------------------------

echo "== doc-links: BUG-046 — closure enumerates the doc surface minus consumables =="
mkdir -p "$TMP/closure/docs/agents" "$TMP/closure/docs/specs" "$TMP/closure/docs/work" \
         "$TMP/closure/plugins/foo/skills/bar"
cat > "$TMP/closure/docs/overview.md" <<'EOF'
# Overview

## Problem

Premise text.
EOF
cat > "$TMP/closure/docs/decisions.md" <<'EOF'
# Decisions

## Closed Forks

| Fork | Because |
|---|---|
| Pure reverse-link gate | `overview.md` errs false-negative |
EOF
cat > "$TMP/closure/docs/parked.md" <<'EOF'
# Parked

- Closure map — trigger: doc count.
EOF
cat > "$TMP/closure/docs/agents/issue-tracker.md" <<'EOF'
# Issue Tracker
EOF
cat > "$TMP/closure/docs/specs/x.md" <<'EOF'
# Spec X
EOF
cat > "$TMP/closure/docs/work/README.md" <<'EOF'
# Work threads
EOF
cat > "$TMP/closure/docs/work/TEMPLATE.md" <<'EOF'
# TEMPLATE
EOF
cat > "$TMP/closure/docs/work/GAP-001.md" <<'EOF'
# GAP-001
EOF
cat > "$TMP/closure/docs/work/BUG-001.md" <<'EOF'
# BUG-001
EOF
cat > "$TMP/closure/docs/work/DEBT-001.md" <<'EOF'
# DEBT-001
EOF
cat > "$TMP/closure/README.md" <<'EOF'
# Repo
EOF
cat > "$TMP/closure/plugins/foo/README.md" <<'EOF'
# Plugin foo
EOF
cat > "$TMP/closure/plugins/foo/skills/bar/SKILL.md" <<'EOF'
# Skill bar
EOF

expected_closure="README.md
docs/agents/issue-tracker.md
docs/decisions.md
docs/parked.md
docs/specs/x.md
docs/work/GAP-001.md
docs/work/README.md
plugins/foo/README.md"

got_closure="$(cd "$TMP/closure" && bash "$LINKS" closure docs/overview.md 2>/dev/null)"
if [ "$got_closure" = "$expected_closure" ]; then
  ok "closure: full doc surface minus consumables minus anchor, sorted"
else
  bad "closure: full doc surface minus consumables minus anchor, sorted"
  printf 'expected:\n%s\ngot:\n%s\n' "$expected_closure" "$got_closure" | sed 's/^/        /'
fi

# decisions.md mentions the anchor only as a code span — never as a link — so the
# reverse index cannot reach it; closure must.
if printf '%s\n' "$got_closure" | grep -qxF docs/decisions.md; then
  ok "closure: registry doc unreachable by refs is present"
else
  bad "closure: registry doc unreachable by refs is present"
fi
if printf '%s\n' "$got_closure" | grep -qE '^docs/work/(BUG|DEBT)-001\.md$|^docs/work/TEMPLATE\.md$'; then
  bad "closure: consumables (BUG/DEBT cards, TEMPLATE) excluded"
else
  ok "closure: consumables (BUG/DEBT cards, TEMPLATE) excluded"
fi
if printf '%s\n' "$got_closure" | grep -q 'SKILL.md'; then
  bad "closure: non-surface files (SKILL.md) excluded"
else
  ok "closure: non-surface files (SKILL.md) excluded"
fi

out="$(cd "$TMP/closure" && bash "$LINKS" closure 2>&1)"; rc=$?
if [ "$rc" -eq 1 ] && printf '%s' "$out" | grep -q 'Usage:'; then
  ok "closure: no argument -> usage on stderr, exit 1"
else
  bad "closure: no argument -> usage on stderr, exit 1 (rc=$rc)"
  printf '%s\n' "$out" | sed 's/^/        /'
fi

got_anchored="$(cd "$TMP/closure" && bash "$LINKS" closure 'docs/overview.md#problem' 2>/dev/null)"
if [ "$got_anchored" = "$expected_closure" ]; then
  ok "closure: anchor fragment behaves identically to the bare path"
else
  bad "closure: anchor fragment behaves identically to the bare path"
  printf 'expected:\n%s\ngot:\n%s\n' "$expected_closure" "$got_anchored" | sed 's/^/        /'
fi

echo "== doc-links: DEBT-084 — check/refs/index scan plugins/*/README.md (full doc surface) =="
mkdir -p "$TMP/plug/docs" "$TMP/plug/plugins/foo"
cat > "$TMP/plug/docs/a.md" <<'EOF'
# Doc A

## Known

Body.
EOF
cat > "$TMP/plug/README.md" <<'EOF'
# Repo
EOF
cat > "$TMP/plug/plugins/foo/README.md" <<'EOF'
# Plugin foo

Good: [g](../../docs/a.md#known).
Bad: [b](../../docs/nope.md).
EOF

# check exits 1 and reports exactly the broken link in the plugin README
out_plug="$(cd "$TMP/plug" && bash "$LINKS" check 2>"$TMP/plug.err")"; rc_plug=$?
check "plug fixture: check exits 1" [ "$rc_plug" -eq 1 ]
expected_plug_finding="plugins/foo/README.md:4: docs/nope.md — path not found"
if [ "$out_plug" = "$expected_plug_finding" ]; then
  ok "plug fixture: check reports exactly the plugin-README broken link"
else
  bad "plug fixture: check reports exactly the plugin-README broken link"
  printf 'expected:\n%s\ngot:\n%s\n' "$expected_plug_finding" "$out_plug" | sed 's/^/        /'
fi

# refs docs/a.md lists plugins/foo/README.md as a citer
got_refs_plug="$(cd "$TMP/plug" && bash "$LINKS" refs docs/a.md)"
if printf '%s\n' "$got_refs_plug" | grep -qxF "plugins/foo/README.md"; then
  ok "plug fixture: refs docs/a.md lists plugins/foo/README.md"
else
  bad "plug fixture: refs docs/a.md lists plugins/foo/README.md"
  printf 'got:\n%s\n' "$got_refs_plug" | sed 's/^/        /'
fi

# index contains docs/a.md#known<TAB>plugins/foo/README.md
got_index_plug="$(cd "$TMP/plug" && bash "$LINKS" index)"
expected_index_row="docs/a.md#known	plugins/foo/README.md"
if printf '%s\n' "$got_index_plug" | grep -qxF "$expected_index_row"; then
  ok "plug fixture: index contains docs/a.md#known<TAB>plugins/foo/README.md"
else
  bad "plug fixture: index contains docs/a.md#known<TAB>plugins/foo/README.md"
  printf 'expected row:\n%s\ngot index:\n%s\n' "$expected_index_row" "$got_index_plug" | sed 's/^/        /'
fi

# construct lock: collect_docs() must not remain in the asset
collect_docs_count="$(grep -c '^collect_docs()' "$LINKS" || true)"
if [ "$collect_docs_count" -eq 0 ]; then
  ok "construct lock: collect_docs() not defined in the asset (single collector)"
else
  bad "construct lock: collect_docs() still defined in the asset (count=$collect_docs_count)"
fi

echo "== doc-links: BUG-056 — .claude/ bootstrap plan is machine state, exempt from the grep gate =="
# harness-bootstrap seeds the plan and its sync report beside the runway receipt.
# Machine state narrates nothing, so `terms` derives no grep term from those paths —
# bare and nested forms alike — while an ordinary doc path still yields its term.
for mp in .claude/bootstrap.md .claude/bootstrap-sync-report.md sub/.claude/bootstrap.md sub/.claude/bootstrap-sync-report.md; do
  got_terms="$(cd "$TMP" && bash "$LINKS" terms "$mp")"
  if [ -z "$got_terms" ]; then
    ok "terms: $mp yields no term (exempt machine state)"
  else
    bad "terms: $mp yields no term (exempt machine state)"
    printf 'got:\n%s\n' "$got_terms" | sed 's/^/        /'
  fi
done
got_terms="$(cd "$TMP" && bash "$LINKS" terms docs/techstack.md)"
if [ "$got_terms" = "techstack" ]; then
  ok "terms: an ordinary doc path still yields its term (exemption stays narrow)"
else
  bad "terms: an ordinary doc path still yields its term (exemption stays narrow)"
  printf 'got:\n%s\n' "$got_terms" | sed 's/^/        /'
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
