# DEBT-70b1 — session-close pick rows and predicate route 5 stay under their stated pass conditions

**Logged:** 2026-11-04 · **Source:** DEBT-h3p5 build, two wording rounds (`bench/session-close-moves/` README Findings); DEBT-xs75 RED (`bench/dimension-predicate-audit/` README Findings)
**Problem:** Both builds stopped at their round budget with these unmet:
- `(p5)` 0 of 3 on `full`: picks nest their commits under one `[commit]` row where `session-close` says one row per commit. All walks land the partition, so this is row shape only. Open: accept a nested partition, or hold the text.
- `(p2)` 5 of 6: one `full` run's resolve row reads "the two doc-update rows above state it" instead of carrying the edit, so that outcome can be declined apart from the resolve.
- Stale row in `bench/session-close-judgment/`: `(e)` 2 of 3 on the second round, 3 of 3 on the first. Three runs cannot separate this from variance.
- `dimension-predicate.md` route 5: one of 3 arm runs keeps the status pointer, on text the edit did not change; the control flagged it 3 of 3.
- No reading: park drafts in the judgment, ledger-clear and park as sole writing moves, a path two changes touch, a declined row, the hunk-grain lane per part, a close with only a fix-now move (no RED). The Skill-tool loading order stays with the device case in `docs/test-queue.md`.
**Area:** `plugins/super-bootstrap/skills/session-close/SKILL.md` step 3 and step 4; `plugins/super-bootstrap/skills/commit/SKILL.md` § Session-close entries; `plugins/super-bootstrap/skills/check-docs-consistency/assets/dimension-predicate.md`
