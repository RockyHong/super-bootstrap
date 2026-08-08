#!/usr/bin/env bash
# doc-links.sh — markdown link checker and reverse index for a docs surface
#
# Modes:
#   check          scan docs/**/*.md + README.md for broken links; exit 1 if any
#   refs <path>    print doc-surface files that link to <path> (repo-relative)
#   index          print full inverted map: target<TAB>referrer, sorted
#
# Run from repo root. docs/ may be absent (treated as empty).
# External links (http/https/mailto) and empty targets are skipped.
# Anchor slugs: GitHub-style (lowercase, strip non-alnum except hyphens/spaces/underscores, spaces→hyphens).

set -uo pipefail

MODE="${1:-}"

collect_docs() {
    [ -d docs ] && find docs -name '*.md' -type f
    [ -f README.md ] && echo README.md
    return 0
}

# GitHub-style heading → anchor slug
slugify() {
    printf '%s\n' "$1" \
        | tr '[:upper:]' '[:lower:]' \
        | sed 's/[^a-z0-9 _-]//g' \
        | tr ' ' '-'
}

# Does <anchor> exist as a heading slug in <file>?
# Slugs collect into a variable first: feeding `grep -q` from a live pipeline
# lets its early exit EPIPE the upstream writers, which under `pipefail`
# reports a found anchor as not-found (race — fires when the match is not the
# last heading; msys additionally spams "tr: write error").
anchor_exists() {
    local file="$1" anchor="$2" slugs
    slugs="$(grep '^#' "$file" 2>/dev/null \
        | sed 's/^#\+ *//' \
        | while IFS= read -r h; do slugify "$h"; done)"
    grep -qxF -- "$anchor" <<<"$slugs"
}

# Pure-string path normaliser: resolves . and .. components
normalize_path() {
    printf '%s\n' "$1" | awk '
    {
        n = split($0, a, "/")
        j = 0
        for (i = 1; i <= n; i++) {
            if (a[i] == "" || a[i] == ".") continue
            if (a[i] == "..") { if (j > 0) j-- }
            else parts[++j] = a[i]
        }
        out = ""
        for (i = 1; i <= j; i++) out = out (i > 1 ? "/" : "") parts[i]
        print out
    }'
}

# Extract inline markdown links from file. Output: lineno TAB raw-target
extract_links() {
    awk '
    BEGIN { in_fence = 0 }
    {
        if ($0 ~ /^[[:space:]]*(`{3,}|~{3,})/) { in_fence = !in_fence; next }
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

# Resolve a raw link target relative to src file.
# Output: "external" | "intradoc:<anchor>" | "<repo-rel-path>TAB<anchor>"
resolve_target() {
    local src="$1" raw="$2"
    case "$raw" in
        http://*|https://*|mailto:*) echo "external"; return ;;
        '#'*) printf 'intradoc:%s\n' "${raw#'#'}"; return ;;
    esac

    local path anchor
    if [[ "$raw" == *'#'* ]]; then
        path="${raw%%#*}"; anchor="${raw#*#}"
    else
        path="$raw"; anchor=""
    fi

    [ -z "$path" ] && { echo "external"; return; }   # edge: bare empty path

    local src_dir
    src_dir="$(dirname "$src")"
    [ "$src_dir" = "." ] && src_dir=""

    local joined
    [ -n "$src_dir" ] && joined="$src_dir/$path" || joined="$path"

    printf '%s\t%s\n' "$(normalize_path "$joined")" "$anchor"
}

do_check() {
    local findings=0
    while IFS= read -r doc; do
        while IFS=$'\t' read -r lineno raw; do
            local resolved rel anchor
            resolved="$(resolve_target "$doc" "$raw")"
            case "$resolved" in
                external) continue ;;
                intradoc:*)
                    anchor="${resolved#intradoc:}"
                    if [ -n "$anchor" ] && ! anchor_exists "$doc" "$anchor"; then
                        printf '%s:%s: #%s — anchor not found in same file\n' "$doc" "$lineno" "$anchor"
                        findings=$((findings + 1))
                    fi
                    continue ;;
            esac
            rel="$(printf '%s' "$resolved" | cut -f1)"
            anchor="$(printf '%s' "$resolved" | cut -f2)"
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
    local query
    query="$(normalize_path "$1")"
    while IFS= read -r doc; do
        while IFS=$'\t' read -r lineno raw; do
            local resolved rel
            resolved="$(resolve_target "$doc" "$raw")"
            case "$resolved" in external|intradoc:*) continue ;; esac
            rel="$(printf '%s' "$resolved" | cut -f1)"
            if [ "$rel" = "$query" ]; then
                echo "$doc"; break
            fi
        done < <(extract_links "$doc")
    done < <(collect_docs)
}

do_index() {
    while IFS= read -r doc; do
        while IFS=$'\t' read -r lineno raw; do
            local resolved rel
            resolved="$(resolve_target "$doc" "$raw")"
            case "$resolved" in external|intradoc:*) continue ;; esac
            rel="$(printf '%s' "$resolved" | cut -f1)"
            printf '%s\t%s\n' "$rel" "$doc"
        done < <(extract_links "$doc")
    done < <(collect_docs) | sort -u
}

case "$MODE" in
    check) do_check ;;
    refs)
        [ -z "${2:-}" ] && { printf 'Usage: %s refs <path>\n' "$0" >&2; exit 1; }
        do_refs "$2" ;;
    index) do_index ;;
    *)
        printf 'Usage: %s check | refs <path> | index\n' "$0" >&2
        exit 1 ;;
esac
