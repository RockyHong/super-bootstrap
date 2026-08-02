# Carry — non-mattpocock batch, next session opens work

## Anchor
Work the remaining non-mattpocock board items; mattpocock-parked group stays untouched until change B is discussed.

## Read first
- `docs/work/` open cards (13 after this session's closes)
- `docs/decisions.md` top rows (BUG-020 close + this session's precedents)

## State
Previous batch shipped and pushed (`ae66f7e..27ed1c8`, 8 commits): BUG-021 / DEBT-043 / GAP-044 / DEBT-042 resolved, BUG-020 closed via decisions row, specs-unify landed (docs/specs always scaffolded), GAP-042 parked with provenance. Tree clean, main == origin.

## Next step
Pickup order agreed with user:
1. DEBT-044 + DEBT-039 — verdict option A (README § Inline vs Dispatch rows), **user wants delicate per-item review before any execution — do not auto-run**
2. doc-sync trio as ONE design batch: DEBT-023 (cost down) + GAP-046 (premise predicate) + GAP-049 (wikilinks) — extensions vs cost pull opposite directions, decide together
3. GAP-050 grounding reshape — user-led discussion first
4. DEBT-022 residue — only AFTER GAP-050 (same surfaces: todo agent §4 + fixed floor)
5. DEBT-041 / GAP-048 — independent, anytime

## Watch-outs
- mattpocock parked group (DEBT-035, DEBT-040, GAP-038, GAP-042) — change B (spec §6) gates all four; discuss before touching
- Skeleton + SKILL.md changed this session → next `/release` propagates to bootstrapped repos
- CCM inbox holds pending finding `harness-audit-gate-shared-path-gap-20260802-130847` (device gate misses `plugins/*/shared/**`) — repo-side digest, not ours
