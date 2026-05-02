# Backlog

Single tracker for deferred items — things found but not fixing now. Solo-dev queue. Scanned by doc sync at commit. When picking up new work, scan related items here to bundle.

**Three categories** distinguished by ID prefix:

- **`BUG-###`** — broken behavior with a clear fix. Routes direct to implementation.
- **`DEBT-###`** — working but rotting (test fixture rot, stale dep, cleanup owed). Routes direct to implementation.
- **`GAP-###`** — design gap, never properly specced. Routes through `superpowers:brainstorming` first, then spec → plan → execute.

Format per item: stable ID, short title, affected area, why it matters, proposed fix (BUG/DEBT) or what's missing (GAP). Newest at top. When resolved, **delete the item** — git history is the archive.

---

## Open

*(seeded as items are surfaced during reviews, audits, or development)*
