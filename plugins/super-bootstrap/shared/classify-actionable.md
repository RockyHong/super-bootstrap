# Classify Actionable — shared spec

Single source of truth for deriving, from the open work cards (plus the scale module's test queue when present), **each open item's `{action, intent, stage}`**. Consumed by every caller that needs the classification — `todo`'s bundled `skills/todo/assets/render-board.py` (the primary board renderer, a mechanical encoding of this spec), the `todo` subagent (fallback lane — Reads it at classify time, then ranks + renders a board), and `drain` (gateway Reads it inline, then gates on `Cloud` + spawns per stage). One criterion, many callers: no caller re-derives it.

> **Callers self-read, never paraphrase — and an edit here propagates to the script.** Read this file at classify time and apply it exactly — `todo`'s skill passes the resolved absolute path into the dispatch prompt for the subagent to Read; `drain`'s gateway Reads it inline. Paraphrasing forks the taxonomy — the drift this shared home exists to prevent. The script is the one consumer that *encodes* rather than reads: editing a criterion here pulls `render-board.py` into the edit's closure, checked by the golden bench (`bench/todo-board/` in the source repo).

Three outputs per item:

- **`action`** — the one-line actionable verb-phrase (`"Triage: BUG-12 …"`, `"Continue execute: GAP-31 … (3/7)"`). The render string.
- **`intent`** — `Discuss` | `Cloud` | `Device` | `Harness`. The runnability bucket. `Harness` rows additionally carry **`subgroup`** — `deliberate` | `apply` (§Harness pre-filter).
- **`stage`** — where the item's thread stands: `raw` (no verdict, or a `surface` verdict awaiting the user) · `triaged` (`auto-fix` Verdict block, no plan) · `aimed` (settled-aim Design block, no step-order Plan) · `executing` (Plan block in flight) · `review` (latest Progress reports every plan step done). The entry point for stage-resuming consumers.

`intent` is the gate; `stage` is the entry point; `action` is for human render.

---

## Harness pre-filter (applied before everything)

Before the verb map and any per-source rule: an item whose **deliverable is the harness layer** — `CLAUDE.md`, anything under `.claude/` (rules, skills, agents, hooks, settings), plugin-source harness files (`plugins/*/{skills,agents,shared}/**`, in repos that ship plugins), or a harness-source top-level layout (`skills/*/SKILL.md`, `agents/**`, `rules/**` at the repo root — the shape a repo uses when Claude configuration *is* its product, shipping harness at the tree root rather than under `.claude/` or `plugins/`) — classifies **intent: Harness**, regardless of verb or state. Judge from the card's `Area:` field, its Verdict-block `Files` paths, or its Plan-block step paths: the discriminator is the harness-file marker, not its directory prefix — a `SKILL.md`, agent, or rule target is a harness deliverable wherever it sits. A product change that touches a harness file incidentally is NOT harness — classify by the dominant surface; Harness = the harness file IS the deliverable.

The harness layer is the orchestration engine: it never rides the autonomous queue. A row the pre-filter catches exits here — intent: `Harness`, subgroup assigned below — before any cloud-safe derivation or content read. drain's intent lane guard excludes Harness rows before its admission gate runs.

Each Harness row carries a `subgroup` tag:

- **`deliberate`** — authors new doctrine or carries propagation closure (rewrites what a rule means, chains doc-sync, touches cross-cutting contract surfaces). Action: `"Deliberate: {topic}"`.
- **`apply`** — applies an existing codified rule to a bounded site (path fix, one clause under an existing section) with no closure. Action: `"Apply: {rule} → {site}"`.
- Ambiguous → `deliberate` (careful-handle default).

## Cloud-safe criterion

Applied to `Cloud OR Device (derive)` rows — those the verb map does not lock outright. The criterion judges the item's **next phase** — the phase its action names — never the whole chain: a device-bound tail (a manual verify) walls its own phase, not the build in front of it. Inputs read cheapest-first; stop at the first that locks the row:

> **Cloud-safe = phase produces a verifiable artifact via tooling alone. No human visual judgment, no interactive browser/device step, no "looks right" call. A fully-automated headless suite (playwright et al., assertions only) is tooling; browser-MCP automation is not — the extension relay attaches to interactive sessions only, so a headless run never reaches it.**

### Derivation inputs (read in order — stop at the first that locks the row)

1. **Phase verb** in derived action:
   - `Write plan` / `Approve design` / `Triage` / `Extract` / `Doc-edit` → cloud-safe regardless of paths
   - `Manually verify` → device-only
   - `E2E run` / `Smoke test` → derive from the suite's run shape: fully-automated headless suite (assertions only) → cloud-safe; human eyes, screenshot judgment, or a browser-MCP step → device-only; shape unstated → device-only
   - `Start execute` / `Continue execute` / `Review` / `Implement` → derive per #2 + #3 (for `Implement` rows, skip the free-text keyword grep — read the `auto-fix` Verdict block as fields: its `Files` paths feed #2's path arms; its `Test Strategy` field gates the **review-phase row only** — a device-bound strategy (manual / visual / interactive-browser) walls the verify phase, never the build row in front of it; a fully-automated headless suite does not wall; the field's literal value never re-enters the keyword scan)
2. **Plan-block content** — grep the card's latest `## Plan` block for device signals:
   - Keywords: `manual test`, `visual`, `device`, `mobile`, `browser`, `screenshot` (`e2e` / `playwright` / `cypress` alone are not device signals — a fully-automated headless suite is cloud-runnable; they wall only when paired with a visual / manual / interactive-browser signal)
   - Paths in step lines: `**/components/**`, `**/app/**`, `**/pages/**`, `**/views/**`, `apps/web/**`, `apps/mobile/**` → device-suspicion
   - If only pure-logic paths (`lib/`, `utils/`, `core/`, `packages/{logic-name}/`) and no device keywords → cloud-safe
3. **Design-block success criteria** (when the card carries a `## Design` block) — explicit `manual verification`, `visual check` → device-only for the **review** row (the phase the criterion gates); executing rows derive from #2 alone

### Default

If no signal is conclusive, default cloud-safe for design / plan-write / triage rows; default device for executing rows touching UI surfaces; default cloud for executing rows on pure-logic surfaces.

## Action-verb intent map (applied after the Harness pre-filter)

Intent is determined by action verb before content reads. Rows locked to a definite intent exit here; `Cloud OR Device (derive)` rows proceed to the cloud-safe criterion.

| Action verb prefix                                              | Intent (locked)              | Why                                                                          |
| --------------------------------------------------------------- | ---------------------------- | ---------------------------------------------------------------------------- |
| `Approve design`, `Decide`, `Settle design`, `Confirm`          | **Discuss**                  | User-decision shape — only user can resolve.                                 |
| `Write plan`                                                    | **Cloud**                    | Plan author write is doc artifact, headless.                                 |
| `Refine spec`, `Doc-edit`                                       | **Cloud**                    | Doc artifact, headless.                                                      |
| `Start execute`, `Continue execute`, `Resume`                   | **Cloud OR Device** (derive) | Depends on paths + content per cloud-safe criterion.                         |
| `Review` (read diff of completed plan)                          | **Cloud**                    | Reading diff is headless.                                                    |
| `Manually verify`                                               | **Device**                   | Human visual judgment required.                                              |
| `E2E run`, `Smoke test`                                         | **Cloud OR Device** (derive) | Fully-automated headless suite → Cloud; human eyes or browser-MCP step → Device (cloud-safe criterion #1). |
| `Triage` (raw card, investigate-only)                           | **Cloud**                    | Investigate-only artifact, headless.                                         |
| `Implement` (card carrying an `auto-fix` Verdict block)          | **Cloud OR Device** (derive) | Depends on the Verdict block's `Files` paths + `Test Strategy` per cloud-safe criterion. |
| `Deliberate`, `Apply` (harness surface)                         | **Harness**                  | Pre-filter already caught it; the verb renders the subgroup.                  |

## Thread-state derivation

One source: the open cards at `docs/work/{BUG,DEBT,GAP}-###.md` (plus the scale module's test queue when present). Read each card, derive its `{action, intent, stage}` from where its thread stands. Apply the Harness pre-filter, then the Action-verb intent map, then the content rules.

**Latest-block-leads.** Derive from the **latest** block of each type: a newer `## Plan` supersedes the older one it replaced, the latest `## Progress` reports current execution state. Earlier blocks are grounding for the read, never the lead.

**Optional-source probe discipline.** `docs/work/` and the test queue are optional — absent until a repo reaches that stage. Probe presence by listing the concrete path (a concrete project-relative target lists reliably), not by content-reading a maybe-absent file. An absent optional source — an empty listing *or* a "does not exist" error — is an expected branch of this spec, not an anomaly to diagnose: record it empty, take its skip (§a–b), and move on immediately.

### a. Cards (`docs/work/{BUG|DEBT|GAP}-###.md`)

Cards own BUG/DEBT/GAP — bugs, debt, and design gaps / unverified feature ideas (GAP). A GAP that is a feature idea derives like any other card — no separate lane.

Each card is one append-only thread: a frozen origin block, then dated `## Amendment` / `## Verdict` / `## Design` / `## Plan` / `## Progress` blocks (contract: `docs/work/README.md`). Take the first rule that matches:

- **No Verdict / Design / Plan block** (origin only, or Amendments only — nothing has grounded the card yet) → action: `"Triage: {ID} {title}"`, **intent: Cloud** (triage is investigate-only), **stage: raw**.
- **Latest Verdict is `## Verdict — surface`, no Design or Plan block after it** (fork still waiting on the user) → action: `"Decide: {ID} {title} — triage verdict"`, **intent: Discuss**, **stage: raw**.
- **Latest Verdict is `## Verdict — auto-fix`, no Design or Plan block after it** → action: `"Implement: {ID} {title}"`, intent per cloud-safe derivation over that block's `Files` paths + its `Test Strategy` line, **stage: triaged**.
- **`## Design` block with no approval line appended after it** → action: `"Approve design: {ID} {title}"`, **intent: Discuss**, **stage: aimed**.
- **Approved Design, no `## Plan` block after it** → action: `"Start execute: {ID} {title}"`, **stage: aimed**, intent per cloud-safe derivation. A later `## Progress` → `"Continue execute: {ID} {title}"`, same stage and intent. `"Write plan: {ID} {title}"` (**intent: Cloud**) replaces either only when the card's latest block names a cold-executor route (a drain-wave queue, a cross-session handoff).
- **Latest `## Plan`, no `## Progress` after it** → action: `"Start execute: {ID} {title}"`, **stage: executing**. Intent per cloud-safe derivation.
- **Latest `## Plan` + a later `## Progress` reporting some of its steps done** → action: `"Continue execute: {ID} {title} ({done}/{total})"`, **stage: executing**. Intent per cloud-safe derivation.
- **Latest `## Plan` + a later `## Progress` reporting all of its steps done** → action: `"Review: {ID} {title}"`, **stage: review**. Intent per cloud-safe derivation (manual verification → Device; diff-read → Cloud). Resolution rides the review — the reviewing session deletes the card file; no separate row for it.

**Step counting.** Plan blocks carry steps only, no checkboxes or status marks: `{total}` = steps the latest Plan lists, `{done}` = those the latest Progress reports done, remaining = the difference. Read the Progress prose for which steps it names; a Progress that names none reports zero.

**Wait override.** A card whose origin block or latest appended block explicitly waits on a named party — the user (`needs user`, `decision required`, `route?`, `waiting on user`, an unresolved `?` directed at the user) or an external one (`blocked on {party}`, `waiting on {party}`; `blocked by {ID}` is a hard block, not a wait) → action: `"Decide: {ID} {title} — {what's open}"`, **intent: Discuss**, keeping the **stage** its thread state gives. Overrides the derived action above; an *unruled* `surface` Verdict is its most common form, a ruling whose settled aim is to wait on an external party its second.

**Actor override.** A card whose origin block carries the scale module's `Actor: author` or `Actor: external` fact field — the whole item is that party's move, the repo owning only its result tail → action: `"Decide: {ID} {title} — author moves"` / `"Decide: {ID} {title} — external party moves"`, **intent: Discuss**, keeping the **stage** its thread state gives. Overrides the derived action above; where the wait override also fires, its derived clause is the more specific, so it wins.

Any other file at `docs/work/` root — neither a card (`{BUG|DEBT|GAP}-###.md`) nor `README.md` / `TEMPLATE.md`: emit as `Uncategorized` with reason `"non-canonical work file; docs/work/ holds BUG/DEBT/GAP cards (feature ideas log as GAP). New cards route through /super-bootstrap:log."` — never invent classification.

If `docs/work/` holds no cards, skip §a.

### b. Test queue (`docs/test-queue.md` — scale module, skip if absent)

Entries are `### {plain descriptive title}` headings under `## Pending` (no ID in the heading).

- **`## Pending` entry with `result: pending`** → action: `"Manually verify: {entry title}"`, **intent: Device** (verb-map row already locks it), **stage: review**.
- **`## Failed` entries** → emit nothing; their re-queue + bug row already cover them.
- **Entry carries a `source: {BUG|DEBT|GAP}-###` back-pointer** → don't double-emit against that card's own §a row; the queue entry's row covers the verify obligation.

If `docs/test-queue.md` doesn't exist, skip §b.

---

## Consumer boundary

This spec stops at `{action, intent, stage}`. What each caller does next is **its own** concern, not shared here:

- **`todo`** — Impact/Blast tags, coupling gate, harness Deliberate/Apply grouping, within-mode ranking, scaffold render. Lives in `skills/todo/assets/render-board.py` (primary, mechanical encoding) and `agents/todo.md` (dispatch-lane fallback).
- **`drain`** — intent lane guards (`Harness` and `Discuss` never admit), then the admission gate (next-phase venue when the scale module is wired, `Cloud` otherwise), relation-analysis (file-overlap parallelism), wave selection, worktree spawn, stage-keyed phase entry. Lives in `skills/drain/`.

Edit the classification here; edit each caller's downstream in its own home.
