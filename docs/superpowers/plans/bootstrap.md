# Pipeline Bootstrap Plan

**Goal:** Final adaptive seeding + cleanup for super-bootstrap

**Context:** Pipeline scaffolded on 2026-06-21. CLAUDE.md is live. `docs/techstack.md` and `docs/overview.md` are seeded skeletons — skeleton sections (Runtime / Framework / Build & Dist / Problem / User / State) carry detected facts; grown sections (Architecture Rules / Coding Patterns / Module Index / Data Flow / Key Boundaries) start empty and grow via doc-sync as code lands. Skill / MCP / hook picks pinned in `.claude/settings.json` (pending user approval of the core-pin write).

These tasks complete optional adaptive seeding and final bootstrap cleanup.

---

### Task 2: Seed Backlog

Walk the project once and seed any obvious deferred items already visible in code or recent history.

- [ ] **Scan for `TODO` / `FIXME` / `XXX` / `HACK` markers** in source (skill/agent markdown) — each is a candidate `DEBT-###` or `BUG-###`
- [ ] **Note design gaps surfaced during Q&A / dogfooding** — areas where behavior was hand-waved → `GAP-###`
- [ ] **Cap at ~5 items** — backlog is a queue, not a dump. If more candidates exist, list them but seed only the highest-signal ones
- [ ] **Present to user for review** — user prunes/approves
- [ ] **Commit**: `docs: seed backlog`

If no obvious items exist, leave the file with just its header — that's fine. The tracker grows organically as reviews surface things.

### Task 3: Cleanup

- [ ] **Delete this file** (`docs/superpowers/plans/bootstrap.md`), `docs/superpowers/plans/bootstrap-qa.md`, and `docs/superpowers/plans/bootstrap-sync-report.md` if present — bootstrap is complete
- [ ] **Verify `/super-bootstrap:todo` shows no active work** (unless the user has started real project work)
- [ ] **Commit**: `chore: complete pipeline bootstrap`

---

**Note on re-runs:** if `/super-bootstrap:harness-bootstrap` is run again later, this file gets regenerated. If `docs/backlog.md` already exists with content, Task 2 is dropped — only Task 3 (cleanup) remains. Most refresh value on re-runs comes from Phase 3c curation (skill/MCP picks against live sources), not from this plan.
