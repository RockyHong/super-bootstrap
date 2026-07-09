#!/usr/bin/env bash
# L1 unit tests for the docsync hook pair (spec: 2026-07-07-docsync-gate-bprime-design.md).
# Zero session dependency: pipes fake hook-input JSON, forges mtime via touch -d.
# Targets the PLUGIN ASSETS (source of truth); the live .claude/hooks copies are
# synced verbatim from these.
#
# Usage: bash tests/docsync-hooks.test.sh
set -u

REPO="$(cd "$(dirname "$0")/.." && pwd)"
ASSETS="$REPO/plugins/super-bootstrap/skills/harness-bootstrap/assets/hooks"
GATE="$ASSETS/docsync-gate.sh"
SCAN="$ASSETS/docsync-scan.sh"
CHANNEL="$ASSETS/commit-channel.sh"

pass=0; fail=0
ok()   { pass=$((pass+1)); echo "  ok: $1"; }
bad()  { fail=$((fail+1)); echo "  FAIL: $1"; }
check() { # check <desc> <expr...>
  local desc="$1"; shift
  if "$@"; then ok "$desc"; else bad "$desc"; fi
}

# --- fixture: scratch main repo ---
TMP="$(mktemp -d)"
trap 'rm -rf "$TMP"' EXIT
MAIN="$TMP/main"
mkdir -p "$MAIN"
git -C "$TMP" init -q "$MAIN"
( cd "$MAIN" && git commit -q --allow-empty -m init )
TOKEN="$MAIN/.git/docsync-token"

# gate runner: <cmd-string> [session_id] ; echoes gate stdout, returns script rc
run_gate() {
  local cmd="$1" sid="${2-}"
  jq -cn --arg c "$cmd" --arg s "$sid" '{tool_input:{command:$c}, session_id:$s}' \
    | CLAUDE_PROJECT_DIR="$MAIN" bash "$GATE"
}
denied()  { echo "$1" | grep -q '"permissionDecision":"deny"'; }
allowed() { [ -z "$1" ] || ! denied "$1"; }

echo "== gate: non-commit pass-through =="
out=$(run_gate "ls -la")
check "non-git-commit command passes" allowed "$out"

echo "== gate: missing token denies =="
rm -f "$TOKEN"
out=$(run_gate "git commit -m x" "sess-A")
check "missing token -> deny" denied "$out"

echo "== scan: self-stamps token with session id =="
rm -f "$TOKEN"
( cd "$MAIN" && CLAUDE_PROJECT_DIR="$MAIN" CLAUDE_CODE_SESSION_ID="sess-A" bash "$SCAN" >/dev/null )
check "token exists after scan" test -f "$TOKEN"
check "token carries session id" grep -q "sess-A" "$TOKEN"

echo "== scan: works with CLAUDE_PROJECT_DIR unset (exit-127 regression) =="
rm -f "$TOKEN"
( cd "$MAIN" && env -u CLAUDE_PROJECT_DIR CLAUDE_CODE_SESSION_ID="sess-A" bash "$SCAN" >/dev/null 2>&1 )
check "scan self-locates repo root" test -f "$TOKEN"

echo "== gate: fresh + matching session passes and consumes =="
( cd "$MAIN" && CLAUDE_PROJECT_DIR="$MAIN" CLAUDE_CODE_SESSION_ID="sess-A" bash "$SCAN" >/dev/null )
out=$(run_gate "git commit -m x" "sess-A")
check "fresh matching token -> allow" allowed "$out"
check "token consumed (one-shot)" test ! -f "$TOKEN"

echo "== gate: stale token denies (TTL) =="
( cd "$MAIN" && CLAUDE_PROJECT_DIR="$MAIN" CLAUDE_CODE_SESSION_ID="sess-A" bash "$SCAN" >/dev/null )
touch -d "45 minutes ago" "$TOKEN"
out=$(run_gate "git commit -m x" "sess-A")
check "stale (45min) token -> deny" denied "$out"

echo "== gate: cross-session token denies (GAP-011) =="
( cd "$MAIN" && CLAUDE_PROJECT_DIR="$MAIN" CLAUDE_CODE_SESSION_ID="sess-A" bash "$SCAN" >/dev/null )
out=$(run_gate "git commit -m x" "sess-B")
check "other session's fresh token -> deny" denied "$out"

echo "== gate: empty session id degrades to TTL-only =="
rm -f "$TOKEN"
( cd "$MAIN" && CLAUDE_PROJECT_DIR="$MAIN" CLAUDE_CODE_SESSION_ID="" bash "$SCAN" >/dev/null )
out=$(run_gate "git commit -m x" "sess-B")
check "empty-token-session + fresh -> allow (graceful)" allowed "$out"

echo "== gate: drain-managed worktree passes through; other worktrees stay gated =="
DWT="$MAIN/.claude/worktrees/job1"
mkdir -p "$MAIN/.claude/worktrees"
git -C "$MAIN" worktree add -q "$DWT" -b drain-branch
rm -f "$TOKEN"
out=$(jq -cn --arg c "git commit -m x" --arg s "sess-A" '{tool_input:{command:$c}, session_id:$s}' \
  | CLAUDE_PROJECT_DIR="$DWT" bash "$GATE")
check "drain worktree (.claude/worktrees/) no token -> allow" allowed "$out"
WT="$TMP/wt"
git -C "$MAIN" worktree add -q "$WT" -b wt-branch
rm -f "$TOKEN"
out=$(jq -cn --arg c "git commit -m x" --arg s "sess-A" '{tool_input:{command:$c}, session_id:$s}' \
  | CLAUDE_PROJECT_DIR="$WT" bash "$GATE")
check "non-drain worktree no token -> deny (gate applies)" denied "$out"

echo "== deny messages: never name a bare token command (BUG-007) =="
rm -f "$TOKEN"
out=$(run_gate "git commit -m x" "sess-A")
check "deny msg has no touch/token escape hatch" bash -c "! echo \"\$0\" | grep -qi 'touch'" "$out"
check "deny msg legitimizes scan-first flows" bash -c "echo \"\$0\" | grep -q 'docsync-scan.sh'" "$out"

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

echo "== commit-channel: real invocation from commit agent passes =="
out=$(run_channel "git commit -m x" "super-bootstrap:commit")
check "real git commit from commit agent -> allowed" allowed "$out"

echo "== commit-channel: real invocation from main passes =="
out=$(run_channel "git commit -m x" "main")
check "real git commit from main -> allowed" allowed "$out"

echo
echo "RESULT: $pass passed, $fail failed"
[ "$fail" -eq 0 ]
