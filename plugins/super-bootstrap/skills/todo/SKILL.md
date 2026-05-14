---
name: todo
description: "Intent-based session opener. Bare `/super-bootstrap:todo` renders the full board (every open spec/plan/backlog row + next roadmap pickup). Sub-verbs filter by intent + environment: `/super-bootstrap:todo discuss` (decisions, spec approvals), `/super-bootstrap:todo cloud` (cloud-safe queue), `/super-bootstrap:todo device` (UI/e2e/manual). Scans docs/superpowers/specs|plans + docs/backlog.md + docs/overview.md § Roadmap. Bundled with super-bootstrap — works in any repo with the superpowers pipeline."
tags: [todo, scan, status, pipeline, superpowers]
---

# Todo — Intent-Filtered Pipeline Scanner

Default render is the full board (every open spec/plan/backlog row + next roadmap pickup). Sub-verbs let the user slice by mental mode (deciding / on cloud Claude / on device Claude) when the board gets big enough to warrant it. State reconstructed from `docs/superpowers/specs/*.md`, `docs/superpowers/plans/*.md`, `docs/backlog.md`, and `docs/overview.md` § Roadmap. Pipeline state = file presence (spec/plan/code presence drives "started" classification; roadmap entries without matching specs are "unstarted").

Bundled with `/super-bootstrap`. The harness CLAUDE.md and bootstrap plan tell future sessions to "Run `/super-bootstrap:todo`" — this is that command.

## Why default-full, sub-verbs opt-in

Newcomers don't know the intent taxonomy (Discuss / Cloud / Device). A gate that forces the choice upfront is noise — especially on greenfield repos where bootstrap leaves an empty backlog and the only signal is the next roadmap pickup (or an empty board pointing at `/brainstorm`). Render the full board by default; surface a self-teaching footer once the board grows enough to make filtering useful. Power users keep direct sub-verb access.

## Arguments

| Invocation        | Behavior                                                                                                                                                                                                |
| ----------------- | ------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| `/super-bootstrap:todo`        | **Default.** Render the full board immediately. No gate, no picker. Footer logic adapts to total row count (see §Footer rule).                                                                            |
| `/super-bootstrap:todo discuss`| Decision shape — specs awaiting user approval, brainstorming-style specs needing dialogue, backlog items flagged for user decision, any row whose blocker is "user". **Macro header on top.**          |
| `/super-bootstrap:todo cloud`  | Cloud-safe filter — plan-writes for approved specs, executing plans on pure-logic surfaces, review-stage reads, doc cleanup, backlog triage. **Macro header on top.**                                  |
| `/super-bootstrap:todo device` | Device-only filter — executing plans on UI / e2e / manual surfaces, manual verification of review-stage plans. **Macro header on top.**                                                                |

**Macro header** (sub-verb modes only): single line right under title showing cross-mode counts — `Macro: Discuss {D} · Cloud {C} · Device {V} · Full {T}`. Free (agent classified all rows pre-filter), ignore-or-pickup. Counts only — no IDs, no recommendations.

**Empty-state expanded priors** (sub-verb modes): when current mode has zero rows, agent surfaces top 1-3 IDs from each non-empty other mode. Closes with `Next mode: yours.` — no recommendation. Lets user navigate from empty without blind retype.

## Dispatch behavior

On bare `/super-bootstrap:todo`:

1. Quick-glob `docs/superpowers/specs/*.md`, `docs/superpowers/plans/*.md`, `docs/backlog.md`. Also quick-read `docs/overview.md` for a `## Roadmap` section with at least one bullet entry. If ALL sources are empty/absent (no specs, no plans, no open backlog rows, no roadmap entries), print directly without dispatching:
   > "No active work. Start something with `/brainstorm` or give me a task."
2. Otherwise dispatch the `todo` subagent with `mode: full`. No picker, no questions.
3. Relay the agent's rendered output verbatim. No editorial, no preface.

On sub-verb invocation (`/super-bootstrap:todo cloud` etc.): dispatch immediately with that mode.

## Footer rule

The agent computes total open row count `T = D + C + V` during §1 classification. Footer rendered in the Full scaffold depends on `T`:

- `T ≤ 5` → footer is just `more: /super-bootstrap:help`. Board small; sub-verb learning is premature noise.
- `T ≥ 6` → prepend a filter line above `more: /super-bootstrap:help`:
  ```
  filter: /super-bootstrap:todo cloud (headless) · /super-bootstrap:todo device (needs screen) · /super-bootstrap:todo discuss (decisions)
  more: /super-bootstrap:help
  ```

Sub-verb modes (`/super-bootstrap:todo cloud|device|discuss`) always use plain `more: /super-bootstrap:help` — the user already proved they know the taxonomy by typing the sub-verb.

The filter footer is self-teaching: each sub-verb is annotated with its meaning inline, so newcomers grok modes without reading SKILL.md. Progressive disclosure — surface taxonomy only when the board is big enough to benefit from slicing.

## Execution

The full protocol lives in the `todo` agent (`agents/todo.md`, `model: sonnet`, read-only tools).

When dispatching the agent, the prompt **must embed the literal scaffold** for the chosen mode (see §Scaffolds). Agent fills bracketed slots, cannot reach for alternative templates. Without the embedded scaffold, prior model training pulls render toward generic shapes regardless of mode. Literal injection bypasses model judgment at the render step.

**Dispatch prompt template:**

```
mode: {discuss | cloud | device | full}

Render EXACTLY this scaffold. Fill bracketed slots from your gathered + filtered + ranked rows per agent protocol. Do NOT change shape, do NOT swap to an alternative template, do NOT merge or split groups the scaffold separates. Omit a group's table only if its row count is zero (omit the sub-heading too).

---

{scaffold for chosen mode, copied verbatim from §Scaffolds below}

---

{any user-supplied filter or context appended unchanged}
```

Steps:

1. Pick scaffold for the chosen mode from §Scaffolds.
2. Build dispatch prompt per template above.
3. `Agent` tool, `subagent_type: "todo"`, prompt = the built dispatch prompt.
4. Agent returns rendered scaffold (or empty-state). **Relay verbatim.**

## Skip dispatch if

- User explicitly asks to run inline.
- Quick-gate sources all empty: zero spec/plan files AND zero open backlog rows AND zero overview § Roadmap entries (no point spawning).

## Cloud-safe criterion (single positive rule)

Used by `mode: cloud` to filter rows. Documented here so callers know what gets included.

> **Cloud-safe = phase produces a verifiable artifact via tooling alone. No human visual judgment, no real browser/device interaction, no "looks right" call.**

Pass (cloud-runnable):

- Plan write (write a plan for an approved spec)
- Spec author / refine (doc edit)
- Executing plan on pure-logic paths under unit coverage
- Review-stage read (diff inspection)
- Backlog triage (investigate-only)
- Doc cleanup (deleting merged spec+plan files)
- Refactor under unit coverage
- Lint / typecheck / format fix

Fail (device-only):

- Executing plan touching UI surfaces (components, pages, app routes) that require visual judgment
- E2E real run (needs browser + dev server)
- Manual smoke test
- Mobile install / device test
- Review-stage verification when plan's success criteria include manual checks

Derivation inputs (agent reads): plan file content (paths mentioned, "manual test" / "e2e" / "playwright" / "cypress" / "visual" keywords), spec §Success Criteria if present, file paths the plan tasks touch.

## Impact tag

Single tag per row, drives within-mode ranking (impactful rows surface first).

- **`impactful`** — feature-shaped: `Approve spec` / `Write plan` / `Continue brainstorm` / `Brainstorm` (overview § Roadmap pickup) on feature scope; `Continue execute` with ≥3 remaining checkboxes OR cross-pkg/repo blast; backlog item with severity signal (`critical` / `blocking` / production-down keywords).
- **`quick-pop`** — atomic: `Cleanup` (delete merged spec+plan), `Triage` (single backlog item), `Review` of plan with ≤2 total tasks, `Doc-align` / single-file `Doc-edit`.

Default if ambiguous: `quick-pop`. Better to under-rank than bloat impactful and defeat the cognitive-load reduction.

## Blast tag

Single tag per row, scope-axis hint.

- **`local`** — single file or single module.
- **`pkg`** — within one workspace package.
- **`cross-pkg`** — ≥2 packages.
- **`repo`** — orchestration / `.claude/` / `CLAUDE.md` / `docs/` sweeping.

Discuss-mode rows have no Blast column (decisions don't have blast radius until they become plans). N/A for pure-decision rows; agent omits Blast there.

## Scaffolds

Date placeholder `{date}` = today's date in YYYY-MM-DD form. Agent fills it.

**Macro header** (sub-verb modes only — discuss / cloud / device): single line right under title showing cross-mode counts. Always emit even when current mode is non-empty (free — agent classified all rows pre-filter). Format:

```
Macro: Discuss {D} · Cloud {C} · Device {V} · Full {T}
```

Counts only — no IDs, no impact tags. Decision-is-yours; surface priors not calls. Full mode skips this header (full body IS the macro).

### Discuss

```
# To-Do (Discuss) — {date}

Macro: Discuss {D} · Cloud {C} · Device {V} · Full {T}

| #  | Action                                              | Impact       | Context                                              |
| -- | --------------------------------------------------- | ------------ | ---------------------------------------------------- |
| 1  | {action — one sentence}                             | {tag}        | {one-line — why open, what unblocks}                 |

## Uncategorized

| #  | Action                                              | Why ambiguous                                    |
| -- | --------------------------------------------------- | ------------------------------------------------ |
| 1  | {verb + what}                                       | {one-line — what signal was missing}             |

more: /super-bootstrap:help
```

Empty state:

```
# To-Do (Discuss) — {date}

Macro: Discuss 0 · Cloud {C} · Device {V} · Full {T}

Nothing to decide.

Macro priors (no recommendation):
- Cloud: {top 1-3 with file + one-line reason}
- Device: {top 1-3 with file + one-line reason, or "0"}

Next mode: yours. /super-bootstrap:todo cloud · /super-bootstrap:todo device · /super-bootstrap:todo (full board)

more: /super-bootstrap:help
```

### Cloud

```
# To-Do (Cloud) — {date}

Macro: Discuss {D} · Cloud {C} · Device {V} · Full {T}

| #  | Action                                              | Progress | Impact       | Blast       |
| -- | --------------------------------------------------- | -------- | ------------ | ----------- |
| 1  | {verb + what + one-line reason}                     | {x/y|—}  | {tag}        | {tag}       |

## Uncategorized

| #  | Action                                              | Why ambiguous                                    |
| -- | --------------------------------------------------- | ------------------------------------------------ |
| 1  | {verb + what}                                       | {one-line — what signal was missing}             |

more: /super-bootstrap:help
```

Empty state:

```
# To-Do (Cloud) — {date}

Macro: Discuss {D} · Cloud 0 · Device {V} · Full {T}

Nothing cloud-runnable.

Macro priors (no recommendation):
- Discuss: {top 1-3 with file + one-line reason}
- Device: {top 1-3 with file + one-line reason}

Next mode: yours. /super-bootstrap:todo discuss · /super-bootstrap:todo device · /super-bootstrap:todo (full board)

more: /super-bootstrap:help
```

### Device

```
# To-Do (Device) — {date}

Macro: Discuss {D} · Cloud {C} · Device {V} · Full {T}

| #  | Action                                              | Progress | Impact       | Blast       |
| -- | --------------------------------------------------- | -------- | ------------ | ----------- |
| 1  | {verb + what + one-line reason}                     | {x/y|—}  | {tag}        | {tag}       |

## Uncategorized

| #  | Action                                              | Why ambiguous                                    |
| -- | --------------------------------------------------- | ------------------------------------------------ |
| 1  | {verb + what}                                       | {one-line — what signal was missing}             |

more: /super-bootstrap:help
```

Empty state:

```
# To-Do (Device) — {date}

Macro: Discuss {D} · Cloud {C} · Device 0 · Full {T}

Nothing device-only.

Macro priors (no recommendation):
- Cloud: {top 1-3 with file + one-line reason}
- Discuss: {top 1-3 with file + one-line reason}

Next mode: yours. /super-bootstrap:todo cloud · /super-bootstrap:todo discuss · /super-bootstrap:todo (full board)

more: /super-bootstrap:help
```

### Full

```
# To-Do — {date}

| File                                  | Stage         | Progress | Blocker          | Impact       | Blast       |
| ------------------------------------- | ------------- | -------- | ---------------- | ------------ | ----------- |
| specs/{date}-{slug}.md                | {stage}       | {x/y|—}  | {none|user|...}  | {tag}        | {tag}       |
| plans/{date}-{slug}.md                | {stage}       | {x/y|—}  | {none|user|...}  | {tag}        | {tag}       |

{Backlog: N BUG, M DEBT, K GAP open (see docs/backlog.md) — only if backlog.md exists}
{Roadmap: U unstarted of T (see docs/overview.md § Roadmap) — only if overview.md § Roadmap has entries}

## Uncategorized

| #  | File                                                | Why ambiguous                                    |
| -- | --------------------------------------------------- | ------------------------------------------------ |
| 1  | {file}                                              | {one-line}                                       |

{footer per §Footer rule}
```

No macro header for Full — full IS the macro. No "Next up" recommendation block in any mode (solo-dev momentum-driven; user picks from list, system doesn't strategize).

Footer is conditional on total open row count `T`:
- `T ≤ 5` → `more: /super-bootstrap:help`
- `T ≥ 6` → filter line + `more: /super-bootstrap:help` (see §Footer rule)

Empty state for Full: `No active work. Start something with /brainstorm or give me a task.`

## Why dispatched (Sonnet)

Multi-file scan + classification + ranking + scaffold-fill. Sonnet sweet spot — Opus overkill, Haiku weaker on "which intent does this row belong to" judgment. No iterative back-and-forth: single round-trip, agent returns rendered scaffold, gateway relays verbatim.

## Rules

- **Read-only.** Never modifies files. Never executes git operations.
- **Works in any repo** — only requires `docs/superpowers/` to exist (created by `/super-bootstrap:harness-bootstrap`).
- **Verbatim relay rule.** Agent's output IS the value. Gateway adds nothing — no preface, no editorial.
- **Footer-hint convention.** Sub-verb modes always end with `more: /super-bootstrap:help`. Full mode footer is conditional on total row count `T` (see §Footer rule): plain `more: /super-bootstrap:help` when `T ≤ 5`, filter line + `more: /super-bootstrap:help` when `T ≥ 6`.
