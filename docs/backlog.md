# Backlog

New rows route through `/super-bootstrap:log` — one funnel for classification, dedup, and ID assignment. Bugs, debt, design gaps, and unverified feature ideas all land here as rows; whether each is real or worth doing is decided at `/super-bootstrap:todo` triage on pickup, not at capture.

**Row deletion:** the resolving session — via `/super-bootstrap:commit` doc-sync, or manually on resolve. Direct `git commit` skips the sweep; clean up stale rows when noticed.

**Three categories** distinguished by ID prefix:

- **`BUG-###`** — broken behavior. Surface symptom may hide deeper cause.
- **`DEBT-###`** — working but rotting (test fixture rot, stale dep, cleanup owed).
- **`GAP-###`** — design gap or unverified capability idea, never properly specced. Forward feature ideas land here; triage decides drop / spec.

No phase prescription per category — when an item rolls into a session, the harness phase triage decides which superpowers phases run. Surface "clear fix" can become design work after evidence; pre-routing biases that judgment.

**ID high-water mark:** `BUG-006` · `DEBT-008` · `GAP-004` — last consumed ID per category. Next ID = max+1 from this line, bumped in the same write. Resolved rows are deleted but their IDs stay consumed (history = `git log --grep="<id>"`); never re-derive IDs from open rows.

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

### BUG-006 — device harness hooks' path predicate never matches plugin-source layout, silent no-op

**Logged:** 2026-07-07 · **Source:** super-bootstrap session resolving DEBT-005 / harness-collab downstream [owner: claude-config-manager — execute from that repo]
**Problem:** `~/.claude/hooks/harness-author-pretool.sh` (grounding-checklist injection) and `~/.claude/hooks/harness-audit-pretool.sh` (pre-commit audit-freshness stamp + commit gate) share a path predicate matching only `.claude/skills|agents|rules/*` (or, under `STOREHOUSE=1`, root-level `skills|agents|rules|templates/*` — requires `serve.sh`, absent here). super-bootstrap's harness lives under `plugins/super-bootstrap/skills|agents/`, matching neither branch — both hooks silently no-op on this repo's harness edits. Confirmed 2026-07-07: `harness-audit-pretool.sh --stamp plugins/super-bootstrap/skills/todo/SKILL.md` wrote nothing (path filtered from stamp set); pre-commit gate stayed silent on commit 5a2ec8f despite a harness edit.
**Area:** claude-config-manager repo — shared `_harness_paths`/`REL` predicate in `~/.claude/hooks/harness-author-pretool.sh` and `~/.claude/hooks/harness-audit-pretool.sh`
**Prior:** extend the shared predicate with `*/skills/*|*/agents/*|*/rules/*`, or an explicit `plugins/*/skills|agents|rules/**` case, to cover plugin-source layouts.

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

### GAP-004 — no climb-SSOT nudge before AskUserQuestion

**Logged:** 2026-07-06 · **Source:** harness-collab-optimization session, spec `docs/superpowers/specs/harness-collab-optimization.md` item D1 [owner: claude-config-manager — execute from that repo]
**Problem:** no PreToolUse nudge exists on AskUserQuestion to push agents to climb locked decisions → project docs → own capability check → delegation-signal pick-and-state before asking; measured 9-18 asks/session, often outnumbering dispatches.
**Area:** claude-config-manager repo — PreToolUse hook config on AskUserQuestion
**Prior:** add `additionalContext` nudge (never deny — designed pipeline gates like route-confirm/merge-gate/drain-halts are deliberate asks).

### GAP-003 — harness-collab-optimization effect unmeasured against spec's acceptance targets

**Logged:** 2026-07-06 · **Source:** harness-collab-optimization session, spec `docs/superpowers/specs/harness-collab-optimization.md` § 6 acceptance criteria, item C1
**Problem:** the optimization's real-world effect is unverified — no harvest window has yet checked: premature-commitment not top pain shape (first time in 4 windows), model-guard deny hits ≈0 (baseline 35/window), principles-load user re-assertions →0 (baseline ~15/session worst case), authoring inline:dispatch ratio moving from ~13:1 toward dispatch-majority, zero regressions on preserved wins (todo skip-dispatch fast path, four zero-retry dispatch lanes, audit gate).
**Area:** next harness-pain harvest window (spec deleted post-merge; acceptance targets inlined above, full text @ c1e2820)
**Prior:** pure measurement pass at the next harvest window, no code change.
