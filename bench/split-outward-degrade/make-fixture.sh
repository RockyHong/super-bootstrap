#!/usr/bin/env bash
# make-fixture.sh — scratch repo on the retired flat outward shape, scale module installed.
# Usage: bash bench/split-outward-degrade/make-fixture.sh <dir>
#
# After: `docs/outward.md` with two `### OUT-###` entries, `docs/parked.md` from the shipped skeleton
# (the scale module's install marker), no `docs/test-queue.md` (a scale member § 2b's drift check
# resolves `Missing → write` — the run reaching it shows the sync continued), no `docs/outward/`.
# `<dir>.outward.before` holds a copy of the flat file. Pass an absolute <dir>.
set -eu
dir="${1:?usage: make-fixture.sh <dir>}"
here="$(cd "$(dirname "$0")" && pwd)"
scale="$here/../../plugins/super-bootstrap/skills/harness-bootstrap/assets/scale"
rm -rf "$dir" "$dir.outward.before"
mkdir -p "$dir/docs/work"
cd "$dir"
git init -q -b main
cp "$scale/parked-skeleton.md" docs/parked.md
cat > docs/outward.md <<'MD'
# Outward

Items the author or an outside party moves. The repo owns only the result tail.

**ID high-water mark:** OUT-002

## Entries

### OUT-001 — Ask upstream to publish the schema

**Logged:** 2026-10-02 · **Source:** spec review
**Next move:** author files the request upstream
**Waiting on:** upstream maintainers

### OUT-002 — Vendor licence confirmation

**Logged:** 2026-10-20 · **Source:** dependency audit
**Next move:** vendor replies to the licence question
**Waiting on:** vendor legal
MD
printf '# Fixture\n\nA small project.\n' > README.md
cp docs/outward.md "$dir.outward.before"
