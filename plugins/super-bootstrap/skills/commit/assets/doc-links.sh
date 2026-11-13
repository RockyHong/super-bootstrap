#!/usr/bin/env bash
# doc-links.sh — markdown link checker and reverse index for a docs surface
#
# Modes (all but `terms` and `anchors` scan the full doc surface: docs/**/*.md +
#         README.md + plugins/*/README.md, plus every `*.md` glob the repo declares
#         in .claude/doc-surface — see collect_declared_surface; CLAUDE.md § Doc Sync
#         narrates the surface, this file and the declaration compute it):
#   check              scan the doc surface for broken links; exit 1 if any — except
#                      a card thread's link to an absent card ID (both endpoints
#                      docs/work/{BUG,DEBT,GAP}-<id>.md), consumed provenance, skipped
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
#                      work: the paths need not exist. A Godot text asset (`.tscn`,
#                      `.tres`, any case) keeps its extension on the term
#                      (`levels/Ending.tscn` → `Ending.tscn`) — the origin marker
#                      `hits` reads. Always exit 0. A term can hold spaces
#                      (`a/[Image t2i] Krea 2.json` → `[Image t2i] Krea 2`): newline
#                      is the only safe delimiter of this output — feed it on with
#                      `| hits -`, never as an unquoted word list.
#   hits <term>...     print doc-surface files mentioning any term in code shape —
#                      a whole word inside an inline code span, or a path segment
#                      (preceded by `/`, or followed by `/` or `.`+extension).
#                      Bare prose does not hit. Two shape-by-origin exceptions: a hub
#                      stem (HUB_STEMS) counts only as a bare token in a code span — its
#                      path mentions stay out to keep scope bounded — and
#                      an extension-marked asset term (`Ending.tscn`) counts only as
#                      its stem in a path segment (`levels/Ending.tscn`, `Ending.tscn`)
#                      — a backticked bare `Ending` is domain vocabulary, not narration.
#                      Sorted unique; exclusion is the caller's (pipe through
#                      `grep -vxF`). Always exit 0.
#   hits --by-term <term>...
#                      attribution instead of the file list: one `term<TAB>count`
#                      line per distinct input term — the number of doc-surface files
#                      that term hits on its own, under the same rules (a file two
#                      terms hit counts for both). Zero-hit terms print `0`. Sorted by
#                      count, highest first, then term. Takes `-` like `hits`.
#   grep-scope <changed-path>...
#                      print the doc-surface files the grep lane puts in scope for a
#                      changed-file list — `terms - | hits -` with one rule on top.
#                      Each path yields its `terms` term. A term is demoted for this
#                      run only when its own `hits --by-term` count is over the scope
#                      ceiling (GREP_SCOPE_CEILING, 8) AND every changed path that
#                      yields it is a modified file (git status M in the diff) off
#                      the doc surface and not a Godot asset (`X.tscn`). Any other
#                      path yielding the term keeps it undemoted: a doc-surface
#                      path, an asset path, or a path the diff shows as added,
#                      deleted or renamed, or does not show at all (no diff,
#                      untracked, git failed). A demoted term matches as a hub stem
#                      does — a bare token in a code span only, its path mentions
#                      out — and the symbol-shaped identifiers on its paths' changed
#                      lines join the term list: maximal `[A-Za-z0-9_]` runs
#                      starting with a letter or `_` on the diff's `-` / `+` lines
#                      and each hunk header's trailing context, 4+ characters, not
#                      a generic basename word, holding `_`, a digit, or an
#                      uppercase letter after the first character. An undemoted
#                      term adds none. Nothing demoted → output identical to
#                      `terms - | hits -`. Sorted unique;
#                      exclusion is the caller's, as for `hits`. Always exit 0.
#                      Diff source: `git diff HEAD -- <paths>` in the cwd
#                      (`--name-status` for the modified test, `-U0` for the
#                      identifiers), the same worktree-against-HEAD read `term-uses`
#                      makes. Two environment knobs replay another diff (a replay
#                      bench): DOCLINK_DIFF_RANGE="<a> <b>" swaps
#                      `HEAD` for those revision arguments (word-split), and
#                      DOCLINK_DIFF_REPO=<dir> runs git in <dir> (`git -C`) while the
#                      doc surface is still walked in the cwd. Both read by this mode
#                      only.
#   grep-scope --by-term <changed-path>...
#                      attribution instead of the file list, as `hits --by-term`:
#                      `term<TAB>count` over the final term list (head terms plus
#                      added identifiers); a demoted term's line carries its
#                      post-demotion count and a third column, `demoted`.
#   self <path>...     print the changed paths that are doc-surface files in their
#                      own right, sorted unique — a changed doc is its own scope doc.
#                      A path the diff deleted, one off the surface, and frozen
#                      provenance all print nothing. Always exit 0.
#   terminology        print the registered list from docs/terminology.md, file order:
#                      `term<TAB><Term>` per entry line (`**<Term>**: …` at line
#                      start, optionally `- `-prefixed) and `avoid<TAB><word><TAB><Term>`
#                      per word of an `_Avoid_: a, b` line (optionally indented or
#                      `- `-prefixed), each word mapped to the most recent entry; one
#                      trailing `.` on a word is dropped. Lines inside fenced blocks or
#                      HTML comments are not entries. Absent file → nothing. Exit 0.
#   term-uses <path>...
#                      print terminology candidates on the changed docs' added lines
#                      (`git diff HEAD -U0`; a path git does not track reads every line
#                      as added): `doc<TAB>line<TAB>term|avoid<TAB>matched text<TAB>Term`
#                      per line × registered item, for a case-insensitive (ASCII fold)
#                      whole-word match outside fenced blocks. Skipped: a path off the
#                      doc surface, frozen provenance (as `self`), docs/terminology.md
#                      itself. A doc already linking docs/terminology.md takes no
#                      `term` candidate; its `avoid` hits still print — a wrong word
#                      is wrong whatever the doc links. Empty registry → nothing. Mechanical only — whether a use is
#                      substantive is the commit door's judgment. Exit 0.
#   volatile-ids <path>...
#                      print tracker IDs on the changed docs' added lines (same added-line
#                      read as `term-uses`): `doc<TAB>line<TAB>id` per line × distinct ID
#                      matching `\b(BUG|DEBT|GAP|OUT|PARK)-[0-9a-z]+\b` outside fenced
#                      blocks. The literal `xxxx` suffix is a placeholder, skipped; `card`
#                      is a legal suffix, so `GAP-card` hits. Skipped: a path off the doc
#                      surface, docs/work/, docs/outward/ (and the retired flat form),
#                      docs/parked.md, docs/test-queue.md, a `dimension: history` doc.
#                      Advisory: always exit 0.
#   terms - | hits [--by-term] - | grep-scope [--by-term] - | self - | term-uses - | volatile-ids -
#                      a lone `-` reads the list from stdin instead, one item per
#                      line (blank lines skipped, a trailing CR dropped) — the
#                      shell-split-proof form for a path or term holding spaces:
#                      `git -c core.quotePath=false diff --name-only HEAD | doc-links.sh terms - | doc-links.sh hits -`.
#   anchors <path> <r>...  print the section slug(s) each hunk range touches, sorted
#                      unique — <r> is a `git diff -U0` post-image range (`+491`,
#                      `+19,7`, leading `+` optional; no length or `,0` — a pure
#                      deletion — means the one line the range names). A
#                      range covering the doc's first heading prints `(top)`,
#                      meaning whole-file grain: run `refs <path>` unanchored.
#                      Otherwise the range prints the union of every heading whose
#                      own line falls inside the range plus the section the start
#                      line sits in (its nearest heading at or above) — a hunk
#                      spanning several sections prints one slug per section.
#                      Output feeds `refs <path>#<slug>` verbatim.
#
# A doc whose leading YAML frontmatter declares `dimension: history` is frozen
# provenance: `terms` yields nothing for it, `hits`, `refs`, `self` and `pins` leave it
# out, while `check` still validates its links. Card threads (`docs/work/{BUG,DEBT,GAP}-<id>.md`)
# and outward threads (`docs/outward/OUT-<id>.md`, plus the retired flat
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
    local builtin
    builtin="$(collect_builtin_surface)"
    [ -n "$builtin" ] && printf '%s\n' "$builtin"
    collect_declared_surface "$builtin"
    return 0
}

collect_builtin_surface() {
    [ -d docs ] && find docs -name '*.md' -type f
    [ -f README.md ] && echo README.md
    [ -d plugins ] && find plugins -mindepth 2 -maxdepth 2 -name 'README.md' -type f
    return 0
}

# The repo's extra surface: `.claude/doc-surface`, one glob per line, relative to repo
# root. Only entries ending `.md` count (every lane parses markdown); `#` lines and
# blank lines are skipped; surrounding whitespace, a trailing CR and a leading `./`
# are dropped. bash 3.2 has no globstar, so an entry matches as an unquoted `case`
# pattern against one `find` listing — `*` crosses `/`, so `kinds/*.md` also takes
# `kinds/sub/y.md`. Paths already in <builtin> print nothing (dedup), the rest print
# in find order after the built-in set. Absent file or no `.md` entry → no find, no
# output. One read and one find per call; the per-path loop is pure bash.
DOC_SURFACE_FILE=".claude/doc-surface"
collect_declared_surface() {
    local builtin="
$1
" line p pat
    local -a pats
    pats=()
    [ -f "$DOC_SURFACE_FILE" ] || return 0
    while IFS= read -r line || [ -n "$line" ]; do
        line="${line%$'\r'}"
        trim "$line"; line="${TRIM#./}"
        case "$line" in ''|'#'*) continue ;; *.md) pats+=("$line") ;; esac
    done < "$DOC_SURFACE_FILE"
    [ "${#pats[@]}" -gt 0 ] || return 0
    while IFS= read -r p; do
        p="${p#./}"
        case "$builtin" in *"
$p
"*) continue ;; esac
        for pat in "${pats[@]}"; do
            # Unquoted on purpose: the entry is the glob.
            # shellcheck disable=SC2254
            case "$p" in
                $pat) printf '%s\n' "$p"; break ;;
            esac
        done
    done < <(find . \( -name .git -o -name node_modules \) -prune -o -type f -name '*.md' -print 2>/dev/null)
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
# Runs only with $FENCE_AWK prepended (it calls fence_skip): a `#`-led line inside
# a fenced block is code, not a heading.
SLUG_AWK='
{ if (fence_skip($0)) next }
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
    awk -v NUMBERED=0 "$FENCE_AWK$SLUG_AWK" "$1" 2>/dev/null
}

# lineno TAB slug per heading, file order.
slug_lines_numbered() {
    awk -v NUMBERED=1 "$FENCE_AWK$SLUG_AWK" "$1" 2>/dev/null
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
# One toggle, three readers — `extract_links`, `do_pins`, and the SLUG_AWK heading
# table (a `#`-led line inside a fence is code, not a heading) — held in one variable for
# the reason SLUG_AWK is: this nesting rule is bug-fixed history (a closer that
# ignored opener char and run length leaked fenced links out as real targets, now
# test-locked), so a later fix reaching one copy only re-opens that defect.
# State rides three globals the caller resets per file, or runs one file per awk
# process (SLUG_AWK). Returns 1 when the caller
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
                if [[ "$doc" =~ ^docs/work/(BUG|DEBT|GAP)-[0-9a-z]+\.md$ ]] \
                   && [[ "$rel" =~ ^docs/work/(BUG|DEBT|GAP)-[0-9a-z]+\.md$ ]]; then
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
# The commit door's §3 gate reads these: `terms` turns a changed-file list into
# grep terms, `hits` turns terms into doc-surface files, `grep-scope` runs the two as
# the door's grep lane with the demotion rule on top, `anchors` turns a changed
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
    [[ "$1" =~ (^|/)docs/work/(BUG|DEBT|GAP)-[0-9a-z]+\.md$ ]] && return 0
    [[ "$1" =~ (^|/)docs/outward/OUT-[0-9a-z]+\.md$ ]] && return 0
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
# The word list sits in one variable for its two readers: this predicate and
# `grep-scope`'s identifier filter (GREPSCOPE_TOKEN_AWK).
GENERIC_WORDS=" skill claude readme template backlog marketplace plugin gitignore index settings run main test tests spec config "
term_generic() {
    local t
    t="$(printf '%s' "$1" | tr 'A-Z' 'a-z')"
    [ "${#t}" -lt 4 ] && return 0
    case "$GENERIC_WORDS" in
        *" $t "*) return 0 ;;
    esac
    return 1
}

# Harness-seeded hub stems — the skeleton files harness-bootstrap plants in every repo
# (SSOT: skills/harness-bootstrap/SKILL.md § Phase 2c placement rows), cited as link
# targets across the doc surface under the `ssot-doc-link` rule. `hits` counts one of these only as a
# bare token inside a code span (`techstack`): path mentions (`docs/techstack.md`,
# `](../techstack.md)`) stay out of this lane to keep scope bounded. So an unlinked path
# mention of a hub doc is not scanned, and on a section-grain change neither is an
# anchorless link to one; /super-bootstrap:check-docs-consistency is the backstop.
# Hardcoded on purpose — the seeded set moves at release cadence.
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

# One changed path → its grep term, or none. Result in $TERM_OUT (empty = no term).
# One body, two readers (`terms`, `grep-scope`), so the two cannot disagree on a path.
path_term() {
    local p="$1"
    TERM_OUT=""
    path_exempt "$p" && return 0
    is_history_doc "$p" && return 0
    derive_term "$p"
    [ -z "$TERM_OUT" ] && return 0
    if term_generic "$TERM_OUT"; then TERM_OUT=""; return 0; fi
    # Godot text asset → keep the extension: the marker `hits` reads its
    # path-shape-only rule from (see do_hits).
    case "$p" in
        *.[tT][sS][cC][nN]|*.[tT][rR][eE][sS]) TERM_OUT="$TERM_OUT.${p##*.}" ;;
    esac
    return 0
}

do_terms() {
    local p
    for p in "$@"; do
        path_term "$p"
        [ -z "$TERM_OUT" ] && continue
        printf '%s\n' "$TERM_OUT"
    done | LC_ALL=C sort -u
    return 0
}

# Code-shape matching runs in awk, not grep: "inside an inline code span" needs the
# same paired-backtick parse `extract_links` does — a regex cannot tell a span from
# the gap between two spans, and that gap is where bare prose false-hits live. One
# awk pass over the whole surface; terms ride the environment, so no quoting round-trip.
# HITS_BY_TERM=1 swaps the output for attribution: every term is tested against every
# file (no first-match break) and END prints term TAB count — one rule set, so the
# files a term is counted on are exactly the files it adds to the default union.
# Three more inputs, all inert for the `hits` mode itself and set only by `grep-scope`:
# HITS_BY_TERM=2 prints both readouts from one walk, unsorted (`F<TAB>file` per union
# file, `T<TAB>term<TAB>count` per term); HITS_DEMOTED (one term per line) joins the hub
# set for this run only — HUB_STEMS itself never changes; HITS_STDIN_TERMS=1 appends
# stdin's lines to the term list, since a wide diff's identifiers can outgrow what one
# environment variable carries and a failed exec would read as an empty scope.
HITS_BY_TERM=0
HITS_DEMOTED=""
HITS_STDIN_TERMS=0
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
    if [ "${#files[@]}" -eq 0 ]; then
        # No surface: the union is empty, but every term still attributes, at zero.
        [ "$HITS_BY_TERM" -ge 1 ] || return 0
        files=(/dev/null)
    fi
    DOCLINK_TERMS="$terms" DOCLINK_HUB="$HUB_STEMS" DOCLINK_DEMOTED="$HITS_DEMOTED" \
        awk -v BYTERM="$HITS_BY_TERM" -v XT="$HITS_STDIN_TERMS" "$ISWORD_AWK$CODESPAN_AWK"'
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

    # Does term i occur in code shape on this line? One rule set, both outputs.
    function termhit(i, line, code) {
        if (i in asset) return pathin(line, T[i])
        if (T[i] in hub) return barein(code, T[i])
        return (wordin(code, T[i]) || pathin(line, T[i]))
    }

    BEGIN {
        n = split(ENVIRON["DOCLINK_TERMS"], T, "\n")
        # `getline < "-"` is stdin in gawk, mawk and one-true-awk alike.
        if (XT == 1) while ((getline xl < "-") > 0) { sub(/\r$/, "", xl); T[++n] = xl }
        m = split(ENVIRON["DOCLINK_HUB"], H, " ")
        for (j = 1; j <= m; j++) if (H[j] != "") hub[H[j]] = 1
        m = split(ENVIRON["DOCLINK_DEMOTED"], H, "\n")
        for (j = 1; j <= m; j++) if (H[j] != "") hub[H[j]] = 1
        # An extension-marked term (`Ending.tscn`) names a Godot text asset: match its
        # stem path-shaped only. NAME keeps the term as given, for attribution; a
        # repeated term is tested once.
        for (i = 1; i <= n; i++) {
            NAME[i] = T[i]
            if (T[i] == "" || (T[i] in seen)) { T[i] = ""; continue }
            seen[T[i]] = 1
            if (T[i] ~ /\.([Tt][Ss][Cc][Nn]|[Tt][Rr][Ee][Ss])$/) {
                T[i] = substr(T[i], 1, length(T[i]) - 5); asset[i] = 1
            }
        }
    }

    BYTERM >= 1 {
        code = codespans($0)
        for (i = 1; i <= n; i++) {
            if (T[i] == "" || ((FILENAME, i) in th)) continue
            if (termhit(i, $0, code)) { th[FILENAME, i] = 1; cnt[i]++; hit[FILENAME] = 1 }
        }
        next
    }

    {
        if (FILENAME in hit) next
        code = codespans($0)
        for (i = 1; i <= n; i++) {
            if (T[i] == "") continue
            if (termhit(i, $0, code)) { hit[FILENAME] = 1; break }
        }
    }

    END {
        if (BYTERM == 2) {
            for (f in hit) print "F\t" f
            for (i = 1; i <= n; i++) if (T[i] != "") print "T\t" NAME[i] "\t" (cnt[i] + 0)
        } else if (BYTERM == 1) {
            for (i = 1; i <= n; i++) if (T[i] != "") print NAME[i] "\t" (cnt[i] + 0)
        } else {
            for (f in hit) print f
        }
    }
    ' "${files[@]}" | if [ "$HITS_BY_TERM" -eq 2 ]; then
        cat
    elif [ "$HITS_BY_TERM" -eq 1 ]; then
        LC_ALL=C sort -t $'\t' -k2,2nr -k1,1
    else
        LC_ALL=C sort -u
    fi
    return 0
}

# --- grep-scope: the grep lane as one mode ---------------------------------------
#
# `terms - | hits -` plus one rule: a term that alone crosses the scope ceiling, and
# that only modified code files yield, stops counting on path mentions, and what those
# files' diffs changed inside is searched instead. One path of another kind yielding
# the term — a doc-surface path, a Godot asset, a file the diff adds, deletes or
# renames, or one it does not show (no diff, untracked, git failed) — keeps the term
# whole: a deleted or renamed hub file is when the docs citing its path go stale, and a
# failed diff read must not shrink the scope. Every edge leans one way — in doubt, not
# demoted. The rule is a fixed status test and token shape, so the lane stays a gate.

# The commit door's scope ceiling (SSOT: commit/SKILL.md §3). A term can be demoted
# when its own count is over it, not at it.
GREP_SCOPE_CEILING=8

# Symbol-shaped identifiers of a `git diff -U0` stream, one per line, each once. The
# caller's pathspec is the demoted paths only — status M by the caller's own read — so
# every file section is eligible; the add / delete header guard is a second line of
# defence for a tree that moved between the two reads (`--no-renames` turns a rename
# into that pair).
# A run that starts with a digit is dropped whole, not trimmed to its letter tail.
# `--- ` / `+++ ` are file-header lines only before a section's first `@@`: inside a
# hunk a removed line whose text starts with `-- ` prints as `--- `, hence the hdr state.
# tolower() is safe here without the lead-byte probe SLUG_AWK needs: a token is ASCII
# by construction and the caller runs this program under LC_ALL=C.
GREPSCOPE_TOKEN_AWK='
BEGIN { k = split(GENERIC, G, " "); for (i = 1; i <= k; i++) gen[G[i]] = 1; hdr = 1; mod = 0 }
function emit(s,   k, i, a, t) {
    gsub(/[^A-Za-z0-9_]+/, " ", s)
    k = split(s, a, " ")
    for (i = 1; i <= k; i++) {
        t = a[i]
        if (length(t) < 4 || t ~ /^[0-9]/ || (t in seen)) continue
        seen[t] = 1
        if (!(t ~ /_/ || t ~ /[0-9]/ || substr(t, 2) ~ /[A-Z]/)) continue
        if (tolower(t) in gen) continue
        print t
    }
}
/^diff --git / { hdr = 1; mod = 1; next }
hdr && /^(new|deleted) file mode / { mod = 0; next }
/^@@ / {
    hdr = 0
    if (mod) { s = $0; sub(/^@@ [^@]*@@/, "", s); emit(s) }
    next
}
!hdr && mod && /^[-+]/ { emit(substr($0, 2)) }
'

# Up to two walks of the surface: the first prints the head terms' union and per-term
# counts together (HITS_BY_TERM=2), which is the whole answer when nothing is demoted;
# a demotion re-walks with the widened hub set and the added identifiers. Per-path work
# is pure bash; git runs at most twice per call (status, then tokens), never per path,
# and not at all when no term is over the ceiling.
GREP_SCOPE_BY_TERM=0
do_grep_scope() {
    [ "$#" -eq 0 ] && return 0
    local nl=$'\n' tab=$'\t' surface p q t i both line rest files="" counts="" demoted="" tokens
    local held="" over="" st="" mset notm=""
    local -a hterms opaths oterms cpaths dpaths range gitc
    hterms=(); opaths=(); oterms=(); cpaths=(); dpaths=()
    surface="$nl$(collect_surface)$nl"
    for p in "$@"; do
        path_term "$p"
        [ -z "$TERM_OUT" ] && continue
        t="$TERM_OUT"
        hterms+=("$t")
        # Never demoted: a Godot asset term (the shape `hits` reads the asset rule from;
        # the kept extension makes it a term no code path can yield) and any term a
        # doc-surface path yields — `held`, whatever other path yields the same term.
        case "$t" in *.[tT][sS][cC][nN]|*.[tT][rR][eE][sS]) continue ;; esac
        normalize_path "$p"; q="$NORM"
        case "$surface" in *"$nl$q$nl"*) held="$held$t$nl"; continue ;; esac
        opaths+=("${q:-$p}"); oterms+=("$t")
    done
    [ "${#hterms[@]}" -eq 0 ] && return 0

    HITS_BY_TERM=2
    both="$(do_hits "${hterms[@]}")"
    HITS_BY_TERM=0
    while IFS= read -r line; do
        case "$line" in
            F"$tab"*) files="$files${line#F"$tab"}$nl" ;;
            T"$tab"*)
                rest="${line#T"$tab"}"; counts="$counts$rest$nl"
                t="${rest%"$tab"*}"
                [ "${rest##*"$tab"}" -gt "$GREP_SCOPE_CEILING" ] || continue
                case "$nl$held" in *"$nl$t$nl"*) continue ;; esac
                over="$over$t$nl" ;;
        esac
    done <<EOF
$both
EOF

    # Demotion candidates: the code paths of the over-ceiling terms. A term is demoted
    # only when every one of them is a modified file, so the diff status is read before
    # the decision — one git call per run, and none at all when no term is over.
    if [ -n "$over" ]; then
        i=0
        while [ "$i" -lt "${#oterms[@]}" ]; do
            case "$nl$over" in *"$nl${oterms[$i]}$nl"*) cpaths+=("${opaths[$i]}") ;; esac
            i=$((i + 1))
        done
    fi
    if [ "${#cpaths[@]}" -gt 0 ]; then
        # --literal-pathspecs: a changed path can hold glob characters (`[Image t2i] x.json`).
        gitc=(git)
        [ -n "${DOCLINK_DIFF_REPO:-}" ] && gitc=(git -C "$DOCLINK_DIFF_REPO")
        range=(HEAD)
        [ -n "${DOCLINK_DIFF_RANGE:-}" ] && read -r -a range <<< "$DOCLINK_DIFF_RANGE"
        # `M<TAB>path` per modified candidate. Every way this read comes back without a
        # path leaves that path unmodified, hence its term undemoted: git failing (no
        # repo, bad range — a partial listing is dropped with it), a path the diff does
        # not list (unchanged, untracked), an A / D / T / U status (`--no-renames` turns a
        # rename into an A + D pair), and a path git prints C-quoted (a tab, newline,
        # quote or backslash in the name), which matches no candidate. `--relative`
        # prints paths as the pathspecs give them — relative to the directory git runs
        # in, not to the repo top — so a run below the top still matches; a candidate
        # outside that directory (`../x`) is not listed and stays undemoted.
        st="$("${gitc[@]}" --literal-pathspecs -c core.quotePath=false diff --name-status --no-renames \
            --relative --no-ext-diff "${range[@]}" -- "${cpaths[@]}" 2>/dev/null)" || st=""
        mset="$nl"
        while IFS= read -r line; do
            case "$line" in M"$tab"*) mset="$mset${line#M"$tab"}$nl" ;; esac
        done <<EOF
$st
EOF
        # One unmodified path holds its term back; the rest demote, each with its paths.
        i=0
        while [ "$i" -lt "${#oterms[@]}" ]; do
            case "$nl$over" in *"$nl${oterms[$i]}$nl"*)
                case "$mset" in *"$nl${opaths[$i]}$nl"*) ;; *) notm="$notm${oterms[$i]}$nl" ;; esac ;;
            esac
            i=$((i + 1))
        done
        i=0
        while [ "$i" -lt "${#oterms[@]}" ]; do
            t="${oterms[$i]}"; i=$((i + 1))
            case "$nl$over" in *"$nl$t$nl"*) ;; *) continue ;; esac
            case "$nl$notm" in *"$nl$t$nl"*) continue ;; esac
            case "$nl$demoted" in *"$nl$t$nl"*) ;; *) demoted="$demoted$t$nl" ;; esac
            dpaths+=("${opaths[$((i - 1))]}")
        done
    fi

    if [ -z "$demoted" ]; then
        if [ "$GREP_SCOPE_BY_TERM" -eq 1 ]; then
            printf '%s' "$counts" | LC_ALL=C sort -t "$tab" -k2,2nr -k1,1
        else
            printf '%s' "$files" | LC_ALL=C sort -u
        fi
        return 0
    fi

    # Same git command, range and pathspec handling as the status read above; the
    # pathspec is the demoted terms' paths, every one of them status M there.
    tokens="$("${gitc[@]}" --literal-pathspecs -c core.quotePath=false diff -U0 --no-renames --no-ext-diff \
        --no-textconv "${range[@]}" -- "${dpaths[@]}" 2>/dev/null \
        | LC_ALL=C awk -v GENERIC="$GENERIC_WORDS" "$GREPSCOPE_TOKEN_AWK")"

    HITS_DEMOTED="$demoted"; HITS_STDIN_TERMS=1; HITS_BY_TERM="$GREP_SCOPE_BY_TERM"
    if [ "$GREP_SCOPE_BY_TERM" -eq 1 ]; then
        printf '%s\n' "$tokens" | do_hits "${hterms[@]}" | DOCLINK_DEMOTED="$demoted" awk -F'\t' '
            BEGIN { m = split(ENVIRON["DOCLINK_DEMOTED"], D, "\n"); for (j = 1; j <= m; j++) if (D[j] != "") d[D[j]] = 1 }
            { print $0 (($1 in d) ? "\tdemoted" : "") }'
    else
        printf '%s\n' "$tokens" | do_hits "${hterms[@]}"
    fi
    HITS_DEMOTED=""; HITS_STDIN_TERMS=0; HITS_BY_TERM=0
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

# Project term home — one fixed path. Its absence makes both terminology lanes empty.
TERM_HOME="docs/terminology.md"

# Registry read: one awk pass over the term home. HTML comments are stripped first
# (they may span lines), then the shared fence toggle drops fenced lines, then the
# entry / alias shapes match. Portable-awk dialect: no intervals, explicit [ \t].
TERMINOLOGY_AWK='
BEGIN { in_fence = 0; fence_char = ""; fence_len = 0; in_cmt = 0; cur = "" }
{
    s = $0
    if (in_cmt) {
        p = index(s, "-->")
        if (p == 0) next
        s = substr(s, p + 3); in_cmt = 0
    }
    while ((p = index(s, "<!--")) > 0) {
        rest = substr(s, p + 4); q = index(rest, "-->")
        if (q == 0) { s = substr(s, 1, p - 1); in_cmt = 1; break }
        s = substr(s, 1, p - 1) substr(rest, q + 3)
    }
    if (fence_skip(s)) next
    if (match(s, /^(- )?\*\*[^*]+\*\*:/)) {
        t = substr(s, 1, RLENGTH)
        sub(/^(- )?\*\*/, "", t); sub(/\*\*:$/, "", t)
        gsub(/^[ \t]+|[ \t]+$/, "", t)
        if (t != "") { cur = t; print "term\t" t }
        next
    }
    if (cur != "" && match(s, /^[ \t]*(- )?_Avoid_:/)) {
        rest = substr(s, RLENGTH + 1)
        n = split(rest, w, ",")
        for (i = 1; i <= n; i++) {
            x = w[i]
            gsub(/^[ \t]+|[ \t\r]+$/, "", x); sub(/\.$/, "", x)
            if (x != "") print "avoid\t" x "\t" cur
        }
    }
}
'

do_terminology() {
    [ -f "$TERM_HOME" ] || return 0
    awk "$FENCE_AWK$TERMINOLOGY_AWK" "$TERM_HOME"
    return 0
}

# Hunk-range reader, one rule for two readers (TERMUSE_AWK, VOLID_AWK): the first input is
# the `git diff HEAD -U0` text, whose `+c,d` ranges mark the added post-image lines in
# added[]; `next` keeps the diff text from reaching the reader's own rules. Concatenate it
# after the readers' functions and before their main rule — BEGIN position is free.
HUNK_AWK='
FNR == NR {
    if (ALL != 1 && match($0, /^@@ [^+]*\+[0-9]+(,[0-9]+)? @@/)) {
        h = $0; sub(/^@@ [^+]*\+/, "", h); sub(/ @@.*$/, "", h)
        c = h; sub(/,.*$/, "", c); d = 1
        if (index(h, ",") > 0) { d = h; sub(/^[^,]*,/, "", d) }
        for (k = 0; k < d + 0; k++) added[c + k] = 1
    }
    next
}
'

# Candidate match: two inputs per changed doc — the `git diff HEAD -U0` text on stdin
# (its `+c,d` ranges mark the added post-image lines) and the doc itself, walked whole
# so the fence toggle sees every opener. The registry rides the environment, one
# `kind<TAB>word<TAB>Term` per line. Case-fold is ASCII by hand (no tolower — a Latin-1
# ctype rewrites UTF-8 lead bytes), so byte offsets stay aligned with the original line
# and the matched text prints as the doc wrote it. Whole word = isword() on both sides.
TERMUSE_AWK='
function afold(s,   out, i, n, c, p) {
    out = ""; n = length(s)
    for (i = 1; i <= n; i++) {
        c = substr(s, i, 1); p = index("ABCDEFGHIJKLMNOPQRSTUVWXYZ", c)
        out = out (p ? substr("abcdefghijklmnopqrstuvwxyz", p, 1) : c)
    }
    return out
}
BEGIN {
    in_fence = 0; fence_char = ""; fence_len = 0
    nreg = split(ENVIRON["DOCLINK_TERMREG"], rl, "\n")
    for (i = 1; i <= nreg; i++) {
        split(rl[i], f, "\t"); kind[i] = f[1]; word[i] = afold(f[2])
        canon[i] = (f[1] == "term") ? f[2] : f[3]
    }
}
{
    if (fence_skip($0)) next
    if (ALL != 1 && !(FNR in added)) next
    line = $0; fl = afold(line)
    for (i = 1; i <= nreg; i++) {
        w = word[i]; if (w == "") continue
        if (LINKED == 1 && kind[i] == "term") continue
        rest = fl; off = 0
        while ((p = index(rest, w)) > 0) {
            a = off + p; b = a + length(w)
            # a == 1 has no left neighbour: substr(s, 0, 1) is the first char in gawk
            if ((a == 1 || !isword(substr(fl, a - 1, 1))) && !isword(substr(fl, b, 1))) {
                print DOC "\t" FNR "\t" kind[i] "\t" substr(line, a, length(w)) "\t" canon[i]
                break
            }
            off = a; rest = substr(fl, a + 1)
        }
    }
}
'

# Does <doc> carry a link resolving to the term home (any anchor)? A linking doc
# drops only its `term` candidates (LINKED in TERMUSE_AWK). Reuses
# extract_links + resolve_target, so the link parse cannot drift from `check`.
links_term_home() {
    local doc="$1" ln raw
    while IFS="$(printf '\t')" read -r ln raw; do
        resolve_target "$doc" "$raw"
        [ "$R_KIND" = "path" ] && [ "$R_PATH" = "$TERM_HOME" ] && return 0
    done <<EOF
$(extract_links "$doc")
EOF
    return 1
}

do_term_uses() {
    local reg surface p diff all linked
    [ "$#" -eq 0 ] && return 0
    reg="$(do_terminology)"
    [ -z "$reg" ] && return 0
    surface="
$(collect_surface)
"
    for p in "$@"; do
        normalize_path "$p"; p="$NORM"
        [ -z "$p" ] && continue
        [ "$p" = "$TERM_HOME" ] && continue
        case "$surface" in
            *"
$p
"*) ;;
            *) continue ;;
        esac
        is_frozen_provenance_path "$p" && continue
        is_history_doc "$p" && continue
        linked=0
        links_term_home "$p" && linked=1
        diff="$(git diff HEAD -U0 -- "$p" 2>/dev/null)"
        all=0
        if [ -z "$diff" ] && ! git ls-files --error-unmatch -- "$p" >/dev/null 2>&1; then
            all=1
        fi
        printf '%s\n' "$diff" | DOCLINK_TERMREG="$reg" awk -v DOC="$p" -v ALL="$all" -v LINKED="$linked" \
            "$ISWORD_AWK$FENCE_AWK$HUNK_AWK$TERMUSE_AWK" - "$p"
    done
    return 0
}

# Tracker IDs on added lines: the same two awk inputs as TERMUSE_AWK. Awk has no `\b`, so
# the regex takes the run and the boundary test sits beside it. The boundary class is the
# regex word class, narrower than isword(): a hyphen ends an ID (`GAP-abc-def` is `GAP-abc`).
VOLID_AWK='
function idword(c) { return (c != "" && c ~ /[A-Za-z0-9_]/) }
BEGIN { in_fence = 0; fence_char = ""; fence_len = 0 }
{
    if (fence_skip($0)) next
    if (ALL != 1 && !(FNR in added)) next
    line = $0; off = 0; seen = " "
    while (match(substr(line, off + 1), /(BUG|DEBT|GAP|OUT|PARK)-[0-9a-z]+/)) {
        a = off + RSTART; b = a + RLENGTH
        id = substr(line, a, RLENGTH)
        pre = (a > 1) ? substr(line, a - 1, 1) : ""
        if (!idword(pre) && !idword(substr(line, b, 1)) &&
            substr(id, index(id, "-") + 1) != "xxxx" && index(seen, " " id " ") == 0) {
            print DOC "\t" FNR "\t" id
            seen = seen id " "
        }
        off = b - 1
    }
}
'

# Off this lane: the tracker's own files, and whatever records history by declaration.
# Wider than is_frozen_provenance_path — a folder's standing README documents the ID shape.
volatile_ids_exempt() {
    case "$1" in
        docs/work/*|docs/outward/*|docs/parked.md|docs/test-queue.md) return 0 ;;
    esac
    is_frozen_provenance_path "$1" && return 0
    is_history_doc "$1"
}

do_volatile_ids() {
    local surface p diff all
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
        volatile_ids_exempt "$p" && continue
        diff="$(git diff HEAD -U0 -- "$p" 2>/dev/null)"
        all=0
        if [ -z "$diff" ] && ! git ls-files --error-unmatch -- "$p" >/dev/null 2>&1; then
            all=1
        fi
        printf '%s\n' "$diff" | awk -v DOC="$p" -v ALL="$all" "$FENCE_AWK$HUNK_AWK$VOLID_AWK" - "$p"
    done
    return 0
}

# Hunk range → section grain. Headings come out of the shared slug transform in file
# order. A range that covers the doc's first heading is whole-file grain — `(top)` —
# whatever else it touches; otherwise it is the union of every heading whose own
# line falls inside [start, end] plus the section the start line sits in (the last
# heading at or above start), so a hunk spanning several sections names them all
# instead of only the first.
do_anchors() {
    local path="$1" tbl r start len end ln slug found first_ln hits
    shift
    [ -f "$path" ] || return 0
    tbl="$(slug_lines_numbered "$path")"
    for r in "$@"; do
        r="${r#+}"
        start="${r%%,*}"
        case "$start" in ''|*[!0-9]*) continue ;; esac
        case "$r" in
            *,*) len="${r#*,}" ;;
            *) len=1 ;;
        esac
        case "$len" in ''|*[!0-9]*|0) len=1 ;; esac
        # A pure-deletion hunk (`+c,0`) names the line the deletion attaches to —
        # the range is that one line, the same as a one-line edit there.
        end=$((start + len - 1))
        found="(top)"
        first_ln=""
        hits=""
        while IFS="$(printf '\t')" read -r ln slug; do
            [ -z "$ln" ] && continue
            [ -z "$first_ln" ] && first_ln="$ln"
            [ "$ln" -gt "$end" ] && break
            [ "$ln" -le "$start" ] && found="$slug"
            if [ "$ln" -ge "$start" ] && [ "$ln" -le "$end" ]; then
                hits="$hits$slug
"
            fi
        done <<EOF
$tbl
EOF
        if [ -n "$first_ln" ] && [ "$first_ln" -ge "$start" ] && [ "$first_ln" -le "$end" ]; then
            printf '%s\n' "(top)"
        else
            printf '%s\n' "$found"
            [ -n "$hits" ] && printf '%s' "$hits"
        fi
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
       %s terms <changed-path>...|- | hits [--by-term] <term>...|- | anchors <path> <hunk-range>...
       %s grep-scope [--by-term] <changed-path>...|-
       %s self <changed-path>...|- | terminology | term-uses <changed-path>...|- | volatile-ids <changed-path>...|-
       (- = read the list from stdin, one item per line)
'

# `terms` / `hits` / `grep-scope` / `self` list intake: a lone `-` argument reads the list from stdin,
# one item per line, so a path or term holding spaces arrives whole — no shell
# word-splitting between producer and consumer. Pure bash `read` loop, no fork per
# item. Blank lines are skipped and a trailing CR is dropped (a CRLF producer).
# Result in the ITEMS array.
ITEMS=()
read_items() {
    local line
    ITEMS=()
    while IFS= read -r line || [ -n "$line" ]; do
        line="${line%$'\r'}"
        [ -n "$line" ] && ITEMS+=("$line")
    done
}

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
        if [ "$#" -eq 1 ] && [ "$1" = "-" ]; then
            read_items
            do_terms ${ITEMS[@]+"${ITEMS[@]}"}
        else
            do_terms "$@"
        fi ;;
    hits)
        shift
        if [ "${1:-}" = "--by-term" ]; then HITS_BY_TERM=1; shift; fi
        if [ "$#" -eq 1 ] && [ "$1" = "-" ]; then
            read_items
            do_hits ${ITEMS[@]+"${ITEMS[@]}"}
        else
            do_hits "$@"
        fi ;;
    grep-scope)
        shift
        if [ "${1:-}" = "--by-term" ]; then GREP_SCOPE_BY_TERM=1; shift; fi
        if [ "$#" -eq 1 ] && [ "$1" = "-" ]; then
            read_items
            do_grep_scope ${ITEMS[@]+"${ITEMS[@]}"}
        else
            do_grep_scope "$@"
        fi ;;
    self)
        shift
        if [ "$#" -eq 1 ] && [ "$1" = "-" ]; then
            read_items
            do_self ${ITEMS[@]+"${ITEMS[@]}"}
        else
            do_self "$@"
        fi ;;
    terminology) do_terminology ;;
    term-uses)
        shift
        if [ "$#" -eq 1 ] && [ "$1" = "-" ]; then
            read_items
            do_term_uses ${ITEMS[@]+"${ITEMS[@]}"}
        else
            do_term_uses "$@"
        fi ;;
    volatile-ids)
        shift
        if [ "$#" -eq 1 ] && [ "$1" = "-" ]; then
            read_items
            do_volatile_ids ${ITEMS[@]+"${ITEMS[@]}"}
        else
            do_volatile_ids "$@"
        fi ;;
    anchors)
        shift
        [ "$#" -lt 2 ] && { printf 'Usage: %s anchors <path> <hunk-range>...\n' "$0" >&2; exit 1; }
        do_anchors "$@" ;;
    *)
        # shellcheck disable=SC2059
        printf "$USAGE" "$0" "$0" "$0" "$0" >&2
        exit 1 ;;
esac
