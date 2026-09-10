#!/usr/bin/env bash
# L1 unit tests for runway-version.sh: the plugin-owned SessionStart advisory that
# compares the consumer's runway receipt `version` against the installed plugin's
# `plugin.json` `version`. Zero session dependency: the hook's two inputs are
# resolved from CLAUDE_PROJECT_DIR + CLAUDE_PLUGIN_ROOT, so each case points them
# at fixture dirs this file writes under a temp root.
# Targets the PLUGIN-OWNED hook under plugins/super-bootstrap/hooks/ — there is
# no placed copy; the hook runs from the installed plugin tree.
#
# Usage: bash tests/runway-version.test.sh
set -u

REPO="$(cd "$(dirname "$0")/.." && pwd)"
HOOKS="$REPO/plugins/super-bootstrap/hooks"
HOOK="$HOOKS/runway-version.sh"
MANIFEST="$HOOKS/hooks.json"

T="$(mktemp -d "${TMPDIR:-/tmp}/runway-version.XXXXXX")"
trap 'rm -rf "$T"' EXIT

pass=0; fail=0
ok()   { pass=$((pass+1)); echo "  ok: $1"; }
bad()  { fail=$((fail+1)); echo "  FAIL: $1"; }
check() { # check <desc> <expr...>
  local desc="$1"; shift
  if "$@"; then ok "$desc"; else bad "$desc"; fi
}

# Fixture writers. Each case gets its own project + plugin dir so no state leaks.
mk_project() { # <name> [receipt-body] ; no body -> no receipt file
  local dir="$T/$1"
  mkdir -p "$dir/.claude"
  [ $# -ge 2 ] && printf '%s\n' "$2" > "$dir/.claude/super-bootstrap-runway.json"
  printf '%s' "$dir"
}
mk_plugin() { # <name> [manifest-body] ; no body -> no plugin.json
  local dir="$T/$1"
  mkdir -p "$dir/.claude-plugin"
  [ $# -ge 2 ] && printf '%s\n' "$2" > "$dir/.claude-plugin/plugin.json"
  printf '%s' "$dir"
}
receipt()  { printf '{\n  "version": "%s",\n  "covered": ["CLAUDE.md § Planning"],\n  "declined": [],\n  "placed": {}\n}' "$1"; }
manifest() { printf '{\n  "name": "super-bootstrap",\n  "description": "runway version stamp reader",\n  "version": "%s"\n}' "$1"; }

# run_hook <project-dir> <plugin-dir|-> ; sets out + rc. `-` leaves
# CLAUDE_PLUGIN_ROOT unset (a hook spawned outside plugin scope).
run_hook() {
  if [ "$2" = "-" ]; then
    out=$(env -u CLAUDE_PLUGIN_ROOT CLAUDE_PROJECT_DIR="$1" bash "$HOOK" 2>/dev/null); rc=$?
  else
    out=$(CLAUDE_PROJECT_DIR="$1" CLAUDE_PLUGIN_ROOT="$2" bash "$HOOK" 2>/dev/null); rc=$?
  fi
}
silent() { [ "$rc" -eq 0 ] && [ -z "$out" ]; }
no_decision() { ! grep -q '"decision"' <<<"$out"; }
lines()  { [ -z "$out" ] && echo 0 || printf '%s\n' "$out" | wc -l | tr -d ' '; }

echo "== runway-version: receipt older than plugin -> one advisory line, exit 0 =="
p=$(mk_project p-old "$(receipt 2.39.0)"); g=$(mk_plugin g-new "$(manifest 2.49.0)")
run_hook "$p" "$g"
check "exit 0" [ "$rc" -eq 0 ]
check "exactly one stdout line" [ "$(lines)" = "1" ]
check "advisory text names both versions and routes to the bundled skill" \
  [ "$out" = "runway stamped v2.39.0 < plugin v2.49.0 — run /super-bootstrap:harness-bootstrap" ]
check "no JSON decision field on the channel" no_decision

echo "== runway-version: receipt equal -> silent =="
p=$(mk_project p-eq "$(receipt 2.49.0)"); g=$(mk_plugin g-eq "$(manifest 2.49.0)")
run_hook "$p" "$g"
check "equal versions -> no output, exit 0" silent

echo "== runway-version: receipt newer (dev repo ahead of the installed plugin) -> silent =="
p=$(mk_project p-ahead "$(receipt 2.50.0)"); g=$(mk_plugin g-behind "$(manifest 2.49.1)")
run_hook "$p" "$g"
check "receipt newer than plugin -> no output, exit 0" silent

echo "== runway-version: receipt absent (non-bootstrapped repo) -> silent =="
p=$(mk_project p-none); g=$(mk_plugin g-any "$(manifest 2.49.1)")
run_hook "$p" "$g"
check "no receipt -> no output, exit 0" silent

echo "== runway-version: receipt present but unusable -> silent =="
p=$(mk_project p-nover '{ "covered": ["CLAUDE.md § Planning"], "placed": {} }'); g=$(mk_plugin g-nover "$(manifest 2.49.1)")
run_hook "$p" "$g"
check "receipt without a version field -> no output, exit 0" silent

p=$(mk_project p-junk '{ this is not json'); g=$(mk_plugin g-junk "$(manifest 2.49.1)")
run_hook "$p" "$g"
check "malformed receipt JSON -> no output, exit 0" silent

p=$(mk_project p-badver '{ "version": "unknown" }'); g=$(mk_plugin g-badver "$(manifest 2.49.1)")
run_hook "$p" "$g"
check "non-numeric receipt version -> no output, exit 0" silent

p=$(mk_project p-empty ''); g=$(mk_plugin g-empty "$(manifest 2.49.1)")
run_hook "$p" "$g"
check "empty receipt file -> no output, exit 0" silent

echo "== runway-version: plugin.json unreadable -> silent =="
p=$(mk_project p-nomani "$(receipt 2.39.0)"); g=$(mk_plugin g-nomani)
run_hook "$p" "$g"
check "plugin dir without plugin.json -> no output, exit 0" silent

p=$(mk_project p-noroot "$(receipt 2.39.0)")
run_hook "$p" "-"
check "CLAUDE_PLUGIN_ROOT unset -> no output, exit 0" silent

p=$(mk_project p-manijunk "$(receipt 2.39.0)"); g=$(mk_plugin g-manijunk '{ "name": "super-bootstrap", "version": }')
run_hook "$p" "$g"
check "plugin.json without a usable version -> no output, exit 0" silent

echo "== runway-version: dotted-numeric compare, not lexical =="
p=$(mk_project p-patch "$(receipt 2.49.0)"); g=$(mk_plugin g-patch "$(manifest 2.49.1)")
run_hook "$p" "$g"
check "2.49.0 < 2.49.1 (patch bump) -> advisory" \
  [ "$out" = "runway stamped v2.49.0 < plugin v2.49.1 — run /super-bootstrap:harness-bootstrap" ]

p=$(mk_project p-minor "$(receipt 2.9.9)"); g=$(mk_plugin g-minor "$(manifest 2.10.0)")
run_hook "$p" "$g"
check "2.9.9 < 2.10.0 (numeric, where lexical says otherwise) -> advisory" \
  [ "$out" = "runway stamped v2.9.9 < plugin v2.10.0 — run /super-bootstrap:harness-bootstrap" ]

p=$(mk_project p-minor-rev "$(receipt 2.10.0)"); g=$(mk_plugin g-minor-rev "$(manifest 2.9.9)")
run_hook "$p" "$g"
check "2.10.0 vs 2.9.9 (receipt ahead, lexical says behind) -> silent" silent

p=$(mk_project p-short "$(receipt 2.49)"); g=$(mk_plugin g-short "$(manifest 2.49.0)")
run_hook "$p" "$g"
check "2.49 vs 2.49.0 (missing component reads as 0) -> silent" silent

p=$(mk_project p-minified '{"version":"2.39.0","covered":[],"placed":{}}'); g=$(mk_plugin g-minified '{"name":"super-bootstrap","version":"2.49.0"}')
run_hook "$p" "$g"
check "minified one-line JSON on both sides -> advisory" \
  [ "$out" = "runway stamped v2.39.0 < plugin v2.49.0 — run /super-bootstrap:harness-bootstrap" ]

echo "== runway-version: hooks.json manifest wires the script at every session boundary =="
check "hooks.json present" [ -f "$MANIFEST" ]
event_count=$(jq -r '.hooks.SessionStart | length' "$MANIFEST" 2>/dev/null)
check "one SessionStart entry" [ "$event_count" = "1" ]
matcher=$(jq -r '.hooks.SessionStart[0].matcher' "$MANIFEST" 2>/dev/null)
check "matcher re-fires after every context reset" [ "$matcher" = "startup|resume|clear|compact" ]
cmd=$(jq -r '.hooks.SessionStart[0].hooks[0].command' "$MANIFEST" 2>/dev/null)
check "command runs the script from the installed plugin root" \
  [ "$cmd" = 'bash "${CLAUDE_PLUGIN_ROOT}/hooks/runway-version.sh"' ]
htype=$(jq -r '.hooks.SessionStart[0].hooks[0].type' "$MANIFEST" 2>/dev/null)
check "hook element is a command hook" [ "$htype" = "command" ]

echo
echo "RESULT: $pass passed, $fail failed"
[ "$fail" -eq 0 ]
