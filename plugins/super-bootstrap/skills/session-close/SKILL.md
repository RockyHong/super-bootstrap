---
name: session-close
description: "Use at a session boundary — the session looks done, or you are breaking mid-work. Routes by fulfillment: goal delivered whole → done-close (closeout moves + this session's carry file cleared); in-motion remainder → park-close (card-anchored remainder appended as a `## Progress` block on the owning card, only what no card owns to this session's file in the root SESSION-STATE/ ledger). Detects every open closeout move — commit (through /super-bootstrap:commit, doc-sync included), push, card resolve (sweeping every open card for finished or superseded ones, not only this session's), branch prune, merge, finding triage, ledger write/clear — and drives them to done through one confirm-pick; every write runs after the pick. Gates first on work this session launched that has not reported back — wait for it or stop it before the pick. No argument; reads current session state. Owns the session-carry ledger convention."
tags: [session, close, park, ledger, carry]
---

# Session Close — Session-Boundary Gate

## Two terminal shapes

| Detected state | Shape |
|---|---|
| Goal delivered whole, nothing in-motion | **done-close** — closeout moves + own carry cleared |
| In-motion remainder (mid-work break, topic switch, context heavy) | **park-close** — closeout moves + Progress block on the card + carry landed in the ledger |

Step 1 routes by fulfillment; on ambiguity the user's framing wins — only they know a done session from a pause.

## Ledger convention

This section is the convention's SSOT; `/super-bootstrap:session-continue` reads it from here.

- **Path** — `SESSION-STATE/<label>-<id>.md` at the repo root, one file per session. `<label>` = short anchor-derived slug (the card ID when card-anchored); `<id>` = first 8 chars of `$CLAUDE_CODE_SESSION_ID` (absent → `date +%H%M%S`).
- **Slots** — Anchor / Read first / State / Next step / Watch-outs.
- **Park** = whole-file rewrite of the own file (git holds history). **Done** = delete the own file. A file present = that session's carry is in flight.
- **Conflict** (merge markers from a cross-branch carry) → keep either side or regenerate from current state; never hand-merge.

## Protocol

The gateway runs this inline — it inspects the live session's work and tree, dispatches no subagent, pins no model.

Two passes: **detect** every open closeout move (steps 0–3) — read-only, nothing written; step 0's exit choice is the one prompt before the pick — then **drive** them to done in one confirm-pick (step 4).

### 0. Detect — still-running work (gate)

List every finite job this session launched that has not reported back: a background agent or subagent with no completion notice, a backgrounded shell running a job, a spawned `claude -p` or foreign executor (`codex exec`, or equivalent) whose result has not returned. The evidence is this session's own launch records and completion notices in context. Blind spot: a launch record lost to compaction does not show — say so beside the list when the context was compacted.

Any job running → **no pick**. Surface the list — what each job is and what it writes — and the user picks one exit per job:

- **wait** — end the turn; the job's completion notice, or the user re-invoking the close, restarts detection at step 0, and its writes are now session changes that step 2 reads.
- **stop** — `TaskStop`, or kill the shell or executor (a process stop, not a tree write); then inspect its partial writes, which step 2 reads like any tree change.

Once every job has reported or been stopped — or none was running — go to step 1. Recurring or standing items — an armed cron or wakeup, a Monitor, a server shell — never report back and do not gate: list them in the pick, each with a **stop** move.

### 1. Detect — fulfillment → shape

Is this session's goal delivered whole, with nothing left in motion? Whole → **done-close**. An in-motion remainder — a live next-step, a half-built change, a break arriving mid-work → **park-close**. An undelivered goal the user expects finished this session is neither — carry it to step 4's surface, not the move-pick.

### 2. Detect — tree + commit

Inspect for uncommitted session work, untracked files, stray artifacts — this session's changes only. Session changes → a **commit** move, run through `/super-bootstrap:commit` (Skill tool) — the door owns staging, doc-sync, and the message; never a raw `git commit`. Commits ahead of upstream, or a branch with a remote but no upstream → a **push** move, answered in the pick. No remote (`git remote` prints nothing) → no push move.

### 3. Detect — cards + integration + ledger

- **Finished cards — sweep every open card**, not only this session's (`docs/work/{BUG,DEBT,GAP}-*.md`). A card is finished when any signal holds:
  - (a) its latest Progress reports every step of its latest Plan done;
  - (b) its aim moved — an Amendment or link hands it to a card ID now absent from `docs/work/`, or resolved in this close;
  - (c) main-line commits other than its own card-thread writes (log, amend, Plan, Progress) name its ID (`git log --grep`) — this session's merges included — and the named Plan steps / Problem line together cover every step of the latest Plan, or the whole Problem (a commit also touching code counts);
  - (d) this session's work landed it whole, or this session's own text calls it done, superseded, or closed.

  (a)–(c) start as greps over card text and `git log`; deep-read only the cards they hit. Each finished card → a **resolve** move whose line carries its evidence (the signal, quoting the block line or commit): delete the card file per `docs/work/README.md` § Thread contract (Resolve), folded into the close commit. A signal that fires with the card's remaining aim unclear → a **triage** move (`/super-bootstrap:triage {ID}`) instead.
- **Merged local branches** — branches already merged into the main line (main-line name from ambient; exclude main + current). An empty result is the clean case — guard the exclusion greps so a no-match exits 0. Each is a **prune** move via `git branch -d` (merged-guard refuses unmerged — recoverable). A recurring non-empty result is a producer miss — surface it as a **log** move.
- **A complete feature branch ready to integrate** → an opt-in **merge** move via `/super-bootstrap:merge` — never auto-merged.
- **Inflight findings** surfaced this session but not yet carded → triage each: on this session's goal, a bounded live tweak owning no downstream, clean tree, context to spare?
  - all yes → a **fix-now** move: the edit, folded into the close commit.
  - far afield, carries propagation closure, OR context heavy → a **log** move via `/super-bootstrap:log`.
  Judge fit by ownership, not diff size.
- **Ledger** — this session's own file under root `SESSION-STATE/` (other sessions' files stay untouched, read or written):
  - done-close, own file present → a **ledger-clear** move (delete it, folded into the close commit).
  - park-close → a **park** move (step 4 owns its body): a Progress append per anchoring card + the ledger-write.

### 4. Drive to close

Gather every detected move into ONE confirm-pick — multi-select, recommended default = all. A single detected move still routes through the pick, paired with an explicit "close without running it" option, so the pick always offers ≥2 choices. Present each as a concrete line: what it does, and its blast for moves that mutate or reach outward (push, merge, prune). The push line names the remote and states branch → upstream (or the `-u` setup when none exists); the remote is the sole one, or the one the user names when several exist. The pick IS the confirm-gate — no per-move prompt, the door's included.

**The park move** runs the cold-pickup test — "if a new session starts cold, can it orient from files alone?" — and sorts the in-motion remainder:

- **Card-anchored** — which Plan step is done, the next step, and every constraint or watch-out that binds the card's remaining work → a `## Progress — {date}` block appended to the owning card.
- **Durable, not card-owned** (decisions, spec deltas) → the owning doc, landed through the commit door's doc-sync.
- **Volatile, no card owns it** (cross-card session context, a thread not yet carded) → the own ledger file, in the convention's slots; Read first names the card ID(s). Never restate what the Progress block or a doc already holds — a watch-out binding the card lives on the card, not only in the carry. Nothing volatile beyond the card → a pointer-only stub (Anchor + card ID + Next step pointer), still written so session-continue finds it.

Show the drafted Progress block(s) and carry body in the pick. **Nothing is written before the pick.** On confirm, execute the picked moves in dependency order: stop standing items → fix-now edits → Progress appends → ledger-write / ledger-clear → card resolve → commit via `/super-bootstrap:commit` (its §6 handoff line is skipped) → merge → push → prune. The push move runs here, not in a door — neither the commit door nor the merge door pushes: `git push` when the branch has an upstream, else `git push -u <remote> <branch>` with the remote the pick line named. It pushes only a branch whose picked commit or merge landed: a merge move pushes `{base}`, and a merge that stopped on a conflict or red left nothing to push. Never force. It runs once, after every picked commit and merge has landed. Re-verify the tree is clean, then **close**.

If step 1 found an undelivered goal the user expects finished, surface it above the pick in three parts — what's open, what whole-delivery expected, the options (finish it, park-close it, or accept and close anyway). It gates the close but can't be move-executed. Proceed until closed or the user accepts an explicit close-anyway.

## Output

This is the terminal output — the commit door's handoff line does not print under session-close.

- The shape taken (done-close / park-close), the moves executed (and any declined), with the final tree + close state.
- Done: close confirmation, or the open thread blocking a clean close. Park: the Progress block(s) and carry as written, echoed for a final eyeball, and the resume line — `Next session: /super-bootstrap:session-continue`.

## Rules

- **Drive, don't narrate.** Actionable leftovers route to the confirm-pick and execute — never a status report handing a known-actionable list back. A card this close judges done, superseded, or stale is a resolve or triage move in the pick, never only a line of prose.
- **One pick, every gate, writes after it.** Commit, push, merge, prune, and every file write — Progress, carry, fix-now — run only when picked, after the pick. Step 0's wait-or-stop choice is the one prompt before it.
- **Doors, not mechanisms.** Commit → `/super-bootstrap:commit`; log → `/super-bootstrap:log`; merge → `/super-bootstrap:merge`. Never a raw `git commit`.
- **Nothing running at close.** No job this session started is still running when the close commits (step 0).
- **Inline procedure.** No argument, no subagent, no model pin.
- **Own file only.** Write and delete the carry carrying this session's id — authored here or claimed at pickup; leave every other file in `SESSION-STATE/` as found — no read-pass over the folder.
- **Two terminal shapes.** done = goal delivered + tree clean + own carry cleared; park = card state on the card, volatile rest in the own carry. Every close lands exactly one.
- **Card first, carry holds the delta.** What a card owns lands on the card; the carry holds only what no card or doc owns, plus pointers — a restated Progress block is a parallel truth.
- **Surface the un-actionable.** An undelivered goal can't be move-executed; surface it three-part and close only on explicit user accept.
