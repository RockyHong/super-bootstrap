# docs/work — work-unit workspace

One card = one file = one append-only thread. Everything here dies with its work unit — only `README.md` and `TEMPLATE.md` are standing files.

## Routing

New cards enter via `/super-bootstrap:log` (classify + dedup + ID assignment) or by hand-copying [`TEMPLATE.md`](TEMPLATE.md) (sanctioned transcription path). Either way the ID high-water line below is bumped in the same change.

**When a card is owed:** only for work that exits the current flow **incomplete** — deferred or dropped. Work completed in-flow carries no card debt. The trigger is completion-state (observable), not worth (triage's call at pickup).

## Card glob

`{BUG|DEBT|GAP}-###.md` at `docs/work/` root.

## Categories

- **`BUG-###`** — broken behavior. Surface symptom may hide deeper cause.
- **`DEBT-###`** — working but rotting (test fixture rot, stale dep, cleanup owed).
- **`GAP-###`** — design gap or unverified capability idea, never properly specced. Forward feature ideas land here; triage decides drop / spec.

No phase prescription per category — triage decides [how much ceremony the work earns](../../CLAUDE.md#sizing--scale-ceremony-to-the-works-shape) at pickup.

**ID high-water mark:** `BUG-041` · `DEBT-078` · `GAP-063` — last consumed ID per category. Next ID = max+1 from this line, bumped in the same write. Resolved cards are deleted but their IDs stay consumed (history = `git log --grep="<id>"`); never re-derive IDs from live files.

## Thread contract

**Origin block** (H1 + field lines) — frozen at capture; the breadcrumb at the top of the thread.

**Five block types**, each appended at end of file, dated + sourced — context-scope sections assembled on need, [never stages a card must pass](../specs/harness-architecture.md#change-a-is-complete-change-b-is-resolved):

- `## Amendment — {date} · {source}` — reframe, premise supersession, new fact, NEEDS_CONTEXT answer.
- `## Verdict — auto-fix|surface · {date}` — triage output.
- `## Design — {date}` — settled-aim section; lands when [a genuine fork](../../CLAUDE.md#framing--route--state-dont-gate) put the aim to the user — at route time (taste gate), or as a `## Verdict — surface` the user then rules — the chosen option, settled; approval = one appended line. A ruling whose settled aim is to wait names the awaited party — `blocked on {party}` — so [the board's wait override](../../plugins/super-bootstrap/shared/classify-actionable.md) holds the card as a Decide row rather than executable.
- `## Plan — {date}` — step-order section; lands only when a cold executor runs the work (drain worktree, cross-session handoff, scope past the session-carry ledger); step sequence only — no checkboxes, no status marks. Revision = new Plan block that takes over; old stays in the chain.
- `## Progress — {date}` — durable milestone or interruption state; the cross-session handoff surface.

**Mutation authority:** any session or agent appends (end-of-file only, dated + sourced); a changed understanding appends a new block that takes over the lead. Existing content is never edited.

**Read contract:** top-to-bottom = the evolution path; the latest block leads current understanding; origin stays as grounding.

**Live tracking:** in-session execution state belongs to the platform's native task list; durable progress lands as a Progress block.

**Resolve:** the resolving session deletes the card file — work completed and direction dropped both resolve; the deleting commit's message carries the why. Git history is the archive.

**Aim switch:** a thread cuts by aim, not by phase. Same aim, changed understanding → append (the new block takes over the lead). The problem itself superseded → resolve this card with the counter-diagnosis and open a successor card whose origin cites the predecessor ID — the breadcrumb survives in the pointer + git.

**Conflict:** keep either side whole or regenerate from its blocks; never hand-merge block content.
