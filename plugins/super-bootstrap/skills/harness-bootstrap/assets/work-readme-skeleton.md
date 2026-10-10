# docs/work — work-unit workspace

One card = one file = one append-only thread. Everything here dies with its work unit — only `README.md` and `TEMPLATE.md` are standing files.

## Routing

New cards enter via `/super-bootstrap:log` (classify + dedup + ID assignment), in [`TEMPLATE.md`](TEMPLATE.md)'s shape.

**When a card is owed:** only for work that exits the current flow **incomplete** — deferred or dropped. Work completed in-flow carries no card debt. The trigger is completion-state (observable), not worth (triage's call at pickup).

## Card glob

`{BUG|DEBT|GAP}-*.md` at `docs/work/` root.

## Categories

- **`BUG-xxxx`** — broken behavior. Surface symptom may hide deeper cause.
- **`DEBT-xxxx`** — working but rotting (test fixture rot, stale dep, cleanup owed).
- **`GAP-xxxx`** — design gap or unverified capability idea, never properly specced. Forward feature ideas land here; triage decides drop / spec.

No phase prescription per category — triage decides [how much ceremony the work earns](../../CLAUDE.md#sizing--scale-ceremony-to-the-works-shape) at pickup.

**ID shape:** `{CAT}-xxxx` — category prefix + a random 4-char suffix, e.g. `GAP-k7f3`; full pattern `{CAT}-[0-9a-z]+`. Every ID comes from the generator `/super-bootstrap:log` runs, which redraws on any ID already in the repo or its commit messages; never compose, increment, or re-derive one by hand. Legacy numeric IDs (`GAP-012`) stay valid and are never renamed. Order lives in each card's `Logged:` date and in `git log`, not in the ID. Resolved cards are deleted (history = `git log --grep="<id>"`).

## Thread contract

**Origin block** (H1 + field lines) — frozen at capture; the breadcrumb at the top of the thread.

**Five block types**, each appended at end of file, dated + sourced — context-scope sections assembled on need, never stages a card must pass:

- `## Amendment — {date} · {source}` — reframe, premise supersession, new fact, NEEDS_CONTEXT answer.
- `## Verdict — auto-fix|surface · {date}` — triage output; the kind says who is needed — `auto-fix` no one, `surface` the user, for an open fork (`### Decision needed`) or the author's eye (`### Taste needed`).
- `## Design — {date}` — settled-aim section; lands when [a genuine fork](../../CLAUDE.md#framing--route--state-dont-gate) put the aim to the user — at route time (taste gate), or as a `## Verdict — surface` the user then rules — the chosen option, settled; approval = one appended line. Revision = new Design block that takes over; old stays in the chain. A `surface` fork the gateway's climb settles (`/super-bootstrap:triage` step 3) lands the same block naming the settling source instead of a ruling. A ruling whose settled aim is to wait names the awaited party — `blocked on {party}` — so `/super-bootstrap:needs-me` reads the card as waiting on that party and `/super-bootstrap:autorun` leaves it alone.
- `## Plan — {date}` — step-order section; lands only when a cold executor runs the work (autorun worktree, cross-session handoff, scope past the session-carry ledger); step sequence only — no checkboxes, no status marks. Revision = new Plan block that takes over; old stays in the chain.
- `## Progress — {date}` — durable milestone or interruption state; the cross-session handoff surface.

**Mutation authority:** any session or agent appends (end-of-file only, dated + sourced); a changed understanding appends a new block that takes over its type's lead. Existing content is never edited.

**Read contract:** the latest block of each type leads that type — Verdict → grounded scope, Design → aim, Plan → steps, Progress → state; an Amendment applies to the blocks above it; origin stays as grounding. A brief that sends a cold reader to a card names this read set: the origin, the latest Verdict, Design, Plan and Progress the card holds, and every Amendment after the earliest of those — a card holding none of them reads every Amendment after the origin. Top-to-bottom = the evolution path, read whole when the task is tracing how the card evolved.

**Live tracking:** in-session execution state belongs to the platform's native task list; durable progress lands as a Progress block.

**Resolve:** the resolving session deletes the card file — work completed and direction dropped both resolve; the deleting commit's message carries the why. Git history is the archive.

**Aim switch:** a thread cuts by aim, not by phase. Same aim, changed understanding → append (the new block takes over its type's lead). The problem itself superseded → resolve this card with the counter-diagnosis and open a successor card whose origin cites the predecessor ID — the breadcrumb survives in the pointer + git.

**Conflict:** keep either side whole or regenerate from its blocks; never hand-merge block content.
