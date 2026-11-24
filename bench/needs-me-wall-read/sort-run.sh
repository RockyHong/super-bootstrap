#!/usr/bin/env bash
# One cold headless needs-me probe (no tools, no repo): run needs-me's § Scan
# and its user-wall sort over three cards, at the read grain § Scan names.
#   GAP-21  Design body names `waiting on {party}`, a later Progress block
#           follows                                   -> expected: needs you
#   GAP-22  latest block is a Design with no approval line -> expected: needs you
#   GAP-23  auto-fix Verdict, plain runnable          -> expected: runs without you
# The wall evidence for GAP-21 and GAP-22 sits in block bodies; the latest `## `
# heading alone does not carry it.
#
# The prompt carries needs-me SKILL.md whole, shared/user-wall.md whole and
# docs/work/README.md § Thread contract (the read set § Scan / § Recommend name),
# extracted at run time, then the three card files whole. It asks the model to
# judge each card only on the parts § Scan says to read: with no tools the model
# sees every byte, so the grain is the skill's wording, not a file read.
#
# Credentials-only CLAUDE_CONFIG_DIR at <dir>/coldcfg, cwd <dir>/empty.
# Writes bench/needs-me-wall-read/runs/sort-<tag>.prompt.md and .result.txt.
#
# Env knobs:
#   SKILL_REF=<git rev>  take the skill text from that commit (HEAD = control)
#
# Usage: bash sort-run.sh <dir> <tag> [model]   (<dir> absolute, outside this repo)
set -u
FX="${1:?usage: sort-run.sh <dir> <tag> [model]}"
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
contract() { awk '/^## Thread contract/{on=1; print; next} on && /^## /{exit} on' "$ROOT/docs/work/README.md"; }

P="$SRC/runs/sort-$TAG.prompt.md"
{
  printf 'Do not use any tools. Answer from the text below only.\n\n'
  printf 'You are the gateway session of /super-bootstrap:needs-me. The skill text you run under (`SKILL.md`) reads:\n\n---\n'
  src "$PL/skills/needs-me/SKILL.md"
  printf -- '---\n\n`${CLAUDE_PLUGIN_ROOT}/shared/user-wall.md` reads:\n\n---\n'
  src "$PL/shared/user-wall.md"
  printf -- '---\n\n`docs/work/README.md` reads, in part:\n\n---\n'
  contract
  printf -- '---\n\nThe repo holds no `docs/test-queue.md`, no `docs/outward/`, no `docs/parked.md` and no `SESSION-STATE/`. The open cards, file by file:\n\n'
  cat <<'EOF'
=== docs/work/GAP-21.md ===
# GAP-21 — Monthly invoice export to the billing portal

**Logged:** 2026-10-02 · **Source:** user request
**Problem:** Invoices are exported by hand each month; `tools/export.sh` should push them to the billing portal.
**Area:** `tools/export.sh`

## Verdict — surface · 2026-10-03

### Decision needed
Push through the portal's current CSV upload, or wait for its announced JSON API.

## Design — 2026-10-04

Ruling: wait for the JSON API; the CSV upload is being retired. waiting on Acme Billing's API team (JSON API v2 release, no date given).

Approved — user, 2026-10-04.

## Progress — 2026-10-06 · session

Field mapping table written to `docs/export-fields.md`; `tools/export.sh` reads the invoice ledger into that shape.

=== docs/work/GAP-22.md ===
# GAP-22 — Dark theme for the settings page

**Logged:** 2026-10-08 · **Source:** user request
**Problem:** The settings page ignores the system dark-mode preference.
**Area:** `web/settings/`

## Verdict — surface · 2026-10-09

### Decision needed
Follow the system preference only, or add an in-page toggle that overrides it.

## Design — 2026-10-10

Proposed: follow the system preference; add the toggle later if asked. Option chosen by the gateway pending the user's ruling.

=== docs/work/GAP-23.md ===
# GAP-23 — Retry flaky upload in the sync job

**Logged:** 2026-10-11 · **Source:** CI failure
**Problem:** `jobs/sync.sh` fails the whole run when one upload times out.
**Area:** `jobs/sync.sh`, `tests/sync.bats`

## Verdict — auto-fix · 2026-10-12

**Fix-shape:** mechanical
Wrap the upload call in a three-try retry with backoff; `tests/sync.bats` covers it with a stubbed timeout.

EOF
  cat <<'EOF'
Run § Scan and the sort only — no lens question, no recommendation. Judge each card only on the parts of it that § Scan says to read; a part § Scan does not read does not exist for the sort. Print exactly one line per card, in this form and nothing before them:

needs you:         {ID}  {the user-wall line it meets}
runs without you:  {ID}

Then one line per card naming which parts of the card you read, then stop.
EOF
} > "$P"

(
  cd "$FX/empty" || exit 1
  CLAUDE_CONFIG_DIR="$CFG" timeout 300 claude -p --model "$MODEL" \
    --no-session-persistence < "$P"
) > "$SRC/runs/sort-$TAG.result.txt" 2>&1
echo "exit=$?"
