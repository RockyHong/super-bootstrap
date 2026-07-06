# Backlog

New rows route through `/super-bootstrap:log` — one funnel for classification, dedup, and ID assignment. Bugs, debt, design gaps, and unverified feature ideas all land here as rows; whether each is real or worth doing is decided at `/super-bootstrap:todo` triage on pickup, not at capture.

**Row deletion:** the resolving session — via `/super-bootstrap:commit` doc-sync, or manually on resolve. Direct `git commit` skips the sweep; clean up stale rows when noticed.

**Three categories** distinguished by ID prefix:

- **`BUG-###`** — broken behavior. Surface symptom may hide deeper cause.
- **`DEBT-###`** — working but rotting (test fixture rot, stale dep, cleanup owed).
- **`GAP-###`** — design gap or unverified capability idea, never properly specced. Forward feature ideas land here; triage decides drop / spec.

No phase prescription per category — when an item rolls into a session, the harness phase triage decides which superpowers phases run. Surface "clear fix" can become design work after evidence; pre-routing biases that judgment.

**ID high-water mark:** `BUG-005` · `DEBT-008` · `GAP-004` — last consumed ID per category. Next ID = max+1 from this line, bumped in the same write. Resolved rows are deleted but their IDs stay consumed (history = `git log --grep="<id>"`); never re-derive IDs from open rows.

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

### BUG-005 — `_hook_apply.sh` exits 1 on successful wire and idempotent no-op re-run

**Logged:** 2026-07-06 · **Source:** harness-collab-optimization session follow-up, spec `docs/superpowers/specs/harness-collab-optimization.md` item M4 [owner: claude-config-manager — execute from that repo]
**Problem:** `scripts/_hook_apply.sh` returns exit code 1 on both a successful wire and an idempotent no-op re-run despite printing success output; costs 3 extra confirm calls (observed f0d27529:291).
**Area:** claude-config-manager repo — `scripts/_hook_apply.sh`
**Prior:** return 0 on success paths (successful wire, no-op re-run); reserve non-zero for actual failure.

### BUG-004 — session-close single-option AskUserQuestion can never render

**Logged:** 2026-07-06 · **Source:** harness-collab-optimization session follow-up, spec `docs/superpowers/specs/harness-collab-optimization.md` item D2 [owner: claude-config-manager — execute from that repo]
**Problem:** session-close's push-confirm AskUserQuestion offers a single option; schema requires ≥2 options, causing `InputValidationError` (observed 67717a29:270).
**Area:** claude-config-manager repo — session-close skill/hook
**Prior:** fix to two options, or fold the confirm into `/release`.

### BUG-003 — unresolved plugin load error never diagnosed

**Logged:** 2026-07-06 · **Source:** harness-collab-optimization session follow-up, spec `docs/superpowers/specs/harness-collab-optimization.md` item M2
**Problem:** "1 error during load. Run /doctor for details." surfaced 2026-07-04 (transcript da309ecc:471); never diagnosed.
**Area:** plugin load / `/doctor` diagnostics
**Prior:** run `/doctor` once to capture the actual error, then route the fix.

### DEBT-008 — scan-workflow-fanout doctrine stale against locked model-floor policy

**Logged:** 2026-07-06 · **Source:** harness-collab-optimization session, spec `docs/superpowers/specs/harness-collab-optimization.md` item C3 [owner: claude-config-manager — execute from that repo]
**Problem:** `scan-workflow-fanout.md` says "readers on haiku"; `harness-pain-probe` is pinned `model: sonnet` — doctrine no longer matches the locked policy (haiku readers only where a judge stage already exists, sonnet floor otherwise).
**Area:** claude-config-manager repo — `scan-workflow-fanout.md` doctrine
**Prior:** update doctrine text to state the locked policy.

### DEBT-007 — model-guard enforcement duplicated as PreToolUse deny tax

**Logged:** 2026-07-06 · **Source:** harness-collab-optimization session, spec `docs/superpowers/specs/harness-collab-optimization.md` item B1 [owner: claude-config-manager — execute from that repo]
**Problem:** model-guard enforcement runs as a PreToolUse deny even where a typed-agent's frontmatter `model:` plus `CLAUDE_CODE_SUBAGENT_MODEL` env could enforce declaratively; measured cost ~35 deny re-send tax hits/window.
**Area:** claude-config-manager repo — model-guard hook config
**Prior:** demote to declarative (frontmatter `model:` as primary, env var as ad-hoc floor); keep PreToolUse deny only where declarative can't reach (workflow name-launch).

### DEBT-006 — feat/harness-collab-opt unmerged, harness-collab implementation unreleased

**Logged:** 2026-07-06 · **Source:** harness-collab-optimization session, spec `docs/superpowers/specs/harness-collab-optimization.md`
**Problem:** branch `feat/harness-collab-opt` holds the full implementation (3 commits, tree clean) — default-on hooks, `drain --model`, plugin-digest agent, todo/log updates — unmerged; consumers only receive it once `/release` bumps `plugin.json` version and syncs the marketplace description mirror (`plugin.json` description was edited on-branch).
**Area:** repo root — branch `feat/harness-collab-opt`, `plugin.json`, marketplace mirror
**Prior:** merge to main, then run `/release`.

### GAP-004 — no climb-SSOT nudge before AskUserQuestion

**Logged:** 2026-07-06 · **Source:** harness-collab-optimization session, spec `docs/superpowers/specs/harness-collab-optimization.md` item D1 [owner: claude-config-manager — execute from that repo]
**Problem:** no PreToolUse nudge exists on AskUserQuestion to push agents to climb locked decisions → project docs → own capability check → delegation-signal pick-and-state before asking; measured 9-18 asks/session, often outnumbering dispatches.
**Area:** claude-config-manager repo — PreToolUse hook config on AskUserQuestion
**Prior:** add `additionalContext` nudge (never deny — designed pipeline gates like route-confirm/merge-gate/drain-halts are deliberate asks).

### GAP-003 — harness-collab-optimization effect unmeasured against spec's acceptance targets

**Logged:** 2026-07-06 · **Source:** harness-collab-optimization session, spec `docs/superpowers/specs/harness-collab-optimization.md` § 6 acceptance criteria, item C1
**Problem:** the optimization's real-world effect is unverified — no harvest window has yet checked: premature-commitment not top pain shape (first time in 4 windows), model-guard deny hits ≈0 (baseline 35/window), principles-load user re-assertions →0 (baseline ~15/session worst case), authoring inline:dispatch ratio moving from ~13:1 toward dispatch-majority, zero regressions on preserved wins (todo skip-dispatch fast path, four zero-retry dispatch lanes, audit gate).
**Area:** `docs/superpowers/specs/harness-collab-optimization.md` § 6; next harness-pain harvest window
**Prior:** pure measurement pass at the next harvest window, no code change.
