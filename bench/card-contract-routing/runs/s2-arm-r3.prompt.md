Do not use any tools. Answer from the text below only.

You are a Claude Code session working in a repo that runs the super-bootstrap harness. Its workflow doctrine says, in part:

---
Settled design and step sequence land as `## Design` / `## Plan` blocks on the card's own thread ([`docs/work/`](../../docs/work/README.md)).
---

`docs/work/README.md` reads, in part:

---
## Thread contract

**Origin block** (H1 + field lines) — frozen at capture; the breadcrumb at the top of the thread.

**Extensions:** `docs/extensions.md`, when present, declares the fields this repo adds to a card's origin block, each naming the hook, script, or skill that reads it — additive to this contract, never overriding a line of it.

**Six block types**, each appended at end of file, dated + sourced — context-scope sections assembled on need, never stages a card must pass:

- `## Amendment — {date} · {source}` — reframe, premise supersession, new fact, NEEDS_CONTEXT answer.
- `## Verdict — auto-fix|surface · {date}` — triage output; the kind says who is needed — `auto-fix` no one, `surface` the user, for an open fork (`### Decision needed`) or the author's eye (`### Taste needed`).
- `## Design — {date}` — settled-aim section; lands when [a genuine fork](../../.claude/rules/harness.md#framing--route--state-dont-gate) put the aim to the user — at route time (taste gate), or as a `## Verdict — surface` the user then rules — the chosen option, settled; approval = one appended line. Revision = new Design block that takes over; old stays in the chain. A `surface` fork the gateway's climb settles (`/super-bootstrap:triage` step 3) lands the same block naming the settling source instead of a ruling. A ruling whose settled aim is to wait names the awaited party — `waiting on {party}` — so `/super-bootstrap:needs-me` reads the card as waiting on that party and `/super-bootstrap:autorun` leaves it alone. A `## Progress` or `## Design` block whose next step cannot run before a date names it in one fixed shape, verbatim and lowercase — `not before YYYY-MM-DD` — so `/super-bootstrap:session-continue` holds the carry out of resume, `/super-bootstrap:needs-me` lists the card as not yet due, and `/super-bootstrap:autorun` leaves it alone.
- `## Plan — {date}` — step-order section; lands only when a cold executor runs the work (autorun worktree, cross-session handoff, scope past the session-carry ledger); step sequence only — no checkboxes, no status marks. Revision = new Plan block that takes over; old stays in the chain.
- `## Harness edits — {date}` — harness edits an autorun worker leaves for the gateway, which applies them on base after the merge; per edit: file path, exact old string, new string. The latest one leads and lists the edits still pending; not a step list, and it does not make a card in-flight.
- `## Progress — {date}` — durable milestone or interruption state; the cross-session handoff surface.

**Mutation authority:** any session or agent appends (end-of-file only, dated + sourced); a changed understanding appends a new block that takes over its type's lead. Existing content is never edited.

**Append routing:** content that stays true after the card is gone — a ruling that binds work outside the card, a standing fact — lands in its owning doc in the same write, and the card block links to it; a later revision edits that doc, not a second truth on the card. Working state stays on the card.

**Read contract:** the latest block of each type leads that type — Verdict → grounded scope, Design → aim, Plan → steps, Progress → state; an Amendment applies to the blocks above it; origin stays as grounding. A brief that sends a cold reader to a card names this read set: the origin, the latest Verdict, Design, Plan and Progress the card holds, and every Amendment after the earliest of those — a card holding none of them reads every Amendment after the origin. Top-to-bottom = the evolution path, read whole when the task is tracing how the card evolved.

**Live tracking:** in-session execution state belongs to the platform's native task list; durable progress lands as a Progress block.

**Resolve:** the resolving session deletes the card file — work completed and direction dropped both resolve; the deleting commit's message carries the why. Before the delete, a behavior or limitation the card leaves true lands in its owning doc — unless a line of that doc already states it, and then the deleting commit's message names that doc:line ([`.claude/rules/dimension-discipline.md`](../../.claude/rules/dimension-discipline.md) item 5). Git history is the archive.

**Aim switch:** a thread cuts by aim, not by phase. Same aim, changed understanding → append (the new block takes over its type's lead). The problem itself superseded → resolve this card with the counter-diagnosis and open a successor card whose origin cites the predecessor ID — the breadcrumb survives in the pointer + git.

**Conflict:** keep either side whole or regenerate from its blocks; never hand-merge block content.
---

The repo's files (paths only, except the one shown whole below): `README.md`, `docs/overview.md`, `docs/specs/cache.md`, `docs/work/README.md`, `docs/work/TEMPLATE.md`, `docs/work/DEBT-41.md`, `src/cache/store.py`.

=== docs/work/DEBT-41.md ===
# DEBT-41 — Cache hit rate dropped after the store rewrite

**Logged:** 2026-11-18 · **Source:** dashboard
**Problem:** Hit rate fell from 92% to 71% after the `src/cache/store.py` rewrite.
**Area:** `src/cache/store.py`

## Verdict — auto-fix · 2026-11-19

**Fix-shape:** mechanical
The eviction key drops the tenant prefix; restore it in `store.py`.

=== task ===
Today is 2026-11-26. You restored the tenant prefix in `store.py` and it is committed. The fix ships with the weekly deploy on 2026-12-03; the hit rate can only be re-measured on production traffic after that deploy, so the next step — re-measure the hit rate and resolve the card if it is back above 90% — cannot run before 2026-12-03. You are ending the session now. Park this work on the card, following the card contract above.

Print every file write you would make, and nothing else, each in this shape:

=== WRITE {repo-relative path} ===
{the exact text you append or the full new section, as it would land in the file}
=== END ===

Print one such block per file you touch. Touch only the files the task needs.
