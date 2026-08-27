#!/usr/bin/env bash
# Golden test for skills/commit/assets/doc-links.sh — the commit door's mechanical
# doc-sync gate. Runs each mode from the fixture root and diffs stdout against expected/.
# Usage: bash bench/doc-links/run.sh   (from the repo root or this directory)
set -u
cd "$(dirname "$0")/../.." || exit 1
SCRIPT="$PWD/plugins/super-bootstrap/skills/commit/assets/doc-links.sh"
FIX="$PWD/bench/doc-links/fixture"
FIXHB="$PWD/bench/doc-links/fixture-history-broken"
FIXCC="$PWD/bench/doc-links/fixture-consumed-card"
FIXCCC="$PWD/bench/doc-links/fixture-consumed-card-clean"
EXP="$PWD/bench/doc-links/expected"
TMP="$(mktemp)"
fail=0

# Raw stdout, byte-compared, plus exit 0 — an empty golden must mean "ran and found
# nothing", never "mode not recognised". stderr is dropped: diagnostics are not the contract.
run_case() {
  name="$1"; shift
  ( cd "$FIX" && bash "$SCRIPT" "$@" ) > "$TMP" 2>/dev/null
  rc=$?
  if [ "$rc" -eq 0 ] && diff "$EXP/$name.txt" "$TMP" > /dev/null; then
    echo "PASS $name"
  else
    echo "FAIL $name (exit $rc)"
    diff "$EXP/$name.txt" "$TMP"
    fail=1
  fi
}

# `refs` prints in doc-surface order, which is filesystem-order dependent; the
# union + uniqueness property is what these goldens pin, so they are sort-normalized.
run_case_sorted() {
  name="$1"; shift
  ( cd "$FIX" && bash "$SCRIPT" "$@" ) 2>/dev/null | LC_ALL=C sort > "$TMP"
  if diff "$EXP/$name.txt" "$TMP" > /dev/null; then
    echo "PASS $name"
  else
    echo "FAIL $name"
    diff "$EXP/$name.txt" "$TMP"
    fail=1
  fi
}

# --- terms: path-class filter, derivation, generic + short drop ---
run_case terms-skill terms plugins/x/skills/foo-bar/SKILL.md
run_case terms-history terms docs/chronicle.md docs/specs/thing.md
run_case terms-agent terms plugins/x/agents/judge.md
# Machine-state files harness-bootstrap seeds under .claude/ narrate nothing.
run_case terms-machine-state terms .claude/super-bootstrap-runway.json .claude/templates/worktree-settings.local.json
run_case terms-dropped terms \
  bench/todo-board/run.sh \
  tests/expected/full.md \
  README.md \
  plugins/x/assets/run.sh \
  docs/work/DEBT-001.md \
  docs/work/README.md \
  docs/outward.md \
  SESSION-STATE/park-a1b2c3d4.md \
  docs/specs/ui.md \
  docs/assets/diagram.png
run_case terms-mixed terms \
  docs/specs/thing.md \
  scripts/level.gd \
  plugins/x/skills/foo-bar/SKILL.md \
  README.md \
  bench/todo-board/run.sh

# Replay: the acceptance fixtures, as file lists. A bench-only commit yields no term;
# a skill commit yields the skill name plus its asset basename.
run_case terms-replay-bench terms \
  bench/todo-board/README.md \
  bench/todo-board/expected/full-nosubstrate.md \
  bench/todo-board/expected/needme-nosubstrate.md \
  bench/todo-board/fixture-nosubstrate/docs/work/README.md \
  bench/todo-board/fixture-nosubstrate/docs/work/notes-scratch.md \
  bench/todo-board/run.sh \
  docs/work/DEBT-100.md
run_case terms-replay-skill terms \
  docs/work/DEBT-089.md \
  plugins/super-bootstrap/skills/harness-bootstrap/SKILL.md \
  plugins/super-bootstrap/skills/harness-bootstrap/assets/claude-md-skeleton.md

# --- hits: code shape only ---
run_case hits-level hits level
run_case hits-hyphen hits foo-bar
run_case hits-multi hits level foo-bar
run_case hits-miss hits zzznothing
# A `dimension: history` frontmatter declaration drops the doc from the hit set; the
# same string sitting in a body is prose, so the undeclared doc still hits.
run_case hits-history hits foo-baz
# Harness-seeded hub stems count only as a bare token inside a code span: a link
# target, a backticked path and a bare path all stay out; the doc naming the
# artifact itself hits.
run_case hits-hub hits overview techstack

# --- anchors: nearest heading at or above each range start ---
run_case anchors-basic anchors docs/anchors.md +9 +16,2
run_case anchors-top anchors docs/anchors.md +1
run_case anchors-punct anchors docs/anchors.md +21
run_case anchors-noplus anchors docs/anchors.md 9

# --- refs: single anchor unchanged, multi-anchor union ---
run_case_sorted refs-single refs docs/anchors.md#alpha
run_case_sorted refs-multi refs docs/anchors.md#alpha docs/anchors.md#beta
# The only citer of specs/thing.md is the history-dimension doc, so the citer lane is empty.
run_case refs-history refs docs/specs/thing.md

# --- check: the fixture surface has no broken links ---
( cd "$FIX" && bash "$SCRIPT" check ) > "$TMP" 2>/dev/null
rc=$?
if [ "$rc" -eq 0 ] && diff "$EXP/check.txt" "$TMP" > /dev/null; then
  echo "PASS check"
else
  echo "FAIL check (exit $rc)"
  diff "$EXP/check.txt" "$TMP"
  fail=1
fi

# --- check: a history doc keeps its links in the integrity lane ---
# Own fixture root, one history doc, one dangling link: `check` reports it and exits 1.
( cd "$FIXHB" && bash "$SCRIPT" check ) > "$TMP" 2>/dev/null
rc=$?
if [ "$rc" -eq 1 ] && diff "$EXP/check-history-broken.txt" "$TMP" > /dev/null; then
  echo "PASS check-history-broken"
else
  echo "FAIL check-history-broken (exit $rc)"
  diff "$EXP/check-history-broken.txt" "$TMP"
  fail=1
fi

# --- check: a card→card link to an absent card ID is consumed provenance ---
# Own fixture root. The exempt class (a card thread citing a deleted sibling) leaves
# no line; both controls stay strict — a card citing an absent spec, and a non-card
# doc citing an absent card (the exemption is source-scoped) — so exit stays 1.
( cd "$FIXCC" && bash "$SCRIPT" check ) > "$TMP" 2>/dev/null
rc=$?
if [ "$rc" -eq 1 ] && diff "$EXP/check-consumed-card.txt" "$TMP" > /dev/null; then
  echo "PASS check-consumed-card"
else
  echo "FAIL check-consumed-card (exit $rc)"
  diff "$EXP/check-consumed-card.txt" "$TMP"
  fail=1
fi

# --- check: the exempt class alone is silent, exit 0 ---
( cd "$FIXCCC" && bash "$SCRIPT" check ) > "$TMP" 2>/dev/null
rc=$?
if [ "$rc" -eq 0 ] && diff "$EXP/check-consumed-card-clean.txt" "$TMP" > /dev/null; then
  echo "PASS check-consumed-card-clean"
else
  echo "FAIL check-consumed-card-clean (exit $rc)"
  diff "$EXP/check-consumed-card-clean.txt" "$TMP"
  fail=1
fi

rm -f "$TMP"
exit "$fail"
