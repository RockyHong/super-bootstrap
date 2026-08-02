# Carry — non-mattpocock batch; trio designed, wave-1 ready for auto-runner

## Anchor
Work the remaining non-mattpocock board items; mattpocock-parked group stays untouched until change B is discussed.

## Read first
- `docs/work/DEBT-023.md`, `GAP-049.md`, `GAP-046.md` — `## Design` blocks (settled 2026-08-02, one batch)
- `docs/work/GAP-050.md` — judges-unification scope (blocks GAP-046's container)
- `docs/decisions.md` top two rows (consult-hook fork, BUG-020)

## State
Dispatch-audit round closed: DEBT-039 + DEBT-044 resolved (see `git log --grep`), DEBT-030 re-scoped (log collapse candidate + dedup-MCQ), DEBT-045 split (help mechanization). review-intake untouched — its fate rides GAP-050. doc-sync trio design settled + committed (`dab7ad9`): reference graph as shared substrate. Tree clean; main ahead of origin (push pending).

## Next step
`/auto-session-runner` wave-1, executing per Design blocks:
1. DEBT-023 card-lifecycle gate exemption — RED first (card-only diff skips, mixed diff fires), then `audit-harness-edits`
2. GAP-049 (a) broken-link script + (c) reverse index — mechanical, zero-model-token layer
3. GAP-046 routing predicate + interim enumeration — predicate only

**Walls (stop, route to user):** GAP-046 judge container (BLOCKED on GAP-050); GAP-050 itself (user-led discussion); `/release`; push; mattpocock parked group (DEBT-035/040, GAP-038/042).

Then: GAP-050 grounding-reshape discussion (user-led) → DEBT-022 residue (after GAP-050, same surfaces) → DEBT-041 / GAP-048 anytime.

## Watch-outs
- Skeleton + SKILL.md edits from wave-1 → next `/release` propagates to bootstrapped repos
- Gate exemption doesn't cover diffs touching `docs/` outside `docs/work/` — decisions.md edits still fire the scan by design
- CCM inbox holds pending finding `harness-audit-gate-shared-path-gap-20260802-130847` — repo-side digest, not ours
