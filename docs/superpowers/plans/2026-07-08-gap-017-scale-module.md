# GAP-017 Wave 2 — Scale Module Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Ship the opt-in scale module — ChewLingo's tracker constellation distilled into harness-bootstrap assets (parked + test-queue containers, venue-map / capture-routing / pickup-grounding rules, capture fact fields) — installed by `§2a-scale` when a repo earns it.

**Architecture:** Pure asset-layer: the module is docs containers + path-scoped rules; shipped root skills (log, todo, drain) pick the behavior up via rule injection on file match — zero edits to root skill/agent bodies. classify-actionable gains one file-presence-gated source (§d test-queue). Venue metadata is advisory until drain (Wave 3) wires the S-lane.

**Tech Stack:** Markdown-authored Claude Code plugin. No build. Test surface = writing-skills RED pressure scenarios (dispatched probe agents).

**Temporal:** delete this plan once the artifacts have landed **and** shipped in a release (same handling as prior distill plans).

**Source grain:** CL originals live at `V:\ChewLingo` (`.claude/rules/{venue-map,capture-routing,pickup-grounding}.md`, `docs/{parked,test-queue,tracker}.md`). Read them at authoring time for wording candidates — port pattern, never product nouns.

## Global Constraints

- User-approved scope deviation from the spec verdict table: 3 rules port (venue-map, capture-routing, pickup-grounding); 3 close (worktree-boundary structurally; triage-routing + findings-logging after clean spot-check controls). Spec verdict row updates in Task 10.
- Scoped RED rule (decisions.md precedent): a discipline line ships only if control agents WITHOUT it violate; controls clean across all runs → cut the line + log the closed fork.
- Consumer-safety (repo-boundary rule): shipped skeletons reference only surfaces harness-bootstrap stamps (`docs/backlog.md`, `docs/parked.md`, `docs/test-queue.md`, `docs/superpowers/triage/`, `docs/decisions.md`) + `/super-bootstrap:*` slash names + superpowers core-pin skills. No plugin-internal paths, no device-only skills, no ChewLingo paths or product nouns.
- Taxonomy guard: nothing in the module overrides `shared/classify-actionable.md`'s `{action, intent, stage}` derivation. Venue is advisory metadata; intent stays the gate.
- No stored state: sb's file-presence stage derivation won over CL's stored `State:` field (shipped triage doctrine: "verdict files are the state"). No module artifact introduces a status field.
- BUG-012: any dispatched writer creating new files under `plugins/**` runs **foreground**; a stall → gateway writes inline + datapoint on the BUG-012 row.
- Probe agents Read scenario files themselves — never paste full file bodies into probe prompts.
- Plan references draft bodies by section (§ Distill route sizing); only short contract atoms (enums, field lists, gate lines) embed verbatim.
- IDs: parked entries are `PARK-###` (word-prefix like BUG/DEBT/GAP; avoids collision with venue `P`).

---

### Task 1: Pressure-scenario rig

**Files:**
- Create (scratchpad, NOT repo): `<scratchpad>/scale-red/S1-parked/`, `S2-venue/`, `S3-pickup/`, `S4-triage-routing/`, `S5-findings/`

**Interfaces:**
- Produces: five self-contained scenario dirs consumed by Task 2 (controls) and Task 5 (targets). Each dir carries a `backlog.md` in sb row shape (Logged/Source/Problem/Area/Prior) plus the files named below.

- [ ] **Step 1: Write scenarios**

`S1-parked/` (headline — parked admission): `backlog.md` (2 open rows, high-water line) + empty-skeleton `parked.md` (header only: admission line + `PARK-000` high-water + sweep-log section) + `observations.md` carrying three raw captures: (a) actionable-now bug, (b) "defer adding retry logic until the queue refactor lands" (deferrable, trigger nameable), (c) "keep an eye on memory usage" (no nameable action). Control failure = (b) lands as a backlog row or as a parked entry without an observer + fire-moment trigger, or (c) lands anywhere instead of dropping.

`S2-venue/` (venue derivation): `backlog.md` with two tricky rows — `BUG-910` carrying `**Stochastic:** llm` (LLM-judge flakiness), `DEBT-911` whose acceptance criterion is visual polish ("spacing feels cramped") — + a `question.md` asking "which of these can run headless in cloud, which cannot, and why". Control failure = classifies the stochastic or visual row as cloud-runnable without flagging the modality.

`S3-pickup/` (grounding order): `backlog.md` row `BUG-912` whose Prior blames module A + `triage/BUG-912-notes.md` whose findings supersede it (real cause in module B, explicit "supersedes the card's prior" line) + task prompt "pick up BUG-912 and propose next step". Control failure = leads with the row's stale prior, or silently rewrites the row to match the notes.

`S4-triage-routing/` (redundancy spot check): `backlog.md` row `BUG-913` (runtime-symptom bug, cause plausible-looking) + a snippet file `root-context.md` quoting sb root verbatim: CLAUDE.md cluster row 8 (triage route) + § Dispatch closure paragraph. Task: "decide whether to investigate via dispatch or fix inline, citing your rule". Control (root context only, no CL rule) failure = inline-fixes a runtime-symptom bug.

`S5-findings/` (redundancy spot check): a subagent-report `report.md` containing two out-of-scope findings + `root-context.md` quoting sb root verbatim: log skill description ("Claude needs to file its own findings...") + CLAUDE.md § Dispatch lane text. Task: "you are the gateway absorbing this report — what happens to the findings?". Control failure = instructs the subagent to write backlog rows directly, or drops the findings.

- [ ] **Step 2: Verify rig** — each dir self-contained; rows match sb backlog row shape; S4/S5 root-context quotes copied verbatim from `CLAUDE.md` + `plugins/super-bootstrap/skills/log/SKILL.md`.

### Task 2: RED — control runs

**Interfaces:**
- Consumes: Task 1 scenario dirs.
- Produces: per-scenario RED verdict (ship / cut / close) feeding Tasks 4 and 8.

- [ ] **Step 1: Dispatch controls** (foreground, `model: sonnet`, tools Read/Grep/Glob/Edit for S1, Read/Grep/Glob for S2–S5). Control prompts carry ONLY the baseline task — none of the rule text. Runs: S1 ×5 (headline), S2 ×2, S3 ×2, S4 ×2, S5 ×2.
- [ ] **Step 2: Score.**
  - S1 violation ⇒ capture-routing three-way + named-trigger line ships RED-backed. All 5 clean ⇒ the admission gate is already carried by root (log agent's no-standing-watch gate) — cut the redundant lines, ship only the parked container mechanics, log closed fork.
  - S2/S3 violation ⇒ the marked lines in venue-map / pickup-grounding ship RED-backed. Clean ⇒ cut those lines to pointer-grade prose.
  - S4/S5: any violation ⇒ that CL rule is NOT redundant — reopen scope with the user before Task 8. Both clean (expected) ⇒ close as superseded, decisions.md rows in Task 8.

### Task 3: Author module containers

**Files:**
- Create: `plugins/super-bootstrap/skills/harness-bootstrap/assets/scale/parked-skeleton.md`
- Create: `plugins/super-bootstrap/skills/harness-bootstrap/assets/scale/test-queue-skeleton.md`
- Create: `plugins/super-bootstrap/skills/harness-bootstrap/assets/scale/backlog-fact-fields.md`

**Interfaces:**
- Produces: skeleton targets `docs/parked.md`, `docs/test-queue.md`; fact-fields block appended to `docs/backlog.md` header by §2a-scale (Task 6). Entry shapes consumed by Task 4's rules and Task 7's classify-actionable §d.

- [ ] **Step 1: Invoke `superpowers:writing-skills`** (headers are behavior-shaping) — carry through Task 4.

- [ ] **Step 2: `parked-skeleton.md`** — sections: title + admission header (verbatim gate line: "Parked = actionable-but-waits-on-a-named-trigger; every entry MUST carry that trigger (observer + fire-moment), else it drops.") · ID convention (`PARK-###`, monotonic, never reused, `**ID high-water mark:** PARK-000` line, `/super-bootstrap:log` bumps it) · entry shape (`### PARK-### — {title}`, then `**Trigger:**` clause or `surface-on:feature=X` tag, then WHY) · consumer note (untagged entries are NOT surfaced per-session; the trigger's observer fires them — no standing-watch semantics) · `## Entries` (empty) · `## Sweep log — {date}` (overwrite-in-place, no chronicle). Port CL `docs/parked.md` header pattern; drop all CL section headings and product entries.

- [ ] **Step 3: `test-queue-skeleton.md`** — sections: title + framing (auto-shrinking artifact; a smoke step repeated across two consecutive merges is a retire-rule trigger — graduate it to an automated test) · entry shape (`run on:` / markdown checklist / `result: pending|pass|fail` / optional `source: {BUG|DEBT|GAP}-###` back-pointer / `on fail:` action clause) · lifecycle (append at review-stage handoff when a plan's verification is manual; pass ⇒ entry self-discharges in the same commit, independent of merge; fail ⇒ log a bug via `/super-bootstrap:log`, re-queue as `result: pending`) · `## Pending` · `## Failed (re-queued for fix)`. Port CL `docs/test-queue.md` mechanism; sb stage vocabulary (review-stage plans), no builder/reviewed states.

- [ ] **Step 4: `backlog-fact-fields.md`** — a marked insert block (`<!-- scale-module: fact fields -->` … `<!-- /scale-module -->`) documenting three OPTIONAL row fields: `**Test-feel:**` (`unit | e2e | manual | doc-only`) · `**Stochastic:** llm` (present only when diagnosis/verification depends on live-LLM behavior) · `**Blast:**` (`local | pkg | cross-pkg | repo`). One consumer line each: Test-feel + Stochastic feed venue derivation (`.claude/rules/venue-map.md`); Blast feeds pickup sizing. Optional at capture — absent fields imply "derive at pickup".

### Task 4: Author rule skeletons

**Files:**
- Create: `plugins/super-bootstrap/skills/harness-bootstrap/assets/scale/rules-venue-map-skeleton.md`
- Create: `plugins/super-bootstrap/skills/harness-bootstrap/assets/scale/rules-capture-routing-skeleton.md`
- Create: `plugins/super-bootstrap/skills/harness-bootstrap/assets/scale/rules-pickup-grounding-skeleton.md`

**Interfaces:**
- Consumes: Task 2 RED verdicts (lines marked `[RED: Sx]` ship only on their scenario's violation), Task 3 entry shapes.
- Produces: rule targets `.claude/rules/{venue-map,capture-routing,pickup-grounding}.md`; venue enum consumed by drain Wave 3.

- [ ] **Step 1: `rules-venue-map-skeleton.md`** — frontmatter `paths: ['docs/backlog.md', 'docs/test-queue.md']`. Sections:
  - § Venues — verbatim enum table (contract atom, drain Wave 3 interface):

    | Venue | Meaning | Cloud-run | Drainable |
    |---|---|---|---|
    | T | Tooling/headless — artifact via tooling alone | yes | yes, in-worktree |
    | S | Stack-bound — needs a real runner (emulator/ports/browser), no human | no | Wave 3: via gateway merge-probe |
    | U | User-walled — needs human eyes/decision | no | no — halts to user |
    | P | Probe/stochastic — LLM-eval, cost-sensitive, non-deterministic | no | no — excluded |

  - § Derivation — venue is derived fresh per read, never stored: stage (classify-actionable file-presence) → next phase → venue. Phase table keyed to sb stages: raw→Triage=T · triaged→Implement=derive from scope.md · spec→Write plan=T · plan→Continue execute=derive · review→Review=T (manual verification arm → U/S per Test-feel).
  - § Modality overrides — [RED: S2] `**Stochastic:** llm` row field ⇒ triage/build/test phases downgrade T→P (plan/spec/doc stay T); [RED: S2] visual-taste acceptance ⇒ U, keyed on "who accepts this as done? the user's eyes → U", never keyword matching. Test-feel: `e2e`→S, `manual`→U for the verify phase.
  - § Consumer boundary — verbatim subordination line: "This rule never overrides `{action, intent, stage}` from the shared classification — venue is advisory run-location metadata. Mapping: T≈Cloud, U≈Discuss/Device; S and P are refinements the drain lane consumes when wired." One map, two filters, never re-derived by hand.

- [ ] **Step 2: `rules-capture-routing-skeleton.md`** — frontmatter `paths: ['docs/backlog.md', 'docs/parked.md']`. Sections:
  - § Admission gate — one test at write moment, verbatim contract atom:
    ```
    yes + now    → docs/backlog.md row (BUG/DEBT/GAP per its header)
    yes + later  → docs/parked.md — MUST carry a named trigger (observer + fire-moment)   [RED: S1]
    can't name   → DROP — re-entry as a fresh capture when the pain is felt               [RED: S1]
    ```
  - § Container = state — which file an item lives in IS its state; no cross-container status fields.
  - § Three deferral routes, no standing-watch rows — (1) wire the observer now (log line / lint / CI assertion), (2) park with named trigger, (3) drop and trust re-entry. Restates the backlog header's no-standing-watch gate as the parked-aware three-way; the closed-fork bounce stays owned by the log agent (reference, don't duplicate).
  - § Absence-claims verify before they anchor — "missing/never-tracked" claims confirm via `git ls-files` / `git log` before landing a row.
  - § Ownership boundary — this rule owns the admission decision; the containers own their schema.

- [ ] **Step 3: `rules-pickup-grounding-skeleton.md`** — frontmatter `paths: ['docs/backlog.md', 'docs/superpowers/triage/**']`. Sections: § When (picking up a row that has a verdict artifact — `{ID}-scope.md` / `{ID}-notes.md`) · § Order ([RED: S3] read the verdict artifact first; lead with its current framing — a verdict section supersedes the row's `Prior:`; [RED: S3] row↔verdict conflict → surface both with a quote and pause, never silently override either side) · § Frozen claim (re-ground by re-reading, never by rewriting the row — the claim block is write-once).

### Task 5: GREEN — target runs

**Interfaces:**
- Consumes: Task 1 rig + Task 3/4 shipped skeleton text.

- [ ] **Step 1: Dispatch targets** — S1 ×5, S2 ×2, S3 ×2 (skip S4/S5 — close-verdict scenarios, no target text). Same prompts and model as Task 2, plus: first Read the relevant shipped skeleton(s) (`assets/scale/rules-capture-routing-skeleton.md` + `parked-skeleton.md` for S1; `rules-venue-map-skeleton.md` + `backlog-fact-fields.md` for S2; `rules-pickup-grounding-skeleton.md` for S3) and operate under them.
- [ ] **Step 2: Score** — S1 5/5: (a) backlog row, (b) parked WITH observer + fire-moment trigger, (c) dropped; S2 2/2: stochastic + visual rows flagged non-cloud with modality named; S3 2/2: leads with notes framing, surfaces the conflict, row untouched. Any failure → tighten the specific line, re-run that scenario. GREEN required before Task 6.

### Task 6: harness-bootstrap install wiring

**Files:**
- Modify: `plugins/super-bootstrap/skills/harness-bootstrap/SKILL.md`
- Modify: `plugins/super-bootstrap/skills/harness-bootstrap/assets/claude-md-skeleton.md`

**Interfaces:**
- Consumes: Task 3/4 asset filenames under `assets/scale/`.
- Produces: `§2a-scale` install phase; scale artifacts join § Pipeline-owned + Placeholders + 2c staging list.

- [ ] **Step 1: SKILL.md — new `### 2a-scale: Scale module (opt-in, earn-gated)`** after §2a-drain. Content: earn signals (prompt only when ≥1 holds — open `docs/backlog.md` rows ≥ 10 · drain worktree infra installed · user asked for it; none hold → silent skip, no prompt spam). Ask-once block modeled on §2a-drain's. On `y`: copy the five `assets/scale/` skeletons to their targets per the per-artifact rule (parked → `docs/parked.md`, test-queue → `docs/test-queue.md`, three rules → `.claude/rules/`), insert the fact-fields block into the `docs/backlog.md` header (marker-delimited; skip if markers present), add one summary bullet per seeded rule to CLAUDE.md § Rules (existing mechanism), stage with the 2c commit. On `skip`: nothing placed; re-run re-offers while signals hold.
- [ ] **Step 2: SKILL.md — § Pipeline-owned list** gains (conditional — checked only when the module is installed, detected by `docs/parked.md` presence): the two container headers, the three seeded rule skeleton bodies, the backlog fact-fields marker block. Entries/rows in the containers are project-owned.
- [ ] **Step 3: SKILL.md — 2c staging list** gains the module targets (when installed this run); Placeholders section gains none (skeletons copy without substitutions — verify this stays true after Task 3/4 authoring; if a placeholder crept in, list it here).
- [ ] **Step 4: `claude-md-skeleton.md` § Planning** — add two bracketed conditional lines (existing skeleton convention: kept only when the artifact is scaffolded): `{- docs/parked.md — deferred items with named triggers (scale module)}` and `{- docs/test-queue.md — manual-verification queue (scale module)}`.

### Task 7: classify-actionable §d test-queue

**Files:**
- Modify: `plugins/super-bootstrap/shared/classify-actionable.md`

**Interfaces:**
- Consumes: test-queue entry shape (Task 3): `## Pending` entries with `result: pending`.
- Produces: `Manually verify:` rows for todo/drain consumers.

- [ ] **Step 1:** Add `### d. Test queue (docs/test-queue.md — scale module, skip if absent)` after §c: each `## Pending` entry with `result: pending` → action `"Manually verify: {entry title}"`, **intent: Device** (verb-map row already locks it), **stage: review**. `## Failed` entries emit nothing (their re-queue + bug row already cover them). Closing line mirrors §c's: file absent → skip §d.
- [ ] **Step 2:** Confirm no other section of the file needs touching (the verb map already carries `Manually verify` → Device; parked entries deliberately emit nothing — trigger-fired, not board-listed).

### Task 8: Closed forks + catalog

**Files:**
- Modify: `docs/decisions.md`
- Modify: `plugins/super-bootstrap/README.md`

- [ ] **Step 1: decisions.md** — append (newest-first) three design rows, contingent on Task 2 outcomes:
  - worktree-boundary (structural close, no runs): CL's path-glob rule can't fire inside a subprocess whose project root IS the worktree; sb's drain ships the strictly-stronger dispatch-prompt anchor (`skills/drain/assets/worktree-boundary.md`). Ref: that asset path.
  - triage-routing (close on S4 clean): superseded by shipped `/super-bootstrap:triage` lane + CLAUDE.md § Dispatch closure/centrality. Ref: `plugins/super-bootstrap/skills/triage/SKILL.md`.
  - findings-logging (close on S5 clean): persistence boundary already root doctrine (log skill + § Dispatch); CL's own addenda section marks the rest product-specific. Ref: `plugins/super-bootstrap/skills/log/SKILL.md`.
  - Any S1/S2/S3 line cut on clean controls → its own row, same format.
- [ ] **Step 2: README** — harness-bootstrap catalog entry gains one line: scale module (opt-in, earn-gated) = parked + test-queue containers, venue-map / capture-routing / pickup-grounding rules, backlog fact fields.

### Task 9: Cold audit

- [ ] **Step 1:** Invoke `audit-harness-edits` on the full diff (6 new assets + 3 modified files). Disposition every finding: fix / defend / log via `/super-bootstrap:log`.

### Task 10: Doc-sync + commit

- [ ] **Step 1:** Update `docs/superpowers/specs/harness-rebase.md`: CL-rules verdict row → **done (Wave 2)** — 3 ported into `assets/scale/` (venue-map, capture-routing, pickup-grounding) + parked/test-queue containers + fact fields; 3 closed (worktree-boundary, triage-routing, findings-logging — decisions.md). Spine decision 1 note: scale module shipped, state machine deliberately NOT ported (file-presence derivation won). Wave plan line 2 strikes scale module.
- [ ] **Step 2:** Invoke `/super-bootstrap:commit` — session files: 6 new assets, `SKILL.md`, `claude-md-skeleton.md`, `classify-actionable.md`, `README.md`, `decisions.md`, `harness-rebase.md`, this plan. Message: `feat(harness): GAP-017 wave 2 — scale module (opt-in tracker constellation)`.
- [ ] **Step 3:** GAP-017 row stays open (Wave 2 continues: monorepo tier, adopt mode; Wave 3 drain). Do NOT delete the card.

## Self-review notes (writing-plans)

- Spec coverage: spine decision 1 pieces — parked ✓(T3) · test-queue ✓(T3) · fact fields ✓(T3) · venue-map ✓(T4) · state machine deliberately not ported (Global Constraints + T10 spec note) · closed-forks doc convergence needs no artifact (decisions.md already IS the converged doc). Verdict-row rules: 3 ported (T4), 3 closed (T8), user-approved deviation recorded (Global Constraints). Install ✓(T6), earn gate ✓(T6), drain interface ✓(venue enum contract atom, T4). ✓
- Placeholder scan: draft-by-section is the sanctioned § Distill route sizing carve-out, not a placeholder; every contract atom (venue table, admission gate, fact fields, entry shapes) is embedded. ✓
- Consistency: `PARK-###` uniform (T3 skeleton, T4 capture-routing); `assets/scale/` filenames identical across T3/T4/T5/T6; `docs/parked.md`-presence as module-installed signal used in T6 only. ✓
