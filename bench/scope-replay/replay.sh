#!/usr/bin/env bash
# Replay the commit door's four scope lanes (SKILL.md §3) over historical commits.
# Read-only on every source repo: git log / diff / ls-tree / archive with
# --no-optional-locks; each commit's doc surface is materialized under $REPLAY_DIR.
#
#   replay.sh list  <repo> gate|doc <n> <end-rev>
#   replay.sh run   <repo> <repo-label> <set> <script-label> <doc-links.sh> <sha-list>
#   replay.sh pairs <repo> <repo-label> <set> <doc-links.sh> <sha-list>
#   replay.sh all   [results-dir]   the README's matrix; needs SB_REPO and MR_REPO
#
# `run` prints one row per commit, columns in COMMIT_HEADER. `pairs` prints one row per
# citer line in PAIR_HEADER, for a citer no lane put in that commit's scope.
set -uo pipefail

: "${REPLAY_DIR:=${TMPDIR:-/tmp}/scope-replay}"
CEILING=8
COMMIT_HEADER='set	script	repo	sha	date	flags	changed	gate_paths	citers	hits	targets	self	union	cross	bytes	subject'
PAIR_HEADER='repo	set	sha	hub	slugs	citer	kind	lineno	line'

g() { local r="$1"; shift; git --no-optional-locks -C "$r" -c core.quotePath=false -c core.autocrlf=false "$@"; }

# Gate-exempt per SKILL.md §3: every changed path inside docs/work/, and outward threads.
is_exempt() { case "$1" in docs/work/*|docs/outward/OUT-*.md) return 0 ;; esac; return 1; }

# The list modes' predicate as awk text: gate = any non-exempt path; doc = any non-exempt
# doc-surface path (history-dimension docs count, the filter reads paths only).
LIST_AWK='
function exempt(p) { return p ~ /^docs\/work\// || p ~ /^docs\/outward\/OUT-.*\.md$/ }
function isdoc(p) { return p ~ /^docs\/.*\.md$/ || p == "README.md" || p ~ /^plugins\/[^\/]+\/README\.md$/ }
function flush() {
    if (sha == "" || done) return
    if (ok) { print sha; if (++got == N) { done = 1; printf "%d\n", skipped > "/dev/stderr" } }
    else skipped++
}
/^@@@/ { flush(); sha = substr($0, 4); ok = 0; next }
NF == 0 { next }
{ if (!exempt($0) && (MODE == "gate" || isdoc($0))) ok = 1 }
END { flush(); if (!done) printf "%d\n", skipped > "/dev/stderr" }
'

# Prints <n> shas newest first; stderr carries the count of commits inside that span the
# filter skipped (card-only door runs under `gate`).
do_list() {
    local repo="$1" mode="$2" n="$3" end="$4"
    g "$repo" log --no-merges --name-only --format='@@@%H' "$end" \
        | awk -v MODE="$mode" -v N="$n" "$LIST_AWK"
}

materialize() {
    local repo="$1" label="$2" sha="$3" dir="$REPLAY_DIR/tree/$label/$sha"
    TREE="$dir"; NAMES="$dir.names"; SIZES="$dir.sizes"
    [ -f "$dir.done" ] && return 0
    mkdir -p "$dir"
    g "$repo" ls-tree -r -l "$sha" | awk -F'\t' '{ n = split($1, a, " "); print a[n] "\t" $2 }' > "$SIZES"
    cut -f2 "$SIZES" > "$NAMES"
    local -a paths=()
    local p
    grep -q '^docs/' "$NAMES" && paths+=(docs)
    while IFS= read -r p; do paths+=("$p"); done < <(grep -E '^(README\.md|plugins/[^/]+/README\.md)$' "$NAMES")
    if [ "${#paths[@]}" -gt 0 ]; then
        g "$repo" archive --format=tar "$sha" -- "${paths[@]}" | tar -xf - -C "$dir"
    fi
    : > "$dir.done"
}

# Feed a list to a doc-links mode by stdin where the script has the `-` form, else as args.
lane() {
    local script="$1" mode="$2" list="$3"
    if grep -q '^read_items()' "$script"; then
        bash "$script" "$mode" - < "$list"
    else
        local -a a=(); local x
        while IFS= read -r x; do a+=("$x"); done < "$list"
        bash "$script" "$mode" "${a[@]+"${a[@]}"}"
    fi
}

# Post-image hunk ranges of one path, one per line.
ranges() {
    g "$1" diff -U0 "$2^" "$2" -- "$3" | awk '/^@@ / { for (i = 1; i <= NF; i++) if ($i ~ /^\+[0-9]/) { print $i; break } }'
}

# Forward-link targets on added lines of non-exempt paths, resolved and kept if the file
# exists at that commit. SKILL.md's regex: \]\([^)]+\.md[^)]*\)
targets() {
    g "$1" diff -U0 "$2^" "$2" | awk -v NAMES="$NAMES" '
    BEGIN { while ((getline n < NAMES) > 0) have[n] = 1 }
    function norm(s,   parts, k, i, out, st, top) {
        k = split(s, parts, "/"); top = 0
        for (i = 1; i <= k; i++) {
            if (parts[i] == "" || parts[i] == ".") continue
            if (parts[i] == "..") { if (top == 0) return ""; top--; continue }
            st[++top] = parts[i]
        }
        out = ""
        for (i = 1; i <= top; i++) out = out (i > 1 ? "/" : "") st[i]
        return out
    }
    /^\+\+\+ / {
        f = substr($0, 5); sub(/\t.*$/, "", f); sub(/^"/, "", f); sub(/"$/, "", f)
        sub(/^b\//, "", f)
        skip = (f ~ /^docs\/work\// || f ~ /^docs\/outward\/OUT-.*\.md$/ || f == "/dev/null")
        d = f; if (d ~ /\//) sub(/\/[^\/]*$/, "", d); else d = ""
        next
    }
    /^\+/ && !skip {
        s = substr($0, 2)
        while (match(s, /\]\([^)]+\.md[^)]*\)/)) {
            t = substr(s, RSTART + 2, RLENGTH - 3)
            s = substr(s, RSTART + RLENGTH)
            if (t ~ /^(https?|mailto):/) continue
            sub(/#.*$/, "", t); sub(/[ \t].*$/, "", t)
            r = norm(d == "" ? t : d "/" t)
            if (r != "" && (r in have)) out[r] = 1
        }
    }
    END { for (r in out) print r }
    ' | LC_ALL=C sort -u
}

# Sets one commit's lanes into $W/{changed,gate,citers,hits,targets,self,union}.
compute_lanes() {
    local repo="$1" label="$2" sha="$3" script="$4" w="$5" p r
    mkdir -p "$w"
    materialize "$repo" "$label" "$sha"
    g "$repo" diff --name-only "$sha^" "$sha" > "$w/changed"
    : > "$w/gate"
    while IFS= read -r p; do is_exempt "$p" || printf '%s\n' "$p" >> "$w/gate"; done < "$w/changed"
    : > "$w/citers"; : > "$w/hits"; : > "$w/self"; : > "$w/anchors"
    targets "$repo" "$sha" > "$w/targets"
    (
        cd "$TREE" || exit 1
        lane "$script" terms "$w/gate" | tr -d '\r' > "$w/terms"
        [ -s "$w/terms" ] && lane "$script" hits "$w/terms" | tr -d '\r' | grep -vxF -f "$w/gate" > "$w/hits"
        lane "$script" self "$w/gate" | tr -d '\r' > "$w/self"
    )
    local -a q
    q=()
    while IFS= read -r p; do
        case "$p" in docs/*.md|README.md|plugins/*/README.md) ;; *) continue ;; esac
        local -a rs=()
        while IFS= read -r r; do rs+=("$r"); done < <(ranges "$repo" "$sha" "$p")
        [ "${#rs[@]}" -eq 0 ] && continue
        local slugs s top=0
        slugs="$(cd "$TREE" && bash "$script" anchors "$p" "${rs[@]}" | tr -d '\r')"
        [ -z "$slugs" ] && continue
        printf '%s\t%s\n' "$p" "$(printf '%s' "$slugs" | tr '\n' ' ')" >> "$w/anchors"
        while IFS= read -r s; do [ "$s" = "(top)" ] && top=1; done <<< "$slugs"
        if [ "$top" -eq 1 ]; then q+=("$p"); else
            while IFS= read -r s; do q+=("$p#$s"); done <<< "$slugs"
        fi
    done < "$w/gate"
    if [ "${#q[@]}" -gt 0 ]; then
        (cd "$TREE" && bash "$script" refs "${q[@]}") | tr -d '\r' | LC_ALL=C sort -u | grep -vxF -f "$w/changed" > "$w/citers"
    fi
    LC_ALL=C sort -u "$w/citers" "$w/hits" "$w/targets" "$w/self" > "$w/union"
}

do_run() {
    local repo="$1" label="$2" set="$3" slabel="$4" script="$5" list="$6" sha w
    [ -s "$list" ] || return 0
    while IFS= read -r sha; do
        w="$REPLAY_DIR/lanes/$set.$slabel/$sha"
        rm -rf "$w"
        compute_lanes "$repo" "$label" "$sha" "$script" "$w"
        local bytes cross flags date subj
        bytes="$(awk -F'\t' -v U="$w/union" 'BEGIN { while ((getline n < U) > 0) u[n] = 1 } ($2 in u) && $1 ~ /^[0-9]+$/ { s += $1 } END { print s + 0 }' "$SIZES")"
        cross=0; [ "$(wc -l < "$w/union")" -gt "$CEILING" ] && cross=1
        IFS=$'\t' read -r date subj < <(g "$repo" log -1 --format='%ad%x09%s' --date=short "$sha")
        flags=""
        case "$subj" in
            chore*sync*|chore*Sync*) flags="sync" ;;
            chore\(release\)*|release*|chore:\ release*|chore:\ bump*) flags="release" ;;
        esac
        grep -qE '^docs/overview\.md	.*\b(problem|user)\b' "$w/anchors" && flags="${flags:+$flags,}premise"
        printf '%s\t%s\t%s\t%s\t%s\t%s\t%d\t%d\t%d\t%d\t%d\t%d\t%d\t%d\t%d\t%s\n' \
            "$set" "$slabel" "$label" "${sha:0:8}" "$date" "${flags:--}" \
            "$(wc -l < "$w/changed")" "$(wc -l < "$w/gate")" "$(wc -l < "$w/citers")" "$(wc -l < "$w/hits")" \
            "$(wc -l < "$w/targets")" "$(wc -l < "$w/self")" "$(wc -l < "$w/union")" "$cross" "$bytes" "${subj:0:70}"
    done < "$list"
}

# Citer lines of one hub doc in one doc, outside fences: an anchorless inline link to it
# (kind=link), or a path mention of it with every link construct removed (kind=mention).
# A mention is `<stem>.md`, bare or with a directory prefix that is a suffix of the hub
# path or resolves to it from the citing doc; any other prefix names some other file.
HUB_AWK='
function norm(s,   parts, k, i, out, st, top) {
    k = split(s, parts, "/"); top = 0
    for (i = 1; i <= k; i++) {
        if (parts[i] == "" || parts[i] == ".") continue
        if (parts[i] == "..") { if (top == 0) return "\001"; top--; continue }
        st[++top] = parts[i]
    }
    out = ""
    for (i = 1; i <= top; i++) out = out (i > 1 ? "/" : "") st[i]
    return out
}
function fence(l,   m, c, L) {
    if (match(l, /^ {0,3}(`{3,}|~{3,})/)) {
        m = substr(l, RSTART, RLENGTH); gsub(/ /, "", m); c = substr(m, 1, 1); L = length(m)
        if (!inf) { inf = 1; fc = c; fl = L; return 1 }
        if (c == fc && L >= fl && l ~ /^ {0,3}(`+|~+)[ \t\r]*$/) { inf = 0; return 1 }
    }
    return inf
}
function nospans(l,   out, d, rest, c) {
    out = ""
    while (match(l, /`+/)) {
        d = substr(l, RSTART, RLENGTH); out = out substr(l, 1, RSTART - 1)
        rest = substr(l, RSTART + RLENGTH); c = index(rest, d)
        l = (c > 0) ? substr(rest, c + length(d)) : rest
    }
    return out l
}
function suffix_of(h, m) { return h == m || substr(h, length(h) - length(m)) == "/" m }
FNR == 1 { inf = 0; d = FILENAME; if (d ~ /\//) sub(/\/[^\/]*$/, "", d); else d = "" }
{
    sub(/\r$/, "")
    raw = $0
    if (fence(raw)) next
    l = nospans(raw); link = 0
    while (match(l, /\[[^\]]*\]\([^)]+\)/)) {
        seg = substr(l, RSTART, RLENGTH); l = substr(l, RSTART + RLENGTH)
        t = substr(seg, index(seg, "](") + 2); t = substr(t, 1, length(t) - 1)
        if (t !~ /#/ && t !~ /^(https?|mailto):/ && norm(d == "" ? t : d "/" t) == HUB) link = 1
    }
    if (link) print FILENAME "\tlink\t" FNR "\t" raw
    m = raw
    while (match(m, /\[[^\]]*\]\([^)]+\)/)) m = substr(m, 1, RSTART - 1) " " substr(m, RSTART + RLENGTH)
    pat = "[A-Za-z0-9_./-]*" STEM "\\.md"; mention = 0; off = m
    while (match(off, pat)) {
        tok = substr(off, RSTART, RLENGTH); pre = (RSTART > 1) ? substr(off, RSTART - 1, 1) : ""
        off = substr(off, RSTART + RLENGTH)
        if (tok !~ ("(^|/)" STEM "\\.md$")) continue
        if (suffix_of(HUB, tok) || norm(d == "" ? tok : d "/" tok) == HUB || tok == STEM ".md") mention = 1
    }
    if (mention) print FILENAME "\tmention\t" FNR "\t" raw
}
'

do_pairs() {
    local repo="$1" label="$2" set="$3" script="$4" list="$5" sha w p
    [ -s "$list" ] || return 0
    while IFS= read -r sha; do
        w="$REPLAY_DIR/lanes/$set.pairs/$sha"
        rm -rf "$w"
        compute_lanes "$repo" "$label" "$sha" "$script" "$w"
        local surface="$w/surface"
        (cd "$TREE" && { find docs -name '*.md' -type f 2>/dev/null; [ -f README.md ] && echo README.md; find plugins -mindepth 2 -maxdepth 2 -name README.md -type f 2>/dev/null; } | bash "$script" self - | tr -d '\r') > "$surface"
        grep -vxF -f "$w/union" "$surface" | grep -vxF -f "$w/changed" > "$w/out" || true
        [ -s "$w/out" ] || continue
        while IFS=$'\t' read -r p slugs; do
            local base="${p##*/}" stem
            stem="${base%.md}"
            case " overview techstack decisions " in *" $stem "*) ;; *) continue ;; esac
            local grain=section
            case " $slugs " in *" (top) "*) grain=top ;; esac
            local -a files=()
            local f
            while IFS= read -r f; do files+=("$f"); done < "$w/out"
            (cd "$TREE" && awk -v HUB="$p" -v STEM="$stem" "$HUB_AWK" "${files[@]}") \
                | while IFS=$'\t' read -r citer kind ln text; do
                    # Whole-file grain: `refs <path>` reaches link citers, so only mentions
                    # stay unreached; they carry grain=top and are counted, not judged.
                    [ "$grain" = top ] && [ "$kind" = link ] && continue
                    printf '%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\n' "$label" "$set" "${sha:0:8}" "$p" "$grain:$slugs" "$citer" "$kind" "$ln" "${text:0:600}"
                done
        done < "$w/anchors"
    done < "$list"
}

do_all() {
    local out="${1:-$(cd "$(dirname "$0")" && pwd)/results}"
    : "${SB_REPO:?}"; : "${MR_REPO:?}"
    mkdir -p "$out" "$REPLAY_DIR/lists" "$REPLAY_DIR/scripts"
    local head="$REPLAY_DIR/scripts/doc-links.head.sh" old="$REPLAY_DIR/scripts/doc-links.24d0382.sh"
    local path=plugins/super-bootstrap/skills/commit/assets/doc-links.sh L="$REPLAY_DIR/lists"
    git -C "$SB_REPO" show "HEAD:$path" > "$head"
    git -C "$SB_REPO" show "24d0382:$path" > "$old"
    local et1c=a14b5dd mr_et1c
    mr_et1c="$(g "$MR_REPO" log -1 --format=%H --before='2026-11-03T06:57:08+08:00')"

    do_list "$SB_REPO" gate 30 HEAD        > "$L/sb-recent"      2> "$L/sb-recent.skipped"
    do_list "$MR_REPO" gate 30 HEAD        > "$L/mr-recent"      2> "$L/mr-recent.skipped"
    do_list "$SB_REPO" gate 30 "24d0382^"  > "$L/sb-24d-gate"    2> "$L/sb-24d-gate.skipped"
    do_list "$SB_REPO" doc  30 "24d0382^"  > "$L/sb-24d-doc"     2> "$L/sb-24d-doc.skipped"
    do_list "$SB_REPO" doc  15 "$et1c^"    > "$L/sb-et1c-doc"    2> "$L/sb-et1c-doc.skipped"
    do_list "$MR_REPO" doc  15 "$mr_et1c"  > "$L/mr-et1c-doc"    2> "$L/mr-et1c-doc.skipped"

    { printf '%s\n' "$COMMIT_HEADER"
      local spec repo label set s
      for spec in "SB|sb|sb-recent" "MR|mr|mr-recent" "SB|sb|sb-24d-gate" "SB|sb|sb-24d-doc" "SB|sb|sb-et1c-doc" "MR|mr|mr-et1c-doc"; do
          IFS='|' read -r repo label set <<< "$spec"
          [ "$repo" = SB ] && repo="$SB_REPO" || repo="$MR_REPO"
          do_run "$repo" "$label" "$set" head "$head" "$L/$set"
          do_run "$repo" "$label" "$set" old  "$old"  "$L/$set"
      done
      # Filter probes: wide doc-path lists, read with self > 0 as the sample's filter.
      do_list "$SB_REPO" doc 40 "$et1c^"   > "$L/sb-et1c-doc40" 2>/dev/null
      do_list "$MR_REPO" doc 40 "$mr_et1c" > "$L/mr-et1c-doc40" 2>/dev/null
      do_list "$SB_REPO" doc 45 "24d0382^" > "$L/sb-24d-doc45"  2>/dev/null
      do_run "$SB_REPO" sb sb-et1c-doc40 head "$head" "$L/sb-et1c-doc40"
      do_run "$MR_REPO" mr mr-et1c-doc40 head "$head" "$L/mr-et1c-doc40"
      do_run "$SB_REPO" sb sb-24d-doc45  old  "$old"  "$L/sb-24d-doc45"
      # Control: the card's 16-file diff, recorded at a 29-doc scope.
      g "$MR_REPO" rev-parse 4451477d > "$L/ctrl"
      do_run "$MR_REPO" mr ctrl-4451477d head "$head" "$L/ctrl"
    } > "$out/commits.tsv"

    { printf '%s\n' "$PAIR_HEADER"
      do_pairs "$SB_REPO" sb sb-recent "$head" "$L/sb-recent"
      do_pairs "$MR_REPO" mr mr-recent "$head" "$L/mr-recent"
      do_pairs "$SB_REPO" sb sb-24d-gate "$head" "$L/sb-24d-gate"
      do_pairs "$SB_REPO" sb sb-24d-doc "$head" "$L/sb-24d-doc"
    } > "$out/pairs.tsv"
}

# Sourcing guard: arms.sh sources this file for its helpers and sets REPLAY_SOURCED=1.
[ "${REPLAY_SOURCED:-0}" = 1 ] && return 0

case "${1:-}" in
    list)  shift; do_list "$@" ;;
    run)   shift; do_run "$@" ;;
    pairs) shift; do_pairs "$@" ;;
    all)   shift; do_all "$@" ;;
    *) sed -n '2,11p' "$0"; exit 2 ;;
esac
