# DEBT-110 — review every plugin agent's `model:` pin against the current model family

**Logged:** 2026-09-05 · **Source:** user, after a read-out of the seven `plugins/super-bootstrap/agents/*.md` frontmatters
**Problem:** The agent pins are tier aliases assigned when the tiers were set — `triage` → `opus`; `triage-report`, `review-intake`, `premise-closure`, `doc-sync-scan`, `todo` → `sonnet`; `plugin-digest` → `haiku`. Broadly right, but the model family has moved since (Claude 5: Fable 5.1 / Opus 5 / Sonnet 5, with Haiku still at 4.5), so the tier-to-role mapping is untested against today's capability gaps and available tiers. Each pin needs a review: does the role's judgment grade still match the tier, is a tier above or below now the better fit, and does any door warrant the newest tier.
**Area:** `plugins/super-bootstrap/agents/*.md` frontmatter `model:` (7 files); `plugins/super-bootstrap/README.md` where it narrates tiers; `docs/specs/harness-architecture.md` if it fixes a tier rationale
**Prior:** The alias form (`opus` / `sonnet` / `haiku`) already floats to the newest model per tier, so the rot is in tier assignment, not version strings — re-judge per door by judgment grade × cost, and the pin is stale only where the tier itself changes.
**Test-feel:** `manual` · **Stochastic:** `llm`
