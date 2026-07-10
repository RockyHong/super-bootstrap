# GAP-025 — writing-plans consumption: uniform per-task ceremony + surface-group task sizing

## Findings

- **root cause (isolated):** a doctrine ABSENCE, not a broken line. Task-shape lives in the upstream `superpowers:writing-plans` skill body (not in this repo — confirmed: only `plugins/.../harness-bootstrap/assets/claude-md-skeleton.md` references it; no writing-plans skill vendored here). The dogfood consumption doctrine (`CLAUDE.md` § Development Workflow "The envelope" + § Dispatch) says nothing that (a) scales per-task verification depth to blast radius, nor (b) sizes tasks by logical-change-unit vs surface-group. So plan authors default to uniform full `/audit-harness-edits` per task and one-task-per-file-cluster — the two symptoms the card observed on the GAP-024 8-task run. `audit-harness-edits` already supports a centrality-scoped light-pass (card confirms T2 used it correctly); the gap is that nothing in the consumption prose *tells the planner to reach for it*.
- **fix precedent (verified):** the card's own family already shipped as sb-side carve-outs in `CLAUDE.md` § Dispatch routing prose — `a9f6371 refactor(dispatch): scale SDD re-review to fix grade (GAP-020)`, `a1eb6ef refactor(dispatch): add transcription carve-out; close DEBT-013/GAP-023`. GAP-025 is the same shape: a documented exception in routing prose, not an upstream writing-plans change. Confirms the Prior's placement call is settled by precedent.
- **scope reach:** `CLAUDE.md` § Development Workflow (writing-plans consumption) + § Dispatch + § Cluster routing — PLUS a closure into the shipped skeleton: `claude-md-skeleton.md` § Dispatch mirrors the dogfood § Dispatch near-verbatim (lines 40–45), so a general consumption carve-out pulls the skeleton counterpart in (per `repo-boundary.md` sync-direction), unless deliberately scoped dogfood-only. Not a single contained surface.
- **attempted:** static trace of the named surfaces + git-log of the sibling family. Stopped at verdict — the four auto-fix gates decide this before any deeper trace.

## Why not auto-fix (gate check)

1. root cause clear — partial (named as a doctrine absence, not a wrong line).
2. scope contained — NO: routing-doctrine authoring across mirrored files (dogfood CLAUDE.md + shipped skeleton) with an open same-surface family (GAP-018 route-line sizing, GAP-019 same-session no-placeholder — both cite the identical `§ Cluster routing` / writing-plans-consumption Area).
3. test strategy ∈ {unit, e2e} — **NO (decisive):** harness prose. Verification is `audit-harness-edits` (reasoning pass), not a writable failing repro. Per the envelope, a harness-file change verifies via audit, not tests → normal route.
4. no user judgment — NO: shaping a two-axis carve-out and reconciling it with the *existing* § Dispatch closure doctrine ("Judge by closure, not diff size" already governs unit-of-change) is a `design`-grade call. Fix-shape: **design** (routing-doctrine authoring / boundary call), not mechanical or systematic.

Any one of 2/3/4 forces surface; three fail. Route: **cluster 7 harness edit** → `load-harness-principles` pre / `audit-harness-edits` post (design-intact multi-axis prose → optionally cluster 3 `writing-plans` if decomposed).

## Decision needed

- **Batch or standalone?** GAP-025 edits the same `§ Cluster routing` / writing-plans-consumption / § Dispatch prose as still-open GAP-018 (route-line sizing by work type) and GAP-019 (same-session no-placeholder carve-out). Landing them separately = 3 overlapping edits + 3 audit passes over one prose region — the exact over-decomposition GAP-025 argues against. **recommendation:** batch the writing-plans-consumption/dispatch-sizing family (018/019/025) into one design pass + one audit + one commit; its own thesis (batch same-logical-change surfaces) applies to its own fix.
- **One carve-out or two?** The card's two axes (verification-depth scaling vs logical-change-unit task sizing) are separable and could read as one paragraph or two. **recommendation:** author as two adjacent bullets under writing-plans consumption — distinct triggers (Step-5 depth vs task-boundary drawing), shared home.
- **Skeleton propagation:** decide up front whether the carve-out is general (→ mirror into `claude-md-skeleton.md` § Dispatch, stripped of dogfood-only refs) or dogfood-specific (→ note it). It reads general. **recommendation:** general — propagate to the skeleton in the same pass.
