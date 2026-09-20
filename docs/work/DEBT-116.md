# DEBT-116 — rot scan has no frozen-provenance skip, so history docs re-hit every sync

**Logged:** 2026-09-20 · **Source:** observed during the runway 2.51.0 → 2.51.1 sync this session
**Problem:** `harness-bootstrap` § 2b's rot scan greps every pipeline-owned file in scope for each rename-map `old` literal. A `dimension: history` doc preserves old literals by construction — [`docs/decisions.md`](../decisions.md)'s own scope header binds "existing row text is never deleted or reworded" — so every hit there is structurally undeclinable-once: this sync produced 7 rot rows in that one file, each needing its own decline decision, and the next sync produces the same 7. One of them is worse than noise: the row at `docs/decisions.md:40` records the `sp-bootstrap` grep hazard itself, so migrating its literal would destroy the evidence the row exists to hold. The sibling door already solves this class — [the commit door's frozen-provenance exemption](../../plugins/super-bootstrap/skills/commit/SKILL.md) drops `dimension: history` docs from `terms` / `hits` / `refs` while keeping the link check over them — so the two doors in one plugin disagree on whether a history-dimension doc is scannable prose.
**Area:** `plugins/super-bootstrap/skills/harness-bootstrap/SKILL.md` § 2b Rot scan; `assets/rename-map.md` § Scan guidance
**Prior:** Suspected shape (not settled) — give the rot scan the commit door's frozen-provenance predicate: skip `dimension: history` docs and card threads, keep every other pipeline-owned file strict.
**Test-feel:** doc-only
**Blast:** pkg
