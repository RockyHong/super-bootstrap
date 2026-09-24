#!/usr/bin/env bash
# DEBT-118 M4 — bite check: every score.py assertion must fail on an induced
# bad verdict. bite/ holds hand-authored verdict cards:
#   BUG-001-good       well-formed auto-fix naming the true cause   -> all pass
#   BUG-002-good       a real run's verdict (instrument smoke run)   -> all pass
#   BUG-001-decoy      well-formed, blames is_duplicate              -> cause FAIL, decoy=1
#   BUG-002-decoy      well-formed, blames SYMBOLS                   -> cause FAIL, decoy=1
#   BUG-001-malformed  Execution tag + Test Strategy dropped         -> shape FAIL
#   BUG-001-rewritten  Prior line edited + a second Verdict block    -> origin FAIL, one_block FAIL
#   BUG-001-budget     `truncated at budget` surface exit            -> cause FAIL, budget=1
# Usage: bash bite.sh
SRC="$(cd "$(dirname "$0")" && pwd)"
PYTHONIOENCODING=utf-8 python3 "$SRC/score.py" "$SRC/bite" "$SRC/fixture"
