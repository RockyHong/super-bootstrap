# DEBT-073 — harness-bootstrap first-run handoff names only techstack + overview

**Logged:** 2026-08-21 · **Source:** DEBT-072 triage verdict — adjacent surface scoped out of that fix
**Problem:** `harness-bootstrap/SKILL.md` Phase 3 first-run handoff text ("Skeleton `docs/techstack.md` and `docs/overview.md` carry detected facts …") names only those two seeded docs, while the run also lands `CODING_STANDARDS.md`, `docs/decisions.md`, `docs/specs/`, `docs/work/`, rules, and hooks. Same under-report class as DEBT-072, on a run-report surface rather than the contract: a first-time user reads the handoff as what was written and misses the rest.
**Area:** `plugins/super-bootstrap/skills/harness-bootstrap/SKILL.md` Phase 3 handoff block (~line 565)
**Prior:** Open wording call the DEBT-072 aim did not settle — should the handoff read as an inventory of everything seeded, or stay a two-doc pointer to where detected facts landed? Decide that first; the edit is one paragraph either way. Harness edit — `audit-harness-edits` binds.
