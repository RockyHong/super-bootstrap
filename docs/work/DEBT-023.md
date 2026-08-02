# DEBT-023 — doc-sync-scan per-commit Sonnet dispatch burns ~8-12k tokens for a read-only advisory

**Logged:** 2026-07-25 · **Source:** GitHub issue #24 (claude-config-manager 2026-07-23 harness-pain harvest, absorbed via /pull-issue)
**Problem:** `doc-sync-scan` fires per-commit after the grep-gate pre-filter hits and returns a text advisory with 0 writes by design. Observed burning ~8-12k output tokens per run; across a 5-day window: spotify-radio ×2 (~21.5k combined), stock (~11.5k), super-bootstrap (~19.7k). The grep-gate's false-positive rate or the scan's output scope may be too wide relative to its advisory-only yield.
**Area:** `agents/doc-sync-scan.md`; `/super-bootstrap:commit` commit door; grep-gate pre-filter
**Prior:** Raise grep-gate precision (reduce how often the Sonnet scan fires) or cap/trim the scan's output scope. Dropping doc-sync is not a direction (CLAUDE.md marks it non-negotiable).

## Design — 2026-08-02 · settled with user (trio batch: DEBT-023 + GAP-046 + GAP-049)

- **Immediate — card-lifecycle exemption.** Commit door grep-gate (`skills/commit/SKILL.md` §3): a diff whose paths all fall inside `docs/work/` (card-thread appends, card deletions, README high-water bump) → skip the gate. Card threads are self-contained; cross-card ID mentions are frozen provenance, not behavior narration. Mixed diff → gate runs on the non-`docs/work/` terms only. Evidence: 2026-08-02, two card-only diffs fired the scan (47k + 32k subagent tokens), both returned `clean`; every gate hit was a card cross-ID — systematic FP.
- **Structural — gate evolves grep → reverse-link lookup.** As GAP-049's reference graph gains coverage, stage-1 becomes a mechanical reverse-index query (who links to the touched files) instead of term-grep. Hybrid period per GAP-049's error-direction contract (grep OR link-hit fires); never pure link-gate on unmeasured coverage.
- **Metric.** Track scan fire-rate × clean-rate per release window; clean-rate persistently high after the exemption → the residual FP source gets its own card.
- **Verify.** The gate edit is behavior-shaping prose on a shipped skill → `superpowers:writing-skills` RED first (micro-test: card-only diff must skip, mixed diff must still fire), then `audit-harness-edits` on the harness diff.
