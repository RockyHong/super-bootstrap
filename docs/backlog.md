# Backlog

New rows route through `/super-bootstrap:log` — one funnel for classification, dedup, and ID assignment. Bugs, debt, design gaps, and unverified feature ideas all land here as rows; whether each is real or worth doing is decided at `/super-bootstrap:todo` triage on pickup, not at capture.

**Row deletion:** the resolving session — via `/super-bootstrap:commit` doc-sync, or manually on resolve. Direct `git commit` skips the sweep; clean up stale rows when noticed.

**Three categories** distinguished by ID prefix:

- **`BUG-###`** — broken behavior. Surface symptom may hide deeper cause.
- **`DEBT-###`** — working but rotting (test fixture rot, stale dep, cleanup owed).
- **`GAP-###`** — design gap or unverified capability idea, never properly specced. Forward feature ideas land here; triage decides drop / spec.

No phase prescription per category — when an item rolls into a session, the harness phase triage decides which superpowers phases run. Surface "clear fix" can become design work after evidence; pre-routing biases that judgment.

**ID high-water mark:** `BUG-002` · `DEBT-000` · `GAP-001` — last consumed ID per category. Next ID = max+1 from this line, bumped in the same write. Resolved rows are deleted but their IDs stay consumed (history = `git log --grep="<id>"`); never re-derive IDs from open rows.

**Row shape** — stable ID + frozen claim, newest at top. When resolved, **delete the row** — git history is the archive.

```
### {BUG|DEBT|GAP}-### — {one-line summary}

**Logged:** {date} · **Source:** {where this surfaced}
**Problem:** {what's broken / rotting / missing}
**Area:** {files or module}
**Prior:** {one-line suspected cause or proposed fix — optional}
```

The claim is write-once — captured at the richest-context moment, read cold by later sessions. Sessions that pick a row up work from it; working history lives in specs/plans, not on the row.

---

## Open

### BUG-002 — greenfield emits permanent docs/specs/ files + pre-seeds GAP rows, orphaning forward design from todo scan

**Logged:** 2026-06-24 · **Source:** user, script-captioner greenfield bootstrap (commit c83562d)
**Problem:** `/super-bootstrap` greenfield (Phase 1-2) writes forward feature specs into `docs/specs/` and pre-seeds GAP rows, violating SKILL.md:9 ("No forward feature list is seeded"). `docs/specs/` is todo-invisible — `/super-bootstrap:todo` scans only `docs/superpowers/specs|plans` + `docs/backlog.md` (todo SKILL.md:3) — so those specs are orphaned from the open-work state a cold session reconstructs. Reproduced in script-captioner: 3 files (`p1-word-bullet-srt.md`, `sentence-segmentation.md`, `aligner-proxy-and-media.md`) have no backlog row and are unreachable by todo. Axiom I (speculative scaffolding before code) + Axiom VII (truth home outside the scanner) both violated.
**Area:** `plugins/super-bootstrap/skills/super-bootstrap` (greenfield Phase 1-2); interaction with `plugins/super-bootstrap/skills/todo` scan set
**Prior:** route conflated `docs/specs/` (permanent SSOT, spec-phase only, todo-invisible) with the correct greenfield home for forward design (GAP backlog rows, todo-visible). Fix direction + full repro in `docs/superpowers/scenarios/greenfield-specs-orphaned.md`.
