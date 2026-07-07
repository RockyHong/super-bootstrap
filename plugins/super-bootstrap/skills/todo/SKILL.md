---
name: todo
description: "Intent-based session opener. Bare `/super-bootstrap:todo` renders the full board (every open spec/plan/backlog row). Sub-verbs filter by intent + environment: `/super-bootstrap:todo discuss` (decisions, spec approvals), `/super-bootstrap:todo cloud` (cloud-safe queue), `/super-bootstrap:todo device` (UI/e2e/manual). Scans docs/superpowers/specs|plans + docs/backlog.md. Bundled with super-bootstrap — works in any repo with the superpowers pipeline."
tags: [todo, scan, status, pipeline, superpowers]
---

# Todo — Intent-Filtered Pipeline Scanner

Default render is the full board (every open spec/plan/backlog row). Sub-verbs let the user slice by mental mode (deciding / on cloud Claude / on device Claude) when the board gets big enough to warrant it. State reconstructed from `docs/superpowers/specs/*.md`, `docs/superpowers/plans/*.md`, and `docs/backlog.md`. Pipeline state = file presence (spec/plan/code presence drives stage classification).

## Arguments

| Invocation        | Behavior                                                                                                                                                                                                |
| ----------------- | ------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| `/super-bootstrap:todo`        | **Default.** Render the full board immediately. No mode-picker. Footer logic adapts to total row count (see §Footer rule).                                                                            |
| `/super-bootstrap:todo discuss`| Decision shape — specs awaiting user approval, brainstorming-style specs needing dialogue, backlog items flagged for user decision, any row whose blocker is "user". **Macro header on top.**          |
| `/super-bootstrap:todo cloud`  | Cloud-safe filter — plan-writes for approved specs, executing plans on pure-logic surfaces, review-stage reads, doc cleanup, backlog triage. **Macro header on top.**                                  |
| `/super-bootstrap:todo device` | Device-only filter — executing plans on UI / e2e / manual surfaces, manual verification of review-stage plans. **Macro header on top.**                                                                |

**Macro header** (sub-verb modes only): single line right under title showing cross-mode counts — `Macro: Discuss {D} · Cloud {C} · Device {V} · Full {T}`. Free (agent classified all rows pre-filter), ignore-or-pickup. Counts only — no IDs, no recommendations.

**Empty-state expanded priors** (sub-verb modes): when current mode has zero rows, agent surfaces top 1-3 IDs from each non-empty other mode. Closes with `Next mode: yours.` — no recommendation. Lets user navigate from empty without blind retype.

## Dispatch behavior

**Canonical skip-gate** — applies to bare invocation and every sub-verb. Skip dispatch (no file reads beyond the glob, no agent) when either:

- Quick-glob `docs/superpowers/specs/*.md`, `docs/superpowers/plans/*.md`, `docs/backlog.md` comes back all empty/absent (no specs, no plans, no open backlog rows — any row content under `## Open`, whether canonical `### {BUG|DEBT|GAP}-###` headings, foreign-prefix rows, or un-IDed bullets; the header's ID high-water-mark line doesn't count). Branch on whether `docs/superpowers/` exists, then print the matching message:
  - **`docs/superpowers/` absent** → repo has the super-bootstrap pipeline available but no runway installed:
    > "No runway installed here. Run `/super-bootstrap` to set up the pipeline."
  - **`docs/superpowers/` present, board empty** → bootstrapped, nothing open:
    > "No active work. Start something with `/brainstorm` or give me a task."
- User explicitly asks to run inline.

On bare `/super-bootstrap:todo`:

1. Run the skip-gate above.
2. Otherwise dispatch the `todo` subagent with `mode: full`. No picker, no questions.
3. Relay the agent's rendered output verbatim. No editorial, no preface.

On sub-verb invocation (`/super-bootstrap:todo cloud` etc.): run the skip-gate, then dispatch immediately with that mode.

## Footer rule

Footer is computed by the `todo` agent at render time — it counts total open rows `T` during classification and picks the footer shape. Canonical logic: `agents/todo.md` § Render footer-hint. The gateway relays the agent's output verbatim — it does not compute the footer.

## Execution

The full protocol lives in the `todo` agent (`agents/todo.md`, `model: sonnet`, read-only tools).

When dispatching the agent, the prompt **must embed two literals**: the **classification spec** (how to derive each item's `{action, intent, stage}`) and the **scaffold** for the chosen mode. Agent fills bracketed slots, cannot reach for alternative templates or paraphrase the criteria. Without the embedded literals, prior model training pulls classification + render toward generic shapes. Literal injection bypasses model judgment at both the classify and render steps.

**Dispatch prompt template:**

```
mode: {discuss | cloud | device | full}

Classify every open item per this spec, then render EXACTLY the scaffold below. Fill bracketed slots from your gathered + filtered + ranked rows per agent protocol. Do NOT change shape, do NOT swap to an alternative template, do NOT merge or split groups the scaffold separates. Omit a group's table only if its row count is zero (omit the sub-heading too).

--- CLASSIFICATION SPEC ---

{shared/classify-actionable.md, copied verbatim}

--- SCAFFOLD ---

{scaffold for chosen mode from assets/scaffolds.md, copied verbatim}

---

{any user-supplied filter or context appended unchanged}
```

Steps:

1. Run the skip-gate (§Dispatch behavior). Confirmed dispatch → continue to step 2.
2. Read `shared/classify-actionable.md` (plugin-shared, `../../shared/` from this SKILL.md — SSOT, also consumed by `/super-bootstrap:drain`) and `assets/scaffolds.md` (sibling), embed both verbatim in the dispatch prompt — the agent never fetches files outside the repo docs. Ranking + render live in the `todo` agent.
3. Build dispatch prompt per template above.
4. `Agent` tool, `subagent_type: "todo"`, prompt = the built dispatch prompt.
5. Agent returns rendered scaffold (or empty-state). **Relay verbatim.**
6. **Spot-check:** sample one classified row from the reply against the doc it cites; a confirmed miss → `/super-bootstrap:log` (tier re-pinning evidence).

## Rules

- **Read-only.** Never modifies files. Never executes git operations.
- **Works in any repo** — `docs/superpowers/` present (created by `/super-bootstrap:harness-bootstrap`) drives the board; absent → the skip-gate redirects to `/super-bootstrap`.
- **Verbatim relay rule.** Agent's output IS the value. Gateway adds nothing — no preface, no editorial.
- **Footer-hint convention.** Footer is the agent's render concern, computed per `agents/todo.md` § Render footer-hint (see §Footer rule). Gateway relays verbatim.
