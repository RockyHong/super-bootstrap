# Todo Need-Me Board Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Make bare `/super-bootstrap:todo` render a momentum-driven **need-me board** — drainable work collapses to a count, need-me work groups by venue category with a downstream fan-out signal — dissolving the large-board wall without a mandatory stop.

**Architecture:** All changes are harness prose (markdown skill/agent/scaffold). The `todo` subagent consumes the venue map when wired (degrades to the intent axis when not), splits rows into drainable-count vs four need-me groups, computes fan-out as the reverse of its existing coupling gate, and renders a new default scaffold. The gateway skip-gate drops to existence-only Glob so it never content-reads `docs/**` (kills the path-rule pollution). `/todo full` stays as the flat escape.

**Tech Stack:** Markdown-authored Claude Code plugin. No language runtime, no build. Verification = dispatch the `todo` agent against a synthetic board fixture and diff the render; `audit-harness-edits` post.

## Global Constraints

- **No mandatory stop.** The default board is a rendered surface the user reads and navigates from — never an `AskUserQuestion` gate (the reopened decisions.md line 28 bar).
- **Graceful degrade is a file-presence branch, not a code fork.** `if exists(.claude/rules/venue-map.md)` → venue grouping; else → intent-axis grouping. Same shape either way. Mirror `skills/drain/assets/eligibility.md`'s branch exactly.
- **Venue is consumed, never re-derived.** The agent reads venue from `venue-map.md` (`§Derivation`, `§Modality overrides`); it never hand-maps a phase to T/S/U/P.
- **Shipped scaffold stays self-contained** (repo-boundary): the `skills/todo/**` assets must resolve in a consumer repo that has only the installed plugin — no wire to the author's `.claude/guidelines/`, no plugin-internal path a consumer lacks.
- **Verbatim relay unchanged.** The subagent renders; the gateway relays its returned text with no editorial. The gateway never content-reads `docs/**`.
- **Classification is not touched.** `shared/classify-actionable.md` stops at `{action, intent, stage}` (its consumer boundary). Fan-out + venue grouping live in `agents/todo.md`. This plan does NOT edit `classify-actionable.md`.

---

## File Structure

| File | Responsibility | Task |
|---|---|---|
| `plugins/super-bootstrap/skills/todo/assets/scaffolds.md` | Literal render templates — add the default **need-me** scaffold + fan-out column; refine the "no Next up" note; `Full` scaffold stays as flat escape | 1 |
| `plugins/super-bootstrap/agents/todo.md` | Render logic — venue/need-me split + degrade (Task 2); fan-out compute + ranking (Task 3) | 2, 3 |
| `plugins/super-bootstrap/skills/todo/SKILL.md` | Dispatch shell — skip-gate → glob-only, dispatch unconditional, empty-state in subagent, `/todo full` doc | 4 |
| `plugins/super-bootstrap/skills/harness-bootstrap/assets/scale/rules-venue-map-skeleton.md` | Clarify the `/todo` consumer face (need-me grouping the map serves) | 5 |
| `docs/decisions.md` | Line 28 → reopen executed | 6 |
| `docs/superpowers/specs/2026-07-08-todo-need-me-board-design.md` | Correct the closure table (drop `classify-actionable.md`) | 6 |

`CLAUDE.md § Rules` is untouched — `venue-map.md` is a scale-module skeleton, not an active rule in this repo, so no active-rule summary changes.

---

## Task 0: RED — synthetic fixture + expected render (baseline fails)

**Files:**
- Create: `<scratchpad>/todo-fixture/docs/backlog.md`
- Create: `<scratchpad>/todo-fixture/docs/superpowers/specs/2026-07-01-sample-feature-design.md`
- Create: `<scratchpad>/todo-fixture/docs/superpowers/triage/GAP-050-scope.md`
- Create: `<scratchpad>/todo-fixture/.claude/rules/venue-map.md` (copy of the skeleton, for the wired case)
- Create: `<scratchpad>/todo-fixture-expected-needme.md` (expected render)

`<scratchpad>` = `C:\Users\User\AppData\Local\Temp\claude\D--Git-super-bootstrap\bd3bcaed-0025-49cb-a78e-6b3d600373cd\scratchpad`

- [ ] **Step 1: Build the fixture board** — a mix that exercises every branch:

```
docs/backlog.md ## Open:
### BUG-041  visual glitch on login button   (Area: apps/web/login, Test-feel: manual)   → Device-bound (U)
### GAP-050  add retry to sync core          (Area: packages/sync)  triage scope.md exists → Implement, pure-logic → drainable (T)
### GAP-051  decide: port vs rewrite parser   (line: needs user decision)               → Decide/approve (U)
### GAP-052  eval prompt quality harness       (Area: packages/eval, Stochastic: llm)     → Probe/grant (P)
### DEBT-030 refactor auth module, blocked by GAP-051  (line: "depends on GAP-051")      → hard-blocked, held; GAP-051 fan-out +1
### GAP-053  Deliberate: split drain venue lanes  (Area: .claude/rules)                   → Harness
specs/2026-07-01-sample-feature-design.md  (approved, no plan)                            → Write plan → drainable (T)
```

- [ ] **Step 2: Write the expected need-me render** to `todo-fixture-expected-needme.md`:

```
# To-Do — {date}

Drainable: 2  →  /super-bootstrap:drain

▸ Need me

## Decide / approve
| # | Action | unblocks | Impact | Blast |
| 1 | Decide: GAP-051 port vs rewrite parser | 1 | impactful | repo |

## Device-bound
| # | Action | unblocks | Impact | Blast |
| 1 | Manually verify: BUG-041 login button glitch | 0 | quick-pop | local |

## Harness
| # | Action | unblocks | Impact | Blast |
| 1 | Deliberate: split drain venue lanes | 0 | impactful | repo |

## Probe / grant
| # | Action | unblocks | Impact | Blast |
| 1 | Grant: GAP-052 eval prompt quality harness | 0 | quick-pop | pkg |

pending unblock: 1
flat list: /super-bootstrap:todo full · drainable detail: /super-bootstrap:todo cloud
more: /super-bootstrap:help
```

(GAP-050 + the approved spec are the 2 drainable → count only. DEBT-030 is hard-blocked → held, surfaces as `pending unblock: 1`, and lifts GAP-051's `unblocks` to 1.)

- [ ] **Step 3: Dispatch the CURRENT `todo` agent against the fixture** — confirm it renders the OLD full board (every row as a card, no drainable-count collapse, no fan-out column, no venue groups):

Run (from a shell with the fixture as cwd, or pass the fixture root in the dispatch prompt):
`Agent subagent_type: "super-bootstrap:todo"`, prompt = current `/todo` full-mode dispatch template pointed at the fixture.
Expected: **FAIL** — output is the flat `Full` scaffold (File/Stage/Progress/Blocker/Impact/Blast columns), drainable rows listed as cards, no `Drainable: N` line, no `unblocks` column, no venue group headings.

- [ ] **Step 4: Commit the fixture**

```bash
git add docs/superpowers/plans/2026-07-08-todo-need-me-board.md
git commit -m "test(todo): red — need-me board fixture + expected render"
```

(The fixture files live in scratchpad, uncommitted — throwaway. Only the plan is tracked. The RED evidence is recorded in the task checkboxes.)

---

## Task 1: Need-me default scaffold + fan-out column

**Files:**
- Modify: `plugins/super-bootstrap/skills/todo/assets/scaffolds.md`

**Interfaces:**
- Produces: the literal slot names the `todo` agent fills — `{date}`, the `Drainable: {N}` line, four group headings (`## Decide / approve`, `## Device-bound`, `## Harness`, `## Probe / grant`), the column set `| # | Action | unblocks | Impact | Blast |`, `## Uncategorized`, `pending unblock: {n}`, and the footer nav line. Tasks 2–4 fill exactly these.

- [ ] **Step 1: Add the default need-me scaffold** at the top of `scaffolds.md` (before the existing `### Discuss` section), as the new bare-`/todo` render:

````markdown
### Need-me (default — bare `/super-bootstrap:todo`)

Drainable rows collapse to the count line; the four need-me groups render as
tables. Omit any group whose row count is zero (drop its heading too). Groups
render in this fixed order.

```
# To-Do — {date}

Drainable: {N}  →  /super-bootstrap:drain

▸ Need me

## Decide / approve

| #  | Action                                  | unblocks | Impact       | Blast       |
| -- | --------------------------------------- | -------- | ------------ | ----------- |
| 1  | {verb + what + one-line reason}         | {n}      | {tag}        | {tag}       |

## Device-bound

| #  | Action                                  | unblocks | Impact       | Blast       |
| -- | --------------------------------------- | -------- | ------------ | ----------- |
| 1  | {verb + what + one-line reason}         | {n}      | {tag}        | {tag}       |

## Harness

| #  | Action                                  | unblocks | Impact       | Blast       |
| -- | --------------------------------------- | -------- | ------------ | ----------- |
| 1  | Deliberate: {topic} / Apply: {rule}→{site} | {n}   | {tag}        | {tag}       |

## Probe / grant

| #  | Action                                  | unblocks | Impact       | Blast       |
| -- | --------------------------------------- | -------- | ------------ | ----------- |
| 1  | {verb + what + one-line reason}         | {n}      | {tag}        | {tag}       |

## Uncategorized

| #  | Action                                  | Why ambiguous                          |
| -- | --------------------------------------- | -------------------------------------- |
| 1  | {verb + what}                           | {one-line — what signal was missing}   |

{pending unblock: {n} — only if n>0}
flat list: /super-bootstrap:todo full · drainable detail: /super-bootstrap:todo cloud
more: /super-bootstrap:help
```

Empty state (no need-me rows AND no drainable):

```
# To-Do — {date}

No active work. Start something with /brainstorm or give me a task.
```

Empty need-me but drainable pending:

```
# To-Do — {date}

Drainable: {N}  →  /super-bootstrap:drain

Nothing needs you right now — the board is all auto-runnable.

flat list: /super-bootstrap:todo full
more: /super-bootstrap:help
```
````

- [ ] **Step 2: Refine the "no Next up" note** — locate in `scaffolds.md` (the `### Full` section trailer, currently `No "Next up" recommendation block in any mode (solo-dev momentum-driven; user picks from list, system doesn't strategize).`) and replace with:

```
No "Next up" recommendation block in any mode. Momentum-driven surfacing is
**computed foregrounding** — venue grouping + fan-out rank order the board by
objective leverage, no opinion prose. The bar stands on strategizing ("Best
next: Y" / "Recommend X"), never on ranked ordering: surface, don't editorialize.
```

- [ ] **Step 3: Verify the scaffold is structurally complete**

Run: `grep -nE "Drainable:|Decide / approve|Device-bound|Probe / grant|unblocks|flat list:" plugins/super-bootstrap/skills/todo/assets/scaffolds.md`
Expected: all six literals present; the `Need-me` section precedes `### Discuss`.

- [ ] **Step 4: Commit**

```bash
git add plugins/super-bootstrap/skills/todo/assets/scaffolds.md
git commit -m "feat(todo): add need-me default scaffold + fan-out column"
```

---

## Task 2: Venue consumption + need-me/drainable split in the agent

**Files:**
- Modify: `plugins/super-bootstrap/agents/todo.md`

**Interfaces:**
- Consumes: `{action, intent, stage}` from the embedded `classify-actionable.md` (unchanged); venue T/S/U/P + modality from `venue-map.md` when present.
- Produces: each row tagged `lane ∈ {drainable, needme}` and, for `needme`, `group ∈ {decide, device, harness, probe}` — Task 3 ranks within these, the scaffold (Task 1) renders them.

- [ ] **Step 1: Add a "Lane + group split" section** to `agents/todo.md` after the Modes table (before `## Classification`), defining the split the default render uses:

```markdown
## Lane split — drainable vs need-me (default render)

Bare `/super-bootstrap:todo` renders the **need-me board**. Before ranking, tag
each classified row with a **lane**, and each need-me row with a **group**.

**Venue map wired** (`.claude/rules/venue-map.md` present) — read each row's
**next-phase venue** from the map (`§Derivation` + `§Modality overrides`); never
re-derive it:

| Venue | Lane | Need-me group |
|---|---|---|
| **T** (tooling/headless) | drainable | — |
| **S** (stack-bound, merge-probe) | drainable | — |
| **U**, no device modality | need-me | **decide** |
| **U** via device modality (visual-taste / `Test-feel: manual`) | need-me | **device** |
| **P** (probe/stochastic) | need-me | **probe** |
| `intent: Harness` (pre-filter, drain-excluded) | need-me | **harness** |

`intent: Harness` wins over venue — the harness layer never drains, whatever its
phase venue. The modality that splits **U** into decide vs device is read from the
row's fields (the same signals `venue-map.md §Modality overrides` consumes), never
by keyword-guessing the action text.

**Venue map absent** (no scale module) — degrade to the intent axis, same
file-presence branch `skills/drain/assets/eligibility.md` uses:

| Intent | Lane | Need-me group |
|---|---|---|
| `Cloud` | drainable | — |
| `Discuss` | need-me | **decide** |
| `Device` | need-me | **device** |
| `Harness` | need-me | **harness** |

(No `probe` group without the map — `P` collapses into the bare cloud-safe axis,
exactly the degrade `drain` accepts. `S` collapses to `Device` and would render
under **device**; acceptable — the map is what promotes it to drainable.)

**Drainable count** `N` = count of `lane: drainable` rows. It renders as the
`Drainable: {N}` line, never as cards. The need-me rows render grouped.
```

- [ ] **Step 2: Point the render step at the need-me scaffold for the default (bare/full-dispatch) path.** In `agents/todo.md` `## Render`, add: the dispatched scaffold for the default board is the **Need-me** scaffold (Task 1); the `Full` scaffold is reserved for the explicit `/super-bootstrap:todo full` flat escape. Update the Modes table `full` row note to distinguish: bare `/todo` → need-me board; `/todo full` → flat everything.

Replace the `Modes` table `full` row:
```
| `full`    | Explicit `/super-bootstrap:todo full` — flat escape | All rows (need-me + drainable) ungrouped, ranked — the flat "非類清單". |
```
And add a `needme` row:
```
| `needme`  | Default bare `/super-bootstrap:todo`                 | Drainable→count; need-me grouped by venue category with fan-out. |
```

- [ ] **Step 3: Verify the split logic reads without gaps**

Run: `grep -nE "Lane split|drainable|need-me group|venue-map.md|degrade to the intent axis" plugins/super-bootstrap/agents/todo.md`
Expected: the section exists, names both the wired and degrade branches, and cites `venue-map.md` as the venue source.

- [ ] **Step 4: Commit**

```bash
git add plugins/super-bootstrap/agents/todo.md
git commit -m "feat(todo): lane split — drainable count vs venue-grouped need-me"
```

---

## Task 3: Fan-out compute + ranking in the agent

**Files:**
- Modify: `plugins/super-bootstrap/agents/todo.md`

**Interfaces:**
- Consumes: the coupling edges already traced in `§4 Rank within mode` (hard-block explicit naming; soft-coupling shared artifact/convention); the `group` tags from Task 2.
- Produces: `fanout: {n}` per need-me row (the `unblocks` column the scaffold renders); ranking within each group.

- [ ] **Step 1: Add the fan-out definition** to `agents/todo.md §4` (right after the Coupling gate's two edge kinds), as the reverse of the edges just defined:

```markdown
**Fan-out (leverage signal — reverse of the coupling edges above).** For each
need-me row X, `fanout(X)` = the count of other open rows that X unblocks:

- **+1 per hard-blocked row that names X** — a row held out of the body by the
  Coupling gate whose named prerequisite resolves to X. (These are the rows
  behind the `pending unblock` footer count; fan-out is the reason to do X.)
- **+1 per soft-coupled row X shapes** — a body row whose correct execution
  depends on X's artifact / convention (X is the upstream of the soft edge).

`fanout` is rendered as the `unblocks` column. `0` is valid and shown — not every
need-me card unblocks downstream, but it still needs attention. Fan-out is a
**computed** count, never an opinion.
```

- [ ] **Step 2: Make fan-out the primary rank key within a group.** In `§4 Rank within mode`, prepend a rank key ahead of the existing four (Impact desc → Progress → action-verb → Recency):

```markdown
Within each need-me group, rank by these keys in order:

0. **Fan-out desc** — higher `unblocks` first (do the card that releases the most
   downstream). Ties fall through to the keys below.
1. **Impact desc** — `impactful` first, `quick-pop` second
2. **Progress desc within Impact** — most-complete executing rows first
3. **Action-verb priority** — {existing order, unchanged}
4. **Recency desc** — newest first (tiebreak)

**Soft-coupling adjacency** still overrides locally: a soft-coupling upstream row
ranks immediately above the row it shapes, even when fan-out or the other keys
would separate them.
```

- [ ] **Step 3: Verify fan-out wiring**

Run: `grep -nE "Fan-out|fanout|unblocks|Fan-out desc" plugins/super-bootstrap/agents/todo.md`
Expected: definition present, `unblocks` column named, fan-out is rank key 0.

- [ ] **Step 4: Commit**

```bash
git add plugins/super-bootstrap/agents/todo.md
git commit -m "feat(todo): fan-out unblocks-count as need-me leverage + rank key"
```

---

## Task 4: Skip-gate → glob-only; subagent owns empty-state

**Files:**
- Modify: `plugins/super-bootstrap/skills/todo/SKILL.md`

**Interfaces:**
- Consumes: nothing new.
- Produces: a gateway that content-reads no `docs/**` file; the subagent owns the empty/non-empty determination and the empty-state render.

- [ ] **Step 1: Rewrite the skip-gate** in `SKILL.md §Dispatch behavior` — replace the content-reading emptiness check with an existence-only Glob branch:

```markdown
**Canonical skip-gate (existence-only — the gateway never content-reads `docs/**`).**
The gateway decides dispatch from **directory presence alone** (Glob lists paths,
loads no file content, fires no `docs/**` path-scoped rule):

- **`docs/superpowers/` absent** (Glob returns nothing) → repo has the pipeline
  available but no runway installed. Print, no dispatch:
  > "No runway installed. Run `/super-bootstrap` to set up the pipeline."
- **`docs/superpowers/` present** → **dispatch the `todo` subagent unconditionally.**
  The empty/non-empty determination moves into the subagent: it reads the three
  sources and renders either the empty-state (`No active work…`) or the board.

The gateway performs **no content read** of `docs/backlog.md`, specs, or plans —
that is why the doc path-rules (`dimension-discipline`, `ssot-doc-link`,
`venue-map`) no longer load in the gateway's context on `/todo`. All `docs/**`
reads happen inside the subagent.
```

- [ ] **Step 2: Update the dispatch steps** in `SKILL.md §Dispatch behavior` "On bare `/super-bootstrap:todo`" — remove "Run the skip-gate" content-scan wording; the step is now "Glob `docs/superpowers/` presence; absent → print the runway message; present → dispatch `needme` mode." Change the bare dispatch mode from `full` to `needme`. Add a line documenting `/super-bootstrap:todo full` as the flat-escape sub-verb dispatching `full` mode.

- [ ] **Step 3: Update the Arguments table** — the bare `/super-bootstrap:todo` row now reads "Render the **need-me board** (drainable→count, venue-grouped)." Add a `/super-bootstrap:todo full` row: "Flat escape — every row (need-me + drainable) ungrouped, ranked."

- [ ] **Step 4: Verify**

Run: `grep -nE "existence-only|never content-read|dispatch the \`todo\` subagent unconditionally|todo full|needme" plugins/super-bootstrap/skills/todo/SKILL.md`
Expected: skip-gate is existence-only, bare dispatches `needme`, `full` documented as flat escape.

- [ ] **Step 5: Commit**

```bash
git add plugins/super-bootstrap/skills/todo/SKILL.md
git commit -m "feat(todo): skip-gate glob-only, bare renders need-me, /todo full escape"
```

---

## Task 5: Clarify the venue-map `/todo` consumer face

**Files:**
- Modify: `plugins/super-bootstrap/skills/harness-bootstrap/assets/scale/rules-venue-map-skeleton.md`

**Interfaces:**
- Consumes: nothing.
- Produces: the skeleton documents what `/todo` derives from the map (the need-me grouping), matching Task 2's lane split.

- [ ] **Step 1: Extend the `## Consumer boundary` section** — the current line says "todo (cloud vs device)". Replace with the need-me framing:

```markdown
One map, two filters — never re-derived by hand:

- **`/super-bootstrap:todo`** reads it **drainable vs need-me**: venues **T/S** →
  the drainable count; **U** → *decide* (or *device* when a device modality gates
  the phase); **P** → *probe*; `intent: Harness` → *harness*. The four need-me
  groups are the board body; drainable is one count line.
- **`/super-bootstrap:drain`** reads it **dispatch vs wall**: next-phase venue
  ∈ {T, S} admits; {U, P} → skip & surface.

Mapping to the bare axis: T≈Cloud, U≈Discuss/Device; S and P are refinements each
lane consumes when the map is wired.
```

- [ ] **Step 2: Verify**

Run: `grep -nE "drainable vs need-me|decide|probe|harness" plugins/super-bootstrap/skills/harness-bootstrap/assets/scale/rules-venue-map-skeleton.md`
Expected: the consumer boundary names the four need-me groups.

- [ ] **Step 3: Commit**

```bash
git add plugins/super-bootstrap/skills/harness-bootstrap/assets/scale/rules-venue-map-skeleton.md
git commit -m "docs(venue-map): document /todo need-me grouping consumer face"
```

---

## Task 6: Record the reopen — decisions.md + spec closure fix

**Files:**
- Modify: `docs/decisions.md` (line 28 row)
- Modify: `docs/superpowers/specs/2026-07-08-todo-need-me-board-design.md` (closure table)

**Interfaces:**
- Consumes: nothing.
- Produces: the history record that the closed fork was reopened and answered.

- [ ] **Step 1: Rewrite the decisions.md line-28 row.** The current row closed the ChewLingo macro-picker port. Replace its verdict column with the reopen-executed record (keep it a state-of-the-decision line, not a dated essay):

```
| design | Port ChewLingo's bare-invoke macro picker (two-turn AskUserQuestion mode gate with per-mode counts) into `/super-bootstrap:todo` | **Reopened + answered without the picker.** The reopen condition (full board outgrows one screen on large repos) was met; the answer is a need-me board — bare `/todo` collapses drainable work to a count and groups need-me work by venue with a fan-out signal, so the wall dissolves with no AskUserQuestion turn. The picker itself stays rejected: its mandatory stop is what a rendered navigable surface avoids. | `plugins/super-bootstrap/skills/todo/**`, `agents/todo.md` (2026-07-08 need-me board) |
```

- [ ] **Step 2: Fix the spec closure table** — in `2026-07-08-todo-need-me-board-design.md`, remove the `shared/classify-actionable.md` row from the "Files touched" table (the consumer boundary keeps fan-out + venue grouping in `agents/todo.md`; classification is untouched). Add a one-line note under the table: "`shared/classify-actionable.md` is **not** touched — its consumer boundary stops at `{action, intent, stage}`; fan-out + venue grouping are `agents/todo.md`'s concern."

- [ ] **Step 3: Verify**

Run: `grep -nE "Reopened \+ answered|need-me board" docs/decisions.md` and `grep -n "classify-actionable" docs/superpowers/specs/2026-07-08-todo-need-me-board-design.md`
Expected: decisions.md row updated; spec closure no longer lists classify-actionable as touched (only the not-touched note).

- [ ] **Step 4: Commit**

```bash
git add docs/decisions.md docs/superpowers/specs/2026-07-08-todo-need-me-board-design.md
git commit -m "docs: record todo need-me reopen; correct spec closure"
```

---

## Task 7: GREEN — fixture render passes + audit

**Files:**
- Uses: the Task 0 fixture.

- [ ] **Step 1: Re-dispatch the `todo` agent against the fixture, venue-map WIRED** — `Agent subagent_type: "super-bootstrap:todo"`, `mode: needme`, pointed at `<scratchpad>/todo-fixture` (which has `.claude/rules/venue-map.md`). Diff against `todo-fixture-expected-needme.md`.
Expected: **PASS** — `Drainable: 2` line; GAP-050 + the approved spec NOT listed as cards; four need-me groups populated (Decide/approve=GAP-051, Device-bound=BUG-041, Harness=GAP-053, Probe/grant=GAP-052); GAP-051 shows `unblocks 1`; `pending unblock: 1`; footer nav line present.

- [ ] **Step 2: Re-dispatch with venue-map ABSENT** — remove `.claude/rules/venue-map.md` from the fixture, dispatch again.
Expected: **PASS (degrade)** — same shape; groups now sourced from the intent axis (BUG-041→device via `Device`, GAP-051→decide via `Discuss`, GAP-053→harness; GAP-052 folds into the drainable/cloud axis — Probe/grant group absent). Drainable count adjusts. No crash, no shape change.

- [ ] **Step 3: Empty-state check** — point the agent at a fixture whose `docs/backlog.md ## Open` is empty and no specs/plans.
Expected: subagent returns `No active work…` — and the gateway did **no** content read (only the existence Glob).

- [ ] **Step 4: `audit-harness-edits`** on the full diff (all of Tasks 1–6). Disposition each finding.

Run: invoke `/audit-harness-edits` (or the skill) against the working diff.
Expected: no unresolved findings; harness centrality earns the pass.

- [ ] **Step 5: Final commit / doc-sync** — run `/super-bootstrap:commit` for any audit-driven fixes and the doc-sync scan across the touched surface.

---

## Self-Review

**Spec coverage:**
- Pillar 1 (drainable→count) → Task 1 (scaffold line) + Task 2 (lane split, count = drainable rows). ✓
- Pillar 2 (need-me venue grouping + degrade) → Task 2 (both branches) + Task 1 (group tables) + Task 5 (venue-map consumer face). ✓
- Pillar 3 (fan-out) → Task 3. ✓
- Pillar 4 (flat escape + Uncategorized) → Task 1 (Uncategorized in scaffold) + Task 4 (`/todo full`). ✓
- Pillar 5 (skip-gate glob-only + subagent empty-state) → Task 4. ✓
- Revisions (decisions.md line 28, "no Next up" note, spec closure) → Task 6 + Task 1 Step 2. ✓

**Placeholder scan:** no "TBD"/"handle edge cases"/"similar to Task N" — each edit block carries its literal prose. Fixture rows are concrete. ✓

**Type consistency:** group names (`decide`/`device`/`harness`/`probe` internal; `Decide / approve`/`Device-bound`/`Harness`/`Probe / grant` rendered), the `unblocks` column, `fanout`, `lane`, `Drainable: {N}` line, and `needme`/`full` modes are used identically across Tasks 1–5. ✓
