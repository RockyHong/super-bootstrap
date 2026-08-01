# DEBT-023 — doc-sync-scan per-commit Sonnet dispatch burns ~8-12k tokens for a read-only advisory

**Logged:** 2026-07-25 · **Source:** GitHub issue #24 (claude-config-manager 2026-07-23 harness-pain harvest, absorbed via /pull-issue)
**Problem:** `doc-sync-scan` fires per-commit after the grep-gate pre-filter hits and returns a text advisory with 0 writes by design. Observed burning ~8-12k output tokens per run; across a 5-day window: spotify-radio ×2 (~21.5k combined), stock (~11.5k), super-bootstrap (~19.7k). The grep-gate's false-positive rate or the scan's output scope may be too wide relative to its advisory-only yield.
**Area:** `agents/doc-sync-scan.md`; `/super-bootstrap:commit` commit door; grep-gate pre-filter
**Prior:** Raise grep-gate precision (reduce how often the Sonnet scan fires) or cap/trim the scan's output scope. Dropping doc-sync is not a direction (CLAUDE.md marks it non-negotiable).
