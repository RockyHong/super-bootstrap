#!/usr/bin/env bash
# rule-paths-coverage.sh — does each placed doc rule fire on the repo's declared doc
# surface? harness-bootstrap runs `check` at placement and on re-run; it warns, it never
# writes to a rule (the consumer adds the printed line to the rule's `paths:` tail).
#
# Usage (run from the repo root):
#   bash rule-paths-coverage.sh check
#     No `.claude/doc-surface` -> no output. Otherwise, for each doc rule present
#     (.claude/rules/dimension-discipline.md, .claude/rules/ssot-doc-link.md) and each
#     declared `.md` glob, every translated entry (below) that no `paths:` entry of that
#     rule covers prints one line:
#       <rule>: doc-surface glob '<glob>' not covered -- add to paths:   - "<entry>"
#     Exit 0 whatever it prints.
#   bash rule-paths-coverage.sh translate <glob>...
#     Print the `paths:` entries that cover each declaration glob, one per line.
#   Any other mode -> usage on stderr, exit 2.
#
# Two glob dialects. A `.claude/doc-surface` line matches with `*` crossing `/` (the
# commit door's doc-links.sh reads it so: `kinds/*.md` takes `kinds/sub/y.md`). A rule's
# `paths:` entry matches gitignore-style: `*` and `?` stop at `/`, `**` crosses it, a
# slash-free entry matches at any depth, a leading `/` pins root.
#
# Translation, declaration -> `paths:` (pre = text before the first `*`, suf = text after
# the last `*`): no `*` -> the glob itself; pre empty or ending `/` -> `<pre>**/*<suf>`
# (`kinds/*.md` -> `kinds/**/*.md`); otherwise `<pre>*<suf>` and `<pre>*/**/*<suf>`.
# Several `*` collapse to pre + suf, the same reading the doc-sync-scan agent gives an
# entry, so the printed entry may fire on a little more than the declaration.
#
# Coverage: an entry E is covered when some `paths:` entry P, compiled to a regex with
# gitignore semantics, matches E's text with E's `**` replaced by a sentinel byte that
# only P's `**` can consume — so `kinds/*/*.md` never covers `kinds/**/*.md`, and the
# verbatim declaration `kinds/*.md` as a tail entry is not coverage. `[...]` classes in P
# pass through; `?`/`[` in a declaration are compared as text.
#
# Declaration parsing matches doc-links.sh: `#` lines and blank lines skipped,
# surrounding whitespace, a trailing CR and a leading `./` dropped, `.md` entries only.
# `paths:` is read from the rule's leading YAML frontmatter, block-list form only.

set -uo pipefail

DOC_SURFACE_FILE=".claude/doc-surface"
DOC_RULES=".claude/rules/dimension-discipline.md .claude/rules/ssot-doc-link.md"
SENT=$'\001'

usage() { echo "usage: rule-paths-coverage.sh check | translate <glob>..." >&2; exit 2; }

trim() {
    local s="$1"
    s="${s#"${s%%[![:space:]]*}"}"
    s="${s%"${s##*[![:space:]]}"}"
    TRIM="$s"
}

# translate <glob> -> TR (array of entries)
translate() {
    local g="$1" pre suf
    case "$g" in
        *'*'*) ;;
        *) TR=("$g"); return 0 ;;
    esac
    pre="${g%%\**}"; suf="${g##*\*}"
    case "$pre" in
        ''|*/) TR=("${pre}**/*${suf}") ;;
        *) TR=("${pre}*${suf}" "${pre}*/**/*${suf}") ;;
    esac
}

# to_regex <paths-entry> -> RX (anchored ERE, gitignore semantics, sentinel-aware)
to_regex() {
    local p="$1" out="" anchor='^(.*/)?' i=0 n c rest cls
    case "$p" in */) p="${p}**" ;; esac
    case "$p" in
        /*) p="${p#/}"; anchor='^' ;;
        *?/*) anchor='^' ;;
    esac
    n=${#p}
    while [ "$i" -lt "$n" ]; do
        c="${p:i:1}"
        if [ "$c" = '*' ] && [ "${p:i+1:1}" = '*' ]; then
            if [ "${p:i+2:1}" = '/' ]; then out+='(.*/)?'; i=$((i+3)); else out+='.*'; i=$((i+2)); fi
            continue
        fi
        case "$c" in
            '*') out+="[^/$SENT]*" ;;
            '?') out+="[^/*$SENT]" ;;
            '[')
                rest="${p:i}"
                case "$rest" in
                    *']'*) cls="${rest%%]*}"; out+="$cls]"; i=$((i+${#cls}+1)); continue ;;
                    *) out+='\[' ;;
                esac ;;
            .|+|'('|')'|'{'|'}'|'|'|'^'|'$'|'\') out+="\\$c" ;;
            *) out+="$c" ;;
        esac
        i=$((i+1))
    done
    RX="$anchor$out\$"
}

# read_paths <rule-file> -> PATHS (array of `paths:` entries)
read_paths() {
    local f="$1" line first=1 inlist=0
    PATHS=()
    while IFS= read -r line || [ -n "$line" ]; do
        line="${line%$'\r'}"
        if [ "$first" -eq 1 ]; then
            [ "$line" = '---' ] || return 0
            first=0; continue
        fi
        [ "$line" = '---' ] && return 0
        trim "$line"
        case "$TRIM" in
            'paths:') inlist=1; continue ;;
        esac
        if [ "$inlist" -eq 1 ]; then
            case "$TRIM" in
                '- '*)
                    trim "${TRIM#- }"
                    case "$TRIM" in
                        \"*\") TRIM="${TRIM#\"}"; TRIM="${TRIM%\"}" ;;
                        \'*\') TRIM="${TRIM#\'}"; TRIM="${TRIM%\'}" ;;
                    esac
                    PATHS+=("$TRIM") ;;
                '') ;;
                *) inlist=0 ;;
            esac
        fi
    done < "$f"
}

read_declared() {
    local line
    DECL=()
    while IFS= read -r line || [ -n "$line" ]; do
        line="${line%$'\r'}"
        trim "$line"; line="${TRIM#./}"
        case "$line" in ''|'#'*) continue ;; *.md) DECL+=("$line") ;; esac
    done < "$DOC_SURFACE_FILE"
}

check() {
    local rule g e q r covered
    local -a rxs
    [ -f "$DOC_SURFACE_FILE" ] || return 0
    read_declared
    [ "${#DECL[@]}" -gt 0 ] || return 0
    for rule in $DOC_RULES; do
        [ -f "$rule" ] || continue
        read_paths "$rule"
        rxs=()
        for e in ${PATHS[@]+"${PATHS[@]}"}; do to_regex "$e"; rxs+=("$RX"); done
        for g in "${DECL[@]}"; do
            translate "$g"
            for e in "${TR[@]}"; do
                q="${e//\*\*/$SENT}"
                covered=0
                for r in ${rxs[@]+"${rxs[@]}"}; do
                    if [[ "$q" =~ $r ]]; then covered=1; break; fi
                done
                [ "$covered" -eq 1 ] || printf "%s: doc-surface glob '%s' not covered -- add to paths:   - \"%s\"\n" "$rule" "$g" "$e"
            done
        done
    done
    return 0
}

case "${1:-}" in
    check) check ;;
    translate)
        shift
        [ "$#" -gt 0 ] || usage
        for g in "$@"; do translate "$g"; printf '%s\n' "${TR[@]}"; done ;;
    *) usage ;;
esac
