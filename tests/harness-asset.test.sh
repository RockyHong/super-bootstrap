#!/usr/bin/env bash
# Shape pin for the plugin-owned harness asset (`harness.md`, placed at
# `.claude/rules/harness.md` in a consumer) and the mixed-ownership files around it.
# RED until the ownership split lands; see docs/work/DEBT-ymdg.md § Plan.
#
# Asserts, against the assets dir A:
#   1. A/harness.md exists, non-empty
#   2. no frontmatter (first line is not ---)
#   3. no {…} placeholder / fill-in token outside fenced code
#   4. every relative link resolves, from .claude/rules/, to docs/**, CODING_STANDARDS.md,
#      CLAUDE.md, README.md or .claude/rules/*.md
#   5. claude-md-skeleton.md's `## ` heading set is exactly the project set
#   6. no heading is a `## ` heading in both harness.md and claude-md-skeleton.md
#   7. techstack / overview / work-readme skeletons do not link CLAUDE.md#anchor
#
# Usage: bash tests/harness-asset.test.sh
#        HARNESS_ASSET_DIR=<dir> bash tests/harness-asset.test.sh   # fixture run
set -u

REPO="$(cd "$(dirname "$0")/.." && pwd)"
A="${HARNESS_ASSET_DIR:-$REPO/plugins/super-bootstrap/skills/harness-bootstrap/assets}"
HARNESS="$A/harness.md"
SKEL="$A/claude-md-skeleton.md"

# The project-owned CLAUDE.md heading set (read off the skeleton as of 2026-11-19).
PROJECT_HEADINGS='Tech Stack
Commands
Rules (auto-load on file match)
Planning
Monorepo — Cross-Package Build Pre-flight'

pass=0; fail=0
ok()  { pass=$((pass+1)); echo "  ok: $1"; }
bad() { fail=$((fail+1)); echo "  FAIL: $1"; }

# Quirk: a checkout with CRLF endings would leave \r on every line; strip it on read.
# nofence <file> : print "<lineno>:<line>" for every line outside fenced code blocks.
nofence() {
  tr -d '\r' < "$1" | awk '
    /^[ \t]*```/ { f = !f; next }
    !f { print NR ":" $0 }'
}

# headings <file> : the `## ` heading texts outside fences. A conditional `{## …}` block
# counts by its heading text. One per line.
headings() {
  nofence "$1" | sed -n -e 's/^[0-9]*:{\{0,1\}## \(.*\)$/\1/p' | sed -e 's/}[ \t]*$//' -e 's/[ \t]*$//'
}

echo "== 1. harness.md exists and is non-empty =="
if [ -s "$HARNESS" ]; then ok "harness.md present"; else bad "$HARNESS missing or empty"; fi

if [ -s "$HARNESS" ]; then
  echo "== 2. no frontmatter =="
  first=$(head -n 1 "$HARNESS" | tr -d '\r')
  if [ "$first" = "---" ]; then bad "harness.md:1 starts with --- (frontmatter)"; else ok "no frontmatter"; fi

  echo "== 3. no placeholder tokens =="
  # Inline code spans are blanked first so `${VAR}` and `{a,b}` examples do not trip it.
  hits=$(nofence "$HARNESS" | sed -e 's/`[^`]*`//g' | grep -E '^[0-9]+:.*\{[^}]*\}' || true)
  if [ -n "$hits" ]; then
    while IFS= read -r l; do bad "harness.md:${l%%:*} placeholder token: ${l#*:}"; done <<<"$hits"
  else ok "no placeholders"; fi

  echo "== 4. links resolve from .claude/rules/ into the allowed set =="
  nlinks=0; badlinks=0
  while IFS= read -r l; do
    ln="${l%%:*}"; body="${l#*:}"
    # one link target per output line; link text containing ]( is not handled
    while IFS= read -r raw; do
      [ -n "$raw" ] || continue
      t="${raw#\](}"; t="${t%)}"; t="${t%% *}"; t="${t%%#*}"
      case "$t" in ''|http:*|https:*|mailto:*) continue ;; esac
      nlinks=$((nlinks+1))
      # normalize: start at .claude/rules, apply segments
      set -f; IFS=/ read -r -a segs <<<"$t"; set +f
      stack=(.claude rules); escaped=0
      for s in "${segs[@]}"; do
        case "$s" in
          ''|.) ;;
          ..) if [ ${#stack[@]} -eq 0 ]; then escaped=1; break; fi
              unset 'stack[${#stack[@]}-1]'; stack=("${stack[@]}") ;;
          *) stack+=("$s") ;;
        esac
      done
      if [ $escaped -eq 1 ]; then
        bad "harness.md:$ln link '$t' escapes the repo root"; badlinks=$((badlinks+1)); continue
      fi
      res=$(IFS=/; echo "${stack[*]:-}")
      case "$res" in
        docs|docs/*|CODING_STANDARDS.md|CLAUDE.md|README.md) ;;
        .claude/rules/*.md) case "${res#.claude/rules/}" in */*) res="!" ;; esac ;;
        *) res="!" ;;
      esac
      if [ "$res" = "!" ]; then
        bad "harness.md:$ln link '$t' resolves to '$(IFS=/; echo "${stack[*]:-}")' (outside docs/**, CODING_STANDARDS.md, CLAUDE.md, README.md, .claude/rules/*.md)"
        badlinks=$((badlinks+1))
      fi
    done < <(printf '%s\n' "$body" | grep -oE '\]\([^)]*\)')
  done < <(nofence "$HARNESS" | grep -E '^[0-9]+:.*\]\(' || true)
  [ $badlinks -eq 0 ] && ok "$nlinks link(s) resolve into the allowed set"
fi

echo "== 5. claude-md-skeleton.md heading set is the project set =="
if [ -s "$SKEL" ]; then
  got=$(headings "$SKEL")
  extra=0
  while IFS= read -r h; do
    [ -n "$h" ] || continue
    if ! grep -qxF -- "$h" <<<"$PROJECT_HEADINGS"; then
      bad "claude-md-skeleton.md has non-project heading: ## $h"; extra=1
    fi
  done <<<"$got"
  while IFS= read -r h; do
    if ! grep -qxF -- "$h" <<<"$got"; then bad "claude-md-skeleton.md lacks project heading: ## $h"; extra=1; fi
  done <<<"$PROJECT_HEADINGS"
  [ $extra -eq 0 ] && ok "heading set equals project set"
else
  bad "$SKEL missing or empty"
fi

echo "== 6. no heading owned by both files =="
if [ -s "$HARNESS" ] && [ -s "$SKEL" ]; then
  dup=0
  hh=$(headings "$HARNESS")
  while IFS= read -r h; do
    [ -n "$h" ] || continue
    if grep -qxF -- "$h" <<<"$(headings "$SKEL")"; then bad "heading '## $h' appears in both harness.md and claude-md-skeleton.md"; dup=1; fi
  done <<<"$hh"
  [ $dup -eq 0 ] && ok "headings disjoint"
else
  bad "cannot compare: harness.md or claude-md-skeleton.md missing"
fi

echo "== 7. doc skeletons carry no CLAUDE.md#anchor link =="
for f in techstack-skeleton.md overview-skeleton.md work-readme-skeleton.md; do
  if [ ! -s "$A/$f" ]; then bad "$f missing"; continue; fi
  hits=$(nofence "$A/$f" | grep -E '\]\([^)]*CLAUDE\.md#' || true)
  if [ -n "$hits" ]; then
    while IFS= read -r l; do
      tgt=$(printf '%s\n' "${l#*:}" | grep -oE '\]\([^)]*CLAUDE\.md#[^)]*\)' | tr '\n' ' ')
      bad "$f:${l%%:*} links into CLAUDE.md anchor: $tgt"
    done <<<"$hits"
  else ok "$f clean"; fi
done

echo
echo "harness-asset: $pass passed, $fail failed"
[ "$fail" -eq 0 ]
