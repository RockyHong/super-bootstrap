#!/usr/bin/env bash
# L1 unit tests for runway-drift.sh: the plugin-owned SessionStart advisory that
# compares four placed runway files with the shipped assets by content (CR
# ignored) and prints one line when any pair differs. No version is read.
# Zero session dependency: inputs come from CLAUDE_PROJECT_DIR + CLAUDE_PLUGIN_ROOT,
# so each case points them at fixture dirs written under a temp root.
#
# Usage: bash tests/runway-drift.test.sh
set -u

REPO="$(cd "$(dirname "$0")/.." && pwd)"
HOOKS="$REPO/plugins/super-bootstrap/hooks"
HOOK="${HOOK_UNDER_TEST:-$HOOKS/runway-drift.sh}"
MANIFEST="$HOOKS/hooks.json"

T="$(mktemp -d "${TMPDIR:-/tmp}/runway-drift.XXXXXX")"
trap 'rm -rf "$T"' EXIT

pass=0; fail=0
ok()   { pass=$((pass+1)); echo "  ok: $1"; }
bad()  { fail=$((fail+1)); echo "  FAIL: $1"; }
check() { local desc="$1"; shift; if "$@"; then ok "$desc"; else bad "$desc"; fi }

HOOK_FILES=".claude/hooks/commit-channel.sh .claude/hooks/consult-check-sessionstart.sh .claude/hooks/consult-check-check.sh"

# mk_case <name> -> sets P (project dir) and G (plugin root) with all four pairs equal.
mk_case() {
  P="$T/$1/proj"; G="$T/$1/plugin"
  local A="$G/skills/harness-bootstrap/assets"
  mkdir -p "$P/.claude/rules" "$P/.claude/hooks" "$A/hooks"
  printf 'doctrine line 1\ndoctrine line 2\n' | tee "$P/.claude/rules/harness.md" > "$A/harness.md"
  local n
  for n in commit-channel consult-check-sessionstart consult-check-check; do
    printf '#!/usr/bin/env bash\necho %s\n' "$n" | tee "$P/.claude/hooks/$n.sh" > "$A/hooks/$n.sh"
  done
}
asset() { printf '%s' "$G/skills/harness-bootstrap/assets/$1"; }

run_hook() { # sets out + rc ; CLAUDE_PLUGIN_ROOT=- leaves it unset
  if [ "${2:-$G}" = "-" ]; then
    out=$(env -u CLAUDE_PLUGIN_ROOT CLAUDE_PROJECT_DIR="$P" bash "$HOOK" 2>/dev/null); rc=$?
  else
    out=$(CLAUDE_PROJECT_DIR="$P" CLAUDE_PLUGIN_ROOT="${2:-$G}" bash "$HOOK" 2>/dev/null); rc=$?
  fi
}
silent() { [ "$rc" -eq 0 ] && [ -z "$out" ]; }
no_decision() { ! grep -q '"decision"' <<<"$out"; }
lines() { [ -z "$out" ] && echo 0 || printf '%s\n' "$out" | wc -l | tr -d ' '; }
names() { grep -qF -- "$1" <<<"$out"; }
only_names() { # only_names <path>... : every listed path is named; no other placed path is
  local want="$*" p
  for p in .claude/rules/harness.md $HOOK_FILES; do
    case " $want " in
      *" $p "*) names "$p" || return 1 ;;
      *) ! names "$p" || return 1 ;;
    esac
  done
}
tail_ok() { [[ "$out" == *"run /super-bootstrap:harness-bootstrap" ]]; }

echo "== 1: all four pairs equal -> silent =="
mk_case c1; run_hook
check "no output, exit 0" silent

echo "== 2: harness.md differs -> one line naming it =="
mk_case c2; printf 'edited\n' >> "$P/.claude/rules/harness.md"; run_hook
check "exit 0" [ "$rc" -eq 0 ]
check "exactly one line" [ "$(lines)" = "1" ]
check "names only .claude/rules/harness.md" only_names .claude/rules/harness.md
check "ends with the re-run route" tail_ok
check "no JSON decision" no_decision

echo "== 3: one hook script differs -> one line naming that path only =="
mk_case c3; printf 'edited\n' >> "$P/.claude/hooks/consult-check-check.sh"; run_hook
check "exactly one line" [ "$(lines)" = "1" ]
check "names only the differing hook" only_names .claude/hooks/consult-check-check.sh
check "ends with the re-run route" tail_ok

echo "== 4: two files differ -> still one line naming both =="
mk_case c4; printf 'x\n' >> "$P/.claude/rules/harness.md"; printf 'x\n' >> "$P/.claude/hooks/commit-channel.sh"; run_hook
check "exactly one line" [ "$(lines)" = "1" ]
check "names both, no other" only_names .claude/rules/harness.md .claude/hooks/commit-channel.sh
check "exit 0, no decision" no_decision

echo "== 5: legacy (no placed harness.md, CLAUDE.md doctrine) -> silent even with differing hooks =="
mk_case c5; rm "$P/.claude/rules/harness.md"
printf '# proj\n\n## Doc Sync (non-negotiable)\n\n## Dispatch\n' > "$P/CLAUDE.md"
printf 'edited\n' >> "$P/.claude/hooks/commit-channel.sh"; run_hook
check "gate: no output, exit 0" silent

echo "== 6: CRLF-only difference -> silent =="
mk_case c6
sed 's/$/\r/' "$(asset harness.md)" > "$P/.claude/rules/harness.md"
sed 's/$/\r/' "$(asset hooks/commit-channel.sh)" > "$P/.claude/hooks/commit-channel.sh"; run_hook
check "CR ignored: no output, exit 0" silent

echo "== 7: CLAUDE_PLUGIN_ROOT unset -> silent =="
mk_case c7; printf 'edited\n' >> "$P/.claude/rules/harness.md"; run_hook x -
check "no output, exit 0" silent

echo "== 8: receipt version behind plugin.json, content equal -> silent =="
mk_case c8
printf '{ "version": "1.0.0", "covered": [], "placed": {} }\n' > "$P/.claude/super-bootstrap-runway.json"
mkdir -p "$G/.claude-plugin"; printf '{ "name": "super-bootstrap", "version": "9.9.9" }\n' > "$G/.claude-plugin/plugin.json"
run_hook
check "version is not read: no output, exit 0" silent

echo "== 9: shipped harness.md absent (older plugin) -> that pair skipped =="
mk_case c9; rm "$(asset harness.md)"; printf 'edited\n' >> "$P/.claude/rules/harness.md"; run_hook
check "no output, exit 0" silent
mk_case c9b; rm "$(asset hooks/commit-channel.sh)"; printf 'edited\n' >> "$P/.claude/hooks/commit-channel.sh"; run_hook
check "shipped hook absent -> skipped" silent
mk_case c9c; rm "$P/.claude/hooks/consult-check-check.sh"; run_hook
check "placed hook absent -> skipped" silent
mk_case c9d; rm "$P/.claude/hooks/consult-check-check.sh"; printf 'edited\n' >> "$P/.claude/rules/harness.md"; run_hook
check "absent pair skipped, differing pair still reported" only_names .claude/rules/harness.md

echo "== 10: project dir path containing a space -> one line =="
mk_case "c 10 sp"; printf 'edited\n' >> "$P/.claude/hooks/commit-channel.sh"; run_hook
check "exactly one line" [ "$(lines)" = "1" ]
check "names the differing hook" only_names .claude/hooks/commit-channel.sh

echo "== hooks.json wires the new script =="
check "hooks.json present" [ -f "$MANIFEST" ]
check "one SessionStart entry" [ "$(jq -r '.hooks.SessionStart | length' "$MANIFEST" 2>/dev/null)" = "1" ]
check "matcher re-fires after every context reset" \
  [ "$(jq -r '.hooks.SessionStart[0].matcher' "$MANIFEST" 2>/dev/null)" = "startup|resume|clear|compact" ]
check "command runs runway-drift.sh from the plugin root" \
  [ "$(jq -r '.hooks.SessionStart[0].hooks[0].command' "$MANIFEST" 2>/dev/null)" = 'bash "${CLAUDE_PLUGIN_ROOT}/hooks/runway-drift.sh"' ]
check "hook element is a command hook" \
  [ "$(jq -r '.hooks.SessionStart[0].hooks[0].type' "$MANIFEST" 2>/dev/null)" = "command" ]

echo
echo "RESULT: $pass passed, $fail failed"
[ "$fail" -eq 0 ]
