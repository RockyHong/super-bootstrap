#!/usr/bin/env bash
# doc-links.sh — markdown link checker and reverse index for a docs surface
#
# Modes:
#   check              scan docs/**/*.md + README.md for broken links; exit 1 if any
#   refs <path>[#a]    print doc-surface files that link to <path> (repo-relative);
#                      with #a, only files whose link cites that anchor (section grain)
#   index              print full inverted map: target[#anchor]<TAB>referrer, sorted
#   closure <path>[#a] print the premise-closure set of <path>: the doc surface
#                      (docs/**/*.md + README.md + plugins/*/README.md) minus
#                      consumables (docs/work/{BUG,DEBT}-*.md, docs/work/TEMPLATE.md)
#                      minus <path> itself, sorted; #a is ignored (whole-file grain)
#
# Run from repo root. docs/ may be absent (treated as empty).
# External links (http/https/mailto) and empty targets are skipped.
# Links inside fenced code blocks (```/~~~) and inline code spans are ignored;
# a fence closes only on the same character with a run at least as long as its
# opener and nothing but whitespace after it, so a nested shorter fence stays inside the block.
# Anchor slugs: GitHub-style (lowercase, strip non-alnum except hyphens/spaces/underscores, spaces→hyphens).
#
# Fork discipline: `check` walks (anchored links × headings in each target), so
# any per-item subprocess multiplies across the whole surface. Slug tables are
# derived by one awk pass per file and memoized per file; path normalisation and
# target resolution are pure bash returning through globals — no command
# substitution and no `cut` inside any per-link loop.

set -uo pipefail

MODE="${1:-}"

collect_docs() {
    [ -d docs ] && find docs -name '*.md' -type f
    [ -f README.md ] && echo README.md
    return 0
}

# Surface for `closure` only — the doc surface CLAUDE.md § Doc Sync defines,
# which extends the link-scanned set with each plugin's README. `check`/`refs`/
# `index` keep scanning `collect_docs`: link integrity and the reverse index are
# a separate concern from closure membership.
collect_surface() {
    collect_docs
    [ -d plugins ] && find plugins -mindepth 2 -maxdepth 2 -name 'README.md' -type f
    return 0
}

# GitHub-style heading → anchor slug table for <file>: one awk pass over the
# file emitting one slug per heading line — lowercase, strip everything outside
# [a-z0-9 _-], spaces→hyphens. Same transform the former per-heading
# `printf | tr | sed | tr` pipeline performed, at one process per file instead
# of four per heading. Portable-awk dialect: no interval expressions, no POSIX
# character classes.
slug_lines() {
    awk '
    /^#/ {
        s = $0
        sub(/^#*/, "", s)
        sub(/^ */, "", s)
        s = tolower(s)
        gsub(/[^a-z0-9 _-]/, "", s)
        gsub(/ /, "-", s)
        print s
    }
    ' "$1" 2>/dev/null
}

# Slug table for <file>, memoized — many anchored links resolve into the same
# target, and re-deriving that target's table per link was the dominant cost of
# `check`. bash 3.2 has no associative arrays, so the cache key is a sanitised
# variable name; a companion SLUGFILE_ variable records which file owns the
# entry, so two paths that sanitise alike recompute rather than answer for each
# other. Result in $SLUG_TABLE.
#
# The table is buffered into a variable before any matching: feeding slugs from
# a live pipeline into an early-exiting matcher lets the matcher EPIPE its
# upstream writers, which under `pipefail` reports a found anchor as not-found
# (race — fires when the match is not the last heading; msys additionally spams
# "tr: write error"). The one-pass form preserves that guarantee by construction.
SLUG_TABLE=""
slug_table() {
    local file="$1" san="${1//[^a-zA-Z0-9]/_}" owner
    eval "owner=\"\${SLUGFILE_$san-}\""
    if [ "$owner" = "$file" ]; then
        eval "SLUG_TABLE=\"\$SLUGCACHE_$san\""
    else
        SLUG_TABLE="$(slug_lines "$file")"
        eval "SLUGCACHE_$san=\"\$SLUG_TABLE\"; SLUGFILE_$san=\"\$file\""
    fi
}

# Does <anchor> exist as a heading slug in <file>?
# Whole-line match against the buffered table via `case` — quoted, so an anchor
# carrying glob characters stays literal — instead of a `grep -qxF` fork per link.
anchor_exists() {
    slug_table "$1"
    case "
$SLUG_TABLE
" in
        *"
$2
"*) return 0 ;;
    esac
    return 1
}

# Pure-string path normaliser: resolves . and .. components. Pure bash, no awk
# fork — it runs once per link on the whole surface. Semantics preserved exactly:
# skip empty and "." segments, pop on ".." only when the accumulator is
# non-empty. Result in $NORM.
NORM=""
normalize_path() {
    local rest="$1" seg out=""
    while [ -n "$rest" ]; do
        seg="${rest%%/*}"
        if [ "$seg" = "$rest" ]; then rest=""; else rest="${rest#*/}"; fi
        case "$seg" in
            ''|.) ;;
            ..)
                if [ -n "$out" ]; then
                    case "$out" in
                        */*) out="${out%/*}" ;;
                        *)   out="" ;;
                    esac
                fi
                ;;
            *)
                if [ -n "$out" ]; then out="$out/$seg"; else out="$seg"; fi
                ;;
        esac
    done
    NORM="$out"
}

# Extract inline markdown links from file. Output: lineno TAB raw-target
extract_links() {
    awk '
    BEGIN { in_fence = 0; fence_char = ""; fence_len = 0 }
    {
        # fence lines: opening records the opener char + run length; a closer needs
        # the same char, a run at least as long, and nothing but whitespace after it
        # (an info string marks an opener, never a closer). No interval expressions.
        if (match($0, /^[ \t]*(`+|~+)/)) {
            run = substr($0, RSTART, RLENGTH)
            sub(/^[ \t]*/, "", run)
            fchar = substr(run, 1, 1)
            flen  = length(run)
            frest = substr($0, RSTART + RLENGTH)
            if (flen >= 3) {
                if (!in_fence) {
                    in_fence = 1; fence_char = fchar; fence_len = flen
                } else if (fchar == fence_char && flen >= fence_len && frest ~ /^[ \t]*$/) {
                    in_fence = 0; fence_char = ""; fence_len = 0
                }
                next
            }
        }
        if (in_fence) next
        # strip inline code spans (matched backtick-run delimiters) before link matching
        line = $0; out = ""
        while (match(line, /`+/)) {
            delim = substr(line, RSTART, RLENGTH)
            out   = out substr(line, 1, RSTART - 1)
            rest  = substr(line, RSTART + RLENGTH)
            cpos  = index(rest, delim)
            line  = (cpos > 0) ? substr(rest, cpos + length(delim)) : rest
        }
        line = out line
        while (match(line, /\[[^\]]*\]\([^)]+\)/)) {
            seg  = substr(line, RSTART, RLENGTH)
            p    = index(seg, "](")
            tgt  = substr(seg, p + 2, length(seg) - p - 2)
            print NR "\t" tgt
            line = substr(line, RSTART + RLENGTH)
        }
    }
    ' "$1"
}

# Resolve a raw link target relative to src file. Returns through globals rather
# than stdout — a stdout return costs a command substitution (fork) per link:
#   R_KIND=external                      http/https/mailto, or a bare empty path
#   R_KIND=intradoc  R_ANCHOR=<anchor>   same-file "#a" link
#   R_KIND=path      R_PATH=<repo-rel>   R_ANCHOR=<anchor> or empty
# The src parent directory is stripped with `case`, not a `dirname` fork.
R_KIND=""; R_PATH=""; R_ANCHOR=""
resolve_target() {
    local src="$1" raw="$2" path anchor src_dir joined
    R_KIND=""; R_PATH=""; R_ANCHOR=""
    case "$raw" in
        http://*|https://*|mailto:*) R_KIND="external"; return ;;
        '#'*) R_KIND="intradoc"; R_ANCHOR="${raw#'#'}"; return ;;
    esac

    if [[ "$raw" == *'#'* ]]; then
        path="${raw%%#*}"; anchor="${raw#*#}"
    else
        path="$raw"; anchor=""
    fi

    [ -z "$path" ] && { R_KIND="external"; return; }   # edge: bare empty path

    case "$src" in
        */*) src_dir="${src%/*}" ;;
        *)   src_dir="" ;;
    esac
    [ "$src_dir" = "." ] && src_dir=""

    if [ -n "$src_dir" ]; then joined="$src_dir/$path"; else joined="$path"; fi

    normalize_path "$joined"
    R_KIND="path"; R_PATH="$NORM"; R_ANCHOR="$anchor"
}

do_check() {
    local findings=0
    while IFS= read -r doc; do
        while IFS=$'\t' read -r lineno raw; do
            local rel anchor
            resolve_target "$doc" "$raw"
            case "$R_KIND" in
                external) continue ;;
                intradoc)
                    anchor="$R_ANCHOR"
                    if [ -n "$anchor" ] && ! anchor_exists "$doc" "$anchor"; then
                        printf '%s:%s: #%s — anchor not found in same file\n' "$doc" "$lineno" "$anchor"
                        findings=$((findings + 1))
                    fi
                    continue ;;
            esac
            rel="$R_PATH"
            anchor="$R_ANCHOR"
            if [ ! -e "$rel" ]; then
                printf '%s:%s: %s — path not found\n' "$doc" "$lineno" "$rel"
                findings=$((findings + 1))
            elif [ -n "$anchor" ] && ! anchor_exists "$rel" "$anchor"; then
                printf '%s:%s: %s#%s — anchor not found in target\n' "$doc" "$lineno" "$rel" "$anchor"
                findings=$((findings + 1))
            fi
        done < <(extract_links "$doc")
    done < <(collect_docs)

    if [ "$findings" -gt 0 ]; then
        printf '%d broken link(s)\n' "$findings" >&2
        return 1
    fi
}

do_refs() {
    local query qpath qanchor
    query="$1"
    if [[ "$query" == *'#'* ]]; then
        normalize_path "${query%%#*}"; qpath="$NORM"; qanchor="${query#*#}"
    else
        normalize_path "$query"; qpath="$NORM"; qanchor=""
    fi
    while IFS= read -r doc; do
        while IFS=$'\t' read -r lineno raw; do
            local rel anchor
            resolve_target "$doc" "$raw"
            case "$R_KIND" in external|intradoc) continue ;; esac
            rel="$R_PATH"
            anchor="$R_ANCHOR"
            if [ "$rel" = "$qpath" ] && { [ -z "$qanchor" ] || [ "$anchor" = "$qanchor" ]; }; then
                echo "$doc"; break
            fi
        done < <(extract_links "$doc")
    done < <(collect_docs)
}

do_index() {
    while IFS= read -r doc; do
        while IFS=$'\t' read -r lineno raw; do
            local rel anchor
            resolve_target "$doc" "$raw"
            case "$R_KIND" in external|intradoc) continue ;; esac
            rel="$R_PATH"
            anchor="$R_ANCHOR"
            [ -n "$anchor" ] && rel="$rel#$anchor"
            printf '%s\t%s\n' "$rel" "$doc"
        done < <(extract_links "$doc")
    done < <(collect_docs) | sort -u
}

# Closure membership is a whole-file property — an anchor fragment on the query
# narrows nothing, so it is stripped. Consumables are dropped by one grep and the
# anchor by a second: two forks for the whole surface, no per-file loop.
do_closure() {
    local query qpath
    query="$1"
    case "$query" in *'#'*) query="${query%%#*}" ;; esac
    normalize_path "$query"; qpath="$NORM"
    if [ -z "$qpath" ]; then
        collect_surface | grep -Ev '^docs/work/(BUG|DEBT)-[^/]*\.md$|^docs/work/TEMPLATE\.md$' \
            | LC_ALL=C sort -u
    else
        collect_surface | grep -Ev '^docs/work/(BUG|DEBT)-[^/]*\.md$|^docs/work/TEMPLATE\.md$' \
            | grep -vxF "$qpath" | LC_ALL=C sort -u
    fi
    return 0
}

case "$MODE" in
    check) do_check ;;
    refs)
        [ -z "${2:-}" ] && { printf 'Usage: %s refs <path>[#anchor]\n' "$0" >&2; exit 1; }
        do_refs "$2" ;;
    index) do_index ;;
    closure)
        [ -z "${2:-}" ] && { printf 'Usage: %s closure <path>[#anchor]\n' "$0" >&2; exit 1; }
        do_closure "$2" ;;
    *)
        printf 'Usage: %s check | refs <path>[#anchor] | index | closure <path>[#anchor]\n' "$0" >&2
        exit 1 ;;
esac
