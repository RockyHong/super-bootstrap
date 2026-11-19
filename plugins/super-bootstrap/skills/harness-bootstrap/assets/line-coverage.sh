#!/usr/bin/env bash
# line-coverage.sh — did a CLAUDE.md migration lose a line? harness-bootstrap runs it after
# splitting an old CLAUDE.md onto the placed doctrine file: every non-blank line of the old
# file must be found in the new pair (new CLAUDE.md + placed harness.md) or on a drop list
# the user saw. It reports; it never writes.
#
# Usage:
#   bash line-coverage.sh <old-CLAUDE.md> <new-CLAUDE.md> <placed-harness.md> [<drop-list-file>]
#     The drop list is plain text, one dropped old line per line, verbatim. Omitted or
#     empty -> no drops.
#
# Normalisation, applied to every line of all four inputs before comparing: strip CR; trim
# leading and trailing spaces and tabs; replace each markdown link target `](...)` with
# `]()`. Comparison is exact string equality on the result (never a pattern).
#
# A non-blank normalised old line is covered when it equals a normalised line of <new>,
# <placed-harness> or <drop-list-file>. Duplicate old lines are judged one by one.
#
# Output and exit codes:
#   0  all covered; one line: `line-coverage: <N> lines — <M> in the new pair, <K> on the
#      drop list` (N = non-blank old lines; a line in both the pair and the drop list
#      counts under the pair)
#   1  some uncovered; per uncovered old line, in file order,
#      `uncovered: <old line number>: <original line, CR stripped>`, then the last line
#      `line-coverage: <U> of <N> lines uncovered`
#   2  wrong argument count, or old/new/harness missing or unreadable, or a named drop
#      list missing: one line on stderr, nothing on stdout
#
# Why link targets are masked: a migration re-bases link paths (`docs/x.md` becomes
# `../../docs/x.md` once the doctrine moves under .claude/rules/), so a target differs
# between old and new by design. Link TEXT still compares; link validity is another
# check's job (the commit door's doc-links.sh).
#
# Dialect: one awk pass, no subprocess per line; awk limited to the portable subset
# (asset-dialects rule) — no interval expressions, explicit [ \t]. Input files are read
# with getline inside awk, and their names travel through ENVIRON, not `-v` (which would
# interpret backslashes in a Windows path) and not as operands (a name like `a=b.md`
# would be read as a variable assignment, and an empty file would not signal its turn).

set -uo pipefail

usage() { echo "usage: line-coverage.sh <old-CLAUDE.md> <new-CLAUDE.md> <placed-harness.md> [<drop-list-file>]" >&2; exit 2; }
die()   { echo "line-coverage.sh: $1" >&2; exit 2; }

[ "$#" -ge 3 ] && [ "$#" -le 4 ] || usage
for f in "$1" "$2" "$3"; do
    [ -f "$f" ] && [ -r "$f" ] || die "cannot read '$f'"
done
if [ "$#" -eq 4 ]; then
    [ -f "$4" ] && [ -r "$4" ] || die "cannot read drop list '$4'"
fi

LC_OLD="$1" LC_NEW="$2" LC_HARNESS="$3" LC_DROP="${4:-}" awk '
function norm(s) {
    gsub(/\r/, "", s)
    sub(/^[ \t]+/, "", s)
    sub(/[ \t]+$/, "", s)
    gsub(/\]\([^)]*\)/, "]()", s)
    return s
}
# load <file> <set-name-flag>: flag 1 -> pair set, 2 -> drop set
function load(file, flag,    line, k) {
    while ((getline line < file) > 0) {
        k = norm(line)
        if (k == "") continue
        if (flag == 1) pair[k] = 1; else drop[k] = 1
    }
    close(file)
}
BEGIN {
    load(ENVIRON["LC_NEW"], 1)
    load(ENVIRON["LC_HARNESS"], 1)
    if (ENVIRON["LC_DROP"] != "") load(ENVIRON["LC_DROP"], 2)
    old = ENVIRON["LC_OLD"]
    n = 0; m = 0; kd = 0; u = 0; ln = 0
    while ((getline line < old) > 0) {
        ln++
        k = norm(line)
        if (k == "") continue
        n++
        if (k in pair) m++
        else if (k in drop) kd++
        else {
            u++
            orig = line; gsub(/\r/, "", orig)
            print "uncovered: " ln ": " orig
        }
    }
    close(old)
    if (u > 0) { print "line-coverage: " u " of " n " lines uncovered"; exit 1 }
    print "line-coverage: " n " lines — " m " in the new pair, " kd " on the drop list"
    exit 0
}
'
