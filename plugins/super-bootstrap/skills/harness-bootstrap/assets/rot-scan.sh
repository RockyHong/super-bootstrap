#!/usr/bin/env bash
# rot-scan.sh — harness-bootstrap's § 2b rot scan instrument: find renamed-away literals
# from rename-map.md in the scope files. It reports; it never writes.
#
# Usage:
#   printf '%s\n' <scope files...> | bash rot-scan.sh <rename-map.md>
#     Scope list on stdin, one path per line (a path may hold spaces; a trailing CR and
#     blank lines are ignored).
#
# Rows parsed out of the map (a row = a markdown bullet whose text opens with a
# backticked literal):
#   - rename row, any section but § Retired files:  - `old` → `new` [— reason]
#     A bullet with no ` → `new`` after the first literal is not a row.
#   - retired row, under `## Retired files`:        - `old` [— reason]
#     Every such bullet is a row, whatever follows the literal; its new column prints
#     `(retired)`.
#
# Token boundary — one definition for every row. An occurrence of `old` is a hit when:
#   - the byte before it is NOT a word char [A-Za-z0-9_], `/`, `.`, `-` or `:`
#     (line start counts as a boundary), and
#   - the byte after it is NOT a word char, `-` or `/`, and is not a `:` that is itself
#     followed by a word char (the plugin namespace separator, `/x:log`).
#   Line end, whitespace, backtick, other punctuation and `: ` stay real hits. So
#   `/super-bootstrap` misses `/super-bootstrap:log` and `plugins/super-bootstrap/`, and
#   `/commit` misses `…/commit/abc`, but `run /commit: now` hits. The same rule makes a
#   path literal miss a prefixed form: retired `.claude/rules/x.md` does not hit
#   `./.claude/rules/x.md` or `repo/.claude/rules/x.md` (`/` before it).
#
# Output and exit codes:
#   0  one line per hit, `file<TAB>line<TAB>old<TAB>new` (one line per file, line and
#      row however often the literal recurs on that line), in scope-list order, then
#      line order, then map row order; then the last line
#      `literals N files M hits K` (N = rows parsed, M = scope files swept, K = hit lines).
#      An empty scope list is not an error: `files 0`.
#   2  usage error, map missing or unreadable, zero rows parsed from the map, a scope
#      file missing or unreadable, or an awk failure: one line on stderr naming the
#      error, nothing on stdout — no hit line and never the summary line.
#
# Dialect: one awk pass, no subprocess per file or line; awk limited to the portable
# subset (asset-dialects rule). Literal search is index(), never a regex built from the
# literal; boundary tests are index() into a character string, never a bracket
# expression. The awk runs under LC_ALL=C: matching is byte-wise, so a UTF-8 file or the
# map's `→` never meets a locale decoder (a non-UTF-8 locale is what made `grep -P` fail
# per literal and print nothing). Hit lines are buffered and printed in END only when no
# error was seen, so a failure can never be read as a clean scan. The map path travels
# through ENVIRON, not `-v` (which would interpret backslashes in a Windows path).

set -uo pipefail

usage() { echo "usage: rot-scan.sh <rename-map.md>  (scope file list on stdin)" >&2; exit 2; }
die()   { echo "rot-scan.sh: $1" >&2; exit 2; }

[ "$#" -eq 1 ] || usage
[ -f "$1" ] && [ -r "$1" ] || die "cannot read rename map '$1'"

# Read the scope list in the shell (builtins only, no fork per path) so a missing or
# unreadable file fails before awk runs; awk re-checks getline's -1 as a second guard.
scope=""
while IFS= read -r p || [ -n "$p" ]; do
    p="${p%$'\r'}"
    [ -n "$p" ] || continue
    [ -f "$p" ] && [ -r "$p" ] || die "cannot read scope file '$p'"
    scope="$scope$p"$'\n'
done

out="$(printf '%s' "$scope" | LC_ALL=C RS_MAP="$1" awk '
BEGIN {
    WORD = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789_"
    PRE  = WORD "/.-:"      # may not precede a hit
    POST = WORD "-/"        # may not follow a hit (a ":" is tested separately)
    ARROW = " \342\206\222 `"   # " → `" as UTF-8 bytes, so the program text stays ASCII
    err = ""; n = 0; nf = 0; k = 0; nout = 0
    map = ENVIRON["RS_MAP"]
    section = ""
    while ((r = (getline line < map)) > 0) {
        sub(/\r$/, "", line)
        if (substr(line, 1, 3) == "## ") {
            section = substr(line, 4); sub(/[ \t]+$/, "", section); continue
        }
        sub(/^[ \t]+/, "", line)
        if (substr(line, 1, 3) != "- `") continue
        s = substr(line, 4); p = index(s, "`")
        if (p <= 1) continue
        lit = substr(s, 1, p - 1); rest = substr(s, p + 1)
        if (section == "Retired files") {
            new = "(retired)"
        } else {
            if (substr(rest, 1, length(ARROW)) != ARROW) continue
            rest = substr(rest, length(ARROW) + 1); q = index(rest, "`")
            if (q <= 1) continue
            new = substr(rest, 1, q - 1)
        }
        n++; old[n] = lit; repl[n] = new
    }
    if (r < 0) { err = "cannot read rename map " map; exit }
    close(map)
    if (n == 0) { err = "zero literals parsed from " map " - no rot scan"; exit }
}
# is_hit(line, pos, len): token-boundary test for an occurrence at pos
function is_hit(line, pos, len,    c, d) {
    if (pos > 1) { c = substr(line, pos - 1, 1); if (index(PRE, c) > 0) return 0 }
    c = substr(line, pos + len, 1)
    if (c == "") return 1
    if (index(POST, c) > 0) return 0
    if (c == ":") { d = substr(line, pos + len + 1, 1); if (d != "" && index(WORD, d) > 0) return 0 }
    return 1
}
{
    sub(/\r$/, "", $0)
    if ($0 == "") next
    f = $0; nf++; ln = 0
    while ((r = (getline line < f)) > 0) {
        ln++
        sub(/\r$/, "", line)
        for (i = 1; i <= n; i++) {
            lit = old[i]; len = length(lit); off = 0; t = line
            while ((p = index(t, lit)) > 0) {
                if (is_hit(line, off + p, len)) {
                    buf[++nout] = f "\t" ln "\t" lit "\t" repl[i]; k++; break
                }
                off += p; t = substr(t, p + 1)
            }
        }
    }
    if (r < 0) { err = "cannot read scope file " f; exit }
    close(f)
}
END {
    if (err != "") { print "rot-scan.sh: " err > "/dev/stderr"; exit 2 }
    for (j = 1; j <= nout; j++) print buf[j]
    print "literals " n " files " nf " hits " k
}
')"
rc=$?
if [ "$rc" -ne 0 ]; then
    [ "$rc" -eq 2 ] || echo "rot-scan.sh: awk failed (exit $rc)" >&2
    exit 2
fi
# The summary line is the proof of a whole pass; output not ending in it is a failure.
case "${out##*$'\n'}" in
    "literals "*" files "*" hits "*) printf '%s\n' "$out" ;;
    *) die "awk produced no summary line" ;;
esac
