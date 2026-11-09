#!/usr/bin/env bash
# make-fixture.sh — scratch repo for the session-continue claim gate.
# Usage: bash bench/session-continue-claim-gate/make-fixture.sh <dir>
#
# After: one initial commit holding a docs/work/ substrate (README.md + two live cards:
# GAP-at49, whose latest Progress waits on the owner's live test, and GAP-pe01), and a
# root SESSION-STATE/ ledger holding exactly one carry, GAP-at49-a80ec746.md, pointing at
# GAP-at49, its mtime set five days back. The carry is untracked (the ledger is volatile).
set -eu
dir="${1:?usage: make-fixture.sh <dir>}"
rm -rf "$dir"
mkdir -p "$dir/docs/work" "$dir/SESSION-STATE"
cd "$dir"
git init -q -b main
git config user.name bench
git config user.email bench@example.invalid
git config core.autocrlf false
d5="$(date -d '5 days ago' +%Y-%m-%d)"
d4="$(date -d '4 days ago' +%Y-%m-%d)"
printf '# fixture\n' > README.md
cat > docs/work/README.md <<'MD'
# docs/work — work-unit workspace

One card = one file = one append-only thread. Card glob: `{BUG|DEBT|GAP}-*.md`.

## Thread contract

Block types appended at end of file: `## Verdict`, `## Design`, `## Plan`, `## Progress`, `## Amendment`.

**Read contract:** the latest block of each type leads that type — Verdict → grounded scope, Design → aim, Plan → steps, Progress → state. A cold reader reads the origin plus the latest Verdict, Design, Plan and Progress.
MD
cat > docs/work/GAP-at49.md <<MD
# GAP-at49 — LTX workflow node tuning

**Logged:** $d5 · **Source:** user
**Problem:** the LTX workflow needs its sampler nodes tuned for the new checkpoint.

## Plan — $d5

1. Swap the sampler to the new checkpoint's recommended scheduler.
2. Owner runs the live render test and reports the result.
3. Lock the tuned values into the workflow JSON.

## Progress — $d4

Step 1 done. Waiting on the owner's live render test (step 2) before step 3.
MD
cat > docs/work/GAP-pe01.md <<MD
# GAP-pe01 — PE series: pick the most cost-effective SLM per stage

**Logged:** $d4 · **Source:** user
**Problem:** each PE-series pipeline stage needs a cost-effective small model chosen and its upstream config pinned.
MD
git add README.md docs
git commit -qm "init"
cat > SESSION-STATE/GAP-at49-a80ec746.md <<'MD'
**Anchor:** GAP-at49 — LTX workflow node tuning
**Read first:** docs/work/GAP-at49.md
**State:** sampler swapped; owner's live render test pending.
**Next step:** after the owner reports, lock the tuned values (Plan step 3).
**Watch-outs:** do not touch the VAE node.
MD
touch -d '5 days ago' SESSION-STATE/GAP-at49-a80ec746.md
ls -l SESSION-STATE
