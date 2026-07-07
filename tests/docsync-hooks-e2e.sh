#!/usr/bin/env bash
# L2 headless e2e for the docsync gate (spec: 2026-07-07-docsync-gate-bprime-design.md).
# Spawns real fresh Claude Code sessions via `claude -p` in a scratch repo with the
# hooks installed — covers the live PreToolUse firing path (incl. what subagent/SDK
# dispatches see) that L1's fake-stdin tests cannot.
#
# Cost: two headless sessions per run. Run on demand, not in a loop.
# Usage: bash tests/docsync-hooks-e2e.sh
set -u

REPO="$(cd "$(dirname "$0")/.." && pwd)"
ASSETS="$REPO/plugins/super-bootstrap/skills/harness-bootstrap/assets/hooks"

TMP="$(mktemp -d)"
trap 'rm -rf "$TMP"' EXIT
SCRATCH="$TMP/scratch"
mkdir -p "$SCRATCH/.claude/hooks" "$SCRATCH/docs"

cp "$ASSETS/docsync-gate.sh" "$ASSETS/docsync-scan.sh" "$SCRATCH/.claude/hooks/"

# Minimal settings: just the gate wiring (mirror of docsync-gate.hook.json merge shape).
cat > "$SCRATCH/.claude/settings.json" <<'JSON'
{
  "hooks": {
    "PreToolUse": [
      {
        "matcher": "Bash",
        "hooks": [
          { "type": "command", "command": "bash \"$CLAUDE_PROJECT_DIR/.claude/hooks/docsync-gate.sh\"" }
        ]
      }
    ]
  }
}
JSON

( cd "$SCRATCH" \
  && git init -q \
  && git commit -q --allow-empty -m init \
  && echo "seed" > docs/note.md )

pass=0; fail=0
ok()  { pass=$((pass+1)); echo "  ok: $1"; }
bad() { fail=$((fail+1)); echo "  FAIL: $1"; }

commits() { git -C "$SCRATCH" rev-list --count HEAD; }

echo "== e2e 1: bare commit (no scan) must be denied =="
before=$(commits)
( cd "$SCRATCH" && claude -p \
    "Run exactly this and nothing else: git add -A then git commit -m 'e2e bare'. If a command is denied, stop — do not work around it." \
    --settings "$SCRATCH/.claude/settings.json" \
    --allowedTools "Bash" --max-turns 6 ) >/dev/null 2>&1
after=$(commits)
if [ "$after" -eq "$before" ]; then ok "no commit landed without scan"; else bad "commit landed without scan ($before -> $after)"; fi

echo "== e2e 2: scan-first commit must pass =="
before=$(commits)
( cd "$SCRATCH" && claude -p \
    "Do these as SEPARATE Bash calls, in order: 1) bash .claude/hooks/docsync-scan.sh  2) git add -A  3) git commit -m 'e2e scan-first'. Stop after the commit." \
    --settings "$SCRATCH/.claude/settings.json" \
    --allowedTools "Bash" --max-turns 8 ) >/dev/null 2>&1
after=$(commits)
if [ "$after" -gt "$before" ]; then ok "scan-first commit landed"; else bad "scan-first commit did not land"; fi

echo
echo "RESULT: $pass passed, $fail failed"
[ "$fail" -eq 0 ]
