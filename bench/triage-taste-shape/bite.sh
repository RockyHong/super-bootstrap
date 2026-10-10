#!/usr/bin/env bash
# BUG-084 — prove every score.py assertion reds on a violating input and
# passes on a clean one. Exit 0 = every expectation met.
set -u
SRC="$(cd "$(dirname "$0")" && pwd)"
export PYTHONIOENCODING=utf-8
ok=0
expect() { # <want-exit> <mode> <file>
  python "$SRC/score.py" "$2" "$SRC/bite/$3"; got=$?
  [ "$got" -eq "$1" ] && echo "  -> ok (exit $got)" || { echo "  -> UNEXPECTED exit $got (want $1)"; ok=1; }
}
expect 0 agent   agent-good.card.md
expect 1 agent   agent-bad.card.md
expect 1 agent   agent-twoverdicts.card.md
expect 0 gateway gateway-good.md
expect 1 gateway gateway-bad.md
exit $ok
