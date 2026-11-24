# BUG-54wd — A harness-file card loops between autorun and needs-me and never surfaces

**Logged:** 2026-11-24 · **Source:** docs-consistency scan 2026-11-24 (`.review/docs-consistency-2026-11-24.md`), via `/super-bootstrap:triage-report`
**Problem:** `autorun/SKILL.md:26` routes a card whose deliverable is a harness file to `/super-bootstrap:needs-me`, but `shared/user-wall.md` has no harness-file criterion and needs-me lists only user-wall items, counting the rest as autorun's — the card circulates and never shows as a row (scope per docs-consistency scan 2026-11-24, unconfirmed)
**Area:** `plugins/super-bootstrap/shared/user-wall.md`, `skills/needs-me/SKILL.md`, `skills/autorun/SKILL.md`
**Prior:** Add a harness-deliverable criterion to `user-wall.md`, or route autorun's skip elsewhere.
