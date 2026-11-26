Do not use any tools. Answer from the text below only. Today is 2026-11-26.

You are the gateway session of /super-bootstrap:autorun. The skill text you run under (`SKILL.md`) reads:

---
---
name: autorun
description: "Run the cards that do not need you. One `/super-bootstrap:autorun` turn = read every open card → admit the ones whose next step needs no user (shared/user-wall.md) → one isolated git worktree + one headless `claude -p` per card, each running the whole card to done and committing on its branch → when all have stopped, one sheet: DONE rows land through one batch merge line, WALL rows ask resolve / park / drop. Never merges. Sub-verbs: `status`, `release {id}`. User-invoked only."
disable-model-invocation: true
tags: [autorun, worktree, parallel, unattended]
---

# autorun — run what does not need you

Pick → run → sheet. The gateway orchestrates; each admitted card is one worktree session that runs to done or to its first wall. State lives in files — the next invocation re-reads and picks again.

**Consumer contract:** the super-bootstrap runway — `docs/work/{BUG,DEBT,GAP}-*.md` cards, `/super-bootstrap:commit`, `/super-bootstrap:merge`. First run self-installs the worktree infra (`assets/ensure-infra.md`).

## Pre-flight

1. **Infra** — `assets/ensure-infra.md`; absent → one-time install confirm, decline ends the turn.
2. **Base** — `git fetch` + fast-forward the base branch; a conflict surfaces and ends the turn.
3. **In flight** — `Glob .claude/worktrees/autorun-*/OWNED_BY`. Each hit is a claimed card: it is skipped by the pick below and listed under `status`. A worktree whose card file is gone → surface for `release`.
4. **Harness pending** — a card on base whose latest `## Harness edits — {date}` block lists edits, with no unmerged `autorun/{id-lower}` branch and no claimed worktree → run § Harness pending before the pick.

## Pick

Read every open card thread (`docs/work/{BUG,DEBT,GAP}-*.md` — the cold-reader read set, `docs/work/README.md` § Thread contract). Admit a card when its next step needs no user — the test is `${CLAUDE_PLUGIN_ROOT}/shared/user-wall.md`, read at pick time — and none of these hold:

- claimed (an `autorun-{id}` worktree exists) or already on an unmerged branch (`git branch --no-merged {base}`);
- held by an open `docs/outward/OUT-*.md` whose `Owning card:` names it;
- carries a `## Harness edits` block whose latest one lists edits — Pre-flight step 4 owns it.

Harness lines on a card are judged by `user-wall.md`'s harness-primary line: a card that meets it skips as `harness` (`/super-bootstrap:needs-me` lists it); a card whose harness edits are incidental is admitted, the edits riding the card as a `## Harness edits` block (§ Run, § Harness pending).

A prose argument narrows the set (`/super-bootstrap:autorun 不碰 business`, `only DEBT`). Cards whose `Area:` / thread name overlapping files share one worktree and run in dependency order; the rest run in parallel.

Print the pick, then proceed — the user interjects in prose if the pick is wrong:

```
autorun — {N} cards
run:   {ID}  {one-line aim}           (grouped rows share a worktree, "→" between them)
skip:  {ID}  {reason — needs you: decision | taste | eyes | waiting on X | claimed | harness | held | harness pending}
```

Zero admitted → print the skip list and end the turn.

## Run

Per admitted card or group — `assets/parallel-worktrees.md` § Warm (claim = `mkdir .claude/worktrees/autorun-{id}`, branch `autorun/{id-lower}`, template copied, `OWNED_BY` written), then one background dispatch (§ Dispatch step, `--` before the brief, no model pin — the session inherits the default). Append the tools the card's next step needs to that worker's `--allowedTools` — `WebSearch,WebFetch` for web research; stack runners come from the repo's own settings, not the dispatch line (§ Worker grants beyond the base set).

**Brief** — rendered fresh from files at spawn, five parts:

1. `assets/worktree-boundary.md`, verbatim.
2. The card path(s) — "read the cold-reader read set `docs/work/README.md` § Thread contract names — the origin, the latest block of each type, and the Amendments after them."
3. **Work order** — run the card whole under this repo's harness doctrine envelope (`.claude/rules/harness.md`; `CLAUDE.md` in a repo not yet split): ground it if no Verdict block grounds it yet (`/super-bootstrap:triage {ID}`), build, verify, then commit on this branch via `/super-bootstrap:commit` (deferred mode — doc-sync belongs to the merge). A group runs its cards in the listed order, one commit each. Resolve the card as the envelope says (delete the card file in the resolving commit); a card whose work includes harness edits stays, carrying them as a `## Harness edits — {date}` block (`assets/worktree-boundary.md` § Harness edits go on the card); a group whose cards carry any writes `DONE — harness pending`.
4. **Stop conditions** — `${CLAUDE_PLUGIN_ROOT}/shared/user-wall.md` verbatim: the moment finishing needs one of those, land what is done (block appended, commit made), write the status, stop. Missing context the tree does not hold → `BLOCKED`, never a guess.
5. **Status contract** — one line at `.autorun-status` in the worktree root, written atomically (temp file + rename), uncommitted:
   `DONE` · `DONE — harness pending` · `WALL — {one line: what is needed, from whom}` · `BLOCKED — {what is missing}`.

The turn ends after the last dispatch. Completions arrive as background notifications; a notification with no status file reads as `BLOCKED — no status written`.

## Sheet

When every spawned session has returned, read each status via `cat .claude/worktrees/autorun-{id}/.autorun-status` (never `Read` inside a worktree — `assets/parallel-worktrees.md` § Read discipline) and render one sheet. A `DONE — harness pending` worktree renders one `HARNESS` row per card that carries a `## Harness edits` block — per card of the group, `git show autorun/{id-lower}:docs/work/{ID}.md`; `{n}` = the edits in its latest block — and a `DONE` row for each other card. A card § Harness pending left with edits pending keeps its `HARNESS` row, the pending edits named, until they leave the pending set:

```
autorun — sheet
DONE     {ID}  {aim}
HARNESS  {ID}  {aim} · {n} harness edits → after the landing, § Harness pending
WALL     {ID}  {the one line}
BLOCKED  {ID}  {the one line}
land:    inspect, then /super-bootstrap:merge --batch autorun/{id-lower} …   (one invocation naming every DONE and HARNESS row's branch)
```

Then one `AskUserQuestion` per WALL / BLOCKED row — three options, always:

| Pick | Gateway action |
| --- | --- |
| **Resolve now** | The user's answer appends to the card (`## Amendment` / `## Design` per `docs/work/README.md`); re-render the brief and re-spawn in the same worktree. |
| **Park** *(default when the user has no time)* | Append `## Progress — {date} · autorun` to the card: the wall line + `branch: autorun/{id-lower}` + what landed. Tear the worktree down (§ Cleanup), keep the branch. A later session picks the card up cold from its thread. |
| **Drop** | The card is not worth finishing: delete the card file, tear the worktree down, delete the branch — one commit naming why. |

DONE and HARNESS rows wait for the user; they land together through the one `land:` line — `/super-bootstrap:merge`'s batch landing (§ 5b): one integration branch, one verify, one doc-sync over the integrated diff, base fast-forwards once.

## Harness pending

Runs on the base branch at the next invocation's Pre-flight (step 4), per card whose branch has merged:

1. Read the card's latest `## Harness edits — {date}` block. Apply each edit verbatim with `Edit` — old string to new string, in the named file. An old string that occurs zero or several times leaves that edit pending.
2. Run `audit-harness-edits` (or the repo's harness-edit audit) on the applied diff; disposition its findings.
3. No edit pending → delete the card file and commit via `/super-bootstrap:commit`. An edit pending → append a new `## Harness edits — {date}` block listing only the pending edits, commit it with the applied part, and surface each pending edit: what (file + old string), expected (one occurrence), options (re-derive the edit from the card's Problem · apply it by hand · drop it).
4. The user's pick takes the edit out of the pending set: the gateway appends a new `## Harness edits — {date}` block listing the edits still pending — a re-derived edit in its new form, a hand-applied or dropped edit left out. An empty list → no edit pending, step 3's delete.

## Sub-verbs

- `status` — list `autorun-*` worktrees with card, branch, age, and the status line. Read-only.
- `release {id}` — tear down a crashed or abandoned worktree (`assets/parallel-worktrees.md` § Cleanup); the card and branch stay.

## Rules

- **Gateway holds destructive git.** Merge, push, worktree removal, branch deletion — gateway only, each behind a user prompt. Sessions hand off through the status line.
- **State = file presence.** Worktree dir + `OWNED_BY` + card thread + branch. Every invocation re-reads; nothing is remembered across turns.
- **Read-around, never Read-in.** `git show autorun/{id-lower}:<path>`, `cat` the status file, `Grep` / `Glob` markers — mechanically backed by the `PreToolUse(Read)` hook ensure-infra installs.
- **Verification that depends on module resolution runs at the merge, on the integrated tree in the main checkout** — a nested worktree can resolve phantom deps from the parent (`assets/parallel-worktrees.md` § Nested-worktree false-greens). The landing changed the tree's sources, so provisioning runs first (`assets/parallel-worktrees.md` § Provisioning).
- **The merge-gate verify is the batch landing's single verify** — `/super-bootstrap:merge` § 5b runs the provisioning commands, then the repo's declared Staged-Tree Verify command (no verify declared → skip both), once on the integration branch, before base moves (again after a doc-sync commit, § 5b step 6). Red → a linear scan names the first red merge, base stays where it was, the output surfaces; every branch stays.
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

The repo holds no `docs/outward/`, no `.claude/worktrees/autorun-*` worktree, and `git branch --no-merged main` prints nothing. No card carries a `## Harness edits` block. Pre-flight passed.

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

Run § Pick only and print the pick block exactly as § Pick shows it (header, one `run:` or `skip:` line per card), nothing before it. Then stop.
