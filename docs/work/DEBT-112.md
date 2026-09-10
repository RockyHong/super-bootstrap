# DEBT-112 — harness-bootstrap: 2a-scale "skip if markers present" vs § Pipeline-owned fact-fields drift — precedence on re-run unstated

**Logged:** 2026-09-10 · **Source:** GAP-073 verify run (cold executor, scale-module re-run on a fixture whose `docs/work/README.md` fact-fields block was stale)
**Problem:** § 2a-scale step 6 says insert the `card-fact-fields.md` marker-delimited block into `docs/work/README.md`, "skip if the markers are already present" — read literally, content inside present markers is never re-checked. § Pipeline-owned separately lists that marker block as drift-checked. A re-run on a repo carrying an older block shape (Venue / Blocked-on vs the current Test-feel / Stochastic / Blast) hits both rules; the executor treated it as a `⚠ drifted → updated` row by inference. State which rule wins: marker-presence is the first-install guard, drift owns re-run.
**Area:** `plugins/super-bootstrap/skills/harness-bootstrap/SKILL.md` § 2a-scale step 6; § Pipeline-owned scale-module line
**Prior:** Step 6 predates the fact-fields block joining the drift list; one clause ("markers present → drift-check the block, § 2b") closes it.
**Test-feel:** doc-only · **Blast:** local
