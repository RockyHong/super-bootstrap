#!/usr/bin/env bash
# doc-links.sh — markdown link checker and reverse index for a docs surface
#
# Modes (all but `terms` and `anchors` scan the full doc surface: docs/**/*.md +
#         README.md + plugins/*/README.md — the markdown-file portion of the doc
#         surface CLAUDE.md § Doc Sync defines):
#   check              scan the doc surface for broken links; exit 1 if any — except
#                      a card thread's link to an absent card ID (both endpoints
#                      docs/work/{BUG,DEBT,GAP}-###.md), consumed provenance, skipped
#   refs <q>...        print doc-surface files that link to any query <q>, in surface
#                      order, each file once. <q> is <path> or <path>#<anchor>; with
#                      an anchor, only files whose link cites it (section grain).
#                      Several queries print the union — one call per changed doc.
#   index              print full inverted map: target[#anchor]<TAB>referrer, sorted
#   closure <path>[#a] print the premise-closure set of <path>: the doc surface
#                      minus consumables (docs/work/{BUG,DEBT}-*.md, docs/work/TEMPLATE.md)
#                      minus <path> itself, sorted; #a is ignored (whole-file grain)
#   terms <path>...    print the grep-gate terms a changed-file list yields, sorted
#                      unique — path-class-exempt paths, asset extensions, generic
#                      basenames and terms under 4 characters yield none. Pure string
#                      work: the paths need not exist. Always exit 0.
#   hits <term>...     print doc-surface files mentioning any term in code shape —
#                      a whole word inside an inline code span, or a path segment
#                      (preceded by `/`, or followed by `/` or `.`+extension).
#                      Bare prose does not hit. Sorted unique; exclusion is the
#                      caller's (pipe through `grep -vxF`). Always exit 0.
#   anchors <path> <r>...  print the slug of the nearest heading at or above each
#                      hunk range's start line, sorted unique — <r> is a `git diff -U0`
#                      post-image range (`+491`, `+19,7`, leading `+` optional).
#                      A range above the first heading prints `(top)`, meaning
#                      whole-file grain: run `refs <path>` unanchored. Output feeds
#                      `refs <path>#<slug>` verbatim.
#
# A doc whose leading YAML frontmatter declares `dimension: history` is frozen
# provenance: `terms` yields nothing for it, `hits` and `refs` leave it out, while
# `check` still validates its links. Card threads (`docs/work/`) and outward entries
# (`docs/outward.md`) are frozen provenance by path: `terms` yields nothing for them
# and `hits` leaves them out; `refs` and `check` still cover them.
#
# Run from repo root. docs/ may be absent (treated as empty).
# External links (http/https/mailto) and empty targets are skipped.
# Links inside fenced code blocks (```/~~~) and inline code spans are ignored;
# a fence closes only on the same character with a run at least as long as its
# opener and nothing but whitespace after it, so a nested shorter fence stays inside the block.
# Anchor slugs: GitHub-style — lowercase, punctuation stripped (ASCII enumerated plus
# common unicode marks), spaces→hyphens; letters of every script survive, so a CJK
# heading anchors as GitHub renders it. A unicode mark absent from the list stays
# in the slug where GitHub would drop it — see SLUG_AWK.
#
# Fork discipline: `check` walks (anchored links × headings in each target), so
# any per-item subprocess multiplies across the whole surface. Slug tables are
# derived by one awk pass per file and memoized per file; path normalisation and
# target resolution are pure bash returning through globals — no command
# substitution and no `cut` inside any per-link loop.

set -uo pipefail

MODE="${1:-}"

collect_surface() {
    [ -d docs ] && find docs -name '*.md' -type f
    [ -f README.md ] && echo README.md
    [ -d plugins ] && find plugins -mindepth 2 -maxdepth 2 -name 'README.md' -type f
    return 0
}

# Leading/trailing whitespace stripped from <s>. Result in $TRIM.
TRIM=""
trim() {
    local s="$1"
    s="${s#"${s%%[![:space:]]*}"}"
    s="${s%"${s##*[![:space:]]}"}"
    TRIM="$s"
}

# Does <file> declare `dimension: history` in leading YAML frontmatter? The block
# opens with `---` on line 1 and closes at the next `---`; no block, or no such key
# inside it, means state dimension. Pure bash — no fork per file, so the whole
# surface can be filtered.
is_history_doc() {
    local file="$1" line n=0
    [ -f "$file" ] || return 1
    while IFS= read -r line; do
        trim "$line"; line="$TRIM"
        n=$((n + 1))
        if [ "$n" -eq 1 ]; then
            [ "$line" = "---" ] || return 1
            continue
        fi
        [ "$line" = "---" ] && return 1
        case "$line" in
            dimension:*)
                trim "${line#dimension:}"
                [ "$TRIM" = "history" ] && return 0
                ;;
        esac
    done < "$file"
    return 1
}

# GitHub-style heading → anchor slug table for <file>: one awk pass over the
# file emitting one slug per heading line — lowercase, strip everything outside
# [a-z0-9 _-], spaces→hyphens. Same transform the former per-heading
# `printf | tr | sed | tr` pipeline performed, at one process per file instead
# of four per heading. Portable-awk dialect: no interval expressions, no POSIX
# character classes.
# One transform, two readers: `check`/`refs` want slugs alone, `anchors` wants each
# slug's line number beside it. Holding the awk body in one variable keeps the two
# readers from drifting — an anchor `anchors` prints must be one `refs` accepts.
SLUG_AWK='
/^#/ {
    s = $0
    sub(/^#*/, "", s)
    sub(/^ */, "", s)
    # Case-fold. tolower() folds non-ASCII letters under gawk in a UTF-8 locale
    # (as GitHub does) and leaves them alone under a C-locale byte-mode awk — but
    # under a Latin-1 / cp1252 ctype (Windows builds) it rewrites UTF-8 lead
    # bytes (C3 → E3: "é" corrupts, Cyrillic and Greek likewise). Probe once with
    # "É": folded to "é" (char-mode) or left untouched (C-locale bytes) means the
    # library fold is safe; anything else is a corrupting ctype — fold ASCII by
    # hand and leave every other byte as it came.
    if (FOLD == "") {
        t = tolower("\303\211")
        FOLD = (t == "\303\251" || t == "\303\211") ? "lib" : "ascii"
    }
    if (FOLD == "lib") s = tolower(s)
    else {
        out = ""; n = length(s)
        for (i = 1; i <= n; i++) {
            c = substr(s, i, 1); p = index("ABCDEFGHIJKLMNOPQRSTUVWXYZ", c)
            out = out (p ? substr("abcdefghijklmnopqrstuvwxyz", p, 1) : c)
        }
        s = out
    }
    # GitHub keeps the letters and digits of every script and strips punctuation;
    # so does this. ASCII punctuation is enumerated (portable-awk dialect: no
    # [:punct:]), and the class is ASCII-only on purpose — a multibyte letter is
    # untouched under both byte-mode awks (mawk, one-true-awk) and char-mode
    # gawk. Common unicode punctuation follows as a literal alternation: the
    # byte sequences match in every awk. Marks outside that list survive into
    # the slug (GitHub drops them) — extend the list on report, never widen the
    # class.
    gsub(/[]!"#$%&\047()*+,.\/:;<=>?@[\134^`{|}~\t\r]/, "", s)
    gsub(/—|–|…|：|，|。|、|（|）|「|」|『|』|【|】|！|？|；|·|“|”|‘|’/, "", s)
    gsub(/ /, "-", s)
    print (NUMBERED == 1 ? NR "\t" : "") s
}
'

slug_lines() {
    awk -v NUMBERED=0 "$SLUG_AWK" "$1" 2>/dev/null
}

# lineno TAB slug per heading, file order.
slug_lines_numbered() {
    awk -v NUMBERED=1 "$SLUG_AWK" "$1" 2>/dev/null
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
                # Consumed provenance: a card thread citing a card ID that no longer
                # exists is a resolved sibling, not a broken path — both endpoints
                # card-shaped, skipped uncounted. Any other target stays strict.
                if [[ "$doc" =~ ^docs/work/(BUG|DEBT|GAP)-[0-9]+\.md$ ]] \
                   && [[ "$rel" =~ ^docs/work/(BUG|DEBT|GAP)-[0-9]+\.md$ ]]; then
                    continue
                fi
                printf '%s:%s: %s — path not found\n' "$doc" "$lineno" "$rel"
                findings=$((findings + 1))
            elif [ -n "$anchor" ] && ! anchor_exists "$rel" "$anchor"; then
                printf '%s:%s: %s#%s — anchor not found in target\n' "$doc" "$lineno" "$rel" "$anchor"
                findings=$((findings + 1))
            fi
        done < <(extract_links "$doc")
    done < <(collect_surface)

    if [ "$findings" -gt 0 ]; then
        printf '%d broken link(s)\n' "$findings" >&2
        return 1
    fi
}

# Queries are held in two parallel arrays and tested inside the existing per-link
# loop, so N queries cost one surface walk instead of N. The doc loop stays outermost:
# each citer prints once, in surface order, whether one query matched or five — a
# single-query call is byte-identical to the one-query-only form it replaced.
do_refs() {
    local -a QPATH QANCHOR
    local query i nq doc matched rel anchor lineno raw
    QPATH=(); QANCHOR=()
    for query in "$@"; do
        if [[ "$query" == *'#'* ]]; then
            normalize_path "${query%%#*}"; QPATH+=("$NORM"); QANCHOR+=("${query#*#}")
        else
            normalize_path "$query"; QPATH+=("$NORM"); QANCHOR+=("")
        fi
    done
    nq="${#QPATH[@]}"
    while IFS= read -r doc; do
        is_history_doc "$doc" && continue
        matched=0
        while IFS=$'\t' read -r lineno raw; do
            resolve_target "$doc" "$raw"
            case "$R_KIND" in external|intradoc) continue ;; esac
            rel="$R_PATH"
            anchor="$R_ANCHOR"
            i=0
            while [ "$i" -lt "$nq" ]; do
                if [ "$rel" = "${QPATH[$i]}" ] \
                   && { [ -z "${QANCHOR[$i]}" ] || [ "$anchor" = "${QANCHOR[$i]}" ]; }; then
                    matched=1; break
                fi
                i=$((i + 1))
            done
            [ "$matched" -eq 1 ] && break
        done < <(extract_links "$doc")
        [ "$matched" -eq 1 ] && echo "$doc"
    done < <(collect_surface)
    return 0
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
    done < <(collect_surface) | sort -u
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

# --- grep-gate enumeration (terms / hits / anchors) ------------------------------
#
# The commit door's §3 gate reads these three: `terms` turns a changed-file list into
# grep terms, `hits` turns terms into doc-surface files, `anchors` turns a changed
# doc's hunk ranges into the section slugs `refs` narrows on. Each is mechanical and
# total — the gate stays a gate, never a judgment call about which identifiers matter.

# Frozen provenance by path — card threads and outward entries are breadcrumbs, not
# behavior narration. One predicate, two readers: `terms` (via path_exempt) and `hits`.
is_frozen_provenance_path() {
    case "$1" in
        docs/work/*|*/docs/work/*|docs/outward.md|*/docs/outward.md) return 0 ;;
    esac
    return 1
}

# Paths that narrate nothing: test scaffolding and its goldens, session ledgers,
# caches, the gate-exempt card surface, and non-text assets. Matched on any path
# segment, so a fixture nested anywhere is caught.
path_exempt() {
    local p="$1" rest seg lower
    is_frozen_provenance_path "$p" && return 0
    case "$p" in
        # Machine state harness-bootstrap seeds under .claude/ — a coverage receipt and
        # a settings template narrate nothing, whatever their stem.
        .claude/super-bootstrap-runway.json|*/.claude/super-bootstrap-runway.json) return 0 ;;
        .claude/templates/*|*/.claude/templates/*) return 0 ;;
    esac
    rest="$p"
    while [ -n "$rest" ]; do
        seg="${rest%%/*}"
        if [ "$seg" = "$rest" ]; then rest=""; else rest="${rest#*/}"; fi
        case "$seg" in
            bench|test|tests|fixtures|expected|SESSION-STATE|.temp|__pycache__) return 0 ;;
            fixture*) return 0 ;;
        esac
    done
    lower="$(printf '%s' "$p" | tr 'A-Z' 'a-z')"
    case "$lower" in
        *.png|*.jpg|*.jpeg|*.gif|*.svg|*.ico|*.webp|*.woff|*.woff2|*.ttf) return 0 ;;
        *.zip|*.tar|*.gz|*.pdf|*.lock) return 0 ;;
    esac
    return 1
}

# Basenames that name a slot rather than a subject — they hit everywhere and mean
# nothing. Compared case-insensitively; terms under 4 characters join them.
term_generic() {
    local t
    t="$(printf '%s' "$1" | tr 'A-Z' 'a-z')"
    [ "${#t}" -lt 4 ] && return 0
    case " skill claude readme template backlog marketplace plugin gitignore index settings run main test tests spec config " in
        *" $t "*) return 0 ;;
    esac
    return 1
}

# Harness-seeded hub stems — the skeleton files harness-bootstrap plants in every repo
# (SSOT: skills/harness-bootstrap/SKILL.md § Phase 2c placement rows), cited as link
# targets across the doc surface under the `ssot-doc-link` rule. `hits` counts one of these only as a
# bare token inside a code span (`techstack`): a path mention (`docs/techstack.md`,
# `](../techstack.md)`) is a citation the anchored citer lane already reaches, not a
# narration. Hardcoded on purpose — the seeded set moves at release cadence.
HUB_STEMS=" overview techstack decisions super-bootstrap-runway worktree-settings.local "

# Path → term. A skill is named by its directory (`*/skills/<X>/SKILL.md` → `<X>`);
# everything else — agents and rules included — by its basename minus one extension.
# Result in $TERM_OUT.
TERM_OUT=""
derive_term() {
    local p="$1" base dir parent grand
    base="${p##*/}"
    if [ "$base" = "SKILL.md" ]; then
        dir="${p%/*}"
        if [ "$dir" != "$p" ]; then
            parent="${dir##*/}"
            grand="${dir%/*}"
            [ "$grand" = "$dir" ] && grand=""
            grand="${grand##*/}"
            if [ "$grand" = "skills" ]; then TERM_OUT="$parent"; return; fi
        fi
    fi
    base="${base#.}"
    case "$base" in *.*) base="${base%.*}" ;; esac
    TERM_OUT="$base"
}

do_terms() {
    local p
    for p in "$@"; do
        path_exempt "$p" && continue
        is_history_doc "$p" && continue
        derive_term "$p"
        [ -z "$TERM_OUT" ] && continue
        term_generic "$TERM_OUT" && continue
        printf '%s\n' "$TERM_OUT"
    done | LC_ALL=C sort -u
    return 0
}

# Code-shape matching runs in awk, not grep: "inside an inline code span" needs the
# same paired-backtick parse `extract_links` does — a regex cannot tell a span from
# the gap between two spans, and that gap is where bare prose false-hits live. One
# awk pass over the whole surface; terms ride the environment, so no quoting round-trip.
do_hits() {
    [ "$#" -eq 0 ] && return 0
    local -a files
    local f terms=""
    for f in "$@"; do terms="$terms$f
"; done
    files=()
    while IFS= read -r f; do
        is_history_doc "$f" && continue
        is_frozen_provenance_path "$f" && continue
        files+=("$f")
    done < <(collect_surface)
    [ "${#files[@]}" -eq 0 ] && return 0
    DOCLINK_TERMS="$terms" DOCLINK_HUB="$HUB_STEMS" awk '
    function isword(c) { return (c != "" && c ~ /[A-Za-z0-9_-]/) }

    # Whole-word occurrence of needle in hay.
    function wordin(hay, needle,   p, off, L, pre, post) {
        L = length(needle); off = 0
        while (1) {
            p = index(substr(hay, off + 1), needle)
            if (p == 0) return 0
            p += off
            pre  = (p > 1) ? substr(hay, p - 1, 1) : ""
            post = substr(hay, p + L, 1)
            if (!isword(pre) && !isword(post)) return 1
            off = p
        }
    }

    # Whole-word occurrence that also sits in a path shape: after a "/", before a
    # "/", or before a "." plus an extension.
    function pathin(hay, needle,   p, off, L, pre, post, after) {
        L = length(needle); off = 0
        while (1) {
            p = index(substr(hay, off + 1), needle)
            if (p == 0) return 0
            p += off
            pre   = (p > 1) ? substr(hay, p - 1, 1) : ""
            after = substr(hay, p + L)
            post  = substr(after, 1, 1)
            if (!isword(pre) && !isword(post)) {
                if (pre == "/" || post == "/") return 1
                if (after ~ /^\.[A-Za-z0-9]+/) return 1
            }
            off = p
        }
    }

    # Whole-word occurrence that is NOT in a path shape: no "/" on either side and no
    # extension following — the bare-token form a hub stem must take to count.
    function barein(hay, needle,   p, off, L, pre, post, after) {
        L = length(needle); off = 0
        while (1) {
            p = index(substr(hay, off + 1), needle)
            if (p == 0) return 0
            p += off
            pre   = (p > 1) ? substr(hay, p - 1, 1) : ""
            after = substr(hay, p + L)
            post  = substr(after, 1, 1)
            if (!isword(pre) && !isword(post) && pre != "/" && post != "/" && after !~ /^\.[A-Za-z0-9]+/) return 1
            off = p
        }
    }

    BEGIN {
        n = split(ENVIRON["DOCLINK_TERMS"], T, "\n")
        m = split(ENVIRON["DOCLINK_HUB"], H, " ")
        for (j = 1; j <= m; j++) if (H[j] != "") hub[H[j]] = 1
    }

    {
        if (FILENAME in hit) next
        # code spans only: matched backtick runs, same pairing rule as extract_links
        code = " "; rest = $0
        while (match(rest, /`+/)) {
            delim = substr(rest, RSTART, RLENGTH)
            tail  = substr(rest, RSTART + RLENGTH)
            cpos  = index(tail, delim)
            if (cpos > 0) {
                code = code substr(tail, 1, cpos - 1) " "
                rest = substr(tail, cpos + length(delim))
            } else {
                rest = ""
            }
        }
        for (i = 1; i <= n; i++) {
            if (T[i] == "") continue
            if (T[i] in hub) {
                if (barein(code, T[i])) { hit[FILENAME] = 1; break }
            } else if (wordin(code, T[i]) || pathin($0, T[i])) { hit[FILENAME] = 1; break }
        }
    }

    END { for (f in hit) print f }
    ' "${files[@]}" | LC_ALL=C sort -u
    return 0
}

# Hunk range → section grain. Headings come out of the shared slug transform in file
# order, so the last one at or above the start line is the section that hunk edited.
do_anchors() {
    local path="$1" tbl r start ln slug found
    shift
    [ -f "$path" ] || return 0
    tbl="$(slug_lines_numbered "$path")"
    for r in "$@"; do
        r="${r#+}"
        start="${r%%,*}"
        case "$start" in ''|*[!0-9]*) continue ;; esac
        found="(top)"
        while IFS="$(printf '\t')" read -r ln slug; do
            [ -z "$ln" ] && continue
            if [ "$ln" -le "$start" ]; then found="$slug"; else break; fi
        done <<EOF
$tbl
EOF
        printf '%s\n' "$found"
    done | LC_ALL=C sort -u
    return 0
}

USAGE='Usage: %s check | refs <path>[#anchor]... | index | closure <path>[#anchor]
       %s terms <changed-path>... | hits <term>... | anchors <path> <hunk-range>...
'

case "$MODE" in
    check) do_check ;;
    refs)
        shift
        [ "$#" -eq 0 ] && { printf 'Usage: %s refs <path>[#anchor]...\n' "$0" >&2; exit 1; }
        do_refs "$@" ;;
    index) do_index ;;
    closure)
        [ -z "${2:-}" ] && { printf 'Usage: %s closure <path>[#anchor]\n' "$0" >&2; exit 1; }
        do_closure "$2" ;;
    terms)
        shift
        do_terms "$@" ;;
    hits)
        shift
        do_hits "$@" ;;
    anchors)
        shift
        [ "$#" -lt 2 ] && { printf 'Usage: %s anchors <path> <hunk-range>...\n' "$0" >&2; exit 1; }
        do_anchors "$@" ;;
    *)
        # shellcheck disable=SC2059
        printf "$USAGE" "$0" "$0" >&2
        exit 1 ;;
esac
