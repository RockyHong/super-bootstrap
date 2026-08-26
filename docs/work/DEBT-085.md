# DEBT-085 — `harness-bootstrap` § 2a-scale asks the installer to add a CLAUDE.md § Rules bullet before § 2b has written CLAUDE.md

**Logged:** 2026-08-26 · **Source:** cold dry-run of the revised § 2a-scale text while resolving DEBT-080 (the executing agent flagged it; pre-existing, not introduced by that fix)
**Problem:** In [`harness-bootstrap/SKILL.md`](../../plugins/super-bootstrap/skills/harness-bootstrap/SKILL.md) § 2a-scale precedes § 2b, yet § 2a-scale's last placement step appends a `venue-map.md` bullet to CLAUDE.md § Rules. On a fresh install CLAUDE.md does not exist at that point — § 2b creates it — so a cold installer either fails the step, creates a stub CLAUDE.md that § 2b then overwrites, or silently defers with no instruction to come back. Sync runs mask it because CLAUDE.md already exists.
**Area:** `plugins/super-bootstrap/skills/harness-bootstrap/SKILL.md` § 2a-scale (final placement step) · § 2b (CLAUDE.md scaffold)
**Prior:** Move the § Rules-bullet step after § 2b (or into § 2b's rules-summary pass) so the file it edits exists; a sequencing change across the two sections, not a wording tweak.
**Test-feel:** doc-only
**Blast:** local
