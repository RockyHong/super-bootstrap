#!/usr/bin/env bash
# L1 unit tests for commit-channel.sh: command-position matcher + agent_type routing.
# Zero session dependency: pipes fake hook-input JSON to the hook, checks the response.
# Targets the PLUGIN ASSETS (source of truth); the live .claude/hooks copy is
# synced verbatim from there.
#
# Usage: bash tests/commit-channel.test.sh
set -u

REPO="$(cd "$(dirname "$0")/.." && pwd)"
ASSETS="$REPO/plugins/super-bootstrap/skills/harness-bootstrap/assets/hooks"
CHANNEL="$ASSETS/commit-channel.sh"

pass=0; fail=0
ok()   { pass=$((pass+1)); echo "  ok: $1"; }
bad()  { fail=$((fail+1)); echo "  FAIL: $1"; }
check() { # check <desc> <expr...>
  local desc="$1"; shift
  if "$@"; then ok "$desc"; else bad "$desc"; fi
}

denied()  { echo "$1" | grep -q '"permissionDecision":"deny"'; }
allowed() { [ -z "$1" ] || ! denied "$1"; }

run_channel() { # <cmd-string> <agent_type> ; echoes channel stdout
  local cmd="$1" agent="$2"
  jq -cn --arg c "$cmd" --arg a "$agent" '{tool_input:{command:$c}, agent_type:$a}' \
    | bash "$CHANNEL"
}

echo "== commit-channel: DEBT-010 — quoted substring must pass through =="
out=$(run_channel 'echo "run git commit -m x inside this script"' "some-worker")
check "DEBT-010: quoted git-commit substring -> allowed (not a real invocation)" allowed "$out"

echo "== commit-channel: real invocation from worker is denied =="
out=$(run_channel "git commit -m x" "some-worker")
check "real git commit from worker -> denied" denied "$out"

echo "== commit-channel: no commit-agent carve-out — a *:commit subagent is denied =="
out=$(run_channel "git commit -m x" "super-bootstrap:commit")
check "*:commit subagent -> denied (gateway-inline model, no commit agent)" denied "$out"

echo "== commit-channel: real invocation from main passes =="
out=$(run_channel "git commit -m x" "main")
check "real git commit from main -> allowed" allowed "$out"

echo
echo "RESULT: $pass passed, $fail failed"
[ "$fail" -eq 0 ]
