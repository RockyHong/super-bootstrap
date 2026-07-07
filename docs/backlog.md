# Backlog

New rows route through `/super-bootstrap:log` — one funnel for classification, dedup, and ID assignment. Bugs, debt, design gaps, and unverified feature ideas all land here as rows; whether each is real or worth doing is decided at `/super-bootstrap:todo` triage on pickup, not at capture.

**Row deletion:** the resolving session — via `/super-bootstrap:commit` doc-sync, or manually on resolve. Direct `git commit` skips the sweep; clean up stale rows when noticed.

**Three categories** distinguished by ID prefix:

- **`BUG-###`** — broken behavior. Surface symptom may hide deeper cause.
- **`DEBT-###`** — working but rotting (test fixture rot, stale dep, cleanup owed).
- **`GAP-###`** — design gap or unverified capability idea, never properly specced. Forward feature ideas land here; triage decides drop / spec.

No phase prescription per category — when an item rolls into a session, the harness phase triage decides which superpowers phases run. Surface "clear fix" can become design work after evidence; pre-routing biases that judgment.

**ID high-water mark:** `BUG-008` · `DEBT-008` · `GAP-009` — last consumed ID per category. Next ID = max+1 from this line, bumped in the same write. Resolved rows are deleted but their IDs stay consumed (history = `git log --grep="<id>"`); never re-derive IDs from open rows.

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

### GAP-009 — version skew leaves partial-hook state undetected; no re-sync reminder

**Logged:** 2026-07-07 · **Source:** BUG-008 fix session; git history — `docsync-gate.sh` introduced c1e2820, `docsync-scan.sh` + `docsync-stamp.sh` added one release later in 59abb4e
**Problem:** doc-sync hook assets did not ship atomically — a repo bootstrapped from a c1e2820-era harness-bootstrap has the gate hook installed but no scan script, and stays in that skew state until it re-runs `/super-bootstrap` (copy-on-drift only re-syncs on next invocation). Two coupled effects surface from this real partial-hook state: (1) `/super-bootstrap:commit` §3's BUG-008 fix (commit f19ada3) correctly probes gate-live and takes the "run scan" branch, but then emits a raw `bash: file-not-found` instead of a clear "doc-sync hooks are stale — run `/super-bootstrap` to sync" message; (2) nothing proactively detects a stale/partial runway+hooks install and nudges re-sync — the plugin ships zero hooks (skills only), and `/super-bootstrap:todo`'s skip-gate conflates "runway absent (never bootstrapped)" with "runway present, no open rows," both printing "empty board / cycle complete."
**Area:** `plugins/super-bootstrap/skills/commit/SKILL.md` §3; `plugins/super-bootstrap/skills/todo/SKILL.md` skip-gate; harness-bootstrap hook-install / copy-on-drift sync
**Prior:** candidate owner is `/super-bootstrap:todo`'s skip-gate (pull-based — a user running `/todo` has signaled intent to work the pipeline) — split "runway/hooks absent-or-stale -> suggest `/super-bootstrap`" from "runway present, empty -> cycle complete"; plan B is a `SessionStart` hook (ambient, but a new architectural surface — plugin ships none today). Whether §3 also gets an explicit third branch (gate-present/scan-absent -> stale message vs raw error) is a separate decision, deferred to triage alongside owner pick. Related to GAP-008 (gate-live path undogfooded in-repo) but distinct — that's test-coverage, this is runtime robustness for consumer repos hitting real version skew — not folded into it.

### GAP-008 — commit §3 doc-sync gate's "gate-live" path never dogfooded in-repo

**Logged:** 2026-07-07 · **Source:** BUG-008 fix session, commit f19ada3
**Problem:** this plugin-source repo has no `.claude/hooks/` installed, so `/super-bootstrap:commit`'s §3 doc-sync gate only ever exercises the "gate absent" branch here. The "gate live" path (run `docsync-scan.sh`, write `.git/docsync-token`, gate consumes it) is never exercised on this repo's own commits — only validated for consumer repos.
**Area:** `.claude/hooks/` (absent in this repo) vs `harness-bootstrap` hook-install procedure; `/super-bootstrap:commit` §3
**Prior:** two options surfaced, undecided — (a) install the source repo's own harness-bootstrap hooks to dogfood gate-live on its own commits, or (b) accept gate-live coverage lives only in consumer repos. Decision deferred to triage.

### GAP-003 — harness-collab-optimization effect unmeasured against spec's acceptance targets

**Logged:** 2026-07-06 · **Source:** harness-collab-optimization session, spec `docs/superpowers/specs/harness-collab-optimization.md` § 6 acceptance criteria, item C1
**Problem:** the optimization's real-world effect is unverified — no harvest window has yet checked: premature-commitment not top pain shape (first time in 4 windows), model-guard deny hits ≈0 (baseline 35/window), principles-load user re-assertions →0 (baseline ~15/session worst case), authoring inline:dispatch ratio moving from ~13:1 toward dispatch-majority, zero regressions on preserved wins (todo skip-dispatch fast path, four zero-retry dispatch lanes, audit gate).
**Area:** next harness-pain harvest window (spec deleted post-merge; acceptance targets inlined above, full text @ c1e2820)
**Prior:** pure measurement pass at the next harvest window, no code change.
