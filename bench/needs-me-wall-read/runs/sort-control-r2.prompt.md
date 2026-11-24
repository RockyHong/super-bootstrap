Do not use any tools. Answer from the text below only.

You are the gateway session of /super-bootstrap:needs-me. The skill text you run under (`SKILL.md`) reads:

---
---
name: needs-me
description: "Session opener for the work that needs you. Scans what is open — cards, the test queue, outward threads, parked items when present — at origin-block grain, cuts it into three or four lenses that exist in this repo right now and asks which one (a free slot takes any focus in prose), then recommends up to five items in that lens with why they need you. A prose argument is the focus and skips the question. Items that need no one are counted, not listed — they belong to /super-bootstrap:autorun. Read-only."
tags: [needs-me, pickup, attention, session-opener]
---

# needs-me — what deserves your attention now

A recommender, not a board. The full list is the card folder itself; this door answers one question — *what is worth my sitting down for* — and hands the pick straight into pickup.

## Scan

`docs/work/` absent → "No runway installed. Run `/super-bootstrap:setup`." and stop.

Otherwise read, inline, cheap:

- every open card's origin block plus its latest `## ` heading (`docs/work/{BUG,DEBT,GAP}-*.md`) — Problem line + where the thread stopped;
- `docs/test-queue.md` § Pending entries, `docs/outward/OUT-*.md` origin + latest block, `docs/parked.md` entries — each only when the file exists;
- `docs/overview.md` Problem / User — the product anchor the ranking leans on.

Root `SESSION-STATE/` holds carry files → print `{N} carries in flight → /super-bootstrap:session-continue` before the lens question; the carries themselves stay unread. The pointer line prints whether or not the lens question runs.

Sort every item by the test in `${CLAUDE_PLUGIN_ROOT}/shared/user-wall.md`: **needs you** or **runs without you**. Only the first set goes further.

## Lenses — cut live, never fixed

Partition the needs-you set into three or four lenses that exist in *this* repo today, one concern each, named by what the user would sit down to do. Illustrations only — never a menu to copy: *decisions that unblock parked autorun work* · *product-anchor / taste items worth a long session* · *verify on device* · *outward — your move*. Each option carries a count and one line. Ask once with `AskUserQuestion`; its built-in Other slot takes a focus in prose. Empty needs-you set → skip the question and print `Nothing needs you right now.`, then § Recommend's two count lines (the `{M}` line only when any).

A prose argument (`/super-bootstrap:needs-me 只看 product`, `不碰 business`) is the focus — apply it, skip the question.

## Recommend

Deep-read the candidates in the chosen lens — past the origin, through the cold-reader read set `docs/work/README.md` § Thread contract names. Print at most five lines, leverage first (what its resolution unblocks, then how close it sits to the product anchor):

```
{ID}  {title}  — {why you, ≤ 8 words}
…
{N} items run without you → /super-bootstrap:autorun
{M} look done or premise-dead: {IDs} → offered for resolve at /super-bootstrap:session-close        (omit when none)
```

Reply with an ID and the session is in pickup — framing line + route per the harness doctrine (`.claude/rules/harness.md`; `CLAUDE.md` in a repo not yet split), no re-scan.

## Rules

- **Read-only.** Never edits, never runs git.
- **Needs-you only.** An item that runs without the user is the count line, never a row — `/super-bootstrap:autorun` owns it.
- **No board, no footer, no sub-verbs.** Zero rows in the lens → say so and name the next-fullest lens in one line.
---

`${CLAUDE_PLUGIN_ROOT}/shared/user-wall.md` reads:

---
# User wall — the one judgment two doors share

A card **needs the user** when finishing it requires any of:

- **A decision only the user owns** — a design fork with no ruling on the card or in `docs/decisions.md`, a product / business / scope call, an unruled `## Verdict — surface` carrying `### Decision needed`, a `## Design` block with no approval line.
- **Taste** — visual, copy, UX, or naming acceptance where "looks right" is the test, an unruled `## Verdict — surface` carrying `### Taste needed` included.
- **Human eyes** — a verify step no tooling can run (device, manual play-through, listening, a browser the user drives; a fully automated headless suite is tooling, not eyes).
- **A party outside the repo** — the card or its outward thread waits on someone's reply, a portal, a key.
- **Real cost or an irreversible move** — paid APIs, external compute, a push / release / delete the user has not asked for.
- **A harness-primary deliverable** — the card's deliverable is a harness file (`CLAUDE.md`, `.claude/**`, the repo's skill / agent / rule files), needs a harness change to work, or has docs describing that change as its only non-harness part. It lands in an attended main-checkout session. Harness edits incidental to a deliverable that stands and verifies without them do not meet this line: they ride the card as a `## Harness edits` block, and the work goes on.

Everything else runs without the user. Judge the card's **next step**, not its whole tail — the harness-primary line excepted, which is judged on the deliverable: a build whose only human step is final acceptance runs to that acceptance and stops there.

Consumers: `/super-bootstrap:needs-me` lists what passes this test; `/super-bootstrap:autorun` admits what fails it. Read here, never restated.
---

`docs/work/README.md` reads, in part:

---
## Thread contract

**Origin block** (H1 + field lines) — frozen at capture; the breadcrumb at the top of the thread.

**Extensions:** `docs/extensions.md`, when present, declares the fields this repo adds to a card's origin block, each naming the hook, script, or skill that reads it — additive to this contract, never overriding a line of it.

**Six block types**, each appended at end of file, dated + sourced — context-scope sections assembled on need, [never stages a card must pass](../specs/harness-architecture.md#no-external-process-harness-is-routed):

- `## Amendment — {date} · {source}` — reframe, premise supersession, new fact, NEEDS_CONTEXT answer.
- `## Verdict — auto-fix|surface · {date}` — triage output; the kind says who is needed — `auto-fix` no one, `surface` the user, for an open fork (`### Decision needed`) or the author's eye (`### Taste needed`) ([shapes](../../plugins/super-bootstrap/agents/triage.md#output-formats)).
- `## Design — {date}` — settled-aim section; lands when [a genuine fork](../../.claude/rules/harness.md#framing--route--state-dont-gate) put the aim to the user — at route time (taste gate), or as a `## Verdict — surface` the user then rules — the chosen option, settled; approval = one appended line. Revision = new Design block that takes over; old stays in the chain. A `surface` fork the gateway's climb settles ([`skills/triage/SKILL.md`](../../plugins/super-bootstrap/skills/triage/SKILL.md) step 3) lands the same block naming the settling source instead of a ruling. A ruling whose settled aim is to wait names the awaited party — `waiting on {party}` — so `/super-bootstrap:needs-me` reads the card as waiting on that party and `/super-bootstrap:autorun` leaves it alone.
- `## Plan — {date}` — step-order section; lands only when a cold executor runs the work (autorun worktree, cross-session handoff, scope past the session-carry ledger); step sequence only — no checkboxes, no status marks. Revision = new Plan block that takes over; old stays in the chain.
- `## Harness edits — {date}` — harness edits an autorun worker leaves for the gateway, which applies them on base after the merge; per edit: file path, exact old string, new string. The latest one leads and lists the edits still pending; not a step list, and it does not make a card in-flight.
- `## Progress — {date}` — durable milestone or interruption state; the cross-session handoff surface.

**Mutation authority:** any session or agent appends (end-of-file only, dated + sourced); a changed understanding appends a new block that takes over its type's lead. Existing content is never edited.

**Read contract:** the latest block of each type leads that type — Verdict → grounded scope, Design → aim, Plan → steps, Progress → state; an Amendment applies to the blocks above it; origin stays as grounding. A brief that sends a cold reader to a card names this read set: the origin, the latest Verdict, Design, Plan and Progress the card holds, and every Amendment after the earliest of those — a card holding none of them reads every Amendment after the origin. Top-to-bottom = the evolution path, read whole when the task is tracing how the card evolved.

**Live tracking:** in-session execution state belongs to the platform's native task list; durable progress lands as a Progress block.

**Resolve:** the resolving session deletes the card file — work completed and direction dropped both resolve; the deleting commit's message carries the why. Before the delete, a behavior or limitation the card leaves true lands in its owning doc — unless a line of that doc already states it, and then the deleting commit's message names that doc:line ([`.claude/rules/dimension-discipline.md`](../../.claude/rules/dimension-discipline.md) item 5). Git history is the archive.

**Aim switch:** a thread cuts by aim, not by phase. Same aim, changed understanding → append (the new block takes over its type's lead). The problem itself superseded → resolve this card with the counter-diagnosis and open a successor card whose origin cites the predecessor ID — the breadcrumb survives in the pointer + git.

**Conflict:** keep either side whole or regenerate from its blocks; never hand-merge block content.
---

The repo holds no `docs/test-queue.md`, no `docs/outward/`, no `docs/parked.md` and no `SESSION-STATE/`. The open cards, file by file:

=== docs/work/GAP-21.md ===
# GAP-21 — Monthly invoice export to the billing portal

**Logged:** 2026-10-02 · **Source:** user request
**Problem:** Invoices are exported by hand each month; `tools/export.sh` should push them to the billing portal.
**Area:** `tools/export.sh`

## Verdict — surface · 2026-10-03

### Decision needed
Push through the portal's current CSV upload, or wait for its announced JSON API.

## Design — 2026-10-04

Ruling: wait for the JSON API; the CSV upload is being retired. waiting on Acme Billing's API team (JSON API v2 release, no date given).

Approved — user, 2026-10-04.

## Progress — 2026-10-06 · session

Field mapping table written to `docs/export-fields.md`; `tools/export.sh` reads the invoice ledger into that shape.

=== docs/work/GAP-22.md ===
# GAP-22 — Dark theme for the settings page

**Logged:** 2026-10-08 · **Source:** user request
**Problem:** The settings page ignores the system dark-mode preference.
**Area:** `web/settings/`

## Verdict — surface · 2026-10-09

### Decision needed
Follow the system preference only, or add an in-page toggle that overrides it.

## Design — 2026-10-10

Proposed: follow the system preference; add the toggle later if asked. Option chosen by the gateway pending the user's ruling.

=== docs/work/GAP-23.md ===
# GAP-23 — Retry flaky upload in the sync job

**Logged:** 2026-10-11 · **Source:** CI failure
**Problem:** `jobs/sync.sh` fails the whole run when one upload times out.
**Area:** `jobs/sync.sh`, `tests/sync.bats`

## Verdict — auto-fix · 2026-10-12

**Fix-shape:** mechanical
Wrap the upload call in a three-try retry with backoff; `tests/sync.bats` covers it with a stubbed timeout.

Run § Scan and the sort only — no lens question, no recommendation. Judge each card only on the parts of it that § Scan says to read; a part § Scan does not read does not exist for the sort. Print exactly one line per card, in this form and nothing before them:

needs you:         {ID}  {the user-wall line it meets}
runs without you:  {ID}

Then one line per card naming which parts of the card you read, then stop.
