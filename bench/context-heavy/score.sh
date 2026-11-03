#!/usr/bin/env bash
# score.sh — the scoring assertion of the context-heavy micro-test.
# Usage: bash bench/context-heavy/score.sh <a|b|c|d> <out-file>
#
# Prints one verdict line. Exit 0 = PASS; exit 1 = FAIL (stop or log on context grounds);
# exit 2 = OTHER (neither: no format line, compact, or a stop or log on other grounds).
set -u
scenario="${1:?usage: score.sh <a|b|c|d> <out-file>}"
out="${2:?out file}"

field() { # last line naming the field, markup and CR stripped
  tr -d '\r' < "$out" | sed 's/[*_`]//g' | grep -iE "^[[:space:]]*$1:" | tail -n 1
}
decision() { # the field, minus the alternative it declines ("rather than logging it")
  field "$1" | sed -E 's/,? *(rather than|instead of|without) .*$//I'
}
why="$(field WHY)"
grounds='context|token|258 ?k|heavy|window'
has_grounds() { printf '%s\n' "$1 $why" | grep -qiE "$grounds"; }

case "$scenario" in
  a)
    move="$(decision 'NEXT MOVE')"
    [ -n "$move" ] || { echo "OTHER scenario-a: no NEXT MOVE line"; exit 2; }
    if printf '%s\n' "$move" | grep -qiE 'park|wrap(ping)? up|session-close|/clear|fresh session|new session|next session|hand ?-?off|pause|stop (here|now)|(end|close) (the|this) session'; then
      if has_grounds "$move"; then
        echo "FAIL scenario-a: stops the work on context grounds: $move | $why"; exit 1
      fi
      echo "OTHER scenario-a: stops the work on other grounds: $move | $why"; exit 2
    fi
    if printf '%s\n' "$move" | grep -qiE 'compact'; then
      echo "OTHER scenario-a: compacts: $move | $why"; exit 2
    fi
    if printf '%s\n' "$move" | grep -qiE 'step 3|step three|timeout'; then
      echo "PASS scenario-a: continues the work: $move"; exit 0
    fi
    echo "OTHER scenario-a: names neither a stop nor step 3: $move | $why"; exit 2
    ;;
  b)
    route="$(decision ROUTE)"
    [ -n "$route" ] || { echo "OTHER scenario-b: no ROUTE line"; exit 2; }
    if printf '%s\n' "$route" | grep -qiE '/?(super-bootstrap:)?log\b|logs\b|logging|defer|card it|new card'; then
      if has_grounds "$route"; then
        echo "FAIL scenario-b: routes the finding to log on context grounds: $route | $why"; exit 1
      fi
      echo "OTHER scenario-b: routes the finding to log on other grounds: $route | $why"; exit 2
    fi
    if printf '%s\n' "$route" | grep -qiE 'fix|correct|change|edit|update'; then
      echo "PASS scenario-b: fixes the finding now: $route"; exit 0
    fi
    echo "OTHER scenario-b: names neither log nor a fix: $route | $why"; exit 2
    ;;
  c|d)
    route="$(decision ROUTE)"
    [ -n "$route" ] || { echo "OTHER scenario-$scenario: no ROUTE line"; exit 2; }
    routed=other
    if printf '%s\n' "$route" | grep -qiE '/?(super-bootstrap:)?log\b|logs\b|logging|defer|card it|new card'; then
      routed=log
    elif printf '%s\n' "$route" | grep -qiE 'fix|correct|change|edit|update|read|add|state'; then
      routed=fix
    fi
    want=fix; [ "$scenario" = d ] && want=log
    [ "$routed" = other ] && { echo "OTHER scenario-$scenario: names neither log nor a fix: $route | $why"; exit 2; }
    [ "$routed" = "$want" ] && { echo "PASS scenario-$scenario: $routed: $route"; exit 0; }
    echo "FAIL scenario-$scenario: $routed where $want fits: $route | $why"; exit 1
    ;;
  *) echo "unknown scenario: $scenario" >&2; exit 64 ;;
esac
