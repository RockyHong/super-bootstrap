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

# Assembled at runtime so this file's own payload literals never sit at command
# position in a hook-visible command string.
C="commit"
M="merge"
R="rebase"
NL=$'\n'

pass=0; fail=0
ok()   { pass=$((pass+1)); echo "  ok: $1"; }
bad()  { fail=$((fail+1)); echo "  FAIL: $1"; }
check() { # check <desc> <expr...>
  local desc="$1"; shift
  if "$@"; then ok "$desc"; else bad "$desc"; fi
}

denied()  { echo "$1" | grep -q '"permissionDecision":"deny"'; }
allowed() { [ -z "$1" ] || ! denied "$1"; }

run_channel() { # <cmd-string> <agent_type> [tool_name] ; echoes channel stdout
  local cmd="$1" agent="$2" tool="${3:-Bash}"
  jq -cn --arg c "$cmd" --arg a "$agent" --arg t "$tool" \
    '{tool_name:$t, tool_input:{command:$c}, agent_type:$a}' \
    | bash "$CHANNEL"
}

echo "== commit-channel: DEBT-010 — quoted substring must pass through =="
out=$(run_channel "echo \"run git $C -m x inside this script\"" "some-worker")
check "DEBT-010: quoted git-commit substring on one line -> allowed (not a real invocation)" allowed "$out"

echo "== commit-channel: real invocation from worker is denied =="
out=$(run_channel "git $C -m x" "some-worker")
check "real git commit from worker -> denied" denied "$out"

echo "== commit-channel: no commit-agent carve-out — a *:commit subagent is denied =="
out=$(run_channel "git $C -m x" "super-bootstrap:commit")
check "*:commit subagent -> denied (gateway-inline model, no commit agent)" denied "$out"

echo "== commit-channel: real invocation from main passes =="
out=$(run_channel "git $C -m x" "main")
check "real git commit from main -> allowed" allowed "$out"

echo "== commit-channel: a newline is a command separator =="
out=$(run_channel "git add -A${NL}git $C -m x" "some-worker")
check "newline-separated git commit from worker -> denied" denied "$out"

out=$(run_channel "set -e${NL}git $C -q -m \"x\"" "some-worker")
check "multi-line script body (set -e + newline) from worker -> denied" denied "$out"

echo "== commit-channel: the PowerShell tool lane reaches the same script =="
ps_payload="\$FIXTURE = \"C:/tmp/fixture\"${NL}Set-Location \$FIXTURE${NL}git add -A${NL}git $C -m \"add manifest\""
out=$(run_channel "$ps_payload" "some-worker" "PowerShell")
check "PowerShell-shaped payload (tool_name PowerShell, tool_input.command) from worker -> denied" denied "$out"

echo "== commit-channel: heredoc body line is the accepted B1 trade =="
out=$(run_channel "cat > f <<'EOF'${NL}git $C -m x${NL}EOF" "some-worker")
check "heredoc body line beginning git commit -> denied (B1 trade: a visible false-deny that routes to the door beats a silent pass)" denied "$out"

echo "== commit-channel: BUG-072 — chained/piped read-only lines that later mention commit must pass =="
out=$(run_channel "git -C /x log --oneline -20 | grep -i -E \"bypass|wrong $C|main session\"" "some-worker")
check "BUG-072: piped git log | grep mentioning commit -> allowed (read-only, not an invocation)" allowed "$out"

out=$(run_channel "git log --oneline -4 && echo \"--- files in HEAD $C ---\" && git show --stat HEAD" "some-worker")
check "BUG-072: chained git log && echo mentioning commit && git show -> allowed" allowed "$out"

out=$(run_channel "git show x; echo \"=== $C msg ===\"; git log -1 x" "some-worker")
check "BUG-072: semicolon-chained git show; echo mentioning commit; git log -> allowed" allowed "$out"

echo "== commit-channel: BUG-072 guards — real chained/global-flag invocations still deny =="
out=$(run_channel "git -C /x $C -m x" "some-worker")
check "BUG-072 guard: git -C <dir> commit -m x -> denied" denied "$out"

out=$(run_channel "git --no-pager $C -m x" "some-worker")
check "BUG-072 guard: git --no-pager commit -m x -> denied" denied "$out"

out=$(run_channel "git add -A && git $C -m x" "some-worker")
check "BUG-072 guard: git add -A && git commit -m x -> denied" denied "$out"

out=$(run_channel "git add -A; git $C -m x" "some-worker")
check "BUG-072 guard: git add -A; git commit -m x -> denied" denied "$out"

# Accepted residual, locked so a later widening is a deliberate change: a flag
# value carrying `;` `&` `|` stops the walker before `commit` — silent pass.
out=$(run_channel "git -c \"x;y\" $C -m x" "some-worker")
check "BUG-072 accepted residual: git -c \"x;y\" commit -m x -> allowed (exotic global-flag value, not walked)" allowed "$out"

echo "== commit-channel: merge/rebase conclusion is a commit — subagent denied, main allowed =="
out=$(run_channel "git $M --continue" "some-worker")
check "git merge --continue from worker -> denied (concludes a merge = a commit)" denied "$out"

out=$(run_channel "GIT_EDITOR=true git $M --continue" "some-worker")
check "GIT_EDITOR=true git merge --continue from worker -> denied (env-prefixed form)" denied "$out"

out=$(run_channel "git $R --continue" "some-worker")
check "git rebase --continue from worker -> denied" denied "$out"

out=$(run_channel "GIT_EDITOR=true git $C -m x" "some-worker")
check "GIT_EDITOR=true git commit from worker -> denied (env prefix covers every commit verb)" denied "$out"

out=$(run_channel "git add -A${NL}git $M --continue" "some-worker")
check "newline-separated git merge --continue from worker -> denied" denied "$out"

out=$(run_channel "git $M --continue" "main")
check "git merge --continue from main -> allowed" allowed "$out"

out=$(run_channel "GIT_EDITOR=true git $M --continue" "main")
check "GIT_EDITOR=true git merge --continue from main -> allowed" allowed "$out"

out=$(run_channel "git $R --continue" "main")
check "git rebase --continue from main -> allowed" allowed "$out"

echo "== commit-channel: merge/rebase guards — non-concluding verbs from a subagent pass =="
out=$(run_channel "git $M --abort" "some-worker")
check "git merge --abort from worker -> allowed (does not conclude)" allowed "$out"

out=$(run_channel "git $R --abort" "some-worker")
check "git rebase --abort from worker -> allowed (does not conclude)" allowed "$out"

out=$(run_channel "git $M-base HEAD main" "some-worker")
check "git merge-base from worker -> allowed (different verb)" allowed "$out"

out=$(run_channel "git status" "some-worker")
check "git status from worker -> allowed" allowed "$out"

# Accepted residual, locked so a later widening is a deliberate change: the
# assignment walker does not walk a quoted value with a space, nor `env X=y git …`.
out=$(run_channel "GIT_EDITOR=\"vim -f\" git $M --continue" "some-worker")
check "accepted residual: GIT_EDITOR=\"vim -f\" git merge --continue -> allowed (quoted assignment value, not walked)" allowed "$out"

out=$(run_channel "env GIT_EDITOR=true git $M --continue" "some-worker")
check "accepted residual: env GIT_EDITOR=true git merge --continue -> allowed (env form, not walked)" allowed "$out"

out=$(run_channel "echo \"next: git $M --continue\"" "some-worker")
check "quoted git merge --continue mention on one line -> allowed (not an invocation)" allowed "$out"

echo "== commit-channel: settings snippet covers both command tools =="
snippet_matcher=$(jq -r '.matcher' "$ASSETS/commit-channel.hook.json")
check "snippet matcher spans both command tools" [ "$snippet_matcher" = "Bash|PowerShell" ]

snippet_if=$(jq -r '.hooks[0].if' "$ASSETS/commit-channel.hook.json")
check "BUG-039: Bash hook element's pre-filter anchors on the bare command" [ "$snippet_if" = "Bash(git *)" ]

snippet_if_ps=$(jq -r '.hooks[1].if' "$ASSETS/commit-channel.hook.json")
check "PowerShell hook element's pre-filter anchors on the bare command" [ "$snippet_if_ps" = "PowerShell(git *)" ]

cmd0=$(jq -r '.hooks[0].command' "$ASSETS/commit-channel.hook.json")
cmd1=$(jq -r '.hooks[1].command' "$ASSETS/commit-channel.hook.json")
check "both hook elements run the same script" [ "$cmd0" = "$cmd1" ]

echo
echo "RESULT: $pass passed, $fail failed"
[ "$fail" -eq 0 ]
