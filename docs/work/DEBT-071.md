# DEBT-071 — plugin README narrates behavior but sits outside the doc-sync surface

**Logged:** 2026-08-14 · **Source:** release pre-flight after the todo mechanization landed
**Problem:** `plugins/super-bootstrap/README.md` § Inline vs Dispatch declares itself "the only home for inline-vs-dispatch rationale" and narrates per-skill behavior, but [CLAUDE.md § Doc Sync](../../CLAUDE.md#doc-sync-non-negotiable) scopes the doc surface to `docs/**` + root `README` + manifest description fields — so the commit door's grep-gate never enumerates it. The todo mechanization commit shipped with its `todo` row stale (caught manually at release, fixed by hand).
**Area:** CLAUDE.md § Doc Sync; plugins/super-bootstrap/README.md
**Prior:** add the plugin README to the declared doc surface — or move the Inline-vs-Dispatch table into `docs/`; triage decides which side of the install boundary the table belongs on.
