---
name: session-close
description: "Use at a session boundary — the session looks done, or you are breaking mid-work. Routes by fulfillment: goal delivered whole → done-close (closeout moves + this session's carry file cleared); in-motion remainder → park-close (card-anchored remainder appended as a `## Progress` block on the owning card, only what no card owns to this session's file in the root SESSION-STATE/ ledger). Detects every open closeout move — commit (through /super-bootstrap:commit, doc-sync included), card resolve (sweeping every open card for finished or superseded ones, not only this session's), branch prune, merge, push by repo shape, finding triage, ledger write/clear — and drives them to done through one confirm-pick; every write runs after the pick. Work this session took on and left undone — a card it logged and left open, a task it promised — asks in that same pick. Gates first on work this session launched that has not reported back — wait for it or stop it before the pick. No argument; reads current session state. Owns the session-carry ledger convention."
tags: [session, close, park, ledger, carry]
---

# Session Close — Session-Boundary Gate

## Two terminal shapes

| Detected state | Shape |
|---|---|
| Goal delivered whole, nothing in-motion | **done-close** — closeout moves + own carry cleared |
| In-motion remainder (mid-work break, topic switch) | **park-close** — closeout moves + Progress block on the card + carry landed in the ledger |

Step 1 routes by fulfillment; on ambiguity the user's framing wins — only they know a done session from a pause.

## Ledger convention

This section is the convention's SSOT; `/super-bootstrap:session-continue` reads it from here.

- **Path** — `SESSION-STATE/<label>-<id>.md` at the repo root, one file per session. `<label>` = short anchor-derived slug (the card ID when card-anchored); `<id>` = first 8 chars of `$CLAUDE_CODE_SESSION_ID` (absent → `date +%H%M%S`).
- **Slots** — Anchor / Read first / State / Next step / Watch-outs.
- **Park** = whole-file rewrite of the own file (git holds history). **Done** = delete the own file. A file present = that session's carry is in flight.
- **Conflict** (merge markers from a cross-branch carry) → keep either side or regenerate from current state; never hand-merge.

## Protocol

The gateway runs this inline — it inspects the live session's work and tree and pins no model. The close has two dispatch points, both in the foreground: the commit door's own dispatches at step 3b, and the post-edit audit each harness edit the close lands owes, a drive step after the pick (step 4).

Two passes: **detect** every open closeout move (steps 0–3b) — read-only, with worktree, HEAD and shared index left as found; step 0's exit choice is the one prompt before the pick — then **drive** them to done in one confirm-pick (step 4).

### 0. Detect — still-running work (gate)

List every finite job this session launched that has not reported back: a background agent or subagent with no completion notice, a backgrounded shell running a job, a spawned `claude -p` or foreign executor (`codex exec`, or equivalent) whose result has not returned. The evidence is this session's own launch records and completion notices in context. Blind spot: a launch record lost to compaction does not show — say so beside the list when the context was compacted.

Any job running → **no pick**. Surface the list — what each job is and what it writes — and the user picks one exit per job:

- **wait** — end the turn; the job's completion notice, or the user re-invoking the close, restarts detection at step 0, and its writes are now session changes that step 2 reads.
- **stop** — `TaskStop`, or kill the shell or executor (a process stop, not a tree write); then inspect its partial writes, which step 2 reads like any tree change.

Once every job has reported or been stopped — or none was running — go to step 1. Recurring or standing items — an armed cron or wakeup, a Monitor, a server shell — never report back and do not gate: list them in the pick, each with a **stop** move.

### 1. Detect — fulfillment → shape

Is this session's goal delivered whole, with nothing left in motion? Whole → **done-close**. An in-motion remainder — a live next-step, a half-built change, a break arriving mid-work → **park-close**.

Then list every **undone item** — work inside this session's boundary that it left unfinished:

- each card this session logged — an ID its own `/super-bootstrap:log` call printed, or a commit it made that adds `docs/work/{ID}.md` — still in `docs/work/` with no finished-card signal (step 3);
- each task this session's own replies told the user it would do and no later step did, other than the goal;
- an undelivered goal the user expects finished this session.

The boundary is this session's own context: its log output, its commits, its own text. An open card it never logged is outside it and is no item; step 3's sweep still resolves it when finished. A remainder the park move already carries is no item, and work left uncommitted is step 2's commit move, never an item. Blind spot: an item lost to compaction does not show — say so beside the items when the context was compacted. An item whose whole finish is an edit draftable exactly now → a **fix-now** move (step 3's rule), and a card item's fix-now row carries the card's resolve with it; every other item → its own question in step 4's pick.

### 2. Detect — tree + commit

Commits land in flow, so this step catches leaks. Inspect for uncommitted session work, untracked files, stray artifacts — this session's changes only. Session changes, or any move or undone item's park option (step 4) that writes or deletes a file, even on a tree holding no session change → a **commit** move, whose row lists a park option's paths as landing only when that option is picked, run through `/super-bootstrap:commit close-commit` (Skill tool) — the door owns staging, doc-sync, and the message; never a raw `git commit`.

### 3. Detect — cards + integration + ledger

- **Finished cards — sweep every open card**, not only this session's (`docs/work/{BUG,DEBT,GAP}-*.md`). A card is finished when any signal holds:
  - (a) its latest Progress reports every step of its latest Plan done;
  - (b) its aim moved — an Amendment or link hands it to a card ID now absent from `docs/work/`, or resolved in this close;
  - (c) main-line commits other than its own card-thread writes (log, amend, Plan, Progress) name its ID (`git log --grep`) — this session's merges included — and the named Plan steps / Problem line together cover every step of the latest Plan, or the whole Problem (a commit also touching code counts);
  - (d) this session's work landed it whole, or this session's own text calls it done, superseded, or closed.

  A card this session logged that no signal finishes is step 1's undone item. (a)–(c) start as greps over card text and `git log`; deep-read only the cards they hit. Each finished card → a **resolve** move whose row carries its evidence (the signal, quoting the block line or commit) and its outcome — the behavior or limitation the card leaves true: the exact edit drafted into the doc that owns it, or the doc:line that already states it, which the deleting commit's message names. The outcome edit stays on this row, never split into a doc-update row, so picking the resolve picks its outcome. The move lands that edit and deletes the card file per `docs/work/README.md` § Thread contract (Resolve). A signal that fires with the card's remaining aim unclear → a **triage** move (`/super-bootstrap:triage {ID}`) instead.
- **Merged local branches** — branches already merged into the main line (main-line name from ambient; exclude main + current). An empty result is the clean case — guard the exclusion greps so a no-match exits 0. Each is a **prune** move via `git branch -d` (merged-guard refuses unmerged — recoverable). A recurring non-empty result is a producer miss — surface it as a **log** move.
- **A complete feature branch ready to integrate** → an opt-in **merge** move via `/super-bootstrap:merge` — never auto-merged.
- **Inflight findings** surfaced this session but not yet carded → finish what this close can finish. Each takes one move. A finding on a harness path takes the **owner check** first: `ls -a` the path's skill directory for a `.served` marker and its own directory for a `<file>.served` sidecar, and apply any other provenance the repo's harness declares for its served classes, a folder declared served whole included. A hit, or a path in another repo, makes it a served or foreign copy, never this repo's, whatever this session read or drafted for it:
  - This repo's, with its edit and everything that edit must keep in sync draftable exactly now, however far from this session's goal → a **fix-now** move: the exact text in the pick. A ritual the repo's harness binds on that edit — a principles load before it, an audit of the diff after it — is part of landing it, never grounds for log: the pre-edit load runs in this detect pass, where the draft is written, and the row states the post-edit audit, which runs after the pick (step 4).
  - Every other finding → a **log** move via `/super-bootstrap:log`, whose row states why it cannot finish now: its closure outgrows a drafted edit (an owed harness ritual is not closure), its own investigation would pull large unrelated reads into this thread, or another repo or party owns it.
  Judge fit by ownership and closure, not diff size.
- **Ledger** — this session's own file under root `SESSION-STATE/` (other sessions' files stay untouched, read or written):
  - done-close, own file present → a **ledger-clear** move (delete it).
  - park-close → a **park** move (step 4 owns its body): a Progress append per anchoring card + the ledger-write.
- **Push** — run `bash <skill-base>/assets/push-state.sh move`, with `--landing` when this close holds a commit or merge move, as its own call; `<skill-base>` is the `Base directory for this skill:` path surfaced at invocation. A printed line → a **push** move running that line. Nothing printed → this step is finished and leaves no line. The script is the whole check: no separate lookup runs.

### 3b. Detect — the commit door's judgment

With a commit move in hand, run the door's read-only entry — `/super-bootstrap:commit close-detect` — over the session's changes plus every fix-now draft, resolve-outcome draft and park doc draft (step 4's durable, not card-owned edits, so its park sort runs first), so the whole diff is judged once, here; with no session changes, the drafts are its whole input. Each return settles as a row of the pick, its exact text drafted:

- **Stale candidate, premise re-frame or dangling, broken link, stale pin** → a **doc-update** row: path, what is outdated, the edit. Every one of these carries a row.
- **Register item** → a **register** row: the word, doc:line, the entry verbatim, the edit to the using line.
- **Terminology miss** → a **terminology** row: doc:line and the line's edit.
- **Restatement** → a **restatement** row: the edit linking each unlinked copy to the home. No home, or a closure past a drafted edit → a **log** move stating that reason.
- **Volatile-ID hit** → a **volatile-ID** row: doc:line and the line's edit, the outcome stated present-tense or a commit sha cited.
- **Harness row** → step 3's owner check first, then `co-change`:
  - Either hit → foreign-owned, whatever `co-change` says, routed by the repo's own finding lanes, concern first and provenance second: this repo's concern → a **log** move, the copy untouched; the owner's concern → a row naming the path and its owner's route, which writes nothing. The row states which route it took, and the copy's path stays off the commit row.
  - No hit, `co-change: yes` → a **harness-edit** row: path, the outdated line, the exact edit. Its ritual is a fix-now edit's: the pre-edit load runs in this detect pass, where the edit is drafted; it lands with the door-judgment rows and states the post-edit audit it owes, which runs after the pick (step 4).
  - No hit, `co-change: no` → when it earns a move, a **log** move stating the line was already wrong before this change.

A register, terminology, restatement or `co-change: no` harness return that does not earn a move gets no line. A return with two live resolutions only the user can judge carries both on its row.

### 4. Drive to close

Gather every detected move and every undone item (below) into ONE confirm-pick, asked through one AskUserQuestion call with its questions and options in the session's language. Moves count by row, and a commit row counts even when another row's write is all it lands. Several moves → multi-select, recommended default = all; more moves than the tool's option cap → each option groups rows and names them. A single move → single-select with two options, run and skip: that call is the pick, every rule on the pick binds it, and a skip closes without the move. Present each as a concrete line: what it does, and its blast for moves that mutate or reach outward (merge, prune, push). The pick's text is the shape and its rows: the detect pass's working stays behind it, and the close's output names only detected moves. The pick IS the confirm-gate — no per-move prompt, the door's included. The commit move is one row, normally one commit: work the session left uncommitted is named plainly as left uncommitted, by path, however large, and the row lists every other path the picked moves write or delete. Before the pick, read the row's whole path list with the door's §5 test for unrelated changes: unrelated → the row says so in one clause, "splits into N commits", with no nested commit list.

**The park move** runs the cold-pickup test — "if a new session starts cold, can it orient from files alone?" — and sorts the in-motion remainder:

- **Card-anchored** — which Plan step is done, the next step, and every constraint or watch-out that binds the card's remaining work → a `## Progress — {date}` block appended to the owning card.
- **Durable, not card-owned** (decisions, spec deltas) → the owning doc, landed through the commit door's doc-sync.
- **Volatile, no card owns it** (cross-card session context, a thread not yet carded) → the own ledger file, in the convention's slots; Read first names the card ID(s). Never restate what the Progress block or a doc already holds — a watch-out binding the card lives on the card, not only in the carry. Nothing volatile beyond the card → a pointer-only stub (Anchor + card ID + Next step pointer), still written so session-continue finds it.

Show the drafted Progress block(s), carry body, park doc edits, fix-now edits, resolve outcomes and door-judgment rows in the pick. **Nothing is written before the pick.** On confirm, execute the picked moves in dependency order: stop standing items → fix-now edits, park doc edits and picked door-judgment rows → the post-edit audit each harness edit the close landed owes — fix-now and harness-edit rows alike — over its landed paths → Progress appends → ledger-write / ledger-clear → card resolve → commit via `/super-bootstrap:commit close-commit`, handing it the picked commit row (its §6 commit report is skipped) → merge → prune → push. A declined row writes nothing, and its paths leave the commit row; a commit row left with no path runs no commit. A failure the run hits — a hook failure, a conflict, a door stop, an audit finding — stops and surfaces. Re-verify the tree is clean, then **close**.

**Undone items** (step 1) ask in the same AskUserQuestion call, one single-select question each beside the move question, which keeps its own shape (several moves multi-select, a lone move run and skip): what the item is and where it stands, then three options — **finish now** (recommended when the item is small and on this session's goal), **park** (a `## Progress` block on its card, or a carry line for a task no card owns; it joins the park move), **leave open** (no write). An undelivered goal's question also names what whole-delivery expected, and its leave-open option is close anyway. With no moves, the item questions are the whole call. The call holds at most four questions of two to four options each: more items than the questions left beside the move question → every item folds into one multi-select question whose options are each item's finish now, grouped and named when they pass the option cap, and an item not picked there is left open (no park in that case). An item picked **park** makes the close a park-close: the park move writes its Progress block or carry line, and the carry is written rather than cleared. A park option shows the Progress block or carry line it would write. A finish-now pick on any item runs no move and drops the call's other picks: the close stops with one line naming the item, the work resumes, and the user re-invokes the close after it, which detects again from step 0.

## Output

This is the terminal output — the commit door's §6 commit report does not print under session-close.

After the moves, run `bash <skill-base>/assets/push-state.sh state` as its own call.

The final output holds these fields and nothing else. Each field names only what this close did — its moves, the paths they wrote — and its failure; it asks nothing beyond a failure's options, since the pick was the last ask:

- The shape taken (done-close / park-close).
- The moves executed, and any declined, and each undone item's pick.
- The count of scope docs the door read and confirmed unchanged.
- The final tree state: what `git status` shows, by path.
- The line `push-state.sh state` printed, if any.
- What a failure the run hit stopped, and where, and the options for it, if any.
- On a park-close: the Progress block(s) and carry as written, for a final eyeball, and the resume line — `Next session: /super-bootstrap:session-continue`.

A finish-now pause outputs only its one line naming the item. A card with no row or question in the pick gets no line in any field — not as "still open", not as read, not as next: open work is `/super-bootstrap:needs-me`'s.

## Rules

- **Drive, don't narrate.** Actionable leftovers route to the confirm-pick and execute — never a status report handing a known-actionable list back; the line `push-state.sh state` prints is the one push fact reported after the pick (§ Output). A card this close judges done, superseded, or stale is a resolve or triage move in the pick, and a card this session logged and left open is an undone-item question, never only a line of prose. A surfaced item carries the action this close will take or a genuine fork with its options; an item with neither gets no line.
- **One pick, every gate, writes after it.** Commit, merge, prune, push, and every file write — Progress, carry, fix-now, door-judgment rows — run only when picked, after the pick. Step 0's wait-or-stop choice is the one prompt before it. Every judgment settles inside the pick, except the post-edit audit each harness edit the close lands owes (step 4); only a failure the run hits surfaces after it, an audit finding included.
- **Doors, not mechanisms.** Commit → `/super-bootstrap:commit`; log → `/super-bootstrap:log`; merge → `/super-bootstrap:merge`. Never a raw `git commit`.
- **Nothing running at close.** No job this session started is still running when the close commits (step 0).
- **Inline procedure.** No argument, no model pin; the door's dispatches at step 3b and the post-edit audit each harness edit the close lands owes (step 4) are the only ones.
- **Own file only.** Write and delete the carry carrying this session's id — authored here or claimed at pickup; leave every other file in `SESSION-STATE/` as found — no read-pass over the folder.
- **Two terminal shapes.** done = goal delivered + tree clean + own carry cleared; park = card state on the card, volatile rest in the own carry. Every close lands exactly one; a finish-now pause is no close and lands neither.
- **Card first, carry holds the delta.** What a card owns lands on the card; the carry holds only what no card or doc owns, plus pointers — a restated Progress block is a parallel truth.
- **Undone work asks in the pick.** Every undone item (step 1), an undelivered goal included, is a fix-now move or a question of the one call with finish now, park and leave open; a finish-now pick pauses the close before any move.
