=== docs/work/GAP-31.md ===
# GAP-31 — Tune the cache eviction window

**Logged:** 2026-11-20 · **Source:** perf report
**Problem:** `cache/evict.ts` evicts after 10 minutes; hit rate on repeat queries is low.
**Area:** `cache/evict.ts`, `scripts/hit-stats.sh`

## Verdict — auto-fix · 2026-11-21

**Fix-shape:** mechanical
Raise the window to 30 minutes behind the `EVICT_MIN` setting, then compare `scripts/hit-stats.sh` output over one week of traffic and keep the better window.

## Progress — 2026-11-24 · session

Window raised to 30 minutes and deployed on 2026-11-24. Next: run `scripts/hit-stats.sh` over the week and pick the window — not before 2026-12-10, when a full week of data has landed.

=== docs/work/GAP-32.md ===
# GAP-32 — Rotate the nightly log archive

**Logged:** 2026-10-20 · **Source:** disk alert
**Problem:** `logs/archive/` grows without bound; `jobs/rotate.sh` should keep 30 days.
**Area:** `jobs/rotate.sh`, `tests/rotate.bats`

## Verdict — auto-fix · 2026-10-21

**Fix-shape:** mechanical
Delete archive files older than 30 days in `jobs/rotate.sh`; `tests/rotate.bats` covers it with dated stub files.

## Progress — 2026-10-22 · session

Stub fixture written in `tests/rotate.bats`. Next: write the deletion in `jobs/rotate.sh` — not before 2026-11-01, when the old archive format is retired.

=== docs/work/GAP-33.md ===
# GAP-33 — Retry flaky upload in the sync job

**Logged:** 2026-11-11 · **Source:** CI failure
**Problem:** `jobs/sync.sh` fails the whole run when one upload times out.
**Area:** `jobs/sync.sh`, `tests/sync.bats`

## Verdict — auto-fix · 2026-11-12

**Fix-shape:** mechanical
Wrap the upload call in a three-try retry with backoff; `tests/sync.bats` covers it with a stubbed timeout.

