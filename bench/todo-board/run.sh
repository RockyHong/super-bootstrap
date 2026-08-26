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
for m in needme full; do
  if "$PY" "$SCRIPT" bench/todo-board/fixture-actor "$m" --date "$DATE" 2>/dev/null \
     | diff "bench/todo-board/expected/$m-actor.md" - >/dev/null; then
    echo "PASS $m-actor"
  else
    echo "FAIL $m-actor"
    "$PY" "$SCRIPT" bench/todo-board/fixture-actor "$m" --date "$DATE" 2>/dev/null \
      | diff "bench/todo-board/expected/$m-actor.md" -
    fail=1
  fi
done
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
err=$(mktemp)
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
