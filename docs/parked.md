# Parked

Items not in the active pipeline — actionable, but waiting on a named trigger. Delete an entry when it resolves (promoted to a card in `docs/work/`, or killed). Git holds the history.

**Admission:** Parked = actionable-but-waits-on-a-named-trigger; every entry MUST carry that trigger (observer + fire-moment), else it drops. This header owns the admission bar — an item that can't name what it watches for and what fires it is not parked, it's dropped.

**ID convention:** Every entry carries a stable `PARK-xxxx` ID, in the shape and from the generator that [`docs/work/README.md`](work/README.md#categories)'s **ID shape** line states, never made by hand; legacy numeric IDs (`PARK-001`) stay valid. A resolved or promoted entry's ID is never reused; the commits naming it hold its history. On promotion the `PARK-xxxx` retires; the new card file in `docs/work/` is the live handle. IDs index and cross-reference only — no ordering, no priority.

**Entry shape** — an `### PARK-xxxx — {summary}` heading (so every entry indexes by ID in the outline), then the fields:

```
### PARK-xxxx — {one-line summary}

**Logged:** {date} · **Source:** {where this surfaced}
**Watching for:** {the observer — the signal that says the wait is over}
**Fires on:** {the trigger — the concrete event that promotes this to a backlog row}
```

Spec-coupled items may replace **Watching for** / **Fires on** with a `surface-on:feature=X` tag — the item carries rationale that must surface when a spec for feature X is written, and the tag is the grep target.

**Extensions:** `docs/extensions.md`, when present, declares the fields this repo adds to a parked entry, each naming the hook, script, or skill that reads it — additive to this header, never overriding a line of it.

**Consumer note:** Untagged entries are NOT surfaced every session — their trigger's observer fires them when work touches the same surface, not a standing watch. `surface-on:feature=X` entries surface when their feature's spec is written. `/super-bootstrap:needs-me` reads every entry when it runs and lists one only when its next step needs the user.

## Entries

### PARK-001 — doc-sync link-graph walk as a consult-catalog pruning layer

**Logged:** 2026-09-01 · **Source:** GAP-070 demotion — no observed hook failure (bench gates all green, no live recall miss on record), and the win condition exists in no current repo: post-sync catalogs render far under the 1700-char cap (largest real project, 61 docs, renders ~1000). Graph pruning also runs against the measured mechanism (forced evaluation + no pre-filter — the model is the better classifier; [`bench/consult-hook/FINDINGS-gap045.md`](../bench/consult-hook/FINDINGS-gap045.md) § Mechanism finding). The consult/doc-sync artifact split stays as decided in [`docs/decisions.md`](decisions.md); this parks mechanism reuse only.
**Watching for:** a consumer repo's `.claude/.consult-catalog` render (current deriver) approaching the cap — say >1200 chars — or one live consult recall miss through the shipped hook (that instance becomes the fixture).
**Fires on:** either signal → promote to a GAP card carrying this measurement recipe, in order, each stage gating the next: (1) static link-coverage audit via `doc-links.sh index` — orphan rate + k-hop reachability; high orphan rate kills the direction (link graphs err false-negative, per the reverse-link-lookup row in [`docs/decisions.md`](decisions.md)); (2) live shadow read-out from session-store JSONL — per real prompt, compare the docs the model actually read (Read or shell-read events on catalog paths — the shipped check sentence demands no stated verdict, [`FINDINGS-gap045.md`](../bench/consult-hook/FINDINGS-gap045.md) § No-stated-output revision) and the set a graph walk from prompt-named seeds would return; tests GAP-070's entry-node-asymmetry prior on real traffic at zero fixture cost; (3) hermetic A/B on the [`bench/consult-hook/`](../bench/consult-hook/README.md) harness only if 1–2 pass — baseline is the shipped arm, forcedeval-v2 (not no-wire), a graph-oracle ceiling arm runs first, the fixture's doc surface must overflow the flat catalog's token band (else the saturated-baseline flaw recurs), and probes must hit both error directions (keyed doc in a link-reachable unnamed neighbor, and in an orphan doc).

### PARK-mw8r — session-close residuals after the leak-catching redesign

**Logged:** 2026-11-04 · **Source:** `DEBT-70b1`, closed on the user's ruling; its thread is in the deleting commit's parent
**Watching for:** a real close that picks wrong, drops work, or misleads the user. Known residuals: a nested list after "splits into N commits", the register row at 6 of 9, an empty push check named in the pick's framing or final output, and a final output that names an open card no picked move touched ([`bench/session-close-moves`](../bench/session-close-moves/README.md#findings) (w5), 5 of 6). One real close read: a consumer repo's final output listed the open cards after the pick, one marked as needing the owner's judgement; the close skill's § Output bounds that case. No reading yet on a real remote, a rejected push, the Skill-tool path, park-close output or a declined row.
**Fires on:** one such close observed, or `docs/test-queue.md`'s device case failing. Tuning prose against these readings alone does not fire it.

### PARK-wez1 — skill-authoring has no stop rule for a condition prose keeps failing

**Logged:** 2026-11-04 · **Source:** `GAP-exzg`, parked on the user's ask to drain the cards
**Watching for:** a skill edit's bench where one condition reads zero across two wordings and a third wording is proposed. Candidate rule: stop wording work, then use a mechanism or lower the bar, and price a miss before its gate is set.
**Fires on:** that third wording being proposed. Needs a light RED first.

### PARK-wh0x — triage does not ask whether the normal flow should reach the step a card repairs

**Logged:** 2026-11-04 · **Source:** `GAP-e81g`, parked on the user's ask to drain the cards
**Watching for:** a card whose build rounds repair a step that the owner then says the normal flow should rarely reach. Candidate rule: triage asks that question and re-aims at the upstream cause.
**Fires on:** a second such card. Needs a light RED first, since the question may over-fire on ordinary edge-case bugs.

### PARK-s218 — commit doc-sync grep lane does not enumerate the consumer's own harness

**Logged:** 2026-11-09 · **Source:** `GAP-drwb`, option B deferred by its Design block
**Watching for:** a harness line that the same change made stale, found only after the commit landed, that the doc-sync scan did not report. The scan reports a harness co-change only when its judgment reads or greps that file; no mechanical lane lists harness paths. Candidate: widen the commit door's grep lane (`doc-links.sh hits`) to the consumer's own harness (`CLAUDE.md`, `.claude/{rules,skills,agents}/**`) for the diff's removed terms, leaving out served copies by their `.served` marker. Cost: a larger scan scope, so more cold dispatches above the ceiling of 8, and a `doc-links.sh` change with its bench.
**Fires on:** one such post-commit harness drift observed.

### PARK-e0pp — merge `setup` into `harness-bootstrap`

**Logged:** 2026-11-20 · **Source:** `DEBT-ymdg`, closed on the user's ask to split the card by aim
**Watching for:** a change to the install or sync entry. With the per-section sync judgment gone, `setup` (install) and `harness-bootstrap` (sync) no longer need to be two doors.
**Fires on:** the next change that edits `setup`'s or `harness-bootstrap`'s entry flow, or a report that the two entries confuse a user.

### PARK-gqgf — drop the transitional "`CLAUDE.md` in a repo not yet split" pointers

**Logged:** 2026-11-20 · **Source:** `DEBT-ymdg`, closed on the user's ask to split the card by aim
**Watching for:** the skills and agents under `plugins/` that cite the doctrine in both locations (`.claude/rules/harness.md`; `CLAUDE.md` in a repo not yet split). The second half serves only repos still in the pre-split shape.
**Fires on:** the next major release — remove the second half in every file that names it, and state in the README's upgrade note that a pre-split repo installs the last release that carries it. This repo does not track which consumer repos are still pre-split.

### PARK-3bpp — ablation bench for cuttable doctrine lines

**Logged:** 2026-11-20 · **Source:** `DEBT-ymdg`, closed on the user's ask to split the card by aim
**Watching for:** a reason to shrink `assets/harness.md`. Which doctrine lines are cuttable is unmeasured; `docs/decisions.md` records the route line as load-bearing in 2/2 control runs, so a cut needs an ablation bench with fixtures, not judgment.
**Fires on:** the author approves the spend for that bench.

### PARK-zy7b — `line-coverage.sh` unrun under mawk and one-true-awk

**Logged:** 2026-11-20 · **Source:** `DEBT-ymdg`, closed on the user's ask to split the card by aim
**Watching for:** `tests/line-coverage.test.sh` passes 23 of 23 under `gawk --posix` and `gawk --traditional`; mawk and one-true-awk themselves are unrun, since this device holds gawk only and a container run needs Docker Desktop.
**Fires on:** Docker Desktop running here for another task, or a consumer reporting a migration's line-coverage check failing on a non-gawk awk.

### PARK-8a7z — a v7 doctrine migration that fails in a consumer repo

**Logged:** 2026-11-20 · **Source:** `DEBT-ymdg` close; the migration ran end to end once (a `v2.22.0` walk) and is otherwise unmeasured
**Watching for:** a note or issue from a consumer repo naming one of the shapes the README's upgrade note asks users to report: an old `CLAUDE.md` line in neither new file nor on the drop list the user saw; old plugin text kept as the repo's own line (the walk kept the `karpathy-guidelines` pointer this way); one of the four checks failing, or the run stopping on a case the brief does not cover; the regular sync after it proposing section by section again (state detection read the repo wrong).
**Fires on:** one such report → promote to a BUG card with that repo's old `CLAUDE.md` as the fixture.

## Sweep log

*(overwrite in place at each sweep — what was removed and why, no running chronicle)*
