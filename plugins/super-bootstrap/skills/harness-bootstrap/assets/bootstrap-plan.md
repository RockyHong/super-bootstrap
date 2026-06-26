# Pipeline Bootstrap Plan

**Goal:** Final adaptive seeding + cleanup for {project name}

**Context:** Pipeline scaffolded on {date}. CLAUDE.md is live. `docs/techstack.md` and `docs/overview.md` are seeded skeletons — `techstack.md` Runtime / Framework / Build & Dist carry detected manifest facts; `overview.md` Problem / User / Current State start empty and fill at GAP-card pickup; grown sections (Architecture Rules / Coding Patterns / Module Index / Data Flow / Key Boundaries) start empty and grow via doc-sync as code lands. Core plugin pins (superpowers + karpathy) sit in `.claude/settings.json`; stack-matched skill / MCP / hook curation runs as gated tier-2 via `/super-bootstrap` once the seed docs are substantive.

These tasks complete optional adaptive seeding (only the ones whose docs the runway scaffolded) and final bootstrap cleanup.

---

### Task 1: Seed Feature Specs *(only if `docs/specs/` was scaffolded)*

Write initial persistent specs for the project's existing features.

- [ ] **Identify 3-5 major features** from `docs/overview.md` (once Module Index has grown via doc-sync) and code structure
- [ ] **For each feature, write a spec at `docs/specs/{feature-slug}.md`** — first line `# {Feature Name}`, second line a one-paragraph intro stating what the feature does and why it exists, then product-level body: intent, user flow, cross-module interactions, design decisions. Code-light — no API tables or implementation details. Filename + heading convention is the catalog; no separate index file.
- [ ] **Present to user for review**
- [ ] **Commit**: `docs: seed persistent feature specs`

**Hard precondition — source-code features must exist.** Specs document features that are *already built*. A fresh / greenfield scaffold (no source code, Module Index empty) has nothing to spec: Task 1 does not apply and is dropped at write time. Pick it up only after feature commits have given doc-sync a grown Module Index to draw from. Forward design before code lives in `docs/overview.md` § Problem + GAP rows via `/super-bootstrap:log` — never a speculative `docs/specs/` file.

### Task 2: Seed Backlog

Walk the project once and seed any obvious deferred items already visible in code or recent history.

- [ ] **Scan for `TODO` / `FIXME` / `XXX` / `HACK` markers** in source — each is a candidate `DEBT-###` or `BUG-###`
- [ ] **Review test output** — failing or skipped tests with no recent fix attempt → `BUG-###` or `DEBT-###`
- [ ] **Note design gaps surfaced during the scan** — areas where behavior is hand-waved or unbuilt → `GAP-###`
- [ ] **Cap at ~5 items** — backlog is a queue, not a dump. If more candidates exist, list them but seed only the highest-signal ones
- [ ] **Present to user for review** — user prunes/approves
- [ ] **Commit**: `docs: seed backlog`

If no obvious items exist, leave the file with just its header — that's fine. The tracker grows organically as reviews surface things.

### Task 3: Cleanup

- [ ] **Delete this file** (`docs/superpowers/plans/bootstrap.md`) and `docs/superpowers/plans/bootstrap-sync-report.md` if present — bootstrap is complete
- [ ] **Verify `/super-bootstrap:todo` shows no active work** (unless the user has started real project work)
- [ ] **Commit**: `chore: complete pipeline bootstrap`

---

**Note on re-runs:** if `/super-bootstrap:harness-bootstrap` is run again later, this file gets regenerated. If `docs/specs/` and `docs/backlog.md` already exist with content, Tasks 1 and 2 are dropped — only Task 3 (cleanup) remains. Most refresh value on re-runs comes from gated tier-2 curation (skill/MCP picks against live sources, run by `/super-bootstrap` once seed docs are substantive), not from this plan. (Re-runs come via `/super-bootstrap`, which always dispatches the runway, or via `/super-bootstrap:harness-bootstrap` directly for a runway-only sync.)
