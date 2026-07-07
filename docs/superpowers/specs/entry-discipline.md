# Spec: Entry Discipline — cluster routing over a mapped beast

**Status:** approved direction (user verdict "ok" on fit-partial + cluster table, 2026-07-08), ready for plan
**Date locked:** 2026-07-08 · **Decisioner:** user (this session; verdict + cluster review)
**Owner repo:** super-bootstrap (SSOT — ships to consumers via plugin update). CCM device-layer items tagged `[ccm]`, routed via `/contribute`, outside this spec's write boundary.
**Temporal:** delete after merge per [`CLAUDE.md`](../../../CLAUDE.md) § Doc Sync. Durable residuals land in `CLAUDE.md` (doctrine) and [`docs/specs/superpowers-topology.md`](../../specs/superpowers-topology.md) (already committed, `92dc612`).

---

## 1. Diagnosis — the original sin, and honest evidence status

**Original sin:** super-bootstrap rides superpowers on the user's behalf, yet the beast's topology had no home (SSOT violation) — every session steered from partial paraphrase. Paid down: full-tree probe → [`superpowers-topology.md`](../../specs/superpowers-topology.md) (verified, committed).

**What the map overturned** (all verified against superpowers 6.1.1 source):
- Upstream's own constitution cedes routing authority: *"User instructions (CLAUDE.md…) take precedence over skills."* Entry-time routing is sanctioned, not boundary bleed. Mid-chain meddling (stripping `REQUIRED SUB-SKILL` pointers) remains bleed — never do it.
- A third documented entry exists: **writing-plans direct** for design-already-intact work (brainstorming's HARD-GATE lives only in brainstorming's body).
- TDD / verification-before-completion / receiving-code-review / dispatching-parallel-agents are **position-free ambient rules**, not chain links — our Entry Gate encoding them was never chain-theft. The chain proper is 4 links: brainstorm → plan → (sdd | executing-plans) → finishing.
- `<SUBAGENT-STOP>` exempts dispatched subagents; our dispatch lanes are unaffected.

**Evidence status of the pain claims** (three sources, different confidence):

| Claim | Source | Status |
|---|---|---|
| Canonical superpowers skills never invoked in two months of daily use | harvest corpus grep: **zero** mentions of any skill name (4 reports) + user testimony | **Verified.** The ceremony pain cannot be attributed to canonical superpowers — it was never exercised |
| Phase-composition ceremony pain ("center a div → brainstorm → … WTH") | user testimony (2 months, ~10h/day) | Direct testimony; **not in harvest corpus** (its taxonomy captures hook/tool/doc friction, not work-shape ceremony) |
| Confirm/MCQ theater — *"MCQ 給自由假象，實質只是確認"*; ask-threshold over-fire recurs 4/4 harvest windows despite three successive fixes | harvest 2026-07-04 → 07-08 | **Verified (harvested).** Implicates Entry Gate step 2's unconditional "stop for confirm" |
| ~13:1 inline:dispatch ratio | harness-collab transcript mining (35 sessions), **not** harvest corpus | Sourced but un-refreshed; cite as mining baseline only |
| Bugs fixed inline without root-cause; multi-step without plan artifact (cluster 1/3 omission) | inference + testimony | **Unharvested** — harvest taxonomy structurally can't capture skipped-discipline. GAP-003's measurement pass must carry it (§ 6 W9) |

**Root shape (unchanged by evidence review):** entry/routing had no grounded map and no organ; work either over-entered ceremony (cluster 5/6/8 dragged toward phases they don't need) or under-entered discipline (cluster 1/3 skipping root-cause/plan). Both are the same defect: **routing from memory instead of map.**

---

## 2. Verdict — fit-partial: 分階段騎, cut at the shaping|execution seam

Locked by user against the ex-ante criteria table (coverage 🟡 / ceremony 🟡 / boundary 🟢 / assumptions 🔴-at-tail / upstream 🟡):

- **Shaping segment: ride whole.** bug → `systematic-debugging`; fuzzy feature → `brainstorming`; design-intact multi-step → `writing-plans` direct. Zero branch assumptions in this segment; strongest upstream machinery; invoked whole at documented entries, forward-pointers honored while inside.
- **Ambient laws: shared.** TDD / verification / receiving-review / parallel-dispatch — already natively encoded in our envelope; upstream declares them position-free. No invocation ceremony needed to obey law.
- **Execution tail: super-bootstrap owns.** § Dispatch + `/super-bootstrap:commit` + `/super-bootstrap:merge`, main-direct solo ([`CLAUDE.md`](../../../CLAUDE.md) § Git Notes). `subagent-driven-development` is an **optional invoke** for large plans (compaction-durable ledger + per-dispatch model-tier rule, both aligned with our doctrine); `using-git-worktrees` / `finishing-a-development-branch` not wired (branch-flow assumptions fight our grain; worktree skill's own Step-0 detect-and-skip confirms non-use is sanctioned).

Fixed design-time routing — no runtime lane discretion (the drift vector the user vetoed).

---

## 3. Cluster routing table (the durable core — lands in CLAUDE.md)

| # | Work cluster | Route | Notes |
|---|---|---|---|
| 1 | Bug / broken behavior | **`systematic-debugging` whole** | Iron Law root-cause → Phase 4 TDD fix. Card carries the root-cause artifact |
| 2 | Fuzzy feature / new capability | **`brainstorming` whole** | approval-gated spec → hands to writing-plans (its pointer, honored) |
| 3 | Design-intact multi-step | **`writing-plans` direct** | documented entry; the card/spec is its required input; plan file kills half-done risk |
| 4 | Refactor | no upstream entry → card ground; multi-step → cluster 3; atomic → envelope only | |
| 5 | Config / taste / bounded tweak | **inline** (agent-shapes lane; TDD's own exception list includes config) | iterating/drifting taste → card with scope + end state |
| 6 | Docs / prose | envelope only (ground → write → doc-sync → commit) | Red/Verify structurally empty — no surface to drive |
| 7 | Harness edits | our organ pair: `load-harness-principles` pre + `audit-harness-edits` post | upstream `writing-skills` = candidate for plugin-skill authoring (§ 7 O2) |
| 8 | Triage / investigation-only | inline reads + dispatched probes | no entry needed |

Clusters 5/6/8 inline is **grounded routing, not a carve-out** — the difference: a carve-out pre-judges by size ("small → skip"); routing grounds first (card/closure check), then routes. The deleted carve-out ("Non-trivial = anything past a single obvious edit") judged by size; this table judges by cluster + closure.

---

## 4. Entry organ — ground-first, anti-theater

**E1. Entry = card-pickup, always.** Work enters by picking up a card (`/super-bootstrap:todo` or prose ID) or grounding a new one (`/super-bootstrap:log`). The card IS the grounding artifact (bug → root-cause claim; feature → problem statement) and the unit/anchor/boundary/SSOT of the change. Fresh or resume — same door.

**E2. Card-less nudge — push, not pull.** Card-less change-work is a false-confidence failure (gateway pattern-matches "quick fix", doesn't know it's off-track), so a pull resource can't catch it. Organ: **UserPromptSubmit hook** (fires every prompt, tool-call-independent — reaches even answer-from-memory turns) injecting one cheap pointer: *on-lane needs a card in context; none → check backlog / superpowers artifacts, or `/log` first.* Nudge, not deny (an omission can't be denied; honors `decisions.md` row-25 class). `[shipped]` via harness-bootstrap hook assets.

**E3. Route line — state, don't gate (anti-theater).** Harvest verdict: unconditional confirm = ceremony theater (*"實質只是確認"*, 4/4 windows). Replace Entry Gate step 2's unconditional "stop for confirm" with the Ask-Threshold-congruent form:
- Cluster + route resolvable from card/SSOT → **state the route in one line, proceed.** No MCQ, no stop.
- Genuine fork (cluster ambiguous, closed-fork conflict, high blast) → stop for the pick. Deliberate pipeline gates stay.

**E4. Inside an entered skill, its law governs.** Once `systematic-debugging` / `brainstorming` / `writing-plans` is entered, run it whole — its gates, its pointers, its artifacts. Exit points: its own terminal handoff, or its documented choice-points. Never strip, never inject skips.

---

## 5. What this deletes from CLAUDE.md (W-items in § 6)

- "Non-trivial = anything past a single obvious edit" — size-label carve-out (root of both over-entry and under-entry).
- Entry Gate's distilled phase table as the *only* pipeline — replaced by: **envelope** (ground → route → implement+ambient-laws → verify → doc-sync → commit, ours) + **cluster routing table** (§ 3) pointing into superpowers entries for shaping.
- Unconditional route-confirm (E3 replaces).
- The phase-triage table (Brainstorm/Spec/Plan run-when/skip-when) — subsumed by cluster routing: the skip-predicates live in the table's cluster definitions now.

Preserved: § Dispatch (closure-judged, within Implement), doc-sync pipeline + gate, commit lane, rules index, karpathy invoke, audit-harness-edits.

---

## 6. Work items

- **W1. CLAUDE.md § Development Workflow rewrite** — envelope + § 3 routing table + E1/E3/E4; delete § 5 items. Cite topology map. Harness edit → `load-harness-principles` frame (loaded this session) + `audit-harness-edits` verify.
- **W2. UserPromptSubmit card-nudge hook** (E2) — new shipped hook asset + settings wiring in harness-bootstrap (same channel as harness-grounding). Injector discipline: exit 0 always, defensive path silent (prompt-erase is the failure mode).
- **W3. GAP-013 delete** — resolved: original sin paid (topology map committed), seam question answered (CCM tiering correctly downstream-only; entry organ is E1/E2, hookable at prompt-submit, dissolving the "un-hookable" premise).
- **W4. GAP-003 rewrite** — measurement criteria become: (a) off-card / off-lane leakage count; (b) cluster-1/3 omission shapes (bug-without-root-cause, multi-step-without-plan) — currently unharvested, needs explicit capture; (c) route-line theater check (E3 regression); (d) preserved-wins regression. Retire the dispatch-majority ratio target (two-sided value: context-hygiene + strength-routing; a ratio target manufactures reflexive routing).
- **W5. `[ccm]` via `/contribute`** — harvest taxonomy gap: add omission-shape capture (skipped-discipline pain) to the harvest skill's bucket taxonomy.
- **W6. GAP-012 re-triage prompt** — 07-08 harvest documents docsync-gate as top-pain structural defect (auto-mode token forging, one-shot token, ~18 dead attempts across adopters) — stronger evidence than the card's "accepted by design." Surface to user for log-or-retriage; not silently escalated.

## 7. Open items (non-blocking)

- **O1. sdd invoke threshold** — at what plan size the optional `subagent-driven-development` invoke (ledger + model-tier rule) beats § Dispatch. Decide at first large plan; note outcome in techstack.
- **O2. `writing-skills` for plugin-skill authoring** — its pressure-test Iron Law vs our authoring conventions. Evaluate at next new-skill authoring.

## 8. Regression guardrails

- `/super-bootstrap:todo` skip-dispatch fast path; four zero-retry dispatch lanes; `audit-harness-edits` gate; `docsync-gate` + `harness-grounding` hooks (extend, don't break).
- Closed forks: `decisions.md` row 25 (nudge-not-deny) honored by E2; no other row matches. The harness-collab spec's re-opened hook fork already legitimizes shipped nudge hooks.
