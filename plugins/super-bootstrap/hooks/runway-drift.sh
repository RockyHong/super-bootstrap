#!/usr/bin/env bash
# runway-drift v1 (plugin-owned SessionStart advisory)
# Compares four files placed in the consumer repo with the shipped assets by
# content, and when any pair differs prints ONE line routing to the re-run that
# re-syncs them:
#   runway files differ from the shipped assets: <placed paths> — run /super-bootstrap:harness-bootstrap
# On a legacy repo (placed harness.md absent) it prints a different ONE line,
# naming the re-run as the migration:
#   CLAUDE.md holds the plugin's workflow sections in the pre-split shape — run /super-bootstrap:harness-bootstrap to migrate them into .claude/rules/harness.md
#
#   placed (under $CLAUDE_PROJECT_DIR)             shipped (under $CLAUDE_PLUGIN_ROOT/skills/harness-bootstrap/assets/)
#   .claude/rules/harness.md                       harness.md
#   .claude/hooks/commit-channel.sh                hooks/commit-channel.sh
#   .claude/hooks/consult-check-sessionstart.sh    hooks/consult-check-sessionstart.sh
#   .claude/hooks/consult-check-check.sh           hooks/consult-check-check.sh
#
# No version is read and no hash is stored: the placed file is a verbatim copy of
# the asset (hooks-ensure-infra.md: scripts are copied, never templated), so
# content equality is the whole signal. Plugin-owned, not placed — hooks/hooks.json
# runs this from ${CLAUDE_PLUGIN_ROOT}, so it updates with the plugin.
#
# Gate: placed .claude/rules/harness.md absent -> no pair is compared. Legacy =
# CLAUDE.md exists and at least TWO of its lines each equal (CR stripped, whole
# line, literal) a `## ` line of the shipped harness.md asset -> the migration line
# above. Two, not one: a generic heading like `## Git Notes` alone would fire on a
# hand-written repo. Owned headings are read from the asset at run time, no list
# here. Any other absent-harness state (no CLAUDE.md, <2 owned headings, asset
# missing) is silent. A pair is compared only when both sides exist. Every failure
# path is silent: exit 0, no output. Never a JSON
# `decision` — a SessionStart hook's plain stdout on exit 0 reaches the session
# context; the model relays it.
#
# Comparison ignores CR (CRLF checkout vs LF asset). Files are read with
# `$(<file)` — a bash builtin, no fork — and CR stripped by parameter expansion,
# because this fires at every session start. Command substitution also drops
# trailing newlines, so a pair differing only in trailing newlines compares equal
# (accepted: harmless drift, and the re-run copies whole files anyway).
#
# Dialect: POSIX-style bash 3.2-safe, no jq, no awk, no per-file subprocess.
set +e

[ -n "${CLAUDE_PLUGIN_ROOT:-}" ] || exit 0
ROOT="${CLAUDE_PROJECT_DIR:-$PWD}"
ASSETS="$CLAUDE_PLUGIN_ROOT/skills/harness-bootstrap/assets"
CR=$'\r'

if [ ! -f "$ROOT/.claude/rules/harness.md" ]; then
  [ -f "$ROOT/CLAUDE.md" ] && [ -f "$ASSETS/harness.md" ] || exit 0
  md="$(<"$ROOT/CLAUDE.md")" 2>/dev/null || exit 0
  shipped="$(<"$ASSETS/harness.md")" 2>/dev/null || exit 0
  md="${md//$CR/}"
  shipped="${shipped//$CR/}"
  # owned = newline-delimited `## ` lines of the asset; matched below as a quoted
  # (literal) substring, so `—`, `&`, `(`, `)` in headings are never pattern chars.
  owned=$'\n'
  while IFS= read -r line; do
    case "$line" in "## "*) owned="$owned$line"$'\n' ;; esac
  done <<<"$shipped"
  hits=0
  while IFS= read -r line; do
    case "$line" in
      "## "*) case "$owned" in *$'\n'"$line"$'\n'*) hits=$((hits+1)) ;; esac ;;
    esac
  done <<<"$md"
  [ "$hits" -ge 2 ] || exit 0
  printf '%s\n' "CLAUDE.md holds the plugin's workflow sections in the pre-split shape — run /super-bootstrap:harness-bootstrap to migrate them into .claude/rules/harness.md"
  exit 0
fi
drift=""
# <placed relative path>|<shipped relative path>; paths carry no '|' by construction.
for pair in \
  ".claude/rules/harness.md|harness.md" \
  ".claude/hooks/commit-channel.sh|hooks/commit-channel.sh" \
  ".claude/hooks/consult-check-sessionstart.sh|hooks/consult-check-sessionstart.sh" \
  ".claude/hooks/consult-check-check.sh|hooks/consult-check-check.sh"
do
  placed_rel="${pair%%|*}"
  shipped_rel="${pair#*|}"
  [ -f "$ROOT/$placed_rel" ] && [ -f "$ASSETS/$shipped_rel" ] || continue
  a="$(<"$ROOT/$placed_rel")" 2>/dev/null || continue
  b="$(<"$ASSETS/$shipped_rel")" 2>/dev/null || continue
  a="${a//$CR/}"
  b="${b//$CR/}"
  [ "$a" = "$b" ] || drift="${drift:+$drift, }$placed_rel"
done

[ -n "$drift" ] || exit 0
printf '%s\n' "runway files differ from the shipped assets: $drift — run /super-bootstrap:harness-bootstrap"
exit 0
