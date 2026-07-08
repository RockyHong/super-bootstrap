# Design — `/super-bootstrap:todo` need-me board

**Date:** 2026-07-08
**Status:** approved design → writing-plans
**Reopens:** `docs/decisions.md` line 28 (ChewLingo macro-picker port — closed with reopen condition, now met)

## Problem

`/super-bootstrap:todo` is a **momentum-driven** surface, not a kanban. Its job is to
point at the highest-leverage work that **needs the human**, not to inventory every
open row. On a large (ChewLingo-scale) board, bare `/todo` renders a wall — because
the default `full` mode lists **every** open row as a card, and in momentum-driven
dev the autonomously-drainable rows (raw/spec/plan headless work) are the **majority**.
The wall is the drainable majority attaching as cards.

The exact fix the user first reached for — port ChewLingo's two-turn AskUserQuestion
macro-picker — was evaluated and closed in `docs/decisions.md` line 28 for inserting a
**mandatory stop** against the harness "state, don't gate" rule. That decision left an
explicit reopen condition: *"Reopen if the full board routinely outgrows one screen."*
ChewLingo meets it. This spec is the reopen answer — it dissolves the wall **without**
the mandatory stop.

## Intent (the reframe that drives the design)

- **Momentum, not kanban.** Surface leverage, not a complete navigable list.
- **Leverage = unblocked ∧ impactful ∧ high downstream fan-out.** The human clears the
  need-me bottleneck by day; `drain` flows the released downstream by night. Doing the
  highest-fan-out need-me card maximizes what `drain` can chew.
- **todo never focuses on auto-runnable content** — it needs only the *count* of how
  many downstream can drain. Auto rows are `drain`'s concern, not the board's.
- **need-me has natural categories** (venue-keyed). Not all need-me cards unblock
  downstream, but all need attention.

## Design — five pillars

### 1. Drainable → a count, not cards

Autonomously-drainable rows (venue **T** + **S**; ≈ `intent: Cloud` in fallback) collapse
to one line at the top of the board:

```
Drainable: 12  →  /super-bootstrap:drain
```

The board does **not** list these as cards. Collapsing the drainable majority removes
the bulk of the wall by construction, and what remains is exactly need-me.

### 2. Default board = need-me, grouped by venue category

Bare `/super-bootstrap:todo` renders the **need-me board**: rows that need the human,
grouped by their run-location wall. Categories come from the venue map when wired:

| Group | Venue source | Meaning |
|---|---|---|
| **Decide / approve** | venue **U**, no device modality | pure decision / approval — user eyes wall the phase |
| **Device-bound** | venue **U** reached *via* a device modality (visual-taste acceptance / `Test-feel: manual`) | needs a physical screen / manual interaction |
| **Harness** | `intent: Harness` (always drain-excluded) | orchestration engine — careful handle |
| **Probe / grant** | venue **P** | LLM-eval / stochastic / cost-sensitive — needs a human grant |

Both **Decide/approve** and **Device-bound** are venue **U** — the split is the
*modality* that produced the wall: a device/manual signal on the row routes it to
Device-bound, otherwise it is a pure Decide/approve. The `todo` agent reads the modality
from the row's fields (the same signals the venue map's § Modality overrides consume),
never by keyword-guessing the action text.

**Graceful degrade (no scale module).** When `.claude/rules/venue-map.md` is absent,
degrade to the existing intent axis — same file-presence branch `drain` already uses
(`skills/drain/assets/eligibility.md`): `Cloud` → the drainable count; `Discuss` /
`Device` / `Harness` → the need-me groups. Consumer with only the installed plugin gets
exactly this fallback; consumer with the scale module gets the venue-keyed grouping.
The shipped scaffold stays self-contained (repo-boundary: downstream ≠ author).

### 3. Fan-out column — `unblocks N`

Every need-me card renders a **fan-out** signal: how many open downstream rows it
releases when done. This is the reverse of the §4 coupling gate the `todo` agent already
computes:

- The coupling gate traces per-row edges today (**hard block** = explicit naming;
  **soft coupling** = shared artifact / convention) but only *consumes* them to hold
  blocked rows out of the body and lift an upstream row's Impact.
- **fan-out(card) = count of other open rows that name this card as a blocker OR are
  soft-shaped by it** (reverse in-edges). `0` is valid and rendered — not every need-me
  card unblocks downstream, but it still needs attention.

Fan-out is a **computed** leverage signal, not an opinion. It becomes the **primary
ranking key** within each need-me group (fan-out desc), ahead of the existing Impact /
Progress / action-verb keys.

### 4. Flat escape retained

- `/super-bootstrap:todo full` = the flat, ungrouped list of **everything** (need-me +
  drainable), ranked — the "非類清單" escape hatch.
- `## Uncategorized` orphan bucket retained (truly ambiguous rows surface, never hide).
- Sub-verbs (`discuss` / `cloud` / `device` / `harness`) still drill one slice;
  `/super-bootstrap:todo cloud` expands the drainable count into its cards when wanted.

### 5. Skip-gate → glob-only; subagent owns all doc reads

The original rule-pollution the user observed (gateway loading `venue-map` /
`dimension-discipline` / `ssot-doc-link` on `/todo`) traces to the **skip-gate reading
`docs/backlog.md` content** on the gateway — detecting "row content under `## Open`"
requires a content read, not a glob, and that read fires the `docs/**` path-scoped rules
in the gateway's context.

Fix: the gateway does **existence-only Glob**, never a content read.

- Glob `docs/superpowers/` presence (lists paths, loads no content, fires no rule):
  - **absent** → gateway prints `"No runway installed. Run /super-bootstrap"`, no dispatch.
  - **present** → **dispatch the `todo` subagent unconditionally**.
- The **empty/non-empty determination moves into the subagent** — it reads the three
  sources, and renders either the empty-state message or the need-me board.

Cost: a bootstrapped-but-empty board dispatches once to get "No active work" (rare —
the existence Glob already catches the no-runway case; a genuinely empty `## Open` on a
bootstrapped repo is the only extra dispatch, and it is cheap). Benefit: the gateway
context **never** touches `docs/**` path-rules.

**Gateway holds/prints:** verbatim relay, unchanged. The subagent reads + classifies +
renders the need-me layout; the gateway relays it. The board content lives in the
gateway's context as the subagent's *returned text* (path-rules fire on `Read` of a
matching file, not on reading a subagent's reply) — so "do the first one" has its data,
with no rule pollution. One shared classification (`shared/classify-actionable.md`)
feeds both `todo` (render) and `drain` (execute).

## What this revises

- **`docs/decisions.md` line 28** — rewrite from "closed — sb renders the full board" to
  "**reopen executed** — bare `/todo` renders the need-me board (drainable→count,
  venue-grouped, fan-out), not the picker." Record that the reopen answer keeps the
  no-mandatory-stop property that sank the original port.
- **`scaffolds.md` "No 'Next up' recommendation block" note** — refine, don't remove:
  foregrounding by **computed** leverage (group + fan-out rank) is surfacing, not
  strategizing. The bar still stands on **opinion prose** ("Best next: Y") — none is added.

## Files touched (closure)

| File | Change |
|---|---|
| `plugins/super-bootstrap/agents/todo.md` | render refactor: need-me default, drainable→count, fan-out compute + rank, venue-map consumption + degrade |
| `plugins/super-bootstrap/skills/todo/assets/scaffolds.md` | new default need-me scaffold + fan-out column; `full` scaffold stays as flat escape; refine the "no Next up" note |
| `plugins/super-bootstrap/skills/todo/SKILL.md` | new default behavior, skip-gate → glob-only, dispatch-unconditional, `/todo full` escape doc |
| `plugins/super-bootstrap/shared/classify-actionable.md` | fan-out (reverse-edge count) derivation added to the shared classification |
| `plugins/super-bootstrap/skills/harness-bootstrap/assets/scale/rules-venue-map-skeleton.md` | clarify the `/todo` consumer face (need-me grouping the map serves) |
| `docs/decisions.md` | line 28 → reopen executed |
| `CLAUDE.md` § Rules | mirror only if an active-rule summary changes (venue-map is scale-module skeleton here — likely no change) |

## Verification

Behavior-shaping skill/agent prose → `superpowers:writing-skills` RED per the
`skill-authoring` rule. Micro-test the render against a synthetic board (drainable +
need-me + fan-out edges + an orphan) and confirm:

1. Drainable rows collapse to the count line; none appear as cards.
2. Need-me rows group by venue category; each carries `unblocks N` (including `0`).
3. Ranking within a group is fan-out desc, then the existing keys.
4. Absent `venue-map.md`, the board degrades to the intent axis with identical shape.
5. Empty `## Open` yields the empty-state **from the subagent** (gateway did no content read).
6. `/todo full` renders the flat ungrouped everything-list.

`audit-harness-edits` on the diff post-implementation (harness centrality earns it).

## Out of scope

- `drain` eligibility — already consumes the venue map; unchanged.
- Size-threshold / category-dashboard navigation — superseded; the need-me board is
  naturally small because the drainable majority is a count.
- The MCQ macro-picker — stays rejected; this reopen answers the condition without it.
- Wiring `venue-map.md` into any specific consumer repo — a consumer concern; here we
  ship the skill that consumes it when present and degrades when not.
