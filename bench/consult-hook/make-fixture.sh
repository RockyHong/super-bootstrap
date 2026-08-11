#!/usr/bin/env bash
# GAP-045 — assemble a consumer-shaped fixture env for decontaminated runs.
# Simulates the distribution target: generic project CLAUDE.md, no experiment
# artifacts, neutral git history (kills the recent-commits leak), lore
# reachable only via the device plant (~/.claude/guidelines), doc-map derived
# fresh from the plant — the downstream deriver story rehearsed.
# Why each of these: bench/bench-decontamination.md (channels + checklist).
# Usage: bash bench/make-fixture.sh <target-dir>
set -euo pipefail
FX="${1:?usage: make-fixture.sh <target-dir>}"
SRC="$(cd "$(dirname "$0")" && pwd)"

HOMEW="$HOME"
command -v cygpath >/dev/null 2>&1 && HOMEW="$(cygpath -m "$HOME")"

mkdir -p "$FX/bench"
cat > "$FX/CLAUDE.md" <<'EOF'
# CLAUDE.md

Internal tooling repo. Bash + markdown, zero runtime deps beyond git and jq.
Single dev. Conventional commits.
EOF
cp "$SRC/"*-inject.sh "$FX/bench/"   # every arm's hook script — arm-*.json resolve via $CLAUDE_PROJECT_DIR (fixture cwd)
bash "$SRC/derive-map.sh" \
  "$HOMEW/.claude/guidelines/claude-shape/index.md" \
  "$HOMEW/.claude/guidelines/axiom-principles/index.md" \
  > "$FX/bench/doc-map.tsv"

(
  cd "$FX"
  [ -d .git ] || git init -q
  git add -A
  git -c user.email=fx@fx -c user.name=fx commit -qm "init" --no-verify 2>/dev/null || true
)
echo "fixture at $FX ($(wc -l < "$FX/bench/doc-map.tsv") map rows)"
