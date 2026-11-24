# BUG-vk2c — Parked doc says needs-me ignores parked entries; needs-me reads them

**Logged:** 2026-11-24 · **Source:** docs-consistency scan 2026-11-24 (`.review/docs-consistency-2026-11-24.md`), via `/super-bootstrap:triage-report`
**Problem:** `docs/parked.md:23` and `harness-bootstrap/assets/scale/parked-skeleton.md:23` say "`/super-bootstrap:needs-me` does not list either kind on its own", while `needs-me/SKILL.md:3`, `:18` scans `docs/parked.md` entries; the skeleton ships the line into consumer repos (scope per docs-consistency scan 2026-11-24, unconfirmed)
**Area:** `plugins/super-bootstrap/skills/harness-bootstrap/assets/scale/parked-skeleton.md`, `docs/parked.md`, `skills/needs-me/SKILL.md`
**Prior:** needs-me's behavior owns the truth; fix the skeleton line, then refresh `docs/parked.md`.
