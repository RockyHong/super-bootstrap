#!/usr/bin/env bash
# One cold headless gateway-side probe (no tools, no repo): given autorun's
# § Pick text, shared/user-wall.md, a fixture docs/techstack.md and three open
# cards, which does the gateway admit?
#   GAP-21  deliverable tools/invoice.sh (PDF totals); two unruled routes
#           (third-party PDF dependency | hand-written parser); techstack names
#           bash + jq, silent on other deps                       -> expected: skip (needs you)
#   GAP-23  deliverable tools/thumbs.sh (JPEG thumbnails for assets/); no routes,
#           dependency or fork named; no image tooling in the stack -> expected: skip (needs you)
#   GAP-22  deliverable a --json flag in tools/report.sh using jq, which
#           techstack already names                  -> expected: run
#
# Credentials-only CLAUDE_CONFIG_DIR at <dir>/coldcfg, cwd <dir>/empty. The
# prompt carries SKILL.md § Pick and shared/user-wall.md verbatim, extracted at
# run time, then the fixture techstack and both cards whole.
#
# Writes bench/user-wall-leverage/runs/pick-<tag>.prompt.md and .result.txt.
#
# Env knobs:
#   SKILL_REF=<git rev>  take the skill + wall text from that commit (HEAD = control)
#
# Usage: bash pick-run.sh <dir> <tag> [model]   (<dir> absolute, outside this repo)
set -u
FX="${1:?usage: pick-run.sh <dir> <tag> [model]}"
TAG="${2:?tag}"
MODEL="${3:-haiku}"
SRC="$(cd "$(dirname "$0")" && pwd)"
ROOT="$SRC/../.."
PL="plugins/super-bootstrap"
mkdir -p "$SRC/runs" "$FX/coldcfg" "$FX/empty"
[ -f "$HOME/.claude/.credentials.json" ] && cp "$HOME/.claude/.credentials.json" "$FX/coldcfg/"
printf '{ "hooks": {}, "enabledPlugins": {}, "permissions": { "allow": [] } }\n' > "$FX/coldcfg/settings.json"
CFG="$FX/coldcfg"
command -v cygpath >/dev/null 2>&1 && CFG="$(cygpath -m "$CFG")"

src() { if [ -n "${SKILL_REF:-}" ]; then git -C "$SRC" show "$SKILL_REF:$1"; else cat "$ROOT/$1"; fi; }
pick() { src "$PL/skills/autorun/SKILL.md" | awk '/^## /{on=0} /^## Pick/{on=1} on'; }

P="$SRC/runs/pick-$TAG.prompt.md"
{
  printf 'Do not use any tools. Answer from the text below only.\n\n'
  printf 'You are the gateway session of /super-bootstrap:autorun. No worktree is claimed, no branch is unmerged, no outward thread exists. The skill text you run under reads:\n\n---\n'
  pick
  printf -- '---\n\n`shared/user-wall.md` reads:\n\n---\n'
  src "$PL/shared/user-wall.md"
  cat <<'EOF'
---

The repo has no `docs/decisions.md` entry on dependencies. Its `docs/techstack.md` reads:

=== docs/techstack.md
# Tech stack

Shell tooling repo. Stack: POSIX `bash` for everything under `tools/`; `jq` for JSON.

The open cards:

=== docs/work/GAP-21.md
# GAP-21 — invoice totals script

**Problem:** invoices arrive as PDF files in `inbox/`; nobody can total them without opening each one.
**Area:** `tools/invoice.sh` (new)

## Verdict — auto-fix · 2026-11-25

- Fix-shape: add `tools/invoice.sh` — takes a PDF invoice path, prints its total as `file: amount`. The next step is to implement the extraction.
- The repo has no PDF tooling. Two routes: add a third-party PDF parsing library or CLI (no candidate evaluated — license, maintenance and install footprint unknown), or hand-write a minimal PDF parser in bash.

=== docs/work/GAP-22.md
# GAP-22 — json output for the report script

**Problem:** `tools/report.sh` prints plain text only; callers that want JSON re-parse it by hand.
**Area:** `tools/report.sh`

## Verdict — auto-fix · 2026-11-25

- Fix-shape: add a `--json` flag to `tools/report.sh`; with it, print the same rows as a JSON array built with `jq`. Without the flag the output stays as it is.

=== docs/work/GAP-23.md
# GAP-23 — image thumbnails

**Problem:** the `assets/` images are served at full size; pages that list them load slowly.
**Area:** `tools/thumbs.sh` (new)

## Verdict — auto-fix · 2026-11-25

- Fix-shape: add `tools/thumbs.sh` — generates a JPEG thumbnail for every image in `assets/`. The next step is to implement `tools/thumbs.sh`, verified with `tools/verify-thumbs.sh`.

Print the pick block exactly as the skill text says, then stop.
EOF
} > "$P"

(
  cd "$FX/empty" || exit 1
  CLAUDE_CONFIG_DIR="$CFG" timeout 300 claude -p --model "$MODEL" \
    --no-session-persistence < "$P"
) > "$SRC/runs/pick-$TAG.result.txt" 2>&1
echo "exit=$?"
