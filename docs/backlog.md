# Backlog

New rows route through `/super-bootstrap:log` — one funnel for classification, dedup, and ID assignment. Bugs, debt, design gaps, and unverified feature ideas all land here as rows; whether each is real or worth doing is decided at `/super-bootstrap:todo` triage on pickup, not at capture.

**Row deletion:** the resolving session — via `/super-bootstrap:commit` doc-sync, or manually on resolve. Direct `git commit` skips the sweep; clean up stale rows when noticed.

**Three categories** distinguished by ID prefix:

- **`BUG-###`** — broken behavior. Surface symptom may hide deeper cause.
- **`DEBT-###`** — working but rotting (test fixture rot, stale dep, cleanup owed).
- **`GAP-###`** — design gap or unverified capability idea, never properly specced. Forward feature ideas land here; triage decides drop / spec.

No phase prescription per category — when an item rolls into a session, the harness phase triage decides which superpowers phases run. Surface "clear fix" can become design work after evidence; pre-routing biases that judgment.

**ID high-water mark:** `BUG-008` · `DEBT-008` · `GAP-011` — last consumed ID per category. Next ID = max+1 from this line, bumped in the same write. Resolved rows are deleted but their IDs stay consumed (history = `git log --grep="<id>"`); never re-derive IDs from open rows.

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

### GAP-011 — docsync-gate token not session-scoped, lives past abandoned sessions

**Logged:** 2026-07-07 · **Source:** surfaced during the GAP-008 in-repo dogfood (commit 00a2809)
**Problem:** `.git/docsync-token` is not session-scoped — it persists in `.git/` across Claude sessions rather than being cleared at session boundaries. Direct evidence: a stale 0-byte token stamped 08:10 by a prior session was still present at session start ~11:00, even though these hooks had never been live in-repo before. Impact: an un-consumed stamp from an abandoned session A grants session B's first git commit a free gate pass — `docsync-gate` consumes the leftover token without session B ever running its own doc-sync scan, silently violating the gate's core guarantee ("the scan ran for THIS commit"). The gate is one-shot per token but not per-session.
**Area:** `plugins/super-bootstrap/skills/harness-bootstrap/assets/hooks/docsync-stamp.sh` (writer) + `docsync-gate.sh` (consumer); token lifecycle
**Prior:** three candidate fixes, deferred to triage — clear `.git/docsync-token` at `SessionStart`; timestamp/expire the token; or key it to a session id.

### GAP-010 — no detection for bootstrapped-but-stale hook/runway install

**Logged:** 2026-07-07 · **Source:** BUG-008 → GAP-009 fix session; GAP-009's tractable slice shipped in commit 7966373, this is the deferred remainder
**Problem:** nothing detects a repo that IS bootstrapped but whose hooks/runway are OUTDATED (all four hook assets present but lagging the plugin's current version). `/super-bootstrap:commit` §3 only catches gate-present-scan-ABSENT (version skew via missing `docsync-scan.sh`); `/super-bootstrap:todo`'s skip-gate only catches runway-ABSENT (`docs/superpowers/` entirely missing). Neither catches present-but-outdated, so a bootstrapped repo with stale hooks gets no proactive resync nudge from any trigger.
**Area:** `/super-bootstrap:todo` skip-gate (version-marker comparison); `harness-bootstrap` copy-on-drift sync; possible new `SessionStart` hook surface (plugin ships zero hooks today)
**Prior:** two open decisions deferred to triage — (1) where present-but-outdated detection should live: extend `/super-bootstrap:todo`'s skip-gate to compare installed hook version-markers against the plugin's assets, or surface it as `harness-bootstrap` copy-on-drift instead; (2) whether ambient detection warrants a new `SessionStart` hook (plan B, new architectural surface) vs staying pull-only via `/todo`.

### GAP-003 — harness-collab-optimization effect unmeasured against spec's acceptance targets

**Logged:** 2026-07-06 · **Source:** harness-collab-optimization session, spec `docs/superpowers/specs/harness-collab-optimization.md` § 6 acceptance criteria, item C1
**Problem:** the optimization's real-world effect is unverified — no harvest window has yet checked: premature-commitment not top pain shape (first time in 4 windows), model-guard deny hits ≈0 (baseline 35/window), principles-load user re-assertions →0 (baseline ~15/session worst case), authoring inline:dispatch ratio moving from ~13:1 toward dispatch-majority, zero regressions on preserved wins (todo skip-dispatch fast path, four zero-retry dispatch lanes, audit gate).
**Area:** next harness-pain harvest window (spec deleted post-merge; acceptance targets inlined above, full text @ c1e2820)
**Prior:** pure measurement pass at the next harvest window, no code change.
