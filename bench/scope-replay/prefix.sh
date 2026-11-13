#!/usr/bin/env bash
# Pre-fix replay: does the grep lane still reach a stale doc the door once caught?
# For each case the doc surface is the fix commit's parent (`*.md`, plus `.claude/doc-surface`
# when tracked), with the docs edited before the gate overlaid at the code commit's version.
# `terms - | hits -` (base) and `grep-scope -` (new) run over the code commit's gate paths
# off the doc surface plus those pre-gate docs. Read-only on both repos (git objects only).
#
#   prefix.sh <cases.tsv> <out.tsv>      needs SB_REPO and MR_REPO; NOPRE=1 drops the
#                                        pre-gate docs (non-doc paths only)
# cases.tsv: run_id repo lane_type tag code_sha fix_sha stale_doc pre-gate-docs(comma|-) note
#            code_sha `-` marks an excluded row.
# Verdict: kept = base and new reach the stale doc; lost = base only; not-grep = base
# does not. `other_lane` prints `?`; results/prefix-catches.tsv carries it joined by hand.
#
# Lesson: doc-links.sh output needs `tr -d ''` before `grep -xF` on Git Bash.
set -uo pipefail
: "${SB_REPO:?}"; : "${MR_REPO:?}"
: "${REPLAY_DIR:=${TMPDIR:-/tmp}/scope-replay}"
S="$REPLAY_DIR/prefix"; mkdir -p "$S"
MR="$MR_REPO"
SB="$SB_REPO"
SCRIPT="${DOCLINKS:-$SB/plugins/super-bootstrap/skills/commit/assets/doc-links.sh}"
g() { local r="$1"; shift; git --no-optional-locks -C "$r" -c core.quotePath=false -c core.autocrlf=false "$@"; }
is_gate_exempt() { case "$1" in docs/work/*|docs/outward/OUT-*.md) return 0 ;; esac; return 1; }

# Whole *.md set of <sha> (+ .claude/doc-surface when tracked) under $S/tree/<label>/<sha>.
materialize() {
    local repo="$1" label="$2" sha="$3"
    TREE="$S/tree/$label/$sha"
    [ -f "$TREE.done" ] && return 0
    mkdir -p "$TREE"
    local -a spec=(':(glob)**/*.md')
    g "$repo" cat-file -e "$sha:.claude/doc-surface" 2>/dev/null && spec+=('.claude/doc-surface')
    g "$repo" archive --format=tar "$sha" -- "${spec[@]}" | tar -xf - -C "$TREE"
    : > "$TREE.done"
}

cases="$1"; out="$2"
printf 'run_id\trepo\tlane_type\ttag\tcode_sha\tfix_sha\tstale_doc\tchanged_list_basis\tbase_reaches\tbase_scope\tnew_reaches\tnew_scope\tdemoted_terms\tverdict\tother_lane\tnote\n' > "$out"
while IFS=$'\t' read -r id repo lt tag C F D predocs bnote; do
    [ -z "$id" ] && continue
    case "$id" in \#*) continue ;; esac
    if [ "$C" = "-" ]; then
        printf '%s\t%s\t%s\t%s\t-\t-\t%s\t-\t-\t-\t-\t-\t-\texcluded\t-\t%s\n' "$id" "$repo" "$lt" "$tag" "$D" "$bnote" >> "$out"
        continue
    fi
    R="$MR"; label=mr; [ "$repo" = SB ] && { R="$SB"; label=sb; }
    Cf="$(g "$R" rev-parse "$C")"; Ff="$(g "$R" rev-parse "$F")"; P="$(g "$R" rev-parse "$F^")"
    [ "${NOPRE:-0}" = 1 ] && predocs="-"
    w="$S/out${NOPRE:+.nopre}/$id"; rm -rf "$w"; mkdir -p "$w"
    # Pre-fix surface: F^ docs, then the pre-gate docs overlaid at C's version, in a per-case copy.
    materialize "$R" "$label" "$P"
    T="$w/tree"; mkdir -p "$T"; cp -r "$TREE/." "$T/"
    g "$R" diff --name-only "$Cf^" "$Cf" > "$w/changed"
    : > "$w/list"
    while IFS= read -r p; do
        is_gate_exempt "$p" && continue
        printf '%s\n' "$p"
    done < "$w/changed" > "$w/gate"
    # doc-surface class by path shape at the pre-fix tree
    (cd "$T" && bash "$SCRIPT" self - < "$w/gate" | tr -d '\r') > "$w/gate.self"
    awk '/^docs\/.*\.md$/ || $0 == "README.md" || /^plugins\/[^\/]+\/README\.md$/' "$w/gate" | sort -u - "$w/gate.self" > "$w/gate.docs"
    grep -vxF -f "$w/gate.docs" "$w/gate" > "$w/list" || true
    : > "$w/predocs"
    if [ "$predocs" != "-" ]; then
        tr ',' '\n' <<< "$predocs" | while IFS= read -r p; do
            [ -z "$p" ] && continue
            [ "$p" = "$D" ] && continue
            if g "$R" cat-file -e "$Cf:$p" 2>/dev/null; then
                mkdir -p "$T/$(dirname "$p")"; g "$R" show "$Cf:$p" > "$T/$p"
            fi
            printf '%s\n' "$p"
        done > "$w/predocs"
        cat "$w/predocs" >> "$w/list"
    fi
    (
        cd "$T" || exit 1
        bash "$SCRIPT" terms - < "$w/list" | tr -d '\r' > "$w/terms"
        : > "$w/base"; : > "$w/base.byterm"
        if [ -s "$w/terms" ]; then
            bash "$SCRIPT" hits - < "$w/terms" | tr -d '\r' > "$w/base"
            bash "$SCRIPT" hits --by-term - < "$w/terms" | tr -d '\r' > "$w/base.byterm"
        fi
        GIT_OPTIONAL_LOCKS=0 DOCLINK_DIFF_REPO="$R" DOCLINK_DIFF_RANGE="$Cf^ $Cf" bash "$SCRIPT" grep-scope - < "$w/list" | tr -d '\r' > "$w/new"
        GIT_OPTIONAL_LOCKS=0 DOCLINK_DIFF_REPO="$R" DOCLINK_DIFF_RANGE="$Cf^ $Cf" bash "$SCRIPT" grep-scope --by-term - < "$w/list" | tr -d '\r' > "$w/new.byterm"
    )
    br=0; grep -qxF "$D" "$w/base" && br=1
    nr=0; grep -qxF "$D" "$w/new" && nr=1
    bs="$(grep -vxF -f "$w/list" "$w/base" | grep -c . )"
    ns="$(grep -vxF -f "$w/list" "$w/new" | grep -c . )"
    dm="$(awk -F'\t' '$3 == "demoted" { printf "%s%s(%s)", (n++ ? " " : ""), $1, $2 }' "$w/new.byterm")"
    # per-term reach of D at baseline: which head terms hit D on their own
    : > "$w/reach"
    while IFS= read -r t; do
        (cd "$T" && printf '%s\n' "$t" | bash "$SCRIPT" hits - | tr -d '\r') | grep -qxF "$D" && printf '%s\n' "$t" >> "$w/reach"
    done < "$w/terms"
    rt="$(tr '\n' ' ' < "$w/reach")"; rt="${rt% }"
    if [ "$br" = 1 ] && [ "$nr" = 1 ]; then v=kept; elif [ "$br" = 1 ]; then v=lost; else v=not-grep; fi
    basis="non-doc-only"; [ -s "$w/predocs" ] && basis="non-doc+pre-gate-docs($(wc -l < "$w/predocs" | tr -d ' '))"
    printf '%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%d\t%d\t%d\t%d\t%s\t%s\t%s\t%s\n' "$id" "$repo" "$lt" "$tag" "${Cf:0:8}" "${Ff:0:8}" "$D" \
        "$basis" "$br" "$bs" "$nr" "$ns" "${dm:--}" "$v" "?" "terms_reaching_D=[${rt}] n_terms=$(wc -l < "$w/terms" | tr -d ' ') list=$(wc -l < "$w/list" | tr -d ' '); $bnote" >> "$out"
    echo "done $id $v base=$br/$bs new=$nr/$ns demoted=${dm:--} reachD=[$rt]" >&2
done < "$cases"
