#!/usr/bin/env bash
# Replay the commit door's scope under alternative grep-lane term rules ("arms").
# The citers / targets / self lanes come from replay.sh's compute_lanes and are the same
# for every arm; only the `hits` lane is recomputed, by feeding an arm's term list to the
# unmodified doc-links.sh (`hits -`). Arm B runs a copy under $REPLAY_DIR whose HUB_STEMS
# line is widened. Read-only on every source repo.
#
#   arms.sh list    <repo> <repo-label> <doc-links.sh> <n> <end-rev>
#   arms.sh run     <repo> <repo-label> <set> <doc-links.sh> <sha-list> <out-dir>
#   arms.sh summary <out-dir>
#   arms.sh all     [results-dir]     the pinned fixture; needs SB_REPO and MR_REPO
#   arms.sh parity  <shipped-doc-links.sh> [results-dir]   `shipped` against `AB` over the
#                   lists `all` left under $REPLAY_DIR; writes arms-parity.tsv only
#
# Origin class of a gate path: doc = `self` prints it; md = any other `.md`; code = the rest.
# Arms:
#   head      today: `terms` over the gate paths.
#   A-all     doc paths keep their head term. A code/md path with status M: the identifier
#             tokens on its changed lines and hunk-header context. Status A / D / R keeps
#             the basename term (R: the old name's term too).
#   A-shaped  A-all, tokens of symbol shape only (`_`, a digit, or an inner uppercase).
#   B-fanin   head terms; a code/md-origin term with `hits --by-term` > CEILING joins
#             HUB_STEMS in the script copy.
#   AB        B-fanin, plus the A-shaped tokens of each path whose term B demoted.
#   shipped   (`parity` only) a second script's `grep-scope -` over the gate paths — the
#             AB rule as one mode — its diff replayed from git objects through
#             DOCLINK_DIFF_REPO / DOCLINK_DIFF_RANGE. Compared with AB's hits per commit.
# A path `terms` yields nothing for yields nothing in every arm.
#
# Timing (Git Bash, Windows): `all` took 14.5 min for 61 commits — the two `list` walks
# materialize every candidate commit's doc surface (about 3 min), then about 11 s a commit,
# most of it compute_lanes and the one `terms` call per gate path. A `hits` call is ~0.2 s.
# Lesson: git's default rename detection gives the door one gate path per rename (the new
# name), so head never searches the old basename; the A arms add it (`Rold` rows) and can
# return more docs than head on a rename commit.
set -uo pipefail

HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPLAY_SOURCED=1
# shellcheck source=replay.sh
. "$HERE/replay.sh"

ARMS="head A-all A-shaped B-fanin AB"
MR_PIN=3891bf41
SB_PIN=d25164e
SCRIPT_PATH=plugins/super-bootstrap/skills/commit/assets/doc-links.sh
ARMS_COMMIT_HEADER='set	repo	sha	date	arm	n_terms	hits	union	cross	bytes	subject	head_hits_doc_only	head_hits_code_only	head_hits_both'
ARMS_DROPPED_HEADER='set	repo	sha	arm	doc	head_terms'
ARMS_TERMS_HEADER='set	repo	sha	arm	n_terms	terms	demoted'
ARMS_PARITY_HEADER='set	repo	sha	ab_hits	shipped_hits	equal	demoted	ab_only	shipped_only'
ARMS_SUMMARY_HEADER='set	arm	commits	crossings	median_union	max_union	median_hits	dropped_docs'

# The script under test's own term_generic word list, read from its `case " … " in` line,
# so the token filter cannot drift from the script the arm feeds.
# A script that holds the list in a GENERIC_WORDS="…" line (the `grep-scope` one) is read
# from that line instead.
generic_words() {
    awk '/^GENERIC_WORDS="/ { s = $0; sub(/^[^"]*" */, "", s); sub(/ *"[ \t\r]*$/, "", s); print s; exit }
         /^term_generic\(\)/ { f = 1 } f && /^}/ { exit }
         f && /case " / { s = $0; sub(/^[^"]*" */, "", s); sub(/ *" in.*$/, "", s); print s; exit }' "$1"
}

# Every [A-Za-z0-9_] run of 4+ characters in a commit's materialized tree, one per line.
# A term made only of those characters can hit only as a whole word (the script's isword
# is [A-Za-z0-9_-]), so a term absent here hits nothing: dropping it before `hits` leaves
# the result unchanged. Lesson: without this, A-all on a wide diff hands `hits` thousands
# of terms through one environment variable and an awk pass of terms x lines.
tree_words() {
    WORDS="$TREE.words"
    [ -f "$WORDS" ] && return 0
    (cd "$TREE" && find . -type f -name '*.md' -print0 | LC_ALL=C xargs -0 -r awk '
        { n = split($0, a, /[^A-Za-z0-9_]+/); for (i = 1; i <= n; i++) if (length(a[i]) >= 4) w[a[i]] = 1 }
        END { for (t in w) print t }') > "$WORDS.tmp" && mv "$WORDS.tmp" "$WORDS"
}

# hits lane of one term list -> $3, gate paths removed as compute_lanes does.
# ARMS_NOFILTER=1 skips the tree_words prefilter (the equivalence self-check).
arm_hits() {
    local script="$1" terms="$2" out="$3" w="$4"
    : > "$out"
    [ -s "$terms" ] || return 0
    if [ "${ARMS_NOFILTER:-0}" = 1 ]; then cp "$terms" "$terms.live"; else
        LC_ALL=C awk -v W="$WORDS" 'BEGIN { while ((getline l < W) > 0) w[l] = 1 }
            /[^A-Za-z0-9_]/ || ($0 in w)' "$terms" > "$terms.live"
    fi
    [ -s "$terms.live" ] || return 0
    (cd "$TREE" && bash "$script" hits - < "$terms.live" | tr -d '\r' | grep -vxF -f "$w/gate" > "$out")
    return 0
}

# Identifier tokens of the commit's changed lines, for the eligible paths in $PT
# (class code/md, status M, a head term): path TAB token TAB shaped(0|1).
# Token = maximal [A-Za-z0-9_] run that starts with a letter or `_`, length >= 4, not a
# term_generic word. A run that starts with a digit is dropped whole (guess, see report).
# Lesson: `--- ` / `+++ ` are file headers only before a file's first `@@`; inside a hunk
# a removed line whose text starts with `-- ` prints as `--- `, so header state is tracked.
TOKEN_AWK='
BEGIN {
    while ((getline l < PT) > 0) { split(l, f, "\t"); if (f[3] == "M" && f[4] != "" && f[2] != "doc") elig[f[1]] = 1 }
    n = split(GENERIC, G, " "); for (i = 1; i <= n; i++) gen[G[i]] = 1
}
function emit(s,   k, i, a, t, sh) {
    gsub(/[^A-Za-z0-9_]+/, " ", s)
    k = split(s, a, " ")
    for (i = 1; i <= k; i++) {
        t = a[i]
        if (length(t) < 4 || t ~ /^[0-9]/ || (tolower(t) in gen) || ((file, t) in seen)) continue
        seen[file, t] = 1
        sh = (t ~ /_/ || t ~ /[0-9]/ || substr(t, 2) ~ /[A-Z]/) ? 1 : 0
        print file "\t" t "\t" sh
    }
}
/^diff --git / { hdr = 1; file = ""; next }
hdr && /^\+\+\+ / {
    file = substr($0, 5); sub(/\t.*$/, "", file); sub(/^"/, "", file); sub(/"$/, "", file); sub(/^b\//, "", file)
    next
}
/^@@ / && (hdr || file != "") {
    hdr = 0
    if (file in elig) { s = $0; sub(/^@@ [^@]*@@/, "", s); emit(s) }
    next
}
!hdr && /^[-+]/ && (file in elig) { emit(substr($0, 2)) }
'

# One commit: every arm's term list, hits and union under $w, rows appended to $out/*.tsv.
arm_commit() {
    local repo="$1" label="$2" set="$3" script="$4" sha="$5" out="$6"
    local w="$REPLAY_DIR/lanes/$set.arms/$sha" p c s t arm
    rm -rf "$w"
    compute_lanes "$repo" "$label" "$sha" "$script" "$w"
    tree_words

    # Path status. Same rename detection as compute_lanes' --name-only (git's default), so
    # a renamed file is one gate path (the new name) with status R.
    g "$repo" diff --name-status "$sha^" "$sha" > "$w/status"
    awk -F'\t' -v SELF="$w/self" -v ST="$w/status" '
        BEGIN {
            while ((getline l < SELF) > 0) self[l] = 1
            while ((getline l < ST) > 0) { k = split(l, f, "\t"); st[f[k]] = substr(f[1], 1, 1) }
        }
        { print $0 "\t" (($0 in self) ? "doc" : ($0 ~ /\.md$/ ? "md" : "code")) "\t" (($0 in st) ? st[$0] : "?") }
    ' "$w/gate" > "$w/pcs"

    # Per-path head term: path TAB class TAB status TAB term. `terms` prints a sorted
    # unique list, so the path -> term map takes one call per path; skipped when the
    # whole gate list yields nothing. Rename sources follow as status `Rold` rows.
    : > "$w/pt"
    while IFS=$'\t' read -r p c s; do
        t=""
        [ -s "$w/terms" ] && t="$(cd "$TREE" && printf '%s\n' "$p" | bash "$script" terms - | tr -d '\r' | head -n 1)"
        printf '%s\t%s\t%s\t%s\n' "$p" "$c" "$s" "$t" >> "$w/pt"
    done < "$w/pcs"
    awk -F'\t' '$1 ~ /^R/ { print $3 "\t" $2 }' "$w/status" > "$w/renames"
    while IFS=$'\t' read -r p s; do      # p = new name, s = old name
        is_exempt "$p" && continue
        is_exempt "$s" && continue
        c=code; case "$s" in *.md) c=md ;; esac
        t="$(cd "$TREE" && printf '%s\n' "$s" | bash "$script" terms - | tr -d '\r' | head -n 1)"
        printf '%s\t%s\tRold\t%s\n' "$s" "$c" "$t" >> "$w/pt"
    done < "$w/renames"

    g "$repo" diff -U0 --no-ext-diff --no-textconv --src-prefix=a/ --dst-prefix=b/ "$sha^" "$sha" \
        | LC_ALL=C awk -v PT="$w/pt" -v GENERIC="$GENERIC" "$TOKEN_AWK" > "$w/tok"

    # Term lists.
    awk -F'\t' '$3 != "Rold" && $4 != "" { print $4 }' "$w/pt" | LC_ALL=C sort -u > "$w/arm.head.terms"
    awk -F'\t' '$3 != "Rold" && $4 != "" && $2 == "doc" { print $4 }' "$w/pt" | LC_ALL=C sort -u > "$w/origin.doc.terms"
    awk -F'\t' '$3 != "Rold" && $4 != "" && $2 != "doc" { print $4 }' "$w/pt" | LC_ALL=C sort -u > "$w/origin.code.terms"
    for s in 0 1; do
        arm=A-all; [ "$s" = 1 ] && arm=A-shaped
        awk -F'\t' -v SH="$s" '
            FILENAME == ARGV[1] { if ($4 != "" && ($2 == "doc" || $3 != "M")) print $4; next }
            SH == 0 || $3 == 1 { print $2 }
        ' "$w/pt" "$w/tok" | LC_ALL=C sort -u > "$w/arm.$arm.terms"
    done

    # Inline guard: the per-path map must rebuild today's `terms` output exactly.
    cmp -s "$w/terms" "$w/arm.head.terms" || printf 'PARITY terms %s %s\n' "$set" "$sha" >&2

    # B: demote code/md-origin head terms over the ceiling. A term the HUB_STEMS line
    # cannot carry (a space, or a character the shell would expand) is left as it is and
    # reported on stderr. An asset term (`X.tscn`) is listed but `hits` tests its asset
    # rule first, so listing it changes nothing.
    : > "$w/byterm"; : > "$w/demoted"
    [ -s "$w/arm.head.terms" ] && (cd "$TREE" && bash "$script" hits --by-term - < "$w/arm.head.terms" | tr -d '\r') > "$w/byterm"
    awk -F'\t' -v C="$CEILING" -v O="$w/origin.code.terms" '
        BEGIN { while ((getline l < O) > 0) o[l] = 1 }
        ($1 in o) && $2 + 0 > C {
            if ($1 ~ /[^A-Za-z0-9_.+-]/) { print "SKIP-DEMOTE " $1 > "/dev/stderr"; next }
            print $1
        }' "$w/byterm" | LC_ALL=C sort -u > "$w/demoted"
    local bscript="$script"
    if [ -s "$w/demoted" ]; then
        bscript="$w/doc-links.B.sh"
        awk -v ADD="$(tr '\n' ' ' < "$w/demoted")" '
            /^HUB_STEMS="/ && !d { sub(/"[ \t\r]*$/, "", $0); $0 = $0 ADD "\""; d = 1 }
            { print }' "$script" > "$bscript"
        [ "$(diff "$script" "$bscript" | grep -c '^>')" -eq 1 ] || printf 'PATCH-FAILED %s %s\n' "$set" "$sha" >&2
    fi
    cp "$w/arm.head.terms" "$w/arm.B-fanin.terms"
    awk -F'\t' -v D="$w/demoted" '
        BEGIN { while ((getline l < D) > 0) d[l] = 1 }
        FILENAME == ARGV[1] { if ($3 != "Rold" && $4 != "") { print $4; if ($4 in d) dp[$1] = 1 } next }
        $3 == 1 && ($1 in dp) { print $2 }
    ' "$w/pt" "$w/tok" | LC_ALL=C sort -u > "$w/arm.AB.terms"

    # Hits per arm. An arm whose term list and script equal an earlier arm's copies its hits.
    arm_hits "$script" "$w/arm.head.terms" "$w/arm.head.hits" "$w"
    cmp -s "$w/hits" "$w/arm.head.hits" || printf 'PARITY hits %s %s\n' "$set" "$sha" >&2
    arm_hits "$script" "$w/arm.A-all.terms" "$w/arm.A-all.hits" "$w"
    if cmp -s "$w/arm.A-all.terms" "$w/arm.A-shaped.terms"; then cp "$w/arm.A-all.hits" "$w/arm.A-shaped.hits"
    else arm_hits "$script" "$w/arm.A-shaped.terms" "$w/arm.A-shaped.hits" "$w"; fi
    if [ -s "$w/demoted" ]; then
        arm_hits "$bscript" "$w/arm.B-fanin.terms" "$w/arm.B-fanin.hits" "$w"
        if cmp -s "$w/arm.B-fanin.terms" "$w/arm.AB.terms"; then cp "$w/arm.B-fanin.hits" "$w/arm.AB.hits"
        else arm_hits "$bscript" "$w/arm.AB.terms" "$w/arm.AB.hits" "$w"; fi
    else
        cp "$w/arm.head.hits" "$w/arm.B-fanin.hits"; cp "$w/arm.head.hits" "$w/arm.AB.hits"
    fi

    # shipped: one call of the second script's mode, cwd the materialized tree, the diff
    # read from the source repo's objects (no optional locks — nothing is written there).
    # Gate paths removed as arm_hits does. Row: both counts, equal 1|0, AB's demoted
    # terms, and each side's extra docs.
    if [ -n "${SHIPPED_SCRIPT:-}" ]; then
        (cd "$TREE" && GIT_OPTIONAL_LOCKS=0 DOCLINK_DIFF_REPO="$repo" DOCLINK_DIFF_RANGE="$sha^ $sha" \
            bash "$SHIPPED_SCRIPT" grep-scope - < "$w/gate" | tr -d '\r' | grep -vxF -f "$w/gate" > "$w/arm.shipped.hits")
        local eq=0 ao so dm
        cmp -s "$w/arm.AB.hits" "$w/arm.shipped.hits" && eq=1
        ao="$(LC_ALL=C comm -23 "$w/arm.AB.hits" "$w/arm.shipped.hits" | tr '\n' ' ')"; ao="${ao% }"
        so="$(LC_ALL=C comm -13 "$w/arm.AB.hits" "$w/arm.shipped.hits" | tr '\n' ' ')"; so="${so% }"
        dm="$(tr '\n' ' ' < "$w/demoted")"; dm="${dm% }"
        printf '%s\t%s\t%s\t%d\t%d\t%d\t%s\t%s\t%s\n' "$set" "$label" "${sha:0:8}" \
            "$(wc -l < "$w/arm.AB.hits")" "$(wc -l < "$w/arm.shipped.hits")" "$eq" "${dm:--}" "${ao:--}" "${so:--}" >> "$PARITY_OUT"
    fi

    # Origin split of head's hits lane. A term both a doc path and a code/md path yield
    # sits in both origin lists.
    arm_hits "$script" "$w/origin.doc.terms" "$w/origin.doc.hits" "$w"
    arm_hits "$script" "$w/origin.code.terms" "$w/origin.code.hits" "$w"
    local od oc ob
    od="$(LC_ALL=C comm -23 "$w/origin.doc.hits" "$w/origin.code.hits" | wc -l)"
    oc="$(LC_ALL=C comm -13 "$w/origin.doc.hits" "$w/origin.code.hits" | wc -l)"
    ob="$(LC_ALL=C comm -12 "$w/origin.doc.hits" "$w/origin.code.hits" | wc -l)"

    local date subj bytes cross any=0
    IFS=$'\t' read -r date subj < <(g "$repo" log -1 --format='%ad%x09%s' --date=short "$sha")
    for arm in $ARMS; do
        LC_ALL=C sort -u "$w/citers" "$w/arm.$arm.hits" "$w/targets" "$w/self" > "$w/arm.$arm.union"
        bytes="$(awk -F'\t' -v U="$w/arm.$arm.union" 'BEGIN { while ((getline n < U) > 0) u[n] = 1 } ($2 in u) && $1 ~ /^[0-9]+$/ { s += $1 } END { print s + 0 }' "$SIZES")"
        cross=0; [ "$(wc -l < "$w/arm.$arm.union")" -gt "$CEILING" ] && cross=1
        if [ "$arm" = head ]; then s="$od	$oc	$ob"; else s="-	-	-"; fi
        printf '%s\t%s\t%s\t%s\t%s\t%d\t%d\t%d\t%d\t%d\t%s\t%s\n' "$set" "$label" "${sha:0:8}" "$date" "$arm" \
            "$(wc -l < "$w/arm.$arm.terms")" "$(wc -l < "$w/arm.$arm.hits")" "$(wc -l < "$w/arm.$arm.union")" \
            "$cross" "$bytes" "${subj:0:70}" "$s" >> "$out/arms-commits.tsv"
        s="-"; case "$arm" in B-fanin|AB) s="$(tr '\n' ' ' < "$w/demoted")"; s="${s% }"; [ -z "$s" ] && s="-" ;; esac
        t="$(tr '\n' ' ' < "$w/arm.$arm.terms")"; t="${t% }"
        printf '%s\t%s\t%s\t%s\t%d\t%s\t%s\n' "$set" "$label" "${sha:0:8}" "$arm" \
            "$(wc -l < "$w/arm.$arm.terms")" "${t:0:400}" "$s" >> "$out/arms-terms.tsv"
        if [ "$arm" != head ]; then
            LC_ALL=C comm -23 "$w/arm.head.union" "$w/arm.$arm.union" > "$w/arm.$arm.dropped"
            [ -s "$w/arm.$arm.dropped" ] && any=1
        fi
    done

    # Dropped docs with the head terms that reached them. A dropped doc is in head's hits
    # lane only, and a doc-only-origin term reaches the same docs in every arm, so the
    # code/md-origin terms are the whole candidate set: one `hits` call per such term
    # with a non-zero count, run only for a commit that has a dropped doc.
    [ "$any" = 1 ] || return 0
    : > "$w/reach"
    while IFS= read -r t; do
        awk -F'\t' -v T="$t" '$1 == T && $2 + 0 > 0 { f = 1 } END { exit !f }' "$w/byterm" || continue
        printf '%s\n' "$t" > "$w/one.terms"
        arm_hits "$script" "$w/one.terms" "$w/one.hits" "$w"
        awk -v T="$t" '{ print $0 "\t" T }' "$w/one.hits" >> "$w/reach"
    done < "$w/origin.code.terms"
    for arm in $ARMS; do
        [ "$arm" = head ] && continue
        [ -s "$w/arm.$arm.dropped" ] || continue
        awk -F'\t' -v R="$w/reach" -v P="$set	$label	${sha:0:8}	$arm" '
            BEGIN { while ((getline l < R) > 0) { split(l, f, "\t"); by[f[1]] = (f[1] in by) ? by[f[1]] "," f[2] : f[2] } }
            { print P "\t" $0 "\t" (($0 in by) ? by[$0] : "?") }' "$w/arm.$arm.dropped" >> "$out/arms-dropped.tsv"
    done
}

do_arms_run() {
    local repo="$1" label="$2" set="$3" script="$4" list="$5" out="$6" sha
    mkdir -p "$out"
    [ -f "$out/arms-commits.tsv" ] || printf '%s\n' "$ARMS_COMMIT_HEADER" > "$out/arms-commits.tsv"
    [ -f "$out/arms-dropped.tsv" ] || printf '%s\n' "$ARMS_DROPPED_HEADER" > "$out/arms-dropped.tsv"
    [ -f "$out/arms-terms.tsv" ] || printf '%s\n' "$ARMS_TERMS_HEADER" > "$out/arms-terms.tsv"
    GENERIC="$(generic_words "$script")"
    [ -n "$GENERIC" ] || { echo "arms.sh: no term_generic word list in $script" >&2; return 1; }
    [ -s "$list" ] || return 0
    while IFS= read -r sha; do
        arm_commit "$repo" "$label" "$set" "$script" "$sha" "$out"
    done < "$list"
}

# Last <n> non-merge commits ending at <end> with a code/md-class gate path that yields a
# head term. Class needs `self`, so each candidate's doc surface is materialized.
do_arms_list() {
    local repo="$1" label="$2" script="$3" n="$4" end="$5" sha p got=0 tmp="$REPLAY_DIR/lists/.cand.$$"
    mkdir -p "$REPLAY_DIR/lists"
    while IFS= read -r sha; do
        g "$repo" rev-parse -q --verify "$sha^" > /dev/null || continue
        : > "$tmp"
        while IFS= read -r p; do is_exempt "$p" || printf '%s\n' "$p" >> "$tmp"; done < <(g "$repo" diff --name-only "$sha^" "$sha")
        [ -s "$tmp" ] || continue
        materialize "$repo" "$label" "$sha"
        (cd "$TREE" && bash "$script" self - < "$tmp" | tr -d '\r') > "$tmp.self"
        grep -vxF -f "$tmp.self" "$tmp" > "$tmp.nondoc" || continue
        [ -n "$(cd "$TREE" && bash "$script" terms - < "$tmp.nondoc")" ] || continue
        printf '%s\n' "$sha"
        got=$((got + 1)); [ "$got" -ge "$n" ] && break
    done < <(g "$repo" log --no-merges --format=%H "$end")
    rm -f "$tmp" "$tmp.self" "$tmp.nondoc"
}

do_arms_summary() {
    local out="$1"
    printf '%s\n' "$ARMS_SUMMARY_HEADER"
    awk -F'\t' '
        function med(key, n,   i, j, t, v) {
            for (i = 1; i <= n; i++) v[i] = val[key, i]
            for (i = 2; i <= n; i++) { t = v[i]; for (j = i - 1; j >= 1 && v[j] > t; j--) v[j + 1] = v[j]; v[j + 1] = t }
            return (n % 2) ? v[(n + 1) / 2] : (v[n / 2] + v[n / 2 + 1]) / 2
        }
        FILENAME == ARGV[1] { if (FNR > 1) drop[$1, $4]++; next }
        FNR == 1 { next }
        {
            k = $1 SUBSEP $5
            if (!(k in n)) { order[++m] = k; set[k] = $1; arm[k] = $5 }
            n[k]++; cross[k] += $9
            val["u" k, n[k]] = $8 + 0; val["h" k, n[k]] = $7 + 0
            if ($8 + 0 > mx[k]) mx[k] = $8 + 0
        }
        END {
            for (i = 1; i <= m; i++) {
                k = order[i]
                print set[k] "\t" arm[k] "\t" n[k] "\t" cross[k] "\t" med("u" k, n[k]) "\t" (mx[k] + 0) "\t" med("h" k, n[k]) "\t" (drop[k] + 0)
            }
        }' "$out/arms-dropped.tsv" "$out/arms-commits.tsv"
}

do_arms_all() {
    local out="${1:-$HERE/results}"
    : "${SB_REPO:?}"; : "${MR_REPO:?}"
    mkdir -p "$out" "$REPLAY_DIR/lists" "$REPLAY_DIR/scripts"
    local script="$REPLAY_DIR/scripts/doc-links.$SB_PIN.sh" L="$REPLAY_DIR/lists"
    g "$SB_REPO" show "$SB_PIN:$SCRIPT_PATH" > "$script"
    do_arms_list "$MR_REPO" mr "$script" 30 "$MR_PIN" > "$L/mr-code30"
    do_arms_list "$SB_REPO" sb "$script" 30 "$SB_PIN" > "$L/sb-code30"
    g "$MR_REPO" rev-parse "$MR_PIN" > "$L/ctrl-$MR_PIN"
    rm -f "$out/arms-commits.tsv" "$out/arms-dropped.tsv" "$out/arms-terms.tsv" "$out/arms-summary.tsv"
    do_arms_run "$MR_REPO" mr mr-code30 "$script" "$L/mr-code30" "$out"
    do_arms_run "$SB_REPO" sb sb-code30 "$script" "$L/sb-code30" "$out"
    do_arms_run "$MR_REPO" mr "ctrl-$MR_PIN" "$script" "$L/ctrl-$MR_PIN" "$out"
    do_arms_summary "$out" > "$out/arms-summary.tsv"
}

# `shipped` against `AB` over the lists and the pinned script `all` left under $REPLAY_DIR.
# The per-arm tsvs of this re-run go to a scratch directory under $REPLAY_DIR, started
# from their header lines each time: only arms-parity.tsv lands in the results directory.
# Timing (Git Bash, Windows): 15.5 min for the 61 commits — every arm is recomputed for
# each commit, then one `grep-scope` call is added.
do_arms_parity() {
    local shipped="$1" out="${2:-$HERE/results}"
    : "${SB_REPO:?}"; : "${MR_REPO:?}"
    local script="$REPLAY_DIR/scripts/doc-links.$SB_PIN.sh" L="$REPLAY_DIR/lists" scratch="$REPLAY_DIR/parity-out"
    if [ ! -f "$script" ] || [ ! -f "$L/mr-code30" ] || [ ! -f "$L/sb-code30" ] || [ ! -f "$L/ctrl-$MR_PIN" ]; then
        echo "arms.sh: run 'all' first — no lists or pinned script under $REPLAY_DIR" >&2; return 1
    fi
    SHIPPED_SCRIPT="$(cd "$(dirname "$shipped")" && pwd)/$(basename "$shipped")"
    mkdir -p "$scratch" "$out"
    printf '%s\n' "$ARMS_COMMIT_HEADER" > "$scratch/arms-commits.tsv"
    printf '%s\n' "$ARMS_DROPPED_HEADER" > "$scratch/arms-dropped.tsv"
    printf '%s\n' "$ARMS_TERMS_HEADER" > "$scratch/arms-terms.tsv"
    PARITY_OUT="$out/arms-parity.tsv"
    printf '%s\n' "$ARMS_PARITY_HEADER" > "$PARITY_OUT"
    do_arms_run "$MR_REPO" mr "ctrl-$MR_PIN" "$script" "$L/ctrl-$MR_PIN" "$scratch"
    do_arms_run "$MR_REPO" mr mr-code30 "$script" "$L/mr-code30" "$scratch"
    do_arms_run "$SB_REPO" sb sb-code30 "$script" "$L/sb-code30" "$scratch"
    awk -F'\t' 'FNR > 1 { n[$1]++; e[$1] += $6 }
        END { for (s in n) printf "%s\tequal %d\tdifferent %d\n", s, e[s], n[s] - e[s] }' "$PARITY_OUT"
}

case "${1:-}" in
    parity)  shift; do_arms_parity "$@" ;;
    list)    shift; do_arms_list "$@" ;;
    run)     shift; do_arms_run "$@" ;;
    summary) shift; do_arms_summary "$@" ;;
    all)     shift; do_arms_all "$@" ;;
    *) sed -n '2,14p' "$0"; exit 2 ;;
esac
