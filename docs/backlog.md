# Backlog

New rows route through `/super-bootstrap:log` — one funnel for classification, dedup, and ID assignment. Bugs, debt, design gaps, and unverified feature ideas all land here as rows; whether each is real or worth doing is decided at `/super-bootstrap:todo` triage on pickup, not at capture.

**Row deletion:** the resolving session — via `/super-bootstrap:commit` doc-sync, or manually on resolve. Direct `git commit` skips the sweep; clean up stale rows when noticed.

**Three categories** distinguished by ID prefix:

- **`BUG-###`** — broken behavior. Surface symptom may hide deeper cause.
- **`DEBT-###`** — working but rotting (test fixture rot, stale dep, cleanup owed).
- **`GAP-###`** — design gap or unverified capability idea, never properly specced. Forward feature ideas land here; triage decides drop / spec.

No phase prescription per category — when an item rolls into a session, the harness phase triage decides which superpowers phases run. Surface "clear fix" can become design work after evidence; pre-routing biases that judgment.

**ID high-water mark:** `BUG-002` · `DEBT-004` · `GAP-002` — last consumed ID per category. Next ID = max+1 from this line, bumped in the same write. Resolved rows are deleted but their IDs stay consumed (history = `git log --grep="<id>"`); never re-derive IDs from open rows.

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

### GAP-002 — release-init is a one-shot generator with no update/sync channel for already-bootstrapped consumers

**Logged:** 2026-06-28 · **Source:** surfaced while routing DEBT-004 (the /release version-mirror SSoT fix) 2026-06-28
**Problem:** `release-init` generates `.claude/skills/release/SKILL.md` as a one-shot product — step 1 is detect-existing → blind overwrite, no update path. When the upstream template improves, already-bootstrapped consumer repos (any project type — web/app/anything, not necessarily Claude plugins) have no way to pull template improvements into their existing generated skill without a full overwrite that discards their customizations. Note: DEBT-004's fix is Claude-plugin/self-hosted-marketplace specific and deliberately does NOT go into the generic template — so this is a generator-hygiene gap (no update channel for template improvements), not a vehicle to ship the DEBT-004 fix. Likely earns a brainstorm on merge strategy (patch improvements in vs regenerate-with-diff) while preserving consumer customization.
**Area:** `plugins/super-bootstrap/skills/release-init/SKILL.md`, `plugins/super-bootstrap/skills/release-init/assets/template.md`
**Prior:** Design question is merge vs regenerate-with-diff; either path must preserve consumer-side customization.

*(seeded as items are surfaced during reviews, audits, or development)*
