#!/usr/bin/env bash
# closed-forks.sh — resolve docs/decisions.md § Closed Forks for /log step 2's gate
#
#   bash closed-forks.sh [repo-root]        (repo-root defaults to the cwd)
#
# Zero judgement: the source either resolves or fails loud, so a run that read the
# section and a run that read nothing no longer look alike. The collision call
# stays in the skill; this script owns the source and the outcome checklist.
#
# Outcomes:
#   exit 0  file present, section resolved → `docs/decisions.md § Closed Forks — N rows`,
#           one `[domain] direction (ref: ref)` line per data row (Because cell
#           dropped — the skill opens a candidate row itself), then the checklist.
#           An empty table (the shipped skeleton) resolves as 0 rows.
#   exit 0  file absent → `docs/decisions.md § Closed Forks — absent`, then the
#           checklist. A resolved state, distinct from unread.
#   exit 1  unresolvable → stderr names docs/decisions.md and the cause: heading
#           missing (a heading inside a ``` / ~~~ fence does not count), no table
#           under it, a header lacking a Domain / Rejected direction / Ref column,
#           or a data row whose cell count differs from the header's.
#   exit 2  usage error, or the file exists but is unreadable.
#
# Section body = lines after `## Closed Forks` up to the next heading of level 1-2.
# Cells split on `|`; a GFM-escaped `\|` is cell text (restored as `|` in output),
# so a row quoting a matcher like `Edit\|Write` projects whole. A bare `|` inside
# a cell — code span included, as GFM splits there too — shifts the cell count and
# fails loud rather than shifting columns silently.

set -u

[ "$#" -le 1 ] || { echo "usage: closed-forks.sh [repo-root]" >&2; exit 2; }
root=${1:-.}
rel=docs/decisions.md
file=$root/$rel
heading='## Closed Forks'
checklist="Outcome required from step 2, one line per entry reaching the Closed-forks gate: \`decisions.md § Closed Forks — collides: <row>\` or \`decisions.md § Closed Forks — no collision\`"

if [ ! -e "$file" ]; then
  echo "$rel § Closed Forks — absent"
  echo "Outcome required from step 2, one line per entry reaching the Closed-forks gate: \`decisions.md § Closed Forks — absent\`"
  exit 0
fi
[ -r "$file" ] || { echo "closed-forks: cannot read $rel" >&2; exit 2; }

awk -v want="$heading" -v rel="$rel" -v checklist="$checklist" '
  function trim(s) { gsub(/^[ \t]+/, "", s); gsub(/[ \t]+$/, "", s); return s }
  function fail(msg) { print "closed-forks: FAIL: " msg " in " rel > "/dev/stderr"; bad = 1; exit 1 }
  # split a table row into cells[1..n] (outer pipes stripped); escaped \| stays text
  function cells(line,   n, i, raw) {
    line = trim(line)
    gsub(/\\[|]/, "\001", line)
    sub(/^[|]/, "", line); sub(/[|]$/, "", line)
    n = split(line, raw, "|")
    for (i = 1; i <= n; i++) { c[i] = trim(raw[i]); gsub("\001", "|", c[i]) }
    return n
  }
  { sub(/\r$/, "") }
  /^[ \t]*(```|~~~)/ { fence = !fence; next }
  fence { next }
  /^#+[ \t]/ {
    match($0, /^#+/); lvl = RLENGTH
    h = $0; sub(/[ \t]+$/, "", h)
    if (on && lvl <= 2) { on = 0; done = 1 }
    if (!on && !done && h == want) { on = 1; found = 1 }
    next
  }
  !on { next }
  $0 !~ /^[ \t]*[|]/ { next }
  !hdr {
    hn = cells($0); hdr = 1
    for (i = 1; i <= hn; i++) {
      if (c[i] == "Domain") di = i
      else if (c[i] == "Rejected direction") ri = i
      else if (c[i] == "Ref") fi = i
    }
    if (!di) fail("no Domain column in the ## Closed Forks table header")
    if (!ri) fail("no Rejected direction column in the ## Closed Forks table header")
    if (!fi) fail("no Ref column in the ## Closed Forks table header")
    next
  }
  !sep { sep = 1; next }
  {
    n = cells($0)
    if (n != hn) fail("row has " n " cells, header has " hn ": " substr($0, 1, 160))
    rows++
    out[rows] = "[" c[di] "] " c[ri] " (ref: " c[fi] ")"
  }
  END {
    if (bad) exit 1
    if (!found) fail("heading not found: " want)
    if (!hdr) fail("no table under " want)
    print rel " § Closed Forks — " rows + 0 " rows"
    for (i = 1; i <= rows; i++) print out[i]
    print checklist
  }
' "$file"
