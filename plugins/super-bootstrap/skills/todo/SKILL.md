---
name: todo
description: "Intent-based session opener. Bare `/super-bootstrap:todo` renders the need-me board — drainable work collapses to a count, need-me work groups by venue category with a downstream fan-out signal (no MCQ, rendered immediately by a bundled zero-dispatch script; the todo agent dispatches only as the script-failure fallback). Sub-verbs slice explicitly: `/super-bootstrap:todo discuss` (decisions, design approvals), `/super-bootstrap:todo cloud` (drainable detail), `/super-bootstrap:todo device` (UI/e2e/manual), `/super-bootstrap:todo harness` (orchestration-engine rows, careful handle), `/super-bootstrap:todo full` (flat everything). Scans open cards in docs/work/, plus docs/test-queue.md and docs/outward.md when present. Bundled with super-bootstrap — works in any repo with the development pipeline."
tags: [todo, scan, status, pipeline]
---

# Todo — Intent-Filtered Pipeline Scanner

Default render is the **need-me board** — momentum-driven, not a kanban: autonomously-drainable work collapses to one count line, and work that needs the human groups by venue category (decide / outward / device-bound / harness / probe) with a `unblocks N` fan-out signal. Bare invoke renders it immediately — no MCQ, no picker (a rendered surface the user navigates by typing a sub-verb, not a modal stop). Sub-verbs slice explicitly (deciding / drainable detail / on device Claude / touching the engine / flat everything). State reconstructed from open cards in `docs/work/` (glob: `{BUG|DEBT|GAP}-###.md`), plus `docs/test-queue.md` and `docs/outward.md` when present (the scale module's test queue and outward file). Pipeline state = card thread state (block presence drives stage classification).

Two render lanes, one classification SSOT (`shared/classify-actionable.md`): the **script lane** (primary) runs the bundled `assets/render-board.py` — a mechanical encoding of the spec, zero model tokens, sub-second — and the **dispatch lane** (fallback) runs the `todo` agent when the script fails.

## Arguments

| Invocation        | Behavior                                                                                                                                                                                                |
| ----------------- | ------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| `/super-bootstrap:todo`        | **Default.** Render the **need-me board** (drainable→count, need-me grouped by venue category with fan-out). No mode-picker, no MCQ — dispatch immediately.                                            |
| `/super-bootstrap:todo full`   | Flat escape — every row (need-me + drainable), ungrouped, ranked.                                                                                                                    |
| `/super-bootstrap:todo discuss`| Decision shape — designs awaiting approval, surface verdicts awaiting user decision, cards flagged for user decision, any row whose blocker is "user". **Macro header on top.**          |
| `/super-bootstrap:todo cloud`  | Cloud-safe filter — plan-writes for approved designs, executing plans on pure-logic surfaces, review-stage reads, doc cleanup, card triage. **Macro header on top.**                                  |
| `/super-bootstrap:todo device` | Device-only filter — executing plans on UI / visual-e2e / manual surfaces, manual verification of review-stage plans. **Macro header on top.**                                                                |
| `/super-bootstrap:todo harness`| Harness filter — rows whose deliverable is the orchestration engine (`CLAUDE.md`, `.claude/**`, plugin-source harness files), grouped **Deliberate** (new doctrine) / **Apply** (existing doctrine, bounded site). Never mixed into the autonomous slices. **Macro header on top.**                                          |
| *any other value*             | **Fallback.** Dispatch `mode: needme` (the default board), and print this line above the relayed board: `Unrecognized sub-verb '{value}' — rendering the default board. Modes: full · discuss · cloud · device · harness.` Never map an unlisted value onto a listed mode by semantic proximity — this table is the whole set. |

**Macro header** (sub-verb modes only): single line right under title showing cross-mode counts — `Macro: Discuss {D} · Cloud {C} · Device {V} · Harness {H} · Full {T}`. Free (agent classified every row before filtering), ignore-or-pickup. Body rows only — each count matches the rows that mode's board renders; hard-blocked rows ride the footer `pending unblock` count. Counts only — no IDs, no recommendations.

**Empty-state expanded priors** (sub-verb modes): when current mode has zero rows, agent surfaces top 1-3 IDs from each non-empty other mode. Closes with `Next mode: yours.` — no recommendation. Lets user navigate from empty without blind retype.

## Render behavior

**Canonical skip-gate (existence-only — the gateway never content-reads `docs/**`).**
The gateway decides from **directory presence alone** (Glob lists paths,
loads no file content, fires no `docs/**` path-scoped rule):

- **`docs/work/` absent** (Glob returns nothing) → repo has the pipeline
  available but no runway installed. Print, no render:
  > "No runway installed. Run `/super-bootstrap` to set up the pipeline."
- **`docs/work/` present** → render via the script lane; its exit code routes
  the fallback. The empty/non-empty determination lives in the executor: it
  reads the card files and renders either the empty-state (`No active work…`)
  or the board.

The gateway performs **no content read** of cards or the test queue — all
`docs/**` reads happen inside the script or the subagent (script stdout is a
tool result, not a file read, so no `docs/**` path-rule loads in the gateway's
context).

**Script lane (primary).** Resolve the mode by Arguments-table lookup (no
argument → `needme`; no matching row → print the fallback notice, mode
`needme`), then run:

`python3 "${CLAUDE_PLUGIN_ROOT}/skills/todo/assets/render-board.py" "$(pwd)" {mode}`

(The script body is opaque to the permission engine — the grant to carve is the
invocation itself, e.g. `Bash(python3 *)`.)

- **Exit 0** → spot-check first: one rendered row against the doc it cites; a
  confirmed miss → `/super-bootstrap:log` (a renderer defect against the spec).
  Then relay stdout verbatim as the turn's closing message — no editorial, no
  preface. Done — no dispatch.
- **Failure** (`python3` missing, non-zero exit, empty stdout) → dispatch lane.

The script renders in both wiring states. With the scale module's
`.claude/rules/venue-map.md` in place it partitions the need-me board by venue,
off a built-in encoding of the shipped map (`agents/todo.md` § Lane split, wired
arm); without it, by the intent axis. A placed map whose tables differ from that
encoding renders the same board plus one `# note:` line on stderr — the
diagnostic that local map edits do not reach the script lane. A `docs/test-queue.md`
whose `## Pending` holds content but no `### ` entry draws another
`# note:` line, pointing at that file's § Entry shape.

**Dispatch lane (fallback).** Dispatch the `todo` subagent with the resolved
mode per §Execution — the pre-script path, unchanged. Relay the agent's
rendered output verbatim.

Resolve modes by table lookup only — an unlisted value is unlisted, not a
near-match. `full` renders the flat-escape board: every open row from every
source (cards, test queue, outward file) in one ranked table, ungrouped, nothing collapsed
to a count.

## Footer rule

Footer is computed by the rendering executor (script or agent) — it counts total open rows `T` during classification and picks the footer shape. Canonical logic: `agents/todo.md` § Render footer-hint; the script encodes the same logic. The gateway relays the rendered output verbatim — it does not compute the footer.

## Execution — dispatch lane

The fallback protocol lives in the `todo` agent (`agents/todo.md`, `model: sonnet`, read-only tools). It runs only when §Render behavior routes here (script failure).

When dispatching the agent, the prompt **must embed the scaffold** literal for the chosen mode, and supply the **classification spec path** for the agent to self-read. Agent fills bracketed slots per spec; cannot reach for alternative templates or paraphrase the criteria. Without the scaffold literal, prior training pulls render toward generic shapes. Without the explicit path + "classify EXACTLY" instruction, training pulls classification toward generic criteria.

**Dispatch prompt template:**

```
mode: {needme | discuss | cloud | device | harness | full}

Classify every open item per this spec, then render EXACTLY the scaffold below. Fill bracketed slots from your gathered + filtered + ranked rows per agent protocol. Do NOT change shape, do NOT swap to an alternative template, do NOT merge or split groups the scaffold separates. Omit a group's table only if its row count is zero (omit the sub-heading too).

--- CLASSIFICATION SPEC (Read this FIRST) ---

Before classifying, use the Read tool on this exact path: {classify_spec_path}. It is the classification SSOT. Classify EXACTLY per it — do not paraphrase, do not substitute your own criteria.

--- SCAFFOLD ---

{scaffold for chosen mode from assets/scaffolds.md, copied verbatim}

---

{any user-supplied filter or context appended unchanged}

--- REPLY SHAPE ---

Your reply is one part — the scaffold above with its slots filled. It opens with the title line and closes with the footer line (§ Output contract).
```

Steps:

1. Reached from §Render behavior with the mode already resolved (skip-gate passed, script lane failed).
2. Resolve the classification spec path: take the skill base directory (surfaced in the skill invocation as `Base directory for this skill: <abs path>`), append `../../shared/classify-actionable.md`. Read `assets/scaffolds.md` (sibling) and embed the chosen-mode section verbatim in the dispatch prompt. Pass the resolved absolute path as `{classify_spec_path}` — never the file contents. Ranking + render live in the `todo` agent.
3. Build dispatch prompt per template above.
4. `Agent` tool, `subagent_type: "todo"`, prompt = the built dispatch prompt.
5. Agent returns rendered scaffold (or empty-state). **Spot-check first:** sample one classified row from the reply against the doc it cites; a confirmed miss → `/super-bootstrap:log` (tier re-pinning evidence). The script lane carries its own spot-check under §Render behavior's Exit 0 clause.
6. **Relay verbatim** as the turn's closing message.

## Rules

- **Read-only.** Never modifies files. Never executes git operations.
- **Works in any repo** — `docs/work/` present (created by `/super-bootstrap:harness-bootstrap`) drives the board; absent → the skip-gate redirects to `/super-bootstrap`.
- **Verbatim relay rule.** The executor's rendered output IS the value — script stdout and agent reply alike. Gateway adds nothing — no preface, no editorial. Sole exceptions, each printed above the board as its own line, never woven into the render: the §Arguments fallback notice, and the script's `# note:` stderr line(s) when present (§Render behavior). The board closes the turn: every tool call the skill makes (the spot-check included) lands before it, so the rendered surface is the last thing on screen.
- **Footer-hint convention.** Footer is the executor's render concern (see §Footer rule). Gateway relays verbatim.
- **One classification SSOT.** `shared/classify-actionable.md` + `assets/scaffolds.md` bind both lanes; the script encodes them, the agent self-reads them. An edit to either propagates to the script (bench check: `bench/todo-board/` in the source repo) and never forks a lane-local criterion.
