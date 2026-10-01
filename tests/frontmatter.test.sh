#!/usr/bin/env bash
# L1 lint: every shipped SKILL.md and agent .md carries frontmatter that parses as
# strict YAML. A loader that rejects the block drops the skill silently — a quoting
# slip in a `description` (an unescaped `'` inside a single-quoted scalar, a bare
# `: ` inside a plain scalar) ships as a missing command with no error at release.
#
# Requires python3 + PyYAML; exits 2 (not 0) when either is missing so a skipped
# lint never reads as a pass.
#
# Usage: bash tests/frontmatter.test.sh
set -u

REPO="$(cd "$(dirname "$0")/.." && pwd)"
PY="$(command -v python3 || command -v python || true)"
[ -n "$PY" ] || { echo "SKIP: python not found"; exit 2; }
"$PY" -c 'import yaml' 2>/dev/null || { echo "SKIP: PyYAML not installed"; exit 2; }

cd "$REPO" || exit 1
"$PY" - plugins/*/skills/*/SKILL.md plugins/*/agents/*.md <<'EOF'
import sys, yaml
fail = 0
for p in sys.argv[1:]:
    text = open(p, encoding="utf-8").read()
    parts = text.split("---", 2)
    if not text.startswith("---") or len(parts) < 3:
        print(f"  FAIL: {p}: no frontmatter block"); fail += 1; continue
    try:
        fm = yaml.safe_load(parts[1])
    except yaml.YAMLError as e:
        mark = getattr(e, "problem_mark", None)
        where = f" line {mark.line + 1} col {mark.column + 1}" if mark else ""
        print(f"  FAIL: {p}:{where} {getattr(e, 'problem', e)}"); fail += 1; continue
    if not isinstance(fm, dict) or not fm.get("name") or not fm.get("description"):
        print(f"  FAIL: {p}: missing name/description"); fail += 1; continue
    print(f"  ok: {p}")
print(f"{len(sys.argv) - 1 - fail} passed, {fail} failed")
sys.exit(1 if fail else 0)
EOF
