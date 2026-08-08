#!/bin/bash
# SessionStart hook — consult-check catalog derivation (GAP-045 build; GAP-052
# grouped render). Derives the compact doc catalog that consult-check-check.sh
# injects, once per session boundary (startup|resume|clear|compact — default
# matcher), so the per-prompt injector stays a pure read. Staleness tolerance =
# one session.
#
# Sources (curated-signal constraint, bench/FINDINGS-gap045.md § What the build
# inherits):
#   1. project docs/**/*.md — recursive; superpowers/ + work/ excluded
#      (specs|plans|cards are work-tracking, not consult targets — pipeline
#      convention, not name guessing; work/ is the post-rename home of the same
#      substrate). A repo that renames its temporal home declares it in
#      .claude/consult-exclude — one find -path glob per line (e.g. */drafts/*),
#      # comments allowed — instead of this list accreting per-repo names.
#      Undeclared temporal dirs stay listed, the forced YES/NO judges them.
#   2. project .claude/guidelines/**/*.md
#   3. device plant ~/.claude/guidelines/**/*.md (absent on cloud — degrades
#      gracefully to project-only)
# index.md files excluded (navigation — the catalog replaces them). Dedup by
# path-under-guidelines/ (the source repo holds source + device-plant copies
# of the same files; consumers' subtrees are channel-disjoint, no-op there).
#
# Catalog = grouped stems, one line per directory: "- <dir>/: stem, stem, …".
# Every stem is kept — stems are the measured recall carrier (why-text is not
# load-bearing; bench § forcedeval-compact). Grouping only removes repeated
# path prefixes + per-line overhead, so nested project docs fit the same
# budget that per-line rendering blew (GAP-052: nested docs were invisible,
# lore filled the list).
#
# Budget: whole injected block <= ~500 tok (pre-registered gate 4). List capped
# at 1700 chars; an overflowing group line is truncated to the stems that fit
# plus a "+N more" tail — reachability never silently vanishes.
#
# No stdout — this hook only writes the cache; injection is the check slot's
# per-prompt job. Defensive exits are silent: a failed derivation is a missing
# catalog, not a broken session.
set +e

ROOT="${CLAUDE_PROJECT_DIR:-$PWD}"
CACHE="$ROOT/.claude/.consult-catalog"
[ -d "$ROOT/.claude" ] || exit 0

HOME_DIR="${HOME:-$USERPROFILE}"

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

paths="$(
  find "$ROOT/docs" -name '*.md' "${excl[@]}" 2>/dev/null | sed "s|^$ROOT/||" | sort
  find "$ROOT/.claude/guidelines" -name '*.md' ! -name 'index.md' 2>/dev/null | sort
  find "$HOME_DIR/.claude/guidelines" -name '*.md' ! -name 'index.md' 2>/dev/null | sort
)"

# Guidelines rows collapse to their stem after "guidelines/"; the stem doubles
# as the dedup key, so source and device-plant copies of the same file merge
# (project emitted first → project copy wins).
paths="$(awk '{ i=index($0,"guidelines/"); if (i) $0=substr($0,i+11); if (!seen[$0]++) print }' <<<"$paths")"

# Group by directory: docs/ groups at its first subdir level; guideline stems
# group by tree (root-level guideline files land under "guidelines/"). Known
# trees carry a short hint to sharpen the group line's YES/NO.
lines="$(awk '
  {
    p=$0; sub(/\.md$/, "", p)
    if (p ~ /^docs\//) {
      rest=substr(p, 6)
      if (rest ~ /\//) { split(rest, a, "/"); key="docs/" a[1] "/"; stem=substr(rest, length(a[1]) + 2) }
      else             { key="docs/"; stem=rest }
    } else {
      if (p ~ /\//)    { split(p, a, "/"); key=a[1] "/"; stem=substr(p, length(a[1]) + 2) }
      else             { key="guidelines/"; stem=p }
    }
    if (!(key in g)) order[++n]=key
    g[key] = (g[key] == "" ? "" : g[key] ", ") stem
  }
  END {
    hint["work-discipline/"]=" (Claude-at-work discipline)"
    hint["axiom-principles/"]=" (harness-design lore)"
    hint["claude-shape/"]=" (Claude-Code current-shape facts)"
    for (i=1; i<=n; i++) { k=order[i]; printf "- %s%s: %s\n", k, hint[k], g[k] }
  }
' <<<"$paths")"

budget=1700
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
[ "$dropped" -gt 0 ] && out+="- (+$dropped more doc groups over token budget — Glob the trees above if none of the listed docs fit)"$'\n'

printf '%s' "$out" > "$CACHE"
exit 0
