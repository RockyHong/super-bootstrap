# Backlog

New rows route through `/super-bootstrap:log` — one funnel for classification, dedup, and ID assignment. Bugs, debt, design gaps, and unverified feature ideas all land here as rows; whether each is real or worth doing is decided at `/super-bootstrap:todo` triage on pickup, not at capture.

**Row deletion:** the resolving session — via `/super-bootstrap:commit` doc-sync, or manually on resolve. Direct `git commit` skips the sweep; clean up stale rows when noticed.

**Three categories** distinguished by ID prefix:

- **`BUG-###`** — broken behavior. Surface symptom may hide deeper cause.
- **`DEBT-###`** — working but rotting (test fixture rot, stale dep, cleanup owed).
- **`GAP-###`** — design gap or unverified capability idea, never properly specced. Forward feature ideas land here; triage decides drop / spec.

No phase prescription per category — when an item rolls into a session, the harness phase triage decides which superpowers phases run. Surface "clear fix" can become design work after evidence; pre-routing biases that judgment.

**ID high-water mark:** `BUG-002` · `DEBT-005` · `GAP-002` — last consumed ID per category. Next ID = max+1 from this line, bumped in the same write. Resolved rows are deleted but their IDs stay consumed (history = `git log --grep="<id>"`); never re-derive IDs from open rows.

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

### DEBT-005 — todo SKILL.md has two divergent dispatch-flow descriptions

**Logged:** 2026-07-06 · **Source:** Claude-initiated capture — out-of-scope finding from a build subagent's report on branch feat/harness-collab-opt
**Problem:** `## Execution` `Steps:` list and `## Dispatch behavior` section describe the same dispatch flow with divergent content; only one carried the skip-gate before this branch's M1 fix. That divergence was the root cause of the dispatch-prep ordering bug fixed on feat/harness-collab-opt (~5-6K tokens of dispatch-prep files read before the empty-board gate ran). M1 builder surfaced it while applying the fix but left it unmerged per its surgical-edit constraint.
**Area:** `plugins/super-bootstrap/skills/todo/SKILL.md` (`## Execution` Steps list, `## Dispatch behavior` section)
**Prior:** merge the two into one procedure, or make one section canonical and cross-reference from the other.
