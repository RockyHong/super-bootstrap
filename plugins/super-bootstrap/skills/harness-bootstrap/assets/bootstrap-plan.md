# Pipeline Bootstrap Plan

> **For agentic workers:** Use `/sb-todo` to see current progress. Each task is independent and session-sized.

**Goal:** Final adaptive seeding + cleanup for {project name}

**Context:** Pipeline scaffolded on {date}. CLAUDE.md is live. `docs/techstack.md` and `docs/overview.md` are seeded skeletons — skeleton sections (Runtime / Framework / Build & Dist / Problem / User / State) carry detected facts; grown sections (Architecture Rules / Coding Patterns / Module Index / Data Flow / Key Boundaries) start empty and grow via doc-sync as code lands. Skill / MCP / hook picks already curated and pinned in `.claude/settings.json`.

These tasks complete optional adaptive seeding (only the ones whose docs were scaffolded in Phase 2 Q&A) and final bootstrap cleanup.

---

### Task 1: Seed Feature Specs *(only if `docs/specs/` was scaffolded)*

Write initial persistent specs for the project's existing features.

- [ ] **Identify 3-5 major features** from `docs/overview.md` (once Module Index has grown via doc-sync) and code structure
- [ ] **For each feature, write a spec at `docs/specs/{feature-slug}.md`** — first line `# {Feature Name}`, second line a one-paragraph intro stating what the feature does and why it exists, then product-level body: intent, user flow, cross-module interactions, design decisions. Code-light — no API tables or implementation details. Filename + heading convention is the catalog; no separate index file.
- [ ] **Present to user for review**
- [ ] **Commit**: `docs: seed persistent feature specs`

If `docs/overview.md` Module Index hasn't grown yet (fresh scaffold, no commits since), defer this task — pick it up after a few feature commits have given doc-sync something to grow.

### Task 2: Seed Backlog *(only if `docs/backlog.md` was scaffolded)*

Walk the project once and seed any obvious deferred items already visible in code or recent history.

- [ ] **Scan for `TODO` / `FIXME` / `XXX` / `HACK` markers** in source — each is a candidate `DEBT-###` or `BUG-###`
- [ ] **Review test output** — failing or skipped tests with no recent fix attempt → `BUG-###` or `DEBT-###`
- [ ] **Note design gaps surfaced during Q&A** — areas where behavior was hand-waved → `GAP-###`
- [ ] **Cap at ~5 items** — backlog is a queue, not a dump. If more candidates exist, list them but seed only the highest-signal ones
- [ ] **Present to user for review** — user prunes/approves
- [ ] **Commit**: `docs: seed backlog`

If no obvious items exist, leave the file with just its header — that's fine. The tracker grows organically as reviews surface things.

### Task 3: Cleanup

- [ ] **Delete this file** (`docs/superpowers/plans/bootstrap.md`) — bootstrap is complete
- [ ] **Verify `/sb-todo` shows no active work** (unless the user has started real project work)
- [ ] **Commit**: `chore: complete pipeline bootstrap`

---

**Note on re-runs:** if `/harness-bootstrap` is run again later, this file gets regenerated. If `docs/specs/` and `docs/backlog.md` already exist with content, Tasks 1 and 2 are dropped — only Task 3 (cleanup) remains. Most refresh value on re-runs comes from Phase 3c curation (skill/MCP picks against live sources), not from this plan. (Re-runs typically come via `/harness-bootstrap` directly — `/super-bootstrap` is the greenfield-gate entry; once code is landed, it just dispatches to `/harness-bootstrap`.)
