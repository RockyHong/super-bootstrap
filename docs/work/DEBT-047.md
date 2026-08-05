# DEBT-047 — three 2.29.x paths shipped without a live run

**Logged:** 2026-08-05 · **Source:** carried across two session-carry files (`SESSION-STATE/`) since the 2.29.x smoke pass without ever landing a card home
**Problem:** Three shipped paths have no live-run evidence behind them, only static reads. (1) `drain`'s template warning — a fix landed to remove it; nobody has run drain since to confirm it is actually gone. (2) `drain`'s scoped-brief construction has never been exercised end-to-end. (3) `log`'s dedup-surface branch — the suspected-dup surface + amend/new-card/drop pick — has never fired in a real invoke. Each is one executable run away from evidence; deferring them behind "wait for real work to trigger" is what kept them homeless across sessions.
**Area:** `plugins/super-bootstrap/skills/drain/` (template warning, scoped brief), `plugins/super-bootstrap/skills/log/SKILL.md` § Procedure step 3
**Prior:** Verification debt, not suspected breakage — the runs may all pass. Cheapest shape is one drain invoke covering (1) and (2), plus a deliberate duplicate observation through `/super-bootstrap:log` for (3).
