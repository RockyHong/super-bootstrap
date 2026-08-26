# DEBT-092 — § 2a-scale plants three `docs/` pillars without telling the installer to update a repo-local doc-routing rule

**Logged:** 2026-08-27 · **Source:** consumer sync report (v2.29.7 → v2.39.3) — the consumer's own `.claude/rules/doc-ownership.md` requires a routing-table row per new `docs/` pillar; the sync left the table short by three and the post-sync cold audit flagged it as a major finding, fixed forward in a second commit
**Problem:** [`harness-bootstrap/SKILL.md`](../../plugins/super-bootstrap/skills/harness-bootstrap/SKILL.md) § 2a-scale places `docs/parked.md`, `docs/test-queue.md`, `docs/outward.md` and closes with "Stage the placed files with the Phase 2c commit." Nothing in the step tells the installer that a repo may carry its own gate on new `docs/` pillars (a routing table, an ownership rule, a docs index) and that those need a row for each placed file. The skill cannot know the rule's shape, but it does know it just created three durable pillars — the moment to prompt the sweep is there and unused.
**Area:** `plugins/super-bootstrap/skills/harness-bootstrap/SKILL.md` § 2a-scale (closing line) · possibly § 2b-adopt (same gap when adopt mode plants a container)
**Prior:** One closing sentence in § 2a-scale: the placed files are new `docs/` pillars — a repo-local rule or index that enumerates `docs/` pillars (routing table, ownership rule, docs index) gains a row per placed file in the same commit.
**Test-feel:** doc-only
**Blast:** local
