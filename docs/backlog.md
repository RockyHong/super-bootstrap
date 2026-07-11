# Backlog

New rows route through `/super-bootstrap:log` — one funnel for classification, dedup, and ID assignment. Bugs, debt, design gaps, and unverified feature ideas all land here as rows; whether each is real or worth doing is decided at `/super-bootstrap:todo` triage on pickup, not at capture.

**Row deletion:** the resolving session — via `/super-bootstrap:commit` doc-sync, or manually on resolve. Direct `git commit` skips the sweep; clean up stale rows when noticed.

**Three categories** distinguished by ID prefix:

- **`BUG-###`** — broken behavior. Surface symptom may hide deeper cause.
- **`DEBT-###`** — working but rotting (test fixture rot, stale dep, cleanup owed).
- **`GAP-###`** — design gap or unverified capability idea, never properly specced. Forward feature ideas land here; triage decides drop / spec.

No phase prescription per category — when an item rolls into a session, the harness phase triage decides which superpowers phases run. Surface "clear fix" can become design work after evidence; pre-routing biases that judgment.

**ID high-water mark:** `BUG-017` · `DEBT-020` · `GAP-033` — last consumed ID per category. Next ID = max+1 from this line, bumped in the same write. Resolved rows are deleted but their IDs stay consumed (history = `git log --grep="<id>"`); never re-derive IDs from open rows.

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

### DEBT-020 — triage grounding lacks evidence-directness ordering; design prose treated as ground truth

**Logged:** 2026-07-11 · **Source:** BUG-016 triage session (mid-execution finding)
**Problem:** When grounding a behavioral claim, triage reaches for second-hand design prose (SKILL.md, parallel-worktrees.md) as ground truth, bypassing direct evidence already on the card (card-captured raw observations, telemetry, per-worktree denial counts from issue #18). BUG-016 triage produced a correct verdict but with no objective proof — unable to shut down the gateway's competing (incorrect) theory — causing a multi-turn spiral. Fix must land in the shipped triage skill so consumers inherit it on install. Directness ordering: card-captured raw observations / repro output / external system telemetry → ground truth; repo design prose / our own descriptions of the system → second-hand, driftable, falsifiable only. Verdict contract should require citing the most-direct evidence available and explicitly mark repo prose as secondary. Axiom II ("deduction substituted for contact with the real") already bans the inverse pattern; this makes it explicit inside the triage grounding step.
**Area:** `plugins/super-bootstrap/skills/triage/SKILL.md`, `plugins/super-bootstrap/agents/triage.md` (grounding step + verdict contract)
**Prior:** Add a source-provenance / directness-ordering section to the grounding step: direct evidence first, design prose second-hand to-be-falsified only; verdict must present the most-direct available evidence before any design-prose rationale.

### BUG-017 — todo subagent burns extended-thinking spirals probing absent optional dirs/files

**Logged:** 2026-07-11 · **Source:** GitHub issue #17 (https://github.com/RockyHong/super-bootstrap/issues/17), duplicate #16 dismissed
**Problem:** The todo subagent (agents/todo.md) burns large output-token turns (extended-thinking spirals) when probing an absent optional dir/file instead of cheaply treating "not present" as a normal empty result. Evidence: a read-only TODO-board render burned 14.4k + 11.7k output-tok across two runs; single extended-thinking spikes of 13,090 and 9,399 tok on individual Glob calls, both triggered after probing absent optional paths `docs/superpowers/triage/` and `docs/test-queue.md` ("Directory does not exist" error → spike on next Glob). classify-actionable.md carries skip-if-absent semantics for backlog and test-queue but no explicit anti-spiral "absent optional dir = cheap empty" guard for the subagent. Not fixed by commit 742c188 (that fixed the gateway skip-gate, a different layer).
**Area:** `plugins/super-bootstrap/agents/todo.md`, `plugins/super-bootstrap/shared/classify-actionable.md`
**Prior:** Add explicit "absent optional dir = cheap empty result, skip" guard at the classify step so a dir-absent result can't feed an extended-thinking spike.

### GAP-033 — harness-bootstrap Phase 2a-hooks offers no opt-out; unconditional install collides with existing hook layers

**Logged:** 2026-07-11 · **Source:** GitHub issue #19 (https://github.com/RockyHong/super-bootstrap/issues/19)
**Problem:** Phase 2a-hooks installs hooks (entry-nudge, commit-channel) unconditionally with no opt-out. A consumer already owning prompt-entry injection via another layer can't adopt harness-bootstrap's other value (decisions.md scaffold, etc.) without also taking the colliding entry-nudge hook — a second injection on a channel already under cost surveillance. Phase 2a-drain and 2a-scale already offer per-phase skip prompts; 2a-hooks does not. (The harness-grounding double-inject case from the original issue is dissolved — commit 1feca8f retired that hook; the residual is the remaining unconditional hooks with no opt-out.)
**Area:** `plugins/super-bootstrap/skills/harness-bootstrap/assets/hooks-ensure-infra.md`, Phase 2a-hooks install sequence
**Prior:** Add a per-hook skip prompt (matching 2a-drain / 2a-scale pattern) or detection of an existing superseding mechanism at the same hook moment.

### GAP-031 — techstack lacks explicit verify/compare conventions: jq-for-JSON + exit-status gating

**Logged:** 2026-07-11 · **Source:** GitHub issue #20 (https://github.com/RockyHong/super-bootstrap/issues/20), routed from ccm inbox triage
**Problem:** Two convention gaps surfaced by one manifest-parity failure (a `python json.load(open(...))` compare crashed on cp950/em-dash content → empty output → false "identical" pass). (1) Techstack names jq as a zero-dep convention but never states "JSON comparisons use jq, not ad-hoc python," leaving it implicit and prone to off-idiom substitution. (2) No convention states a verify/compare step must gate on the producer's exit status before interpreting output — a crashed producer's zero output read as an empty match.
**Area:** `docs/techstack.md` § zero-dep idioms
**Prior:** Add two explicit lines: "JSON comparisons: jq, not python"; "a verify/compare gates on the producer's exit status — zero output from a crashed producer is not an empty match." (GAP-032 folded in here.)

### DEBT-017 — cloud-reachability of plugin-dir paths from dispatched subagents unvalidated (classify-actionable.md self-read)

**Logged:** 2026-07-10 · **Source:** DEBT-016 self-read fix (commit 2afaac0) residual — flagged during harness audit + verification this session
**Problem:** DEBT-016's fix routes todo/drain subagents to Read `classify-actionable.md` at an absolute plugin-cache path outside the repo. Confirmed reachable locally; in cloud the plugin is runtime-installed at a different path and whether a dispatched subagent's Read tool can reach the runtime-installed plugin dir is untested. If it fails, `/super-bootstrap:todo` (session-opener) + `/super-bootstrap:drain` classification both break in cloud. Validation path: run `/super-bootstrap:todo` or `/drain` in a cloud/Routine session and confirm the todo agent's spec Read succeeds.
**Area:** `plugins/super-bootstrap/skills/todo/SKILL.md`, `plugins/super-bootstrap/skills/drain/SKILL.md`, `plugins/super-bootstrap/agents/todo.md`, `plugins/super-bootstrap/shared/classify-actionable.md`
**Prior:** per `claude-shape/cloud-run-surface.md`, committed project skills run in cloud and plugins are runtime-installed — plugin dir should be present, but Read-tool reachability from a dispatched subagent is the specific unvalidated point; if broken, fallback is embedding spec content inline in the skill/agent rather than a runtime Read.

### GAP-021 — ChewLingo delta artifacts verdicted "upstream as root" never assigned a wave; remain consumer-only

**Logged:** 2026-07-08 · **Source:** GAP-017 program close-out — verdict rows with no wave assignment, carried here before the program map's deletion
**Problem:** Three GAP-017 verdicts marked ChewLingo artifacts as portable root capability but no wave shipped them: `journey-simulation` (portable mechanism, near-zero contamination — upstream whole); spec/plan/implement/review partial salvage (Surface-on-Gap refusal, design gate, evidence block → fold into superpowers route wrappers, not a parallel chain); model-tiering pre/posttool hooks (doctrine lives in served work-discipline lore; hooks are enforcement — upstream as root hook assets). They are not dups (root has no counterpart), so adopt mode correctly left them as ChewLingo delta — but the portable value stays single-consumer until upstreamed.
**Area:** `plugins/super-bootstrap/skills/` (+ `harness-bootstrap` hook assets for model-tiering); source bodies live in `V:\ChewLingo` `.claude/skills/{journey-simulation,spec,plan,implement,review}` + its `.claude/hooks`
**Prior:** same distill recipe as GAP-017 waves (direct port of production-proven text, consumer-safe rewrite, one cold audit per batch); triage decides ship-order or drop per artifact.

### GAP-003 — harness-collab-optimization effect unmeasured; criteria reshaped by entry-discipline

**Logged:** 2026-07-06 (criteria reshaped 2026-07-08, entry-discipline session) · **Source:** harness-collab spec § 6 C1 (full text @ c1e2820) + entry-discipline spec W4
**Problem:** next harvest window measures: (a) off-card / off-lane leakage — change-work entered without a backlog card (entry-discipline E1/E2 regression); (b) cluster-1/3 omission shapes — bug fixed without root-cause entry, multi-step work without plan artifact — unharvestable under current ccm harvest taxonomy, companion `[ccm]` taxonomy item routes via `/contribute`; (c) route-line theater — E3 regression: confirm-stops firing where SSOT already resolved (07-04 baseline: "MCQ 給自由假象，實質只是確認"); (d) zero regressions on preserved wins (todo skip-dispatch fast path, four zero-retry dispatch lanes, audit gate); (e) principles-load user re-assertions →0 (baseline ~15/session worst case); (f) premature-commitment top-pain exit (still top pain 3 consecutive windows as of 07-08 — unmeasured post-entry-discipline). RETIRED: dispatch-majority ratio target — dispatch value is two-sided (context-hygiene + model-strength routing); a ratio target manufactures reflexive routing. Raw inline:dispatch ratio stays descriptive-only (mining baseline ~13:1, 35 sessions — not a harvested figure).
**Area:** next harness-pain harvest window
**Prior:** pure measurement pass, no code change. (The docsync-gate value facet that rode this window is closed — the token gate was dissolved entirely (see git log); its measured near-zero value fed that call.)
**Measured (2026-07-08, ccm three-probe downstream timing audit — evidence: claude-config-manager `docs/harness-pain/reports/2026-07-08.md` + GAP-063 closing commits `d05742e`/`067fac4`):** (1) model-guard deny hits: only 2 real runtime pin-denials corpus-wide post-enforcement, both complied+succeeded next call — EXCLUDE the 4 spotify-radio denies on `super-bootstrap:todo` dispatches (`0696f836`/`15a02eb4`/`df6637d0`/`58108cd9`): stale-copy artifacts of a 06-26 agent-model hook predating ccm's BUG-007 namespaced-pin fix (07-01; copy refreshed 07-07 23:47), NOT guard noise and NOT a todo-template defect (todo's `model: sonnet` pin correct in every released version). (2) docsync-gate value: **facet closed** — measured zero organic catches AND zero firings across all 4 adopters (still on byte-identical v1 hooks); this near-zero evidence fed the decision to dissolve the token gate entirely rather than keep measuring. Adopters shed the retired hooks on their next harness-bootstrap re-sync. (3) unmeasured by this audit: premature-commitment top-pain, principles-load re-assertions, inline:dispatch ratio — DEBT-028 family did recur in-window (ChewLingo ×2 facets).
