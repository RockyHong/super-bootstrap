#!/usr/bin/env bash
# DEBT-118 M4 — build the scratch consumer repo + cold config the arms run in.
#
# Layout under <target-dir>:
#   repo/     `tally`, a small Python billing package, plus two cards:
#               BUG-001  whole-file cause — a control-flow ordering bug in
#                        tally/engine.py run(); the card's Prior plants a
#                        grep-reachable decoy (RefundLedger.is_duplicate)
#               BUG-002  grep-first cause — one of ~20 fmt_money() call sites
#                        across 9 files passes (locale, currency) swapped;
#                        Prior plants a decoy (GBP missing from SYMBOLS)
#             docs/work/README.md + TEMPLATE.md + docs/decisions.md placed from
#             the harness-bootstrap assets verbatim (the card substrate a
#             consumer holds); one neutral commit.
#   plugin/   stands in for ${CLAUDE_PLUGIN_ROOT}: shared/grounding-discipline.md
#             copied from the shipped plugin, so the agent body's self-read
#             instruction resolves.
#   coldcfg/  CLAUDE_CONFIG_DIR holding credentials + a settings file only —
#             no device CLAUDE.md, rules, plugins or hooks reach the run
#             (bench/consult-hook/bench-decontamination.md channel 3).
#
# The fixture's code is at bench/triage-grep-first/fixture/; its test suite is
# green by construction (asserted below) and never exercises either bug.
#
# Usage: bash make-fixture.sh <target-dir>
set -eu
FX="${1:?usage: make-fixture.sh <target-dir>}"
SRC="$(cd "$(dirname "$0")" && pwd)"
ASSETS="$SRC/../../plugins/super-bootstrap/skills/harness-bootstrap/assets"
SHARED="$SRC/../../plugins/super-bootstrap/shared/grounding-discipline.md"

rm -rf "$FX/repo" "$FX/plugin" "$FX/coldcfg"
mkdir -p "$FX/repo" "$FX/plugin/shared" "$FX/coldcfg"
REPO="$FX/repo"

cp -r "$SRC/fixture/." "$REPO/"
find "$REPO" -name '__pycache__' -type d -prune -exec rm -rf {} +
cp "$ASSETS/work-readme-skeleton.md"   "$REPO/docs/work/README.md"
cp "$ASSETS/work-template-skeleton.md" "$REPO/docs/work/TEMPLATE.md"
cp "$ASSETS/decisions-skeleton.md"     "$REPO/docs/decisions.md"
cp "$SHARED" "$FX/plugin/shared/grounding-discipline.md"

# suite green before any run — neither planted bug is covered by a test
( cd "$REPO" && PYTHONIOENCODING=utf-8 python3 -m unittest discover -s tests -t . >/dev/null 2>&1 ) \
  || { echo "fixture suite not green" >&2; exit 1; }
find "$REPO" -name '__pycache__' -type d -prune -exec rm -rf {} +

# cold config: credentials + permissions only. The triage agent's tool set is
# Read, Grep, Glob, Bash, Edit; its Bash floor is read-only git/ls, so only
# those prefixes are allowed — anything else is denied headless.
[ -f "$HOME/.claude/.credentials.json" ] && cp "$HOME/.claude/.credentials.json" "$FX/coldcfg/"
cat > "$FX/coldcfg/settings.json" <<'JSON'
{
  "hooks": {},
  "enabledPlugins": {},
  "includeCoAuthoredBy": false,
  "permissions": {
    "defaultMode": "acceptEdits",
    "allow": ["Bash(git status:*)", "Bash(git diff:*)", "Bash(git log:*)", "Bash(ls:*)"]
  }
}
JSON

# neutral one-commit history
(
  cd "$REPO"
  git init -q
  git config core.autocrlf false
  git -c user.name=dev -c user.email=dev@example.invalid add -A
  git -c user.name=dev -c user.email=dev@example.invalid commit -q -m "tally 0.9.2"
)
echo "fixture repo at $REPO"
echo "plugin root  at $FX/plugin"
echo "cold config  at $FX/coldcfg"
