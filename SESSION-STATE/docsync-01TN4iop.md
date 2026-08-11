# Carry — GAP-058 doc-sync redesign, phase D pickup

**Anchor:** finish [`GAP-058`](../docs/work/GAP-058.md) — phases A–C shipped; remaining = CCM handshake verification, then phase D behind the link-coverage gate. Operator returns via `session-continue` after the CCM-side session lands.

**Read first**

- [`docs/work/GAP-058.md`](../docs/work/GAP-058.md) § Design + § Progress — everything durable lives here (fork answers, mechanization map, phase state, commit shas).
- [`docs/decisions.md`](../docs/decisions.md) reverse-link-gate row — phase D's entry gate (hybrid trigger only after coverage measured trustworthy).
- [`CLAUDE.md`](../CLAUDE.md) § Doc Sync — guarantee rewrite (write → read boundary wording) is deliberately deferred into D; skeleton mirrors it.

**State**

B + C sb-side + release shipped and pushed: v2.33.0 (`a04a375`), tag on origin. A sits in CCM inbox (`invert-doc-link-contradiction-edge-20260811-155004`). CCM was mid-processing at close; sb published, so CCM's retire (hook copy + bench) is fully unblocked. Tree clean, nothing in motion locally.

**Next step**

1. Verify CCM side landed: rule inversion served back into `.claude/rules/ssot-doc-link.md` + `.claude/guidelines/work-discipline/doc-link-discipline.md`, and CCM's hook/bench copies retired.
2. D's bypass first: one-time asserting-line link backfill over `docs/**` so link coverage becomes measurable (rules only govern future authoring; backfill covers the stock).
3. Coverage trustworthy → phase D: commit-door shrink (whole-surface scan → mechanical reverse-lookup + diff-scoped residual) + CLAUDE.md § Doc Sync guarantee rewrite + skeleton mirror. `d3161f3` fixture re-measure before/after.

**Watch-outs**

- Running install lags until `/plugin update super-bootstrap` — the commit door executes the installed text, not the repo's. Update before any measurement.
- This repo's `.claude/hooks/consult-check-*` are still the CCM-planted copies (no FROZEN marker). First `harness-bootstrap` re-sync re-copies from the new assets — expected drift, not a bug.
- Fixture rebuild: `git worktree add --detach <path> d3161f3`; prompt = that commit's diff + date, pasted inline. Never paraphrase the diff from memory — that channel leaks the answer key.
- Deviation on record: the doc-sync label syncs (CLAUDE.md, skeleton, READMEs) shipped without a third cold probe — fix shapes came from the two cold reports themselves.
- Token count is not a cost metric here; tier is not the lever (both measured, closed — do not re-propose).
