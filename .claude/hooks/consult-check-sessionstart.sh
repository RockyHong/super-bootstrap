#!/usr/bin/env bash
# FROZEN consult-check-sessionstart v1
# SessionStart hook — consult-check catalog derivation (grouped render).
# Derives the compact doc catalog that consult-check-check.sh injects, once per
# session boundary (startup|resume|clear|compact — default matcher), so the
# per-prompt injector stays a pure read. Staleness tolerance = one session.
#
# Source (curated-signal constraint — bench + findings: repo-root
# bench/consult-hook/) — project docs/**/*.md, recursive, with superpowers/ +
# work/ excluded (specs|plans|cards are work-tracking, not consult targets —
# pipeline convention, not name guessing; work/ is the post-rename home of the
# same substrate). A repo that renames its temporal home declares it in
# .claude/consult-exclude — one find -path glob per line (e.g. */drafts/*),
# # comments allowed — instead of this list accreting per-repo names.
# Undeclared temporal dirs stay listed, the forced YES/NO judges them.
#
# Device/personal lore trees are deliberately NOT sourced. Lore reaches
# readers through its own doors — path-scoped rules and the harness-edit
# skills at their fire moments. Listing it here as well cost a measured fixed
# 943 chars of every consumer's budget — 62-72% of the render — against the
# 49-200 chars of project docs this bundle exists to surface.
#
# Catalog = grouped stems, one line per directory: "- <dir>/: stem, stem, …",
# where <dir> is the repo-relative path itself — one row, one path, no guessing
# at the prompt moment. Every stem is kept — stems are the measured recall
# carrier (why-text is not load-bearing). Grouping only removes repeated path
# prefixes + per-line overhead, so nested docs fit the budget that per-line
# rendering blew.
#
# Budget: whole injected block <= ~500 tok (pre-registered bench gate). List
# capped at 1700 chars; an overflowing group line is truncated to the stems
# that fit plus a "+N more" tail — reachability never silently vanishes. That
# tail is reserved inside the fill loop; the dropped-groups tail is written
# after it, so the fill runs twice when that tail appears, reserving its width.
#
# No stdout — this hook only writes the cache; injection is the check slot's
# per-prompt job. Defensive exits are silent: a failed derivation is a missing
# catalog, not a broken session.
set +e

ROOT="${CLAUDE_PROJECT_DIR:-$PWD}"
CACHE="$ROOT/.claude/.consult-catalog"
[ -d "$ROOT/.claude" ] || exit 0

# Built-in exclusions = pipeline-convention work-tracking homes; per-repo
# temporal-dir names come from .claude/consult-exclude (header § Sources).
excl=( ! -path '*/superpowers/*' ! -path '*/docs/work/*' )
if [ -f "$ROOT/.claude/consult-exclude" ]; then
  while IFS= read -r glob || [ -n "$glob" ]; do
    glob="${glob%$'\r'}"
    case "$glob" in ''|\#*) continue ;; esac
    excl+=( ! -path "$glob" )
  done < "$ROOT/.claude/consult-exclude"
fi

# Rows stay repo-relative, so each one resolves exactly one way at the prompt
# moment and the injector needs no path fallback.
paths="$(find "$ROOT/docs" -name '*.md' "${excl[@]}" 2>/dev/null | sed "s|^$ROOT/||" | sort)"

# Group by directory at docs/'s first subdir level, so the group key resolves as
# a repo-relative path.
lines="$(awk '
  {
    p=$0; sub(/\.md$/, "", p); rest=substr(p, 6)
    if (rest ~ /\//) { split(rest, a, "/"); key="docs/" a[1] "/"; stem=substr(rest, length(a[1]) + 2) }
    else             { key="docs/"; stem=rest }
    if (!(key in g)) order[++n]=key
    g[key] = (g[key] == "" ? "" : g[key] ", ") stem
  }
  END { for (i=1; i<=n; i++) { k=order[i]; printf "- %s: %s\n", k, g[k] } }
' <<<"$paths")"

# Fill the list to a budget, leaving the result in $out/$used/$dropped. The
# dropped-groups tail below is appended after the loop with no width of its own
# in `used`, so its room must come off the budget — but only in the runs that
# write it. Reserving unconditionally instead costs list capacity in every run
# that truncates without dropping, i.e. the consumers nearest the cap. So: fill
# once to learn whether the tail appears, refill with its width reserved when it
# does. A smaller budget never drops fewer groups, so the second pass still
# writes the tail it reserved for.
fill() {
  local budget=$1 line n avail head total kept
  out=""
  used=0
  dropped=0
  while IFS= read -r line; do
    [ -n "$line" ] || continue
    n=$(( ${#line} + 1 ))
    if [ $(( used + n )) -le "$budget" ]; then
      out+="$line"$'\n'
      used=$(( used + n ))
      continue
    fi
    # Group line overflows: keep the stems that fit, name the remainder.
    avail=$(( budget - used - 40 ))  # room for the "+N more" tail
    if [ "$avail" -lt 60 ]; then dropped=$(( dropped + 1 )); continue; fi
    head="${line:0:$avail}"
    head="${head%,*}"
    total=$(awk -F', ' '{print NF}' <<<"$line")
    kept=$(awk -F', ' '{print NF}' <<<"$head")
    out+="$head, +$(( total - kept )) more — Glob the dir"$'\n'
    used=$budget
  done <<<"$lines"
}

fill 1700
# 100 covers the tail's 95 bytes plus its newline and the count's digits.
[ "$dropped" -gt 0 ] && fill $(( 1700 - 100 ))
[ "$dropped" -gt 0 ] && out+="- (+$dropped more doc groups over token budget — Glob the trees above if none of the listed docs fit)"$'\n'

printf '%s' "$out" > "$CACHE"
exit 0
