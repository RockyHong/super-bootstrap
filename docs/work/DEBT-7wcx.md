# DEBT-7wcx — release-init commits a harness file outside the commit door

**Logged:** 2026-11-24 · **Source:** docs-consistency scan 2026-11-24 (`.review/docs-consistency-2026-11-24.md`), via `/super-bootstrap:triage-report`
**Problem:** `release-init/SKILL.md` §9-§10 commits the generated `.claude/skills/release/SKILL.md` with raw `git commit -o` and offers its own push, bypassing the commit door (doc-sync, harness audit) that `commit/SKILL.md:75` and the session-close Rules require (scope per docs-consistency scan 2026-11-24, unconfirmed)
**Area:** `plugins/super-bootstrap/skills/release-init/SKILL.md`
**Prior:** Decide: accepted exception (as `/release` is for manifests), or route through `/super-bootstrap:commit`.
