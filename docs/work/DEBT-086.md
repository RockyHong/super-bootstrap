# DEBT-086 — § 2a-scale's "2–4 one-line key points" for the `venue-map.md` rule bullet has no selection criterion

**Logged:** 2026-08-26 · **Source:** cold dry-run of the revised § 2a-scale text while resolving DEBT-080 (the executing agent counted ~6 defensible candidates in the rule body; pre-existing wording DEBT-080 did not name)
**Problem:** [`harness-bootstrap/SKILL.md`](../../plugins/super-bootstrap/skills/harness-bootstrap/SKILL.md) § 2a-scale tells the installer to add "2–4 one-line key points" to the CLAUDE.md § Rules bullet for the seeded `venue-map.md`, but names no criterion for which points — the rule body offers more candidates than the cap. Two cold installers produce two different bullets; a sync run then reports the difference as drift.
**Area:** `plugins/super-bootstrap/skills/harness-bootstrap/SKILL.md` § 2a-scale (§ Rules bullet sentence) · `assets/claude-md-skeleton.md` § Rules (bullet form)
**Prior:** Either ship the bullet's key points verbatim in the skeleton (one fixed text, drift-comparable) or state the selection rule (e.g. one point per top-level § of the rule that a gateway decides on before opening the rule).
**Test-feel:** doc-only
**Blast:** local
