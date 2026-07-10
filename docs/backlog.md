# Backlog

New rows route through `/super-bootstrap:log` — one funnel for classification, dedup, and ID assignment. Bugs, debt, design gaps, and unverified feature ideas all land here as rows; whether each is real or worth doing is decided at `/super-bootstrap:todo` triage on pickup, not at capture.

**Row deletion:** the resolving session — via `/super-bootstrap:commit` doc-sync, or manually on resolve. Direct `git commit` skips the sweep; clean up stale rows when noticed.

**Three categories** distinguished by ID prefix:

- **`BUG-###`** — broken behavior. Surface symptom may hide deeper cause.
- **`DEBT-###`** — working but rotting (test fixture rot, stale dep, cleanup owed).
- **`GAP-###`** — design gap or unverified capability idea, never properly specced. Forward feature ideas land here; triage decides drop / spec.

No phase prescription per category — when an item rolls into a session, the harness phase triage decides which superpowers phases run. Surface "clear fix" can become design work after evidence; pre-routing biases that judgment.

**ID high-water mark:** `BUG-015` · `DEBT-018` · `GAP-029` — last consumed ID per category. Next ID = max+1 from this line, bumped in the same write. Resolved rows are deleted but their IDs stay consumed (history = `git log --grep="<id>"`); never re-derive IDs from open rows.

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

### GAP-028 — commit-channel path-class: no lane for harness-only / non-narrated-path diffs; second-commit-lane design unblocked (BUG-015 resolved)

**Logged:** 2026-07-10 · **Source:** DEBT-013 split (probe+design session) — axis-2 extracted so the transcription axis could close; cold-re-triaged with GAP-023
**Problem:** the commit door dispatches unconditionally. On a diff whose staged paths the repo's doc-sync surface doesn't narrate (harness-only / non-narrated), the commit agent's §3 doc-sync scan catches nothing, so the whole commit dispatch is overhead. Any gateway-inline commit forks the SSOT commit path (GAP-024); commit-agent continuation reliability — the load-bearing prerequisite — is now hardened (BUG-015 resolved: continuation = fresh-dispatch invariant), so the second-commit-lane admissibility question can be settled.
**Area:** `plugins/super-bootstrap/skills/commit/SKILL.md`, `plugins/super-bootstrap/agents/commit.md`; `CLAUDE.md` § Dispatch / § Doc Sync
**Prior:** **ALREADY TRIAGED this session — verdict at `docs/superpowers/triage/GAP-028-notes.md`; do not re-triage.** Prerequisite met: decide skip-entirely vs a narrow non-narrated-path lane. The transcription axis (former DEBT-013 axis-1) is closed separately — do not reopen it here.

### GAP-027 — drain confirm-gate runs at full ceremony for single-item waves; no proportionality short-circuit

**Logged:** 2026-07-10 · **Source:** GitHub issue #15, super-bootstrap 2.22.0, filed 2026-07-10
**Problem:** `/super-bootstrap:drain` runs its full ceremony (base sync → scan → classify → relation analysis → confirm-gate [y/N] round-trip) even when relation analysis resolves the eligible set to exactly one in-session item. The wave-of-one carve-out (`eligibility.md` §Inline / wave-of-one) already skips mkdir/worktree/claude -p for the lone item; the surrounding ceremony and confirm round-trip still run at full weight with no parallel-isolation payoff. Full ceremony with no parallelism benefit reads as bureaucratic and trains users to hand-work single items instead of routing through `/drain`, defeating the pickup lane. Design nuance: the confirm gate is also a consent point for autonomous phase-chain work, so skip-entirely vs collapse-to-one-line-consent is a real design choice — not purely mechanical overhead removal.
**Area:** `plugins/super-bootstrap/skills/drain/SKILL.md` (§Shape steps 1-4, §Confirm gate); `plugins/super-bootstrap/skills/drain/assets/eligibility.md`
**Prior:** when eligible set post-relation-analysis is a single in-session item, short-circuit to a collapsed "doing X in-session, ok?" rather than the full scan→confirm→spawn ceremony; triage decides skip-entirely vs one-line-consent and whether the consent-point role of the gate changes the answer.

### DEBT-017 — cloud-reachability of plugin-dir paths from dispatched subagents unvalidated (classify-actionable.md self-read)

**Logged:** 2026-07-10 · **Source:** DEBT-016 self-read fix (commit 2afaac0) residual — flagged during harness audit + verification this session
**Problem:** DEBT-016's fix routes todo/drain subagents to Read `classify-actionable.md` at an absolute plugin-cache path outside the repo. Confirmed reachable locally; in cloud the plugin is runtime-installed at a different path and whether a dispatched subagent's Read tool can reach the runtime-installed plugin dir is untested. If it fails, `/super-bootstrap:todo` (session-opener) + `/super-bootstrap:drain` classification both break in cloud. Validation path: run `/super-bootstrap:todo` or `/drain` in a cloud/Routine session and confirm the todo agent's spec Read succeeds.
**Area:** `plugins/super-bootstrap/skills/todo/SKILL.md`, `plugins/super-bootstrap/skills/drain/SKILL.md`, `plugins/super-bootstrap/agents/todo.md`, `plugins/super-bootstrap/shared/classify-actionable.md`
**Prior:** per `claude-shape/cloud-run-surface.md`, committed project skills run in cloud and plugins are runtime-installed — plugin dir should be present, but Read-tool reachability from a dispatched subagent is the specific unvalidated point; if broken, fallback is embedding spec content inline in the skill/agent rather than a runtime Read.

### GAP-026 — /todo skip-gate covers only empty board; no skip when gateway already holds backlog context

**Logged:** 2026-07-10 · **Source:** GitHub issue #14 (filed via /send-issue, spotify-radio session 2026-07-08)
**Problem:** /super-bootstrap:todo's skip-gate fires only when the board is empty — no guard for the case where the gateway already holds the backlog in context and the ask is directly answerable from it. When that condition holds, the full board render is redundant ceremony. GAP-003 lists the empty-board fast path as a preserved win (already shipped); this is the sibling design gap for the held-context case.
**Area:** `plugins/super-bootstrap/skills/todo/**`; `plugins/super-bootstrap/agents/todo.md`
**Prior:** extend the skip-gate condition to also fire when the gateway already holds the backlog in context and the ask is directly answerable from it — triage decides the gate predicate and session-state signal.

### GAP-025 — writing-plans hard-codes uniform max-ceremony per task and sizes tasks by surface-group rather than logical-change-unit

**Logged:** 2026-07-10 · **Source:** executing GAP-024 8-task doc-sync-gate-redesign plan via subagent-driven-development this session
**Problem:** Two distinct axes. (1) Per-task verification depth not scaled to blast radius — `audit-harness-edits` already supports a centrality-scoped light-pass (used correctly on T2), but the plan hard-coded a uniform full `/audit-harness-edits` into every task's Step 5. Behavior-critical tasks T1 (commit-channel matcher) and T3 (commit-agent doctrine) each had their cold audit catch a real closure miss; narration/cleanup tasks T4/T5/T7 (hook-count prose across README ×2, plugin.json, marketplace mirror, release) and T8 (backlog + temporal-artifact cleanup) carried the same max-ceremony at near-zero blast radius. (2) Tasks sized by surface-group (one task per file cluster) rather than logical-change-unit — "reconcile prose to the 3-hook reality" spanning 3 file clusters became 3 task-cycles + 3 commits + 3 ship-confirms instead of 1. Opposite direction from DEBT-013 (small change over-dispatched into a full pipeline — this is a large change over-decomposed into uniform-ceremony sub-tasks); distinct facets from GAP-018 (route-line sizing by work type), GAP-020 (SDD re-review regardless of fix grade), GAP-023 (dispatch transcription carve-out).
**Area:** `CLAUDE.md` § Development Workflow / writing-plans consumption + § Dispatch; upstream `superpowers:writing-plans` task-shape doctrine
**Prior:** (a) scale each task's verification depth to its blast radius — centrality-scoped audit per `audit-harness-edits`' own doctrine rather than a uniform full-probe per task; (b) batch same-logical-change surfaces (narration across files) into one task/commit. Same carve-out pattern as GAP-019/GAP-020/GAP-023 — sb-side documented exception in routing prose, not an upstream change.

### DEBT-012 — commit batching: propagation closure split across session-isolation into N commits

**Logged:** 2026-07-08 · **Source:** token-cost retrospective on the BUG-014 session (~10-line hook-regex fix; gateway ≥200k + subagents ~460k tokens)
**Problem:** BUG-014's fix (asset matcher fix + verbatim propagation to this repo's git-tracked dogfood copy `.claude/hooks/docsync-gate.sh`) was one logical propagation-closure change, but session-isolation on the commit door forced it into 2 separate commits via 2 separate commit-agent dispatches (`b9f3e36` asset, `3a646fc` dogfood re-sync). The envelope/commit discipline has no "propagation-closure commit" concept bundling a source-harness edit with its verbatim installed/dogfood copy into one commit.
**Area:** super-bootstrap commit door (`plugins/super-bootstrap/skills/commit`, `plugins/super-bootstrap/agents/commit.md`) + `CLAUDE.md` § Dispatch session-isolation rule
**Prior:** when a diff includes a source harness file AND its verbatim installed/dogfood copy, consider allowing one commit instead of forcing session-isolated per-file dispatches; triage decides whether this is a defect or accepted-by-design (isolation is itself a safety property).

### BUG-013 — harness-grounding.sh PreToolUse additionalContext lacks permissionDecision; may be dead or expose subagent Write-corruption

**Logged:** 2026-07-08 · **Source:** surfaced during BUG-012 4-cell live probe investigation
**Problem:** `harness-grounding.sh` (FROZEN v1, `.claude/hooks/harness-grounding.sh`) emits PreToolUse additionalContext with no `permissionDecision` field. Per Tier-1 lore `claude-shape/hook-feedback-channels.md`, PreToolUse additionalContext is valid only paired with `permissionDecision: "allow"` or `"defer"` — unpaired, the injection may be silently dropped (the harness-edit grounding nudge never reaches Claude at all), OR if it does inject, it exposes background-dispatched subagents that create new `.claude/{rules,skills,agents}/` or `CLAUDE.md` files to the same platform Write-corruption BUG-012 fixed for the plugins path (background subagent + PreToolUse additionalContext injection → Write returns "[Tool result missing due to internal error]"). Not directly probed: the BUG-012 4-cell live probe confirmed the device-global "New harness file" hook as injector for `plugins/*/skills/**` new-file creation (cell A failed, cell D on a plain path succeeded); this repo-owned analog (case arms at `harness-grounding.sh:20-30`, firing on `.claude/` + `CLAUDE.md` paths) is inferred exposure, not observed.
**Area:** `.claude/hooks/harness-grounding.sh` (PreToolUse Edit|Write), FROZEN v1
**Prior:** verify whether additionalContext-without-permissionDecision reaches Claude at all (if not, the grounding nudge is dead — a separate latent bug); if it does inject, gate on `agent_type` to skip subagent context (per `claude-shape/hook-agent-type.md`) or align with BUG-012's foreground-dispatch rule. FROZEN v1 hook — any change needs deliberate handling.

### GAP-021 — ChewLingo delta artifacts verdicted "upstream as root" never assigned a wave; remain consumer-only

**Logged:** 2026-07-08 · **Source:** GAP-017 program close-out — verdict rows with no wave assignment, carried here before the program map's deletion
**Problem:** Three GAP-017 verdicts marked ChewLingo artifacts as portable root capability but no wave shipped them: `journey-simulation` (portable mechanism, near-zero contamination — upstream whole); spec/plan/implement/review partial salvage (Surface-on-Gap refusal, design gate, evidence block → fold into superpowers route wrappers, not a parallel chain); model-tiering pre/posttool hooks (doctrine lives in served work-discipline lore; hooks are enforcement — upstream as root hook assets). They are not dups (root has no counterpart), so adopt mode correctly left them as ChewLingo delta — but the portable value stays single-consumer until upstreamed.
**Area:** `plugins/super-bootstrap/skills/` (+ `harness-bootstrap` hook assets for model-tiering); source bodies live in `V:\ChewLingo` `.claude/skills/{journey-simulation,spec,plan,implement,review}` + its `.claude/hooks`
**Prior:** same distill recipe as GAP-017 waves (direct port of production-proven text, consumer-safe rewrite, one cold audit per batch); triage decides ship-order or drop per artifact.

### GAP-020 — SDD's mandatory fix→re-review loop runs regardless of fix grade; transcription-grade fixes earn no new findings

**Logged:** 2026-07-08 · **Source:** GAP-017 scale-module session, user challenged re-review ceremony mid-wave
**Problem:** `superpowers:subagent-driven-development`'s fix→re-review loop dispatches a full re-review after every fix, independent of fix grade. Measured across the GAP-017 todo-distill and scale-module waves: 5 re-review dispatches, 0 new findings — every one a clean confirmation. When the fix dispatch already carries exact old/new text (transcription-grade fix), a re-review by the same reviewer is near-deterministic approval; the step earns itself only for judgment-grade fixes (fix shape left to the implementer).
**Area:** CLAUDE.md § Development Workflow / SDD consumption (upstream skill is superpowers-owned; sb-side fix is a documented carve-out in sb's own routing prose)
**Prior:** same pattern as GAP-019's writing-plans carve-out — transcription-grade fixes (exact old/new text supplied) → dispatcher verifies by reading the diff, no re-review dispatch; judgment-grade fixes (shape left to implementer) → full re-review stays.

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

### GAP-003 — harness-collab-optimization effect unmeasured; criteria reshaped by entry-discipline

**Logged:** 2026-07-06 (criteria reshaped 2026-07-08, entry-discipline session) · **Source:** harness-collab spec § 6 C1 (full text @ c1e2820) + entry-discipline spec W4
**Problem:** next harvest window measures: (a) off-card / off-lane leakage — change-work entered without a backlog card (entry-discipline E1/E2 regression); (b) cluster-1/3 omission shapes — bug fixed without root-cause entry, multi-step work without plan artifact — unharvestable under current ccm harvest taxonomy, companion `[ccm]` taxonomy item routes via `/contribute`; (c) route-line theater — E3 regression: confirm-stops firing where SSOT already resolved (07-04 baseline: "MCQ 給自由假象，實質只是確認"); (d) zero regressions on preserved wins (todo skip-dispatch fast path, four zero-retry dispatch lanes, audit gate); (e) principles-load user re-assertions →0 (baseline ~15/session worst case); (f) premature-commitment top-pain exit (still top pain 3 consecutive windows as of 07-08 — unmeasured post-entry-discipline). RETIRED: dispatch-majority ratio target — dispatch value is two-sided (context-hygiene + model-strength routing); a ratio target manufactures reflexive routing. Raw inline:dispatch ratio stays descriptive-only (mining baseline ~13:1, 35 sessions — not a harvested figure).
**Area:** next harness-pain harvest window
**Prior:** pure measurement pass, no code change. (The docsync-gate value facet that rode this window is closed — the token gate was dissolved entirely (see git log); its measured near-zero value fed that call.)
**Measured (2026-07-08, ccm three-probe downstream timing audit — evidence: claude-config-manager `docs/harness-pain/reports/2026-07-08.md` + GAP-063 closing commits `d05742e`/`067fac4`):** (1) model-guard deny hits: only 2 real runtime pin-denials corpus-wide post-enforcement, both complied+succeeded next call — EXCLUDE the 4 spotify-radio denies on `super-bootstrap:todo` dispatches (`0696f836`/`15a02eb4`/`df6637d0`/`58108cd9`): stale-copy artifacts of a 06-26 agent-model hook predating ccm's BUG-007 namespaced-pin fix (07-01; copy refreshed 07-07 23:47), NOT guard noise and NOT a todo-template defect (todo's `model: sonnet` pin correct in every released version). (2) docsync-gate value: **facet closed** — measured zero organic catches AND zero firings across all 4 adopters (still on byte-identical v1 hooks); this near-zero evidence fed the decision to dissolve the token gate entirely rather than keep measuring. Adopters shed the retired hooks on their next harness-bootstrap re-sync. (3) unmeasured by this audit: premature-commitment top-pain, principles-load re-assertions, inline:dispatch ratio — DEBT-028 family did recur in-window (ChewLingo ×2 facets).
