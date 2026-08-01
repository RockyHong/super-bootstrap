# GAP-047 — Work-tracking substrate redesign (design spec)

> Temporal work order. Dies with this feature's merge — and it is the last tenant:
> the directory that holds it (`docs/work/specs/`) is retired by this very change.

## Problem

Three structural defects share one root: the single-file `docs/backlog.md` shape.

1. **No amendment path.** Rows are write-once with delete-on-resolve as the only
   sanctioned mutation; nobody is named who may amend a live row. Every surface
   needing a mid-life write routes to an actor that refuses it — three live
   refusal loops (DEBT-034, DEBT-036, BUG-022), closure mapped in
   `docs/work/triage/DEBT-034-notes.md`.
2. **Full-file coupling.** Every triage and board render re-reads the whole file
   regardless of working-set size (cost driver named by DEBT-022/027).
3. **Storage carries presentation.** "Newest at top" binds file ordering to board
   ordering — a separation-of-concerns violation; ordering is the todo agent's
   computed output, not the substrate's job.

Separately, `docs/work/specs/` + `docs/work/plans/` are ceremony distilled from
the superpowers workflow, not native to this pipeline's card-anchor model
("the card is the unit/anchor/boundary/SSOT of the change").

## Design

### Layout

```
docs/
  overview.md · techstack.md · decisions.md    ← durable (state / history)
  specs/                                        ← durable specs (unchanged)
  work/                                         ← work-unit workspace (all volatile)
    README.md         ← header: contract, categories, ID high-water line
    TEMPLATE.md       ← copy-to-create origin skeleton
    BUG-022.md · …    ← one card = one file = one thread, flat at work/ root
```

- **Path dimension = lifecycle.** `docs/` root + `docs/specs/` hold only durable
  files; everything under `docs/work/` dies with its work unit.
- Deleted: `docs/backlog.md`, `docs/work/triage/`, `docs/work/specs/`,
  `docs/work/plans/`. No satellites, no subdirectories — the card file is the
  entire work-volatile artifact.
- Card glob: `docs/work/{BUG,DEBT,GAP}-[0-9][0-9][0-9].md`. Everything else in
  `work/` is README/TEMPLATE.

### Card anatomy — append-only thread

```
# {BUG|DEBT|GAP}-### — {one-line summary}

**Logged:** {date} · **Source:** {where this surfaced}
**Problem:** {what's broken / rotting / missing}
**Area:** {files or module}
**Prior:** {one-line suspected cause — optional}

## Amendment — {date} · {source}
## Verdict — auto-fix|surface · {date}
## Design — {date}
## Plan — {date}
## Progress — {date}
```

- **Origin block** (H1 + field lines) — today's row shape verbatim, frozen at
  capture. Always the breadcrumb at the top of the thread. `Area:` field kept
  (drain relations and Blast derivation read it).
- **Five named block types**, all appended at end of file, dated + sourced:
  - **Amendment** — reframe, premise supersession, dup new fact, NEEDS_CONTEXT
    answer. Free content.
  - **Verdict** — triage output (was `{ID}-notes.md` / `{ID}-scope.md`); the
    auto-fix `## Files` section lives inside the block. Verdict kind
    (auto-fix / surface) is in the heading.
  - **Design** — cluster-2 settled design. Approval = one appended line.
  - **Plan** — cluster-3 step sequence. **Steps only — no checkboxes, no status
    marks.** Plan revision = append a new Plan block that takes over; the old one
    stays in the chain.
  - **Progress** — durable milestone / interruption state: which steps are done,
    where work stopped, watch-outs. The cross-session handoff surface.
- **Read contract:** top-to-bottom = the evolution path; the latest block leads
  current understanding; origin stays as grounding. Chain of path is complete —
  drift has nowhere to hide.
- **No editable zones.** 100% append-only, no exceptions.

### Write contract

- **Create** — `/super-bootstrap:log` funnel stays the default door (classify +
  dedup + ID). Copying `TEMPLATE.md` by hand is a sanctioned transcription path.
  Either way: ID = high-water max+1, README counter line bumped in the same
  change (collision-recovery mechanics unchanged).
- **Append** — open to any session or agent. End-of-file only, dated + sourced.
  Overwriting or editing existing content is forbidden everywhere. Mutation
  authority: **anyone may append, no one may overwrite.**
- **Resolve** — delete the one card file. Git history is the archive; the ID
  stays consumed forever (high-water line, never re-derived from live files).
- **Conflict** — on a git conflict in a card file: keep either side whole or
  regenerate the thread from its blocks; never hand-merge block content.

### Live tracking — division of labor

| Timescale | Home |
|---|---|
| In-session execution state | Claude Code native task list (platform-provided) |
| Cross-session durable progress | `## Progress` append on the card |
| Completed truth | git (resolve = delete) |

The Plan block carries only the durable step sequence. In-flight tick-tracking
never lands in repo files. **Self-containment:** this contract references only
the platform and this repo's own files — no device-level or author-personal
conventions.

### Board decoupling

Ordering is computed by the todo agent (rank keys), never stored. Recency comes
from the origin `Logged:` date and block dates. Row derivation collapses from
three sources (specs, plans, backlog) to one: thread state drives the action —
Design block unapproved → `Approve design`; Plan block with steps not yet
reported done (per latest Progress) → `Continue execute`; Verdict block present →
stage `triaged` (detection moves from "scope.md exists" to "Verdict block in
file", same read). Test queue (scale module) unchanged where present.

## What this resolves / what stays

**Resolved by this change** (rows deleted at landing):

- **DEBT-034** — supersession = Amendment block; the verdict's four options moot.
- **DEBT-036** — dup new facts append to the owning card.
- **BUG-022** — NEEDS_CONTEXT answers append to the card.
- **DEBT-030 (contract half)** — the funnel admits a transcription path
  (TEMPLATE copy); cost half stays carded.
- **GAP-047** itself, at full landing.

The refusal-loop clauses these cards name (`agents/log.md:16/21`,
`skills/triage/SKILL.md:24`, triage-report dup branch) are inside the consumer
closure below — rewritten once, consistently.

**Stays open:** DEBT-022, DEBT-027 (classify cost is orthogonal; per-item layout
admits incremental reads but this change does not redesign the classify pass),
DEBT-030 cost half.

## Propagation closure

~25 files reference `docs/backlog.md` (64 occurrences). By group:

- **Root `CLAUDE.md`** — § Development Workflow (card door, cluster row 8),
  § Dispatch, § Doc Sync (backlog-cleanup clause simplifies to "delete the card
  file"; temporal-cleanup clause for specs/plans is deleted), § Finding Triage,
  § Planning (tree rewrite), § Commands.
- **Agents** — `log.md` (write target, owner clauses reconciled: append open to
  all), `todo.md` (sources, stage detection, scaffold feeds), `triage.md`
  (verdict lands as append; read-only reframed as "append-only to card, zero
  writes to code"; needs Edit tool), `triage-report.md` (dup branch gets its real
  destination: append).
- **Skills** — `log`, `todo` (+ scaffolds/assets), `triage`, `triage-report`,
  `commit` (grep-gate doc-surface basenames), `drain` (+ eligibility/relations
  assets), `check-docs-consistency` (+ tracker-annotation asset),
  `super-bootstrap`, `harness-bootstrap` (SKILL + `assets/backlog.md` skeleton →
  README + TEMPLATE skeletons; `claude-md-skeleton.md`; `bootstrap-plan.md`;
  scale assets `parked-skeleton.md`, `rules-venue-map-skeleton.md`).
- **Shared** — `shared/classify-actionable.md` (single-source derivation).
- **Docs** — `docs/specs/harness-architecture.md` (path refs).
  `docs/decisions.md` refs are historical — append-only doc, never rewritten.
- **Out of closure** — `.claude/guidelines/work-discipline/scan-tracker-annotation.md`
  is served/read-only here → route via `/contribute` if load-bearing.
- **Skeleton mirror rides per `repo-boundary.md` sync direction** — shipped
  skeletons stay self-contained (no author-device references).

## Migration

Current live inventory (verified 2026-08-01): `docs/work/specs|plans` hold only
`.gitkeep`; `docs/work/triage/` holds only `DEBT-034-notes.md`.

1. Scaffold `docs/work/README.md` + `TEMPLATE.md` (header content ported from
   `docs/backlog.md`, rewritten to the thread contract; high-water line carried
   over verbatim).
2. Explode the open rows into `docs/work/{ID}.md` — origin block transcribed
   verbatim (H3 → H1 heading only). Rows resolved by this change (DEBT-034,
   DEBT-036, BUG-022) are not migrated.
3. Delete `docs/backlog.md`, `docs/work/triage/` (verdict rides its resolved
   card into git history), `docs/work/specs/`, `docs/work/plans/` — this spec
   file deletes with its directory at merge.
4. Consumer closure lands per the list above.

## Execution notes

- Cluster 3 on top of cluster 7: the implementation plan is authored as
  `docs/work/GAP-047.md`'s `## Plan` block, bootstrap-style in the feature
  branch — the first card of the new substrate, self-demonstrating. The
  superpowers workflow skills (brainstorming / writing-plans / executing-plans)
  are not part of this repo's envelope and route nothing here.
  `load-harness-principles` before authoring, `audit-harness-edits` after,
  full cold audit (ambient surfaces: CLAUDE.md, agents, skills).
- **Close-out: `/release` immediately after landing** — bump the plugin version
  and sync the marketplace so the installed copy supersedes the old harness;
  dogfood sessions must not keep running the pre-substrate pipeline.
- `.claude/rules/skill-authoring.md` binds: behavior-shaping prose edits in
  `plugins/*/skills/**` route through `superpowers:writing-skills` RED
  (micro-test floor); mechanical path swaps ride audit + release checks.
- Watch-out: conflict surface concentrates on card files (plans/verdicts
  in-thread). Solo-dev + append-only keeps real overlap rare; the conflict
  stance above governs.
- Watch-out: `decisions.md` fork "intent axis deletion" reopens only with
  drain's gate replaced — this change does not touch the intent axis; keep it
  that way.
