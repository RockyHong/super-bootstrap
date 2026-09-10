#!/usr/bin/env bash
# runway-version v1 (plugin-owned SessionStart advisory)
# Compares the consumer's runway receipt `version` against the installed plugin's
# own `plugin.json` `version` and, only when the receipt lags, prints one line
# routing to the re-run that re-syncs the placed hooks + snippets:
#   runway stamped v{old} < plugin v{new} — run /super-bootstrap:harness-bootstrap
#
# Plugin-owned, not placed: hooks/hooks.json runs this from
# ${CLAUDE_PLUGIN_ROOT}, so the script updates with plugin autoUpdate and the
# version it reads is the loaded plugin's by construction — the same anchor
# harness-bootstrap SKILL.md § Version-staleness signal uses (plugin.json at the
# plugin root). No registry lookup, no cache-dir scan.
#
# Inputs — both resolved from the hook environment, no session dependency:
#   $CLAUDE_PROJECT_DIR/.claude/super-bootstrap-runway.json  -> "version"
#   ${CLAUDE_PLUGIN_ROOT}/.claude-plugin/plugin.json          -> "version"
#
# Compare: dotted-numeric, component by component (2.9.9 < 2.10.0; a missing
# component reads as 0). Equal or receipt-ahead (a dev checkout newer than the
# installed plugin) stays silent.
#
# Silence on every failure path: no receipt (a repo this plugin never
# bootstrapped — this hook spawns in every repo where the plugin is enabled),
# no plugin root, unreadable manifest, missing or non-numeric version on either
# side → exit 0 with no output. Never a JSON `decision` — a SessionStart hook's
# plain stdout on exit 0 reaches the session context; the model relays it.
#
# Dialect: POSIX bash + portable awk (no interval expressions, [ \t] classes),
# no jq — consumer runtimes carry neither guarantee.
set +e

ROOT="${CLAUDE_PROJECT_DIR:-$PWD}"
RECEIPT="$ROOT/.claude/super-bootstrap-runway.json"
[ -n "${CLAUDE_PLUGIN_ROOT:-}" ] || exit 0
MANIFEST="$CLAUDE_PLUGIN_ROOT/.claude-plugin/plugin.json"
[ -s "$RECEIPT" ] && [ -s "$MANIFEST" ] || exit 0

# version_of <json-file> -> prints the first `"version": "<dotted-numeric>"`
# value, or nothing. Works on pretty-printed and minified JSON alike: the key
# match is a regex over each input line, so a one-line document still yields
# the first occurrence. Anything but digits-and-dots inside the quotes is
# treated as no version.
version_of() {
  awk '
    match($0, /"version"[ \t]*:[ \t]*"[0-9][0-9.]*"/) {
      s = substr($0, RSTART, RLENGTH)
      sub(/^"version"[ \t]*:[ \t]*"/, "", s)
      sub(/"$/, "", s)
      print s
      exit
    }
  ' "$1" 2>/dev/null
}

old="$(version_of "$RECEIPT")"
new="$(version_of "$MANIFEST")"
[ -n "$old" ] && [ -n "$new" ] || exit 0

# older_than <a> <b> -> prints 1 when a < b numerically per dotted component.
older_than() {
  awk -v a="$1" -v b="$2" '
    BEGIN {
      na = split(a, x, "."); nb = split(b, y, ".")
      n = (na > nb) ? na : nb
      for (i = 1; i <= n; i++) {
        p = (i <= na) ? x[i] + 0 : 0
        q = (i <= nb) ? y[i] + 0 : 0
        if (p < q) { print 1; exit }
        if (p > q) { print 0; exit }
      }
      print 0
    }
  '
}

[ "$(older_than "$old" "$new")" = "1" ] || exit 0

printf '%s\n' "runway stamped v$old < plugin v$new — run /super-bootstrap:harness-bootstrap"
exit 0
