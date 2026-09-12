#!/usr/bin/env bash
# doc-links.sh — markdown link checker and reverse index for a docs surface
#
# Modes (all but `terms` and `anchors` scan the full doc surface: docs/**/*.md +
#         README.md + plugins/*/README.md — the markdown-file portion of the doc
#         surface CLAUDE.md § Doc Sync defines):
#   check              scan the doc surface for broken links; exit 1 if any — except
#                      a card thread's link to an absent card ID (both endpoints
#                      docs/work/{BUG,DEBT,GAP}-###.md), consumed provenance, skipped
#   pins               scan the doc surface for lines whose restated model tier
#                      disagrees with the agent frontmatter they name; exit 1 if any.
#                      One finding per line: <doc>:<lineno> TAB claimed tokens TAB
#                      actual tier TAB source path. Keyed on a path mention inside an
#                      inline code span — the paired-backtick parse `hits` uses, its
#                      code-span half only, so a path segment in bare prose (which
#                      `hits` would take via pathin) does not count here — resolved by
#                      unique path-suffix; a line naming zero or several sources, or
#                      carrying no tier token, is skipped, and a line carrying any
#                      agreeing token is clean. A claim lane, so it excludes frozen
#                      provenance the way `refs`/`hits`/`self` do.
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
#   self <path>...     print the changed paths that are doc-surface files in their
#                      own right, sorted unique — a changed doc is its own scope doc.
#                      A path the diff deleted, one off the surface, and frozen
#                      provenance all print nothing. Always exit 0.
#   anchors <path> <r>...  print the slug of the nearest heading at or above each
#                      hunk range's start line, sorted unique — <r> is a `git diff -U0`
#                      post-image range (`+491`, `+19,7`, leading `+` optional).
#                      A range above the first heading prints `(top)`, meaning
#                      whole-file grain: run `refs <path>` unanchored. Output feeds
#                      `refs <path>#<slug>` verbatim.
#
# A doc whose leading YAML frontmatter declares `dimension: history` is frozen
# provenance: `terms` yields nothing for it, `hits`, `refs`, `self` and `pins` leave it
# out, while `check` still validates its links. Card threads (`docs/work/{BUG,DEBT,GAP}-###.md`)
# and outward threads (`docs/outward/OUT-###.md`, plus the retired flat
# `docs/outward.md`) are frozen provenance by path: `terms` yields
# nothing for them and `hits`, `refs`, `self` and `pins` leave them out; `check` alone still
# covers them — a link must resolve whatever dimension it sits in, while a restated
# claim inside a closed-fork row or a card thread is a past value by design.
# Each folder's standing files (`docs/work/README.md`, `docs/outward/README.md`,
# `TEMPLATE.md`) are ordinary surface.
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
    gsub(/—|–|…|：|，|。|、|（|）|「|」|『|』|【|】|！|？|；|·|“|”|‘|’|×|÷|±|§|°|¶|•|→|←|↔|≠|≈|′|″/, "", s)
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

# On a check miss: a strip-list gap, or a genuinely broken link? Strip every
# non-ASCII byte from each computed slug and compare against the anchor the
# link asked for. Equal means the heading carries a mark GitHub drops from its
# own anchor but SLUG_AWK does not — the link is right and the list is short,
# so the hint names the computed slug and the reader extends the alternation
# above (extend the list, never widen the class).
#
# A pure-CJK heading cannot reach here: its stripped form is empty and matches
# nothing. A mixed CJK+ASCII heading can — `## 中文 section` slugs as
# `中文-section`, whose ASCII residue is `-section`, so an anchor written that
# way draws the hint though the link is wrong rather than the list short.
# Separating those needs the unicode-category knowledge this awk dialect
# cannot carry (docs/decisions.md), so that shape is locked as a known
# boundary in the tests rather than discriminated here.
#
# One fork per miss, none on the success path: the whole table is stripped and
# matched inside a single awk, so the per-item loop stays fork-free. The locale
# pin is what makes the byte class portable — LC_ALL=C puts char-mode gawk into
# byte mode too, so \200-\377 means the same under every awk this script
# targets. The anchor arrives through ENVIRON rather than -v, which reads
# escape sequences in the value it is handed; and the match runs to
# end-of-input rather than exit, so the writer upstream never takes EPIPE (the
# race the header notes).
# Result in $SLUG_HINT: a ready-to-append parenthetical, or empty.
SLUG_HINT=""
slug_gap_hint() {
    SLUG_HINT=""
    slug_table "$1"
    local hit
    hit=$(printf '%s\n' "$SLUG_TABLE" | WANT="$2" LC_ALL=C awk '
        BEGIN { want = ENVIRON["WANT"] }
        { if (found) next
          s = $0; gsub(/[\200-\377]/, "", s)
          if (s == want) { print; found = 1 } }')
    [ -n "$hit" ] || return
    SLUG_HINT=" (heading slugs as '$hit' — SLUG_AWK's strip list is missing a mark"
    SLUG_HINT="$SLUG_HINT GitHub drops; if the heading mixes CJK letters with ASCII, the"
    SLUG_HINT="$SLUG_HINT link anchor may be wrong rather than the list short)"
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

# Word-character test — the class that decides where a token starts and ends.
# One predicate, two readers: `hits` (whole-word and path-shape matching) and `pins`
# (left word boundary on a tier token). Kept beside the fragments below for the same
# reason: a boundary rule that disagrees between two lanes is a silent divergence.
ISWORD_AWK='
function isword(c) { return (c != "" && c ~ /[A-Za-z0-9_-]/) }
'

# Fenced-block toggle: an opener records its char + run length; a closer needs the
# same char, a run at least as long, and nothing but whitespace after it (an info
# string marks an opener, never a closer). No interval expressions.
# One toggle, two readers — `extract_links` and `do_pins` — held in one variable for
# the reason SLUG_AWK is: this nesting rule is bug-fixed history (a closer that
# ignored opener char and run length leaked fenced links out as real targets, now
# test-locked), so a later fix reaching one copy only re-opens that defect.
# State rides three globals the caller resets per file. Returns 1 when the caller
# should skip the line — a fence marker, or any line inside a block.
FENCE_AWK='
function fence_skip(s,   run, fchar, flen, frest) {
    if (match(s, /^[ \t]*(`+|~+)/)) {
        run = substr(s, RSTART, RLENGTH)
        sub(/^[ \t]*/, "", run)
        fchar = substr(run, 1, 1)
        flen  = length(run)
        frest = substr(s, RSTART + RLENGTH)
        if (flen >= 3) {
            if (!in_fence) {
                in_fence = 1; fence_char = fchar; fence_len = flen
            } else if (fchar == fence_char && flen >= fence_len && frest ~ /^[ \t]*$/) {
                in_fence = 0; fence_char = ""; fence_len = 0
            }
            return 1
        }
    }
    return in_fence
}
'

# Inline code spans, matched backtick-run delimiters — the pairing rule that decides
# what counts as code shape. One extractor, two readers — `do_hits` and `do_pins` —
# so neither lane can drift from its sibling on where a span ends.
# Returns the span contents joined by spaces, carrying a leading and trailing space so
# a caller can test word boundaries without special-casing the ends; a line with no
# span returns a single space. Note this collects what sits INSIDE the spans — the
# opposite of the strip `extract_links` performs before link matching, which is why
# that one stays its own loop.
CODESPAN_AWK='
function codespans(s,   code, rest, delim, tail, cpos) {
    code = " "; rest = s
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
    return code
}
'

# Extract inline markdown links from file. Output: lineno TAB raw-target
extract_links() {
    awk "$FENCE_AWK"'
    BEGIN { in_fence = 0; fence_char = ""; fence_len = 0 }
    {
        if (fence_skip($0)) next
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
                        slug_gap_hint "$doc" "$anchor"
                        printf '%s:%s: #%s — anchor not found in same file%s\n' "$doc" "$lineno" "$anchor" "$SLUG_HINT"
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
                slug_gap_hint "$rel" "$anchor"
                printf '%s:%s: %s#%s — anchor not found in target%s\n' "$doc" "$lineno" "$rel" "$anchor" "$SLUG_HINT"
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
        is_frozen_provenance_path "$doc" && continue
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

# --- grep-gate enumeration (terms / hits / anchors / self) -----------------------
#
# The commit door's §3 gate reads these four: `terms` turns a changed-file list into
# grep terms, `hits` turns terms into doc-surface files, `anchors` turns a changed
# doc's hunk ranges into the section slugs `refs` narrows on, and `self` keeps each
# changed doc in scope as its own scope doc. Each is mechanical and total — the gate
# stays a gate, never a judgment call about which identifiers matter.

# Frozen provenance by path — card threads and outward threads are breadcrumbs, not
# behavior narration. Keyed on the ID pattern, not the folder: each folder's standing
# files (README.md, TEMPLATE.md) narrate and stay in. One predicate, five
# readers: `terms` (via path_exempt), `hits`, `refs`, `self`, `pins`.
is_frozen_provenance_path() {
    case "$1" in
        docs/outward.md|*/docs/outward.md) return 0 ;;   # the retired flat form
    esac
    [[ "$1" =~ (^|/)docs/work/(BUG|DEBT|GAP)-[0-9]+\.md$ ]] && return 0
    [[ "$1" =~ (^|/)docs/outward/OUT-[0-9]+\.md$ ]] && return 0
    return 1
}

# Paths that narrate nothing: test scaffolding and its goldens, session ledgers,
# caches, the gate-exempt card surface, and non-text assets. Matched on any path
# segment, so a fixture nested anywhere is caught.
path_exempt() {
    local p="$1" rest seg lower
    is_frozen_provenance_path "$p" && return 0
    case "$p" in
        # Machine state harness-bootstrap seeds under .claude/ — a coverage receipt, the
        # bootstrap plan with its sync report, and a settings template narrate nothing,
        # whatever their stem. They sit outside collect_surface() too, so `check`
        # never opens them — the plan and report carry no links.
        .claude/super-bootstrap-runway.json|*/.claude/super-bootstrap-runway.json) return 0 ;;
        .claude/bootstrap.md|*/.claude/bootstrap.md) return 0 ;;
        .claude/bootstrap-sync-report.md|*/.claude/bootstrap-sync-report.md) return 0 ;;
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
    DOCLINK_TERMS="$terms" DOCLINK_HUB="$HUB_STEMS" awk "$ISWORD_AWK$CODESPAN_AWK"'
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
        code = codespans($0)
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

# Changed path → scope doc. Surface membership is decided by `collect_surface` itself,
# buffered once and matched with a quoted `case`, so the boundary cannot drift from the
# one the other lanes walk and a path the diff deleted drops out by construction (the
# walk lists what is in the tree). Frozen provenance is the same pair of predicates the
# `hits` and `refs` lanes apply. One fork for the whole call, none inside the loop.
do_self() {
    local surface p
    [ "$#" -eq 0 ] && return 0
    surface="
$(collect_surface)
"
    for p in "$@"; do
        normalize_path "$p"; p="$NORM"
        [ -z "$p" ] && continue
        case "$surface" in
            *"
$p
"*) ;;
            *) continue ;;
        esac
        is_frozen_provenance_path "$p" && continue
        is_history_doc "$p" && continue
        printf '%s\n' "$p"
    done | LC_ALL=C sort -u
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

# --- pins: restated model tiers against agent frontmatter ------------------------
#
# Keying on the code span rather than the markdown link is what makes the lane reach
# anything: the claims on a real surface carry no links, so a link-keyed check scores
# zero on exactly the class that breaks.
# Three passes, no per-line or per-file fork: one `find` enumerates agent candidates,
# one awk reads their frontmatter, one awk walks the doc surface minus frozen
# provenance (a claim lane, like `refs`/`hits`/`self`). The fence toggle and the
# code-span extractor come from the shared awk variables above.

# path TAB tier for every *.md under a directory named `agents` whose leading YAML
# frontmatter declares `model:`. Dot-directories (.git, .fixtures) and node_modules
# are pruned — a fixture tree is not a source of truth. The prune pattern is `.?*`,
# never `.*`: the latter matches the `.` start point itself and prunes everything.
# Result in $MODEL_INDEX.
MODEL_INDEX=""
build_model_index() {
    local -a cand
    local f
    cand=()
    while IFS= read -r f; do
        f="${f#./}"
        [ -n "$f" ] && cand+=("$f")
    done < <(find . -type d \( -name '.?*' -o -name node_modules \) -prune -o \
                  -type f -name '*.md' -path '*/agents/*' -print 2>/dev/null)
    MODEL_INDEX=""
    [ "${#cand[@]}" -eq 0 ] && return 0
    MODEL_INDEX="$(awk '
        FNR == 1 { fm = ($0 ~ /^---[ \t]*$/) ? 1 : 0; seen = 0; next }
        seen { next }
        fm == 1 {
            if ($0 ~ /^---[ \t]*$/) { seen = 1; next }
            if ($0 ~ /^model:/) {
                v = $0
                sub(/^model:[ \t]*/, "", v)
                sub(/[ \t]*$/, "", v)
                gsub(/["\047]/, "", v)
                if (v != "") print FILENAME "\t" v
                seen = 1
            }
        }
    ' "${cand[@]}" 2>/dev/null)"
    return 0
}

# Whole-surface lane: consults no scan scope, so it needs neither the enumeration
# to have reached the doc nor the judge to have looked. One finding per line:
#   <doc>:<lineno> TAB <claimed tokens> TAB <actual tier> TAB <source path>
# Exit 1 with findings, 0 clean — the `check` convention.
do_pins() {
    local -a files
    local f
    build_model_index
    [ -z "$MODEL_INDEX" ] && return 0
    files=()
    while IFS= read -r f; do
        is_history_doc "$f" && continue
        is_frozen_provenance_path "$f" && continue
        files+=("$f")
    done < <(collect_surface)
    [ "${#files[@]}" -eq 0 ] && return 0
    DOCLINK_PINS="$MODEL_INDEX" awk "$ISWORD_AWK$FENCE_AWK$CODESPAN_AWK"'
    # Closed tier vocabulary. Case-insensitivity is an explicit alternation:
    # tolower() is barred outside the SLUG_AWK lead-byte probe, since a Latin-1
    # ctype rewrites UTF-8 lead bytes.
    function tierre(tok) {
        if (tok == "opus")    return "[Oo][Pp][Uu][Ss]"
        if (tok == "sonnet")  return "[Ss][Oo][Nn][Nn][Ee][Tt]"
        if (tok == "haiku")   return "[Hh][Aa][Ii][Kk][Uu]"
        if (tok == "fable")   return "[Ff][Aa][Bb][Ll][Ee]"
        if (tok == "inherit") return "[Ii][Nn][Hh][Ee][Rr][Ii][Tt]"
        return ""
    }

    # Doc side — human prose, where a tier word turns up by accident. Left boundary
    # required, suffix continuation allowed: the token must begin at a word start and
    # may run on into anything, so "inherits the session model" is a claim of inherit
    # while "octopus" is not opus and "affable" is not fable. A two-sided boundary
    # would buy the second by losing the first. Every occurrence is tested: a
    # rejected one advances the scan, so a bad occurrence ahead of a real one cannot
    # mask it.
    function tierin(s, tok,   re, off, p, pre) {
        re = tierre(tok)
        if (re == "") return 0
        off = 0
        while (1) {
            if (!match(substr(s, off + 1), re)) return 0
            p = off + RSTART
            pre = (p > 1) ? substr(s, p - 1, 1) : ""
            if (!isword(pre)) return 1
            off = p
        }
    }

    # Source side — a frontmatter value drawn from a tiny controlled enum, never
    # prose, so a tier word cannot appear in it by accident and the boundary buys
    # nothing. Unanchored on purpose: the shipped model ids embed the tier mid-token
    # (`claude-sonnet-5`, `claude-haiku-4-5-20251001`), and a hyphen is a word
    # character, so requiring the boundary here would make every agent pinned to a
    # full id normalise to nothing and drop out of the lane silently. Same isword()
    # predicate as above, deliberately not applied at this call site — the asymmetry
    # is the domain difference, not an oversight.
    function tierpin(s, tok,   re) {
        re = tierre(tok)
        return (re != "" && s ~ re)
    }

    # Unique path-suffix match on a "/" boundary is the whole resolver — no
    # doc-relative and no repo-root resolution. A mention naming zero indexed
    # files or more than one is dropped rather than guessed at.
    function resolve(tok,   i, cnt, hit, p, lp, lt) {
        cnt = 0; hit = 0; lt = length(tok)
        for (i = 1; i <= NP; i++) {
            p = IPATH[i]; lp = length(p)
            if (lp < lt) continue
            if (substr(p, lp - lt + 1) != tok) continue
            if (lp > lt && substr(p, lp - lt, 1) != "/") continue
            cnt++; hit = i
        }
        return (cnt == 1) ? hit : 0
    }

    BEGIN {
        VN = split("opus sonnet haiku fable inherit", V, " ")
        n = split(ENVIRON["DOCLINK_PINS"], L, "\n")
        NP = 0
        for (i = 1; i <= n; i++) {
            if (L[i] == "") continue
            t = index(L[i], "\t")
            if (t == 0) continue
            NP++
            IPATH[NP] = substr(L[i], 1, t - 1)
            ITIER[NP] = substr(L[i], t + 1)
        }
        in_fence = 0; fence_char = ""; fence_len = 0
        findings = 0
    }

    FNR == 1 { in_fence = 0; fence_char = ""; fence_len = 0 }

    {
        if (fence_skip($0)) next
        code = codespans($0)
        if (code == " ") next

        gsub(/[^A-Za-z0-9_.\/-]/, " ", code)
        mt = split(code, TOK, " ")
        src = 0; two = 0
        for (i = 1; i <= mt; i++) {
            if (TOK[i] !~ /\.md$/) continue
            r = resolve(TOK[i])
            if (r == 0) continue
            if (src == 0) src = r
            else if (r != src) { two = 1; break }
        }
        if (two || src == 0) next

        # Actual tier, normalised into the vocabulary unanchored (see tierpin), so a
        # bare word and a full model id both resolve. A pin naming no tier in the
        # vocabulary at all leaves nothing to compare against, and only then is the
        # line left alone rather than guessed at.
        act = ""
        for (j = 1; j <= VN; j++) if (tierpin(ITIER[src], V[j])) { act = V[j]; break }
        if (act == "") next

        # Report only when NO token on the line matches. The gate runs on every
        # commit, so a false positive costs more than a miss.
        claimed = ""; agrees = 0
        for (j = 1; j <= VN; j++) {
            if (!tierin($0, V[j])) continue
            claimed = (claimed == "") ? V[j] : claimed "," V[j]
            if (V[j] == act) agrees = 1
        }
        if (claimed == "" || agrees) next
        printf "%s:%d\t%s\t%s\t%s\n", FILENAME, FNR, claimed, act, IPATH[src]
        findings++
    }

    END { if (findings > 0) exit 1 }
    ' "${files[@]}"
}

USAGE='Usage: %s check | pins | refs <path>[#anchor]... | index | closure <path>[#anchor]
       %s terms <changed-path>... | hits <term>... | anchors <path> <hunk-range>...
       %s self <changed-path>...
'

case "$MODE" in
    check) do_check ;;
    pins) do_pins ;;
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
    self)
        shift
        do_self "$@" ;;
    anchors)
        shift
        [ "$#" -lt 2 ] && { printf 'Usage: %s anchors <path> <hunk-range>...\n' "$0" >&2; exit 1; }
        do_anchors "$@" ;;
    *)
        # shellcheck disable=SC2059
        printf "$USAGE" "$0" "$0" "$0" >&2
        exit 1 ;;
esac
