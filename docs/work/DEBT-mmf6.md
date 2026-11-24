# DEBT-mmf6 — Two wait-signal strings, no named machine-read form

**Logged:** 2026-11-24 · **Source:** docs-consistency scan 2026-11-24 (`.review/docs-consistency-2026-11-24.md`), via `/super-bootstrap:triage-report`
**Problem:** `docs/work/README.md:34` uses `waiting on {party}` and `:52` uses `blocked on {party}`, both claimed to be read by needs-me and autorun (`log/SKILL.md:26`, `autorun/SKILL.md:37`); no doc names which string the reader keys on (scope per docs-consistency scan 2026-11-24, unconfirmed)
**Area:** `docs/work/README.md`, `plugins/super-bootstrap/shared/user-wall.md`, `skills/log/SKILL.md`, `skills/autorun/SKILL.md`
**Prior:** Confirm the real reader in `user-wall.md` before choosing one string.
