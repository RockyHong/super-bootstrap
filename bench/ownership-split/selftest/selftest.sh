#!/usr/bin/env bash
# Bite check for score.py. make-trees.py builds the hand-made result trees and
# their expected verdicts; this script scores them and compares row by row:
# `valid` and `pass` must match exactly, and the scorer's reason must carry the
# expected substring (so a fail is checked to name the property it failed on).
# Exits 1 on any wrong verdict. Runs no `claude` process.
#
# Usage: bash selftest/selftest.sh [-v]      -v also prints every scored row
# Env:   KEEP=<dir>  build the trees there and keep them (default: a temp dir, removed)
set -u
D="$(cd "$(dirname "$0")" && pwd)"
VERBOSE="${1:-}"
# native python.exe needs Windows paths, not /d/... or /tmp/...
W() { if command -v cygpath >/dev/null 2>&1; then cygpath -m "$1"; else printf '%s\n' "$1"; fi; }
if [ -n "${KEEP:-}" ]; then T="$KEEP"; rm -rf "$T"; mkdir -p "$T"; else T="$(mktemp -d)"; trap 'rm -rf "$T"' EXIT; fi

PYTHONIOENCODING=utf-8 python3 "$(W "$D/make-trees.py")" "$(W "$T")" >/dev/null || { echo "SELFTEST FAIL — could not build the trees"; exit 1; }
# QUIRK: Windows python prints CRLF; tr strips the CR before comparing.
got="$(PYTHONIOENCODING=utf-8 python3 "$(W "$D/../score.py")" "$(W "$T/trees")" --asset "$(W "$T/asset/harness.md")" --machine | tr -d '\015')"
want="$(tr -d '\015' < "$T/expected.tsv")"

bad=0; n=0
while IFS="$(printf '\t')" read -r name valid pass sub; do
  [ -n "$name" ] || continue
  n=$((n + 1))
  row="$(printf '%s\n' "$got" | awk -F'\t' -v n="$name" '$1 == n')"
  if [ -z "$row" ]; then echo "WRONG $name: no scorer row"; bad=$((bad + 1)); continue; fi
  gv="$(printf '%s' "$row" | cut -f2)"; gp="$(printf '%s' "$row" | cut -f3)"; gr="$(printf '%s' "$row" | cut -f4-)"
  if [ "$gv" != "$valid" ] || [ "$gp" != "$pass" ]; then
    echo "WRONG $name: want valid=$valid pass=$pass, got valid=$gv pass=$gp ($gr)"; bad=$((bad + 1))
  else
    case "$gr" in
      *"$sub"*) [ "$VERBOSE" = "-v" ] && printf '%-28s valid=%s pass=%s  %s\n' "$name" "$gv" "$gp" "$gr" ;;
      *) echo "WRONG $name: reason lacks \`$sub\` — got: $gr"; bad=$((bad + 1)) ;;
    esac
  fi
done <<EOF
$want
EOF
rows="$(printf '%s\n' "$got" | grep -c .)"
[ "$rows" = "$n" ] || { echo "WRONG row count: scorer printed $rows rows, expected $n"; bad=$((bad + 1)); }
if [ "$bad" -eq 0 ]; then echo "SELFTEST OK — $n trees, every verdict and reason as expected"; exit 0; fi
echo "SELFTEST FAIL — $bad wrong verdict(s) of $n"
exit 1
