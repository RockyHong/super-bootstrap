# docs/work — work-unit workspace

One card = one file = one append-only thread. Everything here dies with its work unit — only `README.md` and `TEMPLATE.md` are standing files.

## Routing

New cards enter via `/super-bootstrap:log` (classify + dedup + ID assignment) or by hand-copying `TEMPLATE.md` (sanctioned transcription path). Either way the ID high-water line below is bumped in the same change.

**When a card is owed:** only for work that exits the current flow **incomplete** — deferred or dropped. Work completed in-flow carries no card debt. The trigger is completion-state (observable), not worth (triage's call at pickup).

## Card glob

`{BUG|DEBT|GAP}-###.md` at `docs/work/` root.

## Categories

- **`BUG-###`** — broken behavior. Surface symptom may hide deeper cause.
- **`DEBT-###`** — working but rotting (test fixture rot, stale dep, cleanup owed).
- **`GAP-###`** — design gap or unverified capability idea, never properly specced. Forward feature ideas land here; triage decides drop / spec.

No phase prescription per category — triage decides how much ceremony the work earns at pickup.

**ID high-water mark:** `BUG-022` · `DEBT-045` · `GAP-050` — last consumed ID per category. Next ID = max+1 from this line, bumped in the same write. Resolved cards are deleted but their IDs stay consumed (history = `git log --grep="<id>"`); never re-derive IDs from live files.

## Thread contract

**Origin block** (H1 + field lines) — frozen at capture; the breadcrumb at the top of the thread.

**Five block types**, each appended at end of file, dated + sourced:

- `## Amendment — {date} · {source}` — reframe, premise supersession, new fact, NEEDS_CONTEXT answer.
- `## Verdict — auto-fix|surface · {date}` — triage output.
- `## Design — {date}` — settled design; approval = one appended line.
- `## Plan — {date}` — step sequence only; no checkboxes, no status marks. Revision = new Plan block that takes over; old stays in the chain.
- `## Progress — {date}` — durable milestone or interruption state; the cross-session handoff surface.

**Mutation authority:** any session or agent appends (end-of-file only, dated + sourced); a changed understanding appends a new block that takes over the lead. Existing content is never edited.

**Read contract:** top-to-bottom = the evolution path; the latest block leads current understanding; origin stays as grounding.

**Live tracking:** in-session execution state belongs to the platform's native task list; durable progress lands as a Progress block.

**Resolve:** the resolving session deletes the card file — work completed and direction dropped both resolve; the deleting commit's message carries the why. Git history is the archive.

**Conflict:** keep either side whole or regenerate from its blocks; never hand-merge block content.
