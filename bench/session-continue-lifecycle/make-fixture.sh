#!/usr/bin/env bash
# make-fixture.sh — scratch repo for the session-continue carry lifecycle (hold + retire).
# Usage: bash bench/session-continue-lifecycle/make-fixture.sh <dir>
#
# After: one initial commit holding a docs/work/ substrate (README.md + four live cards), and an
# untracked root SESSION-STATE/ ledger of six carries, each mtime set back to its age:
#   (a) GAP-wt01-aaaa1111.md — 4 days; Next step `not before <today+10>`         → held, named with date
#   (b) BUG-x9z1-bbbb2222.md — Read first names a deleted card (resolved)        → retire candidate
#   (c) GAP-dn02-cccc3333.md — 6 days; card Progress 2 days ago records its next step done → retire
#   (d) GAP-dup3-dddd4444.md — 12-day pointer-only stub (older)                  → retire candidate
#       GAP-dup3-eeee5555.md — 1 day, same card (newer)                          → resume option
#   (e) GAP-lv05-ffff6666.md — 2 days; card Progress 3 days ago                  → resume option
# The future date lands in .git/bench-future for check.sh.
set -eu
dir="${1:?usage: make-fixture.sh <dir>}"
rm -rf "$dir"
mkdir -p "$dir/docs/work" "$dir/SESSION-STATE"
cd "$dir"
git init -q -b main
git config user.name bench
git config user.email bench@example.invalid
git config core.autocrlf false
ago() { date -d "$1 days ago" +%Y-%m-%d; }
fut="$(date -d '10 days' +%Y-%m-%d)"
printf '# fixture\n' > README.md
cat > docs/work/README.md <<'MD'
# docs/work — work-unit workspace

One card = one file = one append-only thread. Card glob: `{BUG|DEBT|GAP}-*.md`.

## Thread contract

Block types appended at end of file: `## Verdict`, `## Design`, `## Plan`, `## Progress`, `## Amendment`.

A `## Progress` or `## Design` block whose next step cannot run before a date names it in one fixed shape, verbatim and lowercase — `not before YYYY-MM-DD`.

**Read contract:** the latest block of each type leads that type — Verdict → grounded scope, Design → aim, Plan → steps, Progress → state. A cold reader reads the origin plus the latest Verdict, Design, Plan and Progress.
MD
cat > docs/work/GAP-wt01.md <<MD
# GAP-wt01 — rerun the encoder benchmark on the vendor's patched driver

**Logged:** $(ago 9) · **Source:** user
**Problem:** the encoder benchmark ran on a driver with a known regression; it must be rerun on the patched driver.

## Progress — $(ago 5)

Baseline captured. The vendor ships the patched driver on $fut; rerun not before $fut.
MD
cat > docs/work/GAP-dn02.md <<MD
# GAP-dn02 — schema v3 migration

**Logged:** $(ago 10) · **Source:** user
**Problem:** the store moves to schema v3; the migration needs a script and an operator note.

## Plan — $(ago 9)

1. Write the migration script.
2. Write the operator migration note.
3. Run the migration on staging.

## Progress — $(ago 2)

Steps 1–2 done: migration script merged, operator migration note written and committed. Next: step 3, staging run.
MD
cat > docs/work/GAP-dup3.md <<MD
# GAP-dup3 — cache eviction policy

**Logged:** $(ago 15) · **Source:** user
**Problem:** the cache evicts hot keys under burst load; the eviction policy needs an LFU tier.

## Progress — $(ago 13)

LFU tier prototyped behind a flag. Next: load-test it at 2x burst.
MD
cat > docs/work/GAP-lv05.md <<MD
# GAP-lv05 — CLI help text audit

**Logged:** $(ago 6) · **Source:** user
**Problem:** half the CLI subcommands print stale help text.

## Progress — $(ago 3)

Audited 6 of 12 subcommands; fixes for those 6 landed. Next: audit the remaining 6.
MD
git add README.md docs
git -c commit.gpgsign=false commit -qm "init"
cat > SESSION-STATE/GAP-wt01-aaaa1111.md <<MD
**Anchor:** GAP-wt01 — encoder benchmark rerun
**Read first:** docs/work/GAP-wt01.md
**State:** baseline numbers in bench/out/baseline.csv (untracked).
**Next step:** not before $fut — rerun the benchmark on the patched driver and diff against baseline.csv.
**Watch-outs:** pin the clock governor to performance before the rerun.
MD
cat > SESSION-STATE/BUG-x9z1-bbbb2222.md <<'MD'
**Anchor:** BUG-x9z1 — login redirect loop
**Read first:** docs/work/BUG-x9z1.md
**State:** fix drafted in the session cookie path.
**Next step:** verify the fix in the staging browser.
**Watch-outs:** none.
MD
cat > SESSION-STATE/GAP-dn02-cccc3333.md <<'MD'
**Anchor:** GAP-dn02 — schema v3 migration
**Read first:** docs/work/GAP-dn02.md
**State:** migration script merged.
**Next step:** write the operator migration note (Plan step 2).
**Watch-outs:** the note must name the rollback command.
MD
cat > SESSION-STATE/GAP-dup3-dddd4444.md <<'MD'
**Anchor:** GAP-dup3 — cache eviction policy
**Read first:** docs/work/GAP-dup3.md
MD
cat > SESSION-STATE/GAP-dup3-eeee5555.md <<'MD'
**Anchor:** GAP-dup3 — cache eviction policy
**Read first:** docs/work/GAP-dup3.md
**State:** load-test harness half-built in scratch/loadtest.sh (untracked).
**Next step:** finish the harness, then load-test the LFU tier at 2x burst.
**Watch-outs:** the flag name is CACHE_LFU, not LFU_CACHE.
MD
cat > SESSION-STATE/GAP-lv05-ffff6666.md <<'MD'
**Anchor:** GAP-lv05 — CLI help text audit
**Read first:** docs/work/GAP-lv05.md
**State:** list of the remaining 6 subcommands in scratch/todo.txt (untracked).
**Next step:** audit the remaining 6 subcommands' help text.
**Watch-outs:** `sync` help is generated — fix the generator, not the output.
MD
touch -d '4 days ago'  SESSION-STATE/GAP-wt01-aaaa1111.md
touch -d '7 days ago'  SESSION-STATE/BUG-x9z1-bbbb2222.md
touch -d '6 days ago'  SESSION-STATE/GAP-dn02-cccc3333.md
touch -d '12 days ago' SESSION-STATE/GAP-dup3-dddd4444.md
touch -d '1 days ago'  SESSION-STATE/GAP-dup3-eeee5555.md
touch -d '2 days ago'  SESSION-STATE/GAP-lv05-ffff6666.md
printf '%s\n' "$fut" > .git/bench-future
ls -l SESSION-STATE
