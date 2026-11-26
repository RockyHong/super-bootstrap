#!/usr/bin/env bash
# Mechanical assertions over one run.sh output file. Prints one PASS / FAIL line
# per expectation; exits 1 on any FAIL.
#   s1, s1b  the ruling lands in docs/specs/cli.md, and the GAP-31 write links to it
#   s2  the DEBT-41 write carries `not before 2026-12-03` (the one fixed shape)
#   s3  the only file written is docs/work/BUG-51.md
#
# Usage: bash check.sh <s1|s1b|s2|s3> <runs/<scenario>-<tag>.result.txt>
set -u
SC="${1:?usage: check.sh <scenario> <file>}"
F="${2:?file}"
[ -f "$F" ] || { echo "FAIL: no file $F"; exit 1; }
rc=0
pass(){ echo "PASS $1"; }
fail(){ echo "FAIL $1"; rc=1; }
# path list, and the body of the WRITE block for one path (backticks stripped)
paths(){ sed -n 's/^=== WRITE \(.*\) ===[[:space:]]*$/\1/p' "$F" | tr -d '`\r'; }
body(){ awk -v p="$1" '/^=== WRITE /{on = (index($0, p) > 0); next} /^=== END ===/{on=0} on' "$F"; }
case "$SC" in
  s1|s1b)
    if paths | grep -qx 'docs/specs/cli.md'; then pass "s1 writes docs/specs/cli.md"; else fail "s1 writes docs/specs/cli.md"; fi
    if body docs/specs/cli.md | grep -Eiq 'verb'; then pass "s1 cli.md carries the naming rule"; else fail "s1 cli.md carries the naming rule"; fi
    if body docs/work/GAP-31.md | grep -Eq '(specs/)?cli\.md'; then pass "s1 GAP-31 block links cli.md"; else fail "s1 GAP-31 block links cli.md"; fi
    ;;
  s2)
    if body docs/work/DEBT-41.md | grep -q 'not before 2026-12-03'; then pass "s2 DEBT-41 block names not before 2026-12-03"; else fail "s2 DEBT-41 block names not before 2026-12-03"; fi
    ;;
  s3)
    if paths | grep -qx 'docs/work/BUG-51.md'; then pass "s3 writes BUG-51.md"; else fail "s3 writes BUG-51.md"; fi
    if paths | grep -vqx 'docs/work/BUG-51.md'; then fail "s3 writes nothing but BUG-51.md"; else pass "s3 writes nothing but BUG-51.md"; fi
    ;;
  *) echo "unknown scenario $SC"; exit 2 ;;
esac
exit $rc
