---
name: todo
description: "Intent-based session opener. Bare `/super-bootstrap:todo` renders the need-me board — drainable work collapses to a count, need-me work groups by venue category with a downstream fan-out signal (no MCQ, dispatched immediately). Sub-verbs slice explicitly: `/super-bootstrap:todo discuss` (decisions, spec approvals), `/super-bootstrap:todo cloud` (drainable detail), `/super-bootstrap:todo device` (UI/e2e/manual), `/super-bootstrap:todo harness` (orchestration-engine rows, careful handle), `/super-bootstrap:todo full` (flat everything). Scans docs/superpowers/specs|plans + docs/backlog.md, plus docs/test-queue.md when present. Bundled with super-bootstrap — works in any repo with the superpowers pipeline."
tags: [todo, scan, status, pipeline, superpowers]
---

# Todo — Intent-Filtered Pipeline Scanner

Default render is the **need-me board** — momentum-driven, not a kanban: autonomously-drainable work collapses to one count line, and work that needs the human groups by venue category (decide / device-bound / harness / probe) with a `unblocks N` fan-out signal. Bare invoke dispatches it immediately — no MCQ, no picker (a rendered surface the user navigates by typing a sub-verb, not a modal stop). Sub-verbs slice explicitly (deciding / drainable detail / on device Claude / touching the engine / flat everything). State reconstructed from `docs/superpowers/specs/*.md`, `docs/superpowers/plans/*.md`, and `docs/backlog.md` (three core sources), plus `docs/test-queue.md` when present (the scale module's test queue). Pipeline state = file presence (spec/plan/code presence drives stage classification).

## Arguments

| Invocation        | Behavior                                                                                                                                                                                                |
| ----------------- | ------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| `/super-bootstrap:todo`        | **Default.** Render the **need-me board** (drainable→count, need-me grouped by venue category with fan-out). No mode-picker, no MCQ — dispatch immediately.                                            |
| `/super-bootstrap:todo full`   | Flat escape — every row (need-me + drainable), ungrouped, ranked.                                                                                                                    |
| `/super-bootstrap:todo discuss`| Decision shape — specs awaiting user approval, brainstorming-style specs needing dialogue, backlog items flagged for user decision, any row whose blocker is "user". **Macro header on top.**          |
| `/super-bootstrap:todo cloud`  | Cloud-safe filter — plan-writes for approved specs, executing plans on pure-logic surfaces, review-stage reads, doc cleanup, backlog triage. **Macro header on top.**                                  |
| `/super-bootstrap:todo device` | Device-only filter — executing plans on UI / e2e / manual surfaces, manual verification of review-stage plans. **Macro header on top.**                                                                |
| `/super-bootstrap:todo harness`| Harness filter — rows whose deliverable is the orchestration engine (`CLAUDE.md`, `.claude/**`, plugin-source harness files), grouped **Deliberate** (new doctrine) / **Apply** (existing doctrine, bounded site). Never mixed into the autonomous slices. **Macro header on top.**                                          |

**Macro header** (sub-verb modes only): single line right under title showing cross-mode counts — `Macro: Discuss {D} · Cloud {C} · Device {V} · Harness {H} · Full {T}`. Free (agent classified all rows pre-filter), ignore-or-pickup. Counts only — no IDs, no recommendations.

**Empty-state expanded priors** (sub-verb modes): when current mode has zero rows, agent surfaces top 1-3 IDs from each non-empty other mode. Closes with `Next mode: yours.` — no recommendation. Lets user navigate from empty without blind retype.

## Dispatch behavior

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
all `docs/**` reads happen inside the subagent (no `docs/**` path-rule loads in
the gateway's context).

On bare `/super-bootstrap:todo`:

1. Run the skip-gate above.
2. Otherwise dispatch the `todo` subagent with `mode: needme`. No picker, no questions.
3. Relay the agent's rendered output verbatim. No editorial, no preface.

`/super-bootstrap:todo full` dispatches `mode: full` — the flat-escape board (every row, need-me + drainable, ungrouped).

On sub-verb invocation (`/super-bootstrap:todo cloud` etc.): run the skip-gate, then dispatch immediately with that mode.

## Footer rule

Footer is computed by the `todo` agent at render time — it counts total open rows `T` during classification and picks the footer shape. Canonical logic: `agents/todo.md` § Render footer-hint. The gateway relays the agent's output verbatim — it does not compute the footer.

## Execution

The full protocol lives in the `todo` agent (`agents/todo.md`, `model: sonnet`, read-only tools).

When dispatching the agent, the prompt **must embed the scaffold** literal for the chosen mode, and supply the **classification spec path** for the agent to self-read. Agent fills bracketed slots per spec; cannot reach for alternative templates or paraphrase the criteria. Without the scaffold literal, prior training pulls render toward generic shapes. Without the explicit path + "classify EXACTLY" instruction, training pulls classification toward generic criteria.

**Dispatch prompt template:**

```
mode: {discuss | cloud | device | harness | full}

Classify every open item per this spec, then render EXACTLY the scaffold below. Fill bracketed slots from your gathered + filtered + ranked rows per agent protocol. Do NOT change shape, do NOT swap to an alternative template, do NOT merge or split groups the scaffold separates. Omit a group's table only if its row count is zero (omit the sub-heading too).

--- CLASSIFICATION SPEC (Read this FIRST) ---

Before classifying, use the Read tool on this exact path: {classify_spec_path}. It is the classification SSOT. Classify EXACTLY per it — do not paraphrase, do not substitute your own criteria.

--- SCAFFOLD ---

{scaffold for chosen mode from assets/scaffolds.md, copied verbatim}

---

{any user-supplied filter or context appended unchanged}
```

Steps:

1. Run the skip-gate (§Dispatch behavior). Confirmed dispatch → continue to step 2.
2. Resolve the classification spec path: take the skill base directory (surfaced in the skill invocation as `Base directory for this skill: <abs path>`), append `../../shared/classify-actionable.md`. Read `assets/scaffolds.md` (sibling) and embed the chosen-mode section verbatim in the dispatch prompt. Pass the resolved absolute path as `{classify_spec_path}` — never the file contents. Ranking + render live in the `todo` agent.
3. Build dispatch prompt per template above.
4. `Agent` tool, `subagent_type: "todo"`, prompt = the built dispatch prompt.
5. Agent returns rendered scaffold (or empty-state). **Relay verbatim.**
6. **Spot-check:** sample one classified row from the reply against the doc it cites; a confirmed miss → `/super-bootstrap:log` (tier re-pinning evidence).

## Rules

- **Read-only.** Never modifies files. Never executes git operations.
- **Works in any repo** — `docs/superpowers/` present (created by `/super-bootstrap:harness-bootstrap`) drives the board; absent → the skip-gate redirects to `/super-bootstrap`.
- **Verbatim relay rule.** Agent's output IS the value. Gateway adds nothing — no preface, no editorial.
- **Footer-hint convention.** Footer is the agent's render concern, computed per `agents/todo.md` § Render footer-hint (see §Footer rule). Gateway relays verbatim.
