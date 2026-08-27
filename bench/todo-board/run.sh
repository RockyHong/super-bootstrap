#!/usr/bin/env bash
# Golden test for skills/todo/assets/render-board.py — the mechanical board renderer.
# Runs the script over the fixtures and diffs each mode against expected/.
# Usage: bash bench/todo-board/run.sh   (from the repo root or this directory)
set -u
cd "$(dirname "$0")/../.." || exit 1
SCRIPT=plugins/super-bootstrap/skills/todo/assets/render-board.py
PY=$(command -v python3 || command -v python) || { echo "SKIP: no python"; exit 1; }
DATE=2026-08-14   # goldens are pinned to this date
fail=0
for m in needme full discuss cloud device harness; do
  if "$PY" "$SCRIPT" bench/todo-board/fixture "$m" --date "$DATE" 2>/dev/null \
     | diff "bench/todo-board/expected/$m.md" - >/dev/null; then
    echo "PASS $m"
  else
    echo "FAIL $m"
    "$PY" "$SCRIPT" bench/todo-board/fixture "$m" --date "$DATE" 2>/dev/null \
      | diff "bench/todo-board/expected/$m.md" -
    fail=1
  fi
done
if "$PY" "$SCRIPT" bench/todo-board/fixture-empty needme --date "$DATE" 2>/dev/null \
   | diff "bench/todo-board/expected/needme-empty.md" - >/dev/null; then
  echo "PASS needme-empty"
else
  echo "FAIL needme-empty"; fail=1
fi
if "$PY" "$SCRIPT" bench/todo-board/fixture-allblocked needme --date "$DATE" 2>/dev/null    | diff "bench/todo-board/expected/needme-allblocked.md" - >/dev/null; then
  echo "PASS needme-allblocked"
else
  echo "FAIL needme-allblocked"
  "$PY" "$SCRIPT" bench/todo-board/fixture-allblocked needme --date "$DATE" 2>/dev/null     | diff "bench/todo-board/expected/needme-allblocked.md" -
  fail=1
fi
for m in needme full; do
  if "$PY" "$SCRIPT" bench/todo-board/fixture-extwait "$m" --date "$DATE" 2>/dev/null \
     | diff "bench/todo-board/expected/$m-extwait.md" - >/dev/null; then
    echo "PASS $m-extwait"
  else
    echo "FAIL $m-extwait"
    "$PY" "$SCRIPT" bench/todo-board/fixture-extwait "$m" --date "$DATE" 2>/dev/null \
      | diff "bench/todo-board/expected/$m-extwait.md" -
    fail=1
  fi
done
# The retired `Actor:` field: both cards classify by their thread state (`Triage:`
# rows, drainable) and each draws a `# note:` naming the leftover. Golden = board +
# both stderr lines, the same capture as the queue-table case below.
err=$(mktemp)
render_actor_retired() {
  "$PY" "$SCRIPT" bench/todo-board/fixture-actor-retired "$1" --date "$DATE" 2>"$err"
  grep -E '^# (note|sources):' "$err"
}
for m in needme full; do
  if render_actor_retired "$m" | diff "bench/todo-board/expected/$m-actor-retired.md" - >/dev/null; then
    echo "PASS $m-actor-retired"
  else
    echo "FAIL $m-actor-retired"
    render_actor_retired "$m" | diff "bench/todo-board/expected/$m-actor-retired.md" -
    fail=1
  fi
done
# The outward container in its folder form: three threads, one of them re-pointed by
# an Amendment (latest block leads), so the group split is read off the live fields.
for m in needme full; do
  if "$PY" "$SCRIPT" bench/todo-board/fixture-outward "$m" --date "$DATE" 2>/dev/null \
     | diff "bench/todo-board/expected/$m-outward.md" - >/dev/null; then
    echo "PASS $m-outward"
  else
    echo "FAIL $m-outward"
    "$PY" "$SCRIPT" bench/todo-board/fixture-outward "$m" --date "$DATE" 2>/dev/null \
      | diff "bench/todo-board/expected/$m-outward.md" -
    fail=1
  fi
done
# A lingering flat `docs/outward.md`: the legacy branch renders the same board it
# always did AND names the sync that splits it. Golden = board + both stderr lines,
# the same capture as the queue-table case.
render_outward_legacy() {
  "$PY" "$SCRIPT" bench/todo-board/fixture-outward-legacy needme --date "$DATE" 2>"$err"
  grep -E '^# (note|sources):' "$err"
}
if render_outward_legacy | diff "bench/todo-board/expected/needme-outward-legacy.md" - >/dev/null; then
  echo "PASS needme-outward-legacy"
else
  echo "FAIL needme-outward-legacy"
  render_outward_legacy | diff "bench/todo-board/expected/needme-outward-legacy.md" -
  fail=1
fi
# The sync-side migration (assets/scale/split-outward.py): the legacy fixture copied
# to a temp root and split — the produced file set is the folder form, the README
# carries the flat header's consumed ID, an entry file is byte-identical to the folder
# fixture's, and the re-render is `# note:`-free (the retired form is gone).
SPLIT=plugins/super-bootstrap/skills/harness-bootstrap/assets/scale/split-outward.py
SKEL=plugins/super-bootstrap/skills/harness-bootstrap/assets/scale/outward-readme-skeleton.md
tmp="$(mktemp -d)"
cp -r bench/todo-board/fixture-outward-legacy/. "$tmp/"
if [ ! -f "$SKEL" ]; then    # skeleton not shipped yet — pin the line shape it carries
  SKEL="$tmp/readme-skeleton.md"
  printf '# Outward\n\n**ID high-water mark:** `OUT-000` — last consumed outward ID.\n' > "$SKEL"
fi
split_ok=1
"$PY" "$SPLIT" "$tmp" "$SKEL" >/dev/null 2>&1 || split_ok=0
produced="$( (cd "$tmp/docs/outward" 2>/dev/null && ls) | LC_ALL=C sort | tr '\n' ' ')"
hw="$(grep -m1 'ID high-water mark' "$tmp/docs/outward/README.md" 2>/dev/null \
      | grep -o 'OUT-[0-9][0-9]*' | head -1)"
notes="$("$PY" "$SCRIPT" "$tmp" needme --date "$DATE" 2>&1 >/dev/null | grep -c '^# note:')"
# Relative link targets gain one `../` (the entry sits a directory deeper than the
# flat file); http(s) / mailto / #anchor / absolute targets stay as written.
links="$(grep -c '\](\.\./business/licences\.md)' "$tmp/docs/outward/OUT-001.md" 2>/dev/null)"
kept="$(grep -c '(https://example\.com/t)' "$tmp/docs/outward/OUT-001.md" 2>/dev/null)"
anchor="$(grep -c '(#entries)' "$tmp/docs/outward/OUT-001.md" 2>/dev/null)"
if [ "$split_ok" = 1 ] && [ "$produced" = "OUT-001.md OUT-002.md README.md " ] \
   && [ "$hw" = "OUT-002" ] && [ ! -f "$tmp/docs/outward.md" ] && [ "$notes" = 0 ] \
   && [ "$links" = 1 ] && [ "$kept" = 1 ] && [ "$anchor" = 1 ] \
   && diff bench/todo-board/fixture-outward/docs/outward/OUT-002.md \
           "$tmp/docs/outward/OUT-002.md" >/dev/null; then
  echo "PASS split-outward"
else
  echo "FAIL split-outward (ran $split_ok · files: $produced · high-water: $hw · notes: $notes · links rebased: $links · kept: $kept/$anchor)"
  diff bench/todo-board/fixture-outward/docs/outward/OUT-002.md "$tmp/docs/outward/OUT-002.md"
  fail=1
fi
# A flat file back beside a live folder must refuse rather than overwrite it.
cp bench/todo-board/fixture-outward-legacy/docs/outward.md "$tmp/docs/outward.md"
if "$PY" "$SPLIT" "$tmp" "$SKEL" >/dev/null 2>&1; then
  echo "FAIL split-outward-refuse (split ran twice)"; fail=1
else
  echo "PASS split-outward-refuse"
fi
rm -rf "$tmp"
# Pre-substrate repo: docs/work/README.md present but without the ID high-water
# line. One substrate row (the agent's literal) plus the per-file row for the
# non-card file, Drainable 0 — never the empty state.
for m in needme full; do
  if "$PY" "$SCRIPT" bench/todo-board/fixture-nosubstrate "$m" --date "$DATE" 2>/dev/null      | diff "bench/todo-board/expected/$m-nosubstrate.md" - >/dev/null; then
    echo "PASS $m-nosubstrate"
  else
    echo "FAIL $m-nosubstrate"
    "$PY" "$SCRIPT" bench/todo-board/fixture-nosubstrate "$m" --date "$DATE" 2>/dev/null       | diff "bench/todo-board/expected/$m-nosubstrate.md" -
    fail=1
  fi
done
# Wired venue map (scale module installed). The board renders from the script's
# built-in encoding of the shipped skeleton; the divergent-map root additionally
# emits a one-line stderr notice, appended to its golden (`# sources:` is not).
for m in needme full; do
  if "$PY" "$SCRIPT" bench/todo-board/fixture-venue "$m" --date "$DATE" 2>/dev/null      | diff "bench/todo-board/expected/$m-venue.md" - >/dev/null; then
    echo "PASS $m-venue"
  else
    echo "FAIL $m-venue"
    "$PY" "$SCRIPT" bench/todo-board/fixture-venue "$m" --date "$DATE" 2>/dev/null       | diff "bench/todo-board/expected/$m-venue.md" -
    fail=1
  fi
done
render_edited() {
  "$PY" "$SCRIPT" bench/todo-board/fixture-venue-edited needme --date "$DATE" 2>"$err"
  grep '^# note:' "$err"
}
if render_edited | diff "bench/todo-board/expected/needme-venue-edited.md" - >/dev/null; then
  echo "PASS needme-venue-edited"
else
  echo "FAIL needme-venue-edited"
  render_edited | diff "bench/todo-board/expected/needme-venue-edited.md" -
  fail=1
fi
# A `## Pending` section in a foreign shape (markdown table): zero entries parse,
# and the board says so on the stderr note channel. Golden = board + both stderr lines.
render_queue_table() {
  "$PY" "$SCRIPT" bench/todo-board/fixture-queue-table needme --date "$DATE" 2>"$err"
  grep -E '^# (note|sources):' "$err"
}
if render_queue_table | diff "bench/todo-board/expected/needme-queue-table.md" - >/dev/null; then
  echo "PASS needme-queue-table"
else
  echo "FAIL needme-queue-table"
  render_queue_table | diff "bench/todo-board/expected/needme-queue-table.md" -
  fail=1
fi
rm -f "$err"

exit "$fail"
