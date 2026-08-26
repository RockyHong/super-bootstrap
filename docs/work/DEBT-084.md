# DEBT-084 — `doc-links.sh` `check` / `refs` / `index` scan `docs/**` + root README only, not the declared doc surface

**Logged:** 2026-08-26 · **Source:** BUG-046 implementation — the new `closure` mode needed `plugins/*/README.md` and grew its own `collect_surface()` beside the older `collect_docs()`
**Problem:** [CLAUDE.md § Doc Sync](../../CLAUDE.md#doc-sync-non-negotiable) defines the doc surface as `docs/**` + root `README` + plugin READMEs (`plugins/*/README.md`), and the commit door's §3 link-integrity check and citer lookup are contracted over that surface — but `collect_docs()` in [`doc-links.sh`](../../plugins/super-bootstrap/skills/commit/assets/doc-links.sh) lists only `docs/**/*.md` + `README.md`, so `check` never validates links inside a plugin README and `refs` never reports a plugin README as a citer. `closure` already uses the wider `collect_surface()`; two surface definitions now live in one script. No live harm today in this repo (its plugin README carries zero `.md` links), which is exactly why nothing caught it.
**Area:** `plugins/super-bootstrap/skills/commit/assets/doc-links.sh` (`collect_docs` vs `collect_surface`) · `plugins/super-bootstrap/skills/commit/SKILL.md` §3 (link check + citer lanes)
**Prior:** Point `check` / `refs` / `index` at `collect_surface()` and retire `collect_docs()`; add a test fixture with a plugin README carrying one good and one broken link; run `check` on this repo first to surface any latent breaks before widening.
**Test-feel:** unit
**Blast:** local
