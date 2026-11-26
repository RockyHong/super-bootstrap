Do not use any tools. Answer from the text below only. Today is 2026-11-26.

You are the gateway session of /super-bootstrap:needs-me. The skill text you run under (`SKILL.md`) reads:

---
---
name: needs-me
description: "Session opener for the work that needs you. Scans what is open — every card thread at the cold-reader read set, the test queue, outward threads, parked items when present — cuts it into three or four lenses that exist in this repo right now and asks which one (a free slot takes any focus in prose), then recommends up to five items in that lens with why they need you. A prose argument is the focus and skips the question. Items that need no one are counted, not listed — they belong to /super-bootstrap:autorun. Read-only."
tags: [needs-me, pickup, attention, session-opener]
---

# needs-me — what deserves your attention now

A recommender, not a board. The full list is the card folder itself; this door answers one question — *what is worth my sitting down for* — and hands the pick straight into pickup.

## Scan

`docs/work/` absent → "No runway installed. Run `/super-bootstrap:setup`." and stop.

Otherwise read, inline:

- each open card (`docs/work/{BUG,DEBT,GAP}-*.md`) at the cold-reader read set (`docs/work/README.md` § Thread contract) — the same read autorun's § Pick runs — the wall's evidence sits in block bodies (a `waiting on {party}` in a Design, an approval line, a surface Verdict's `###` sub-heading), never in a heading alone;
- `docs/test-queue.md` § Pending entries, `docs/outward/OUT-*.md` origin + latest block, `docs/parked.md` entries — each only when the file exists;
- `docs/overview.md` Problem / User — the product anchor the ranking leans on.

Root `SESSION-STATE/` holds carry files → print `{N} carries in flight → /super-bootstrap:session-continue` before the lens question; the carries themselves stay unread. The pointer line prints whether or not the lens question runs.

Sort every item by the test in `${CLAUDE_PLUGIN_ROOT}/shared/user-wall.md`: **needs you** or **runs without you**. Only the first set goes further.

## Lenses — cut live, never fixed

Partition the needs-you set into three or four lenses that exist in *this* repo today, one concern each, named by what the user would sit down to do. Illustrations only — never a menu to copy: *decisions that unblock parked autorun work* · *product-anchor / taste items worth a long session* · *verify on device* · *outward — your move*. Each option carries a count and one line. Ask once with `AskUserQuestion`; its built-in Other slot takes a focus in prose. Empty needs-you set → skip the question and print `Nothing needs you right now.`, then § Recommend's two count lines (the `{M}` line only when any).

A prose argument (`/super-bootstrap:needs-me 只看 product`, `不碰 business`) is the focus — apply it, skip the question.

## Recommend

Rank the candidates in the chosen lens on what § Scan read. Print at most five lines, leverage first (what its resolution unblocks, then how close it sits to the product anchor):

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
- `## Design — {date}` — settled-aim section; lands when [a genuine fork](../../.claude/rules/harness.md#framing--route--state-dont-gate) put the aim to the user — at route time (taste gate), or as a `## Verdict — surface` the user then rules — the chosen option, settled; approval = one appended line. Revision = new Design block that takes over; old stays in the chain. A `surface` fork the gateway's climb settles ([`skills/triage/SKILL.md`](../../plugins/super-bootstrap/skills/triage/SKILL.md) step 3) lands the same block naming the settling source instead of a ruling. A ruling whose settled aim is to wait names the awaited party — `waiting on {party}` — so `/super-bootstrap:needs-me` reads the card as waiting on that party and `/super-bootstrap:autorun` leaves it alone. A `## Progress` or `## Design` block whose next step cannot run before a date names it in one fixed shape, verbatim and lowercase — `not before YYYY-MM-DD` — so `/super-bootstrap:session-continue` holds the carry out of resume, `/super-bootstrap:needs-me` lists the card as not yet due, and `/super-bootstrap:autorun` leaves it alone.
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

The repo holds no `docs/test-queue.md`, no `docs/outward/`, no `docs/parked.md`. `docs/work/` holds `README.md`, `GAP-31.md`, `GAP-32.md`, `GAP-33.md`. Root `SESSION-STATE/` holds three files, shown below; a part the skill does not read does not exist for you.

=== docs/work/GAP-31.md ===
# GAP-31 — Tune the cache eviction window

**Logged:** 2026-11-20 · **Source:** perf report
**Problem:** `cache/evict.ts` evicts after 10 minutes; hit rate on repeat queries is low.
**Area:** `cache/evict.ts`, `scripts/hit-stats.sh`

## Verdict — auto-fix · 2026-11-21

**Fix-shape:** mechanical
Raise the window to 30 minutes behind the `EVICT_MIN` setting, then compare `scripts/hit-stats.sh` output over one week of traffic and keep the better window.

## Progress — 2026-11-24 · session

Window raised to 30 minutes and deployed on 2026-11-24. Next: run `scripts/hit-stats.sh` over the week and pick the window — not before 2026-12-10, when a full week of data has landed.

=== docs/work/GAP-32.md ===
# GAP-32 — Rotate the nightly log archive

**Logged:** 2026-10-20 · **Source:** disk alert
**Problem:** `logs/archive/` grows without bound; `jobs/rotate.sh` should keep 30 days.
**Area:** `jobs/rotate.sh`, `tests/rotate.bats`

## Verdict — auto-fix · 2026-10-21

**Fix-shape:** mechanical
Delete archive files older than 30 days in `jobs/rotate.sh`; `tests/rotate.bats` covers it with dated stub files.

## Progress — 2026-10-22 · session

Stub fixture written in `tests/rotate.bats`. Next: write the deletion in `jobs/rotate.sh` — not before 2026-11-01, when the old archive format is retired.

=== docs/work/GAP-33.md ===
# GAP-33 — Retry flaky upload in the sync job

**Logged:** 2026-11-11 · **Source:** CI failure
**Problem:** `jobs/sync.sh` fails the whole run when one upload times out.
**Area:** `jobs/sync.sh`, `tests/sync.bats`

## Verdict — auto-fix · 2026-11-12

**Fix-shape:** mechanical
Wrap the upload call in a three-try retry with backoff; `tests/sync.bats` covers it with a stubbed timeout.

=== SESSION-STATE/GAP-31-a1b2c3d4.md ===
**Anchor:** GAP-31 cache window
**Read first:** `docs/work/GAP-31.md`
**State:** window raised, deployed
**Next step:** run hit-stats after the week
**Watch-outs:** none

=== SESSION-STATE/GAP-33-e5f6a7b8.md ===
**Anchor:** GAP-33 upload retry
**Read first:** `docs/work/GAP-33.md`
**State:** retry wrapper sketched, not committed
**Next step:** finish the wrapper, run `tests/sync.bats`
**Watch-outs:** none

=== SESSION-STATE/GAP-29-0c9d8e7f.md ===
**Anchor:** GAP-29 login redirect
**Read first:** `docs/work/GAP-29.md`
**State:** redirect fix half done
**Next step:** finish the fix
**Watch-outs:** none

Run § Scan and the sort only — no lens question, no recommendation rows. Judge each card and carry only on the parts the skill says to read. Print, and nothing before it:

1. the SESSION-STATE pointer line exactly as the skill says to print it;
2. one line per card: `{ID} → {where this card shows up in needs-me's output, in the skill's own words} — {one-line reason}`;
3. any count lines § Recommend would print under its rows.

Then stop.
