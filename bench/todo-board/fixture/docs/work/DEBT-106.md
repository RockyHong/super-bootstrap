# DEBT-106 — flaky visual snapshot suite

**Logged:** 2026-08-05 · **Source:** CI noise
**Problem:** Visual snapshot tests flake on font rendering deltas; suite red twice a week with no code change.
**Area:** tests/visual/

## Design — 2026-08-07

Pin the render container font stack and bump the diff threshold per component class. Success criteria: one green week, then manual verification of the snapshot set.

Approved — 2026-08-07.

## Plan — 2026-08-08

1. Pin font stack in the snapshot container
2. Per-class diff thresholds

## Progress — 2026-08-11

Both steps done; suite green four consecutive days.
