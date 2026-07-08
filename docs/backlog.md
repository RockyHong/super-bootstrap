# Backlog

New rows route through `/super-bootstrap:log` — one funnel for classification, dedup, and ID assignment. Bugs, debt, design gaps, and unverified feature ideas all land here as rows; whether each is real or worth doing is decided at `/super-bootstrap:todo` triage on pickup, not at capture.

**Row deletion:** the resolving session — via `/super-bootstrap:commit` doc-sync, or manually on resolve. Direct `git commit` skips the sweep; clean up stale rows when noticed.

**Three categories** distinguished by ID prefix:

- **`BUG-###`** — broken behavior. Surface symptom may hide deeper cause.
- **`DEBT-###`** — working but rotting (test fixture rot, stale dep, cleanup owed).
- **`GAP-###`** — design gap or unverified capability idea, never properly specced. Forward feature ideas land here; triage decides drop / spec.

No phase prescription per category — when an item rolls into a session, the harness phase triage decides which superpowers phases run. Surface "clear fix" can become design work after evidence; pre-routing biases that judgment.

**ID high-water mark:** `BUG-012` · `DEBT-008` · `GAP-019` — last consumed ID per category. Next ID = max+1 from this line, bumped in the same write. Resolved rows are deleted but their IDs stay consumed (history = `git log --grep="<id>"`); never re-derive IDs from open rows.

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

### GAP-019 — writing-plans no-placeholder contract duplicates full file bodies even when the authoring session also executes

**Logged:** 2026-07-08 · **Source:** GAP-017 triage-distill session, meta-harness pain surfaced mid-session
**Problem:** writing-plans' no-placeholder contract (full file bodies embedded in the plan) assumes a cold executor. When the authoring session also executes, the embed is pure duplication and propagates typos — two observed instances (todo distill: 4 typos propagated; triage distill: ~350 lines duplicated).
**Area:** CLAUDE.md § Development Workflow / writing-plans consumption (upstream skill is superpowers-owned; sb-side fix is a documented carve-out in sb's own routing prose)
**Prior:** same-session carve-out — plans reference draft bodies by section instead of embedding full text when the authoring session also executes; already applied ad hoc in `docs/superpowers/specs/harness-rebase.md` § Distill route sizing for GAP-017's remaining waves (temporal, deleted on merge) — this generalizes the fix into the permanent routing prose.

### GAP-018 — cluster routing sizes by work type only; no shape-knowledge valve for spec-driven repeat work

**Logged:** 2026-07-08 · **Source:** GAP-017 triage-distill session, meta-harness pain surfaced mid-session
**Problem:** Envelope's cluster routing (CLAUDE.md § Cluster routing) sizes depth by work TYPE only — new capability → cluster 2 whole (full brainstorming + full plan), regardless of how many same-shape artifacts already preceded it. The 5th same-shape distill artifact in GAP-017 was still forced through full ceremony; meta:ship ratio ran ~2:1 by lines. Shipped Execution tag (`inline|phased|full`) sizes backlog-card pickups but nothing sizes spec-driven repeat work at the route line.
**Area:** CLAUDE.md § Cluster routing / envelope
**Prior:** generalize pipeline sizing to the route line itself (a known-shape route may skip discovery phases) — beyond the per-program patch already in `docs/superpowers/specs/harness-rebase.md` § Distill route sizing (temporal, GAP-017-scoped, deleted on merge).

### BUG-012 — background-dispatched opus subagents stall before first Write when creating new plugin skill files

**Logged:** 2026-07-08 · **Source:** GAP-017 Wave 1 check-docs-consistency promotion, live session observation
**Problem:** Background-dispatched authoring subagents (Agent tool, `run_in_background`, opus) tasked to CREATE new plugin skill files repeatedly stalled — 4 consecutive turns across 2 fresh agents ended with a one-line announcement ("Now writing the files") and zero Write calls, despite explicit resume messages via SendMessage. Same-session opus agents EDITING existing harness files (`agents/log.md`, `skills/merge/SKILL.md`) wrote fine. Gateway ended up writing the files inline, defeating the § Dispatch build lane whenever a card creates new harness files.
**Area:** Agent tool / `run_in_background` dispatch lane; `harness-grounding.sh` PreToolUse(Write) hook; `skill-authoring`/`repo-boundary` rule-reminder injections on `plugins/*/skills/**` paths
**Prior:** suspected interaction — a PreToolUse(Write) nudge or rule-reminder injection firing in the subagent context on new-file Write under `plugins/*/skills/**` stops the agent turn before its first Write call; edits to existing files unaffected, so the trigger looks path-pattern + new-file, not path alone.

### GAP-017 — harness rebase: upstream ChewLingo evolution, rebase ChewLingo onto root

**Logged:** 2026-07-08 · **Source:** harness-unification evaluation session (three-probe grounding: ChewLingo spine, sb root, shared-artifact diff)
**Problem:** ChewLingo is the mother fork of this harness; the two evolved in parallel — ChewLingo grew the judgment layer (venue eligibility, pipeline sizing, closed-fork bounce, 6-mode todo), sb grew the mechanism-hardening layer (ensure-infra, FROZEN assets, Windows FS-boundary, graceful degrade). Bidirectional drift continues until sb is the single root and ChewLingo consumes it.
**Area:** program map + locked spine decisions + per-artifact verdicts + wave plan: [`docs/superpowers/specs/harness-rebase.md`](superpowers/specs/harness-rebase.md)
**Prior:** unify verdict settled (never-merge off the table); five spine decisions locked 2026-07-08. Waves: (1) merge distill + check-docs-consistency promote + log distill; (2) commit/todo/triage + scale module + monorepo tier + adopt mode; (3) drain distill; then supervised `/super-bootstrap` rebase run against ChewLingo + Δ audit. Each artifact rides the normal card→route pipeline; the spec is the map, not a bypass.

### GAP-003 — harness-collab-optimization effect unmeasured; criteria reshaped by entry-discipline

**Logged:** 2026-07-06 (criteria reshaped 2026-07-08, entry-discipline session) · **Source:** harness-collab spec § 6 C1 (full text @ c1e2820) + entry-discipline spec W4
**Problem:** next harvest window measures: (a) off-card / off-lane leakage — change-work entered without a backlog card (entry-discipline E1/E2 regression); (b) cluster-1/3 omission shapes — bug fixed without root-cause entry, multi-step work without plan artifact — unharvestable under current ccm harvest taxonomy, companion `[ccm]` taxonomy item routes via `/contribute`; (c) route-line theater — E3 regression: confirm-stops firing where SSOT already resolved (07-04 baseline: "MCQ 給自由假象，實質只是確認"); (d) zero regressions on preserved wins (todo skip-dispatch fast path, four zero-retry dispatch lanes, audit gate); (e) principles-load user re-assertions →0 (baseline ~15/session worst case); (f) premature-commitment top-pain exit (still top pain 3 consecutive windows as of 07-08 — unmeasured post-entry-discipline). RETIRED: dispatch-majority ratio target — dispatch value is two-sided (context-hygiene + model-strength routing); a ratio target manufactures reflexive routing. Raw inline:dispatch ratio stays descriptive-only (mining baseline ~13:1, 35 sessions — not a harvested figure).
**Area:** next harness-pain harvest window
**Prior:** pure measurement pass, no code change. docsync-gate v3 value + one-shot-token cost (token consumed by a failing commit → forced re-scan) ride this window — v1-era defect evidence closed at GAP-014 triage 2026-07-08 (facets 1+3 verified fixed in v3 in-file; facet 2 structurally present, zero v3 firings measured, adopters pending re-sync).
**Measured (2026-07-08, ccm three-probe downstream timing audit — evidence: claude-config-manager `docs/harness-pain/reports/2026-07-08.md` + GAP-063 closing commits `d05742e`/`067fac4`):** (1) model-guard deny hits: only 2 real runtime pin-denials corpus-wide post-enforcement, both complied+succeeded next call — EXCLUDE the 4 spotify-radio denies on `super-bootstrap:todo` dispatches (`0696f836`/`15a02eb4`/`df6637d0`/`58108cd9`): stale-copy artifacts of a 06-26 agent-model hook predating ccm's BUG-007 namespaced-pin fix (07-01; copy refreshed 07-07 23:47), NOT guard noise and NOT a todo-template defect (todo's `model: sonnet` pin correct in every released version). (2) docsync-gate value since v3: zero organic catches AND zero v3 firings downstream — all 4 adopters still carry byte-identical v1 hooks (every sync predates the first fix; v3 deny text zero corpus hits); measurement blocked on adopter re-sync, which commit-skill's FROZEN drift check triggers on each adopter's next `/super-bootstrap:commit`. (3) unmeasured by this audit: premature-commitment top-pain, principles-load re-assertions, inline:dispatch ratio — DEBT-028 family did recur in-window (ChewLingo ×2 facets).
