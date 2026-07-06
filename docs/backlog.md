# Backlog

New rows route through `/super-bootstrap:log` — one funnel for classification, dedup, and ID assignment. Bugs, debt, design gaps, and unverified feature ideas all land here as rows; whether each is real or worth doing is decided at `/super-bootstrap:todo` triage on pickup, not at capture.

**Row deletion:** the resolving session — via `/super-bootstrap:commit` doc-sync, or manually on resolve. Direct `git commit` skips the sweep; clean up stale rows when noticed.

**Three categories** distinguished by ID prefix:

- **`BUG-###`** — broken behavior. Surface symptom may hide deeper cause.
- **`DEBT-###`** — working but rotting (test fixture rot, stale dep, cleanup owed).
- **`GAP-###`** — design gap or unverified capability idea, never properly specced. Forward feature ideas land here; triage decides drop / spec.

No phase prescription per category — when an item rolls into a session, the harness phase triage decides which superpowers phases run. Surface "clear fix" can become design work after evidence; pre-routing biases that judgment.

**ID high-water mark:** `BUG-006` · `DEBT-008` · `GAP-007` — last consumed ID per category. Next ID = max+1 from this line, bumped in the same write. Resolved rows are deleted but their IDs stay consumed (history = `git log --grep="<id>"`); never re-derive IDs from open rows.

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

### GAP-007 — Greenfield seed logs only 2 GAP cards; downstream bootstrap-loop chain not captured

**Logged:** 2026-07-07 · **Source:** user, gateway session on super-bootstrap repo
**Problem:** `/super-bootstrap:super-bootstrap` greenfield path seeds exactly two GAP cards (fill overview.md, fill techstack.md) via `/super-bootstrap:log` and stops at the resolve gate — it does not log downstream bootstrap-loop steps (e.g. `resolve-plugins`, which requires techstack.md filled first; release-init; remaining loop steps). After the two seed cards resolve, the rest of the bootstrap is implicit/undiscoverable from the backlog and the loop can stall silently.
**Area:** `super-bootstrap` skill, greenfield seed step
**Prior:** greenfield seed should capture the full downstream chain as cards with dependency/ordering noted (e.g. resolve-plugins depends on techstack.md filled); exact enumeration of remaining steps is triage's job at pickup, not capture's.

### GAP-006 — No update pipeline for an already-bootstrapped repo

**Logged:** 2026-07-07 · **Source:** user, gateway session on super-bootstrap repo
**Problem:** pipeline covers install + greenfield seed only — no explicit path to bring a repo bootstrapped at plugin version X forward to version Y (re-sync runway/pins/docs skeleton while preserving user edits to CLAUDE.md/docs).
**Area:** `super-bootstrap` + `harness-bootstrap` skills
**Prior:** depends on GAP-005's version stamp to detect staleness; needs brainstorm on what re-syncs vs preserves and how it slots against harness-bootstrap's existing fresh-vs-sync self-detection.

### GAP-005 — Version-stamp bootstrap artifacts for staleness detection

**Logged:** 2026-07-07 · **Source:** user, gateway session on super-bootstrap repo
**Problem:** `/super-bootstrap:super-bootstrap` and `/super-bootstrap:harness-bootstrap` leave no version marker on what they install/sync into a target repo — no later run or sync check can detect the installed runway is stale relative to the current plugin version.
**Area:** `super-bootstrap` + `harness-bootstrap` skills, target-repo CLAUDE.md / marker file
**Prior:** stamp a version onto the installed runway (e.g. CLAUDE.md or a dedicated marker file) at bootstrap time.

### GAP-003 — harness-collab-optimization effect unmeasured against spec's acceptance targets

**Logged:** 2026-07-06 · **Source:** harness-collab-optimization session, spec `docs/superpowers/specs/harness-collab-optimization.md` § 6 acceptance criteria, item C1
**Problem:** the optimization's real-world effect is unverified — no harvest window has yet checked: premature-commitment not top pain shape (first time in 4 windows), model-guard deny hits ≈0 (baseline 35/window), principles-load user re-assertions →0 (baseline ~15/session worst case), authoring inline:dispatch ratio moving from ~13:1 toward dispatch-majority, zero regressions on preserved wins (todo skip-dispatch fast path, four zero-retry dispatch lanes, audit gate).
**Area:** next harness-pain harvest window (spec deleted post-merge; acceptance targets inlined above, full text @ c1e2820)
**Prior:** pure measurement pass at the next harvest window, no code change.
