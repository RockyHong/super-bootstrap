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
exit "$fail"
