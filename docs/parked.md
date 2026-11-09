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

**Consumer note:** Untagged entries are NOT surfaced every session — their trigger's observer fires them when work touches the same surface, not a standing watch. `surface-on:feature=X` entries surface when their feature's spec is written. `/super-bootstrap:needs-me` does not list either kind on its own.

## Entries

### PARK-001 — doc-sync link-graph walk as a consult-catalog pruning layer

**Logged:** 2026-09-01 · **Source:** GAP-070 demotion — no observed hook failure (bench gates all green, no live recall miss on record), and the win condition exists in no current repo: post-sync catalogs render far under the 1700-char cap (largest real project, 61 docs, renders ~1000). Graph pruning also runs against the measured mechanism (forced evaluation + no pre-filter — the model is the better classifier; [`bench/consult-hook/FINDINGS-gap045.md`](../bench/consult-hook/FINDINGS-gap045.md) § Mechanism finding). The consult/doc-sync artifact split stays as decided in [`docs/decisions.md`](decisions.md); this parks mechanism reuse only.
**Watching for:** a consumer repo's `.claude/.consult-catalog` render (current deriver) approaching the cap — say >1200 chars — or one live consult recall miss through the shipped hook (that instance becomes the fixture).
**Fires on:** either signal → promote to a GAP card carrying this measurement recipe, in order, each stage gating the next: (1) static link-coverage audit via `doc-links.sh index` — orphan rate + k-hop reachability; high orphan rate kills the direction (link graphs err false-negative, per the reverse-link-lookup row in [`docs/decisions.md`](decisions.md)); (2) live shadow read-out from session-store JSONL — per real prompt, compare the docs the model actually read (Read or shell-read events on catalog paths — the shipped check sentence demands no stated verdict, [`FINDINGS-gap045.md`](../bench/consult-hook/FINDINGS-gap045.md) § No-stated-output revision) and the set a graph walk from prompt-named seeds would return; tests GAP-070's entry-node-asymmetry prior on real traffic at zero fixture cost; (3) hermetic A/B on the [`bench/consult-hook/`](../bench/consult-hook/README.md) harness only if 1–2 pass — baseline is the shipped arm, forcedeval-v2 (not no-wire), a graph-oracle ceiling arm runs first, the fixture's doc surface must overflow the flat catalog's token band (else the saturated-baseline flaw recurs), and probes must hit both error directions (keyed doc in a link-reachable unnamed neighbor, and in an orphan doc).

### PARK-mw8r — session-close residuals after the leak-catching redesign

**Logged:** 2026-11-04 · **Source:** `DEBT-70b1`, closed on the user's ruling; its thread is in the deleting commit's parent
**Watching for:** a real close that picks wrong, drops work, or misleads the user. Known residuals: a nested list after "splits into N commits", the register row at 6 of 9, and an empty push check named in the pick's framing or final output. No reading yet on a real remote, a rejected push, the Skill-tool path, park-close output or a declined row.
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

### PARK-knda — cut the harness-bootstrap re-run burden (the audit wait it chains into)

**Logged:** 2026-11-09 · **Source:** `GAP-naw8`, parked on the author's ask with no option settled ("先不選，這session不決定"); its thread — two verdicts, the docs and hook reads, the author's answer that the felt cost is the re-run chaining into `claude-config-manager`'s harness-audit wait — is in the deleting commit's parent
**Watching for:** the author's ruling on which part of the burden the next card targets — the thread's last verdict frames it as options (a)–(d), recommending (c) with (a) first — or one of the routes it names becoming ready: a positive-control probe showing plugin `SessionStart` / `SubagentStart` output reaching the main session, a subagent and a compacted context; or `claude-config-manager`'s audit gate treating a sync placed byte-identical to an audited skeleton (outside a doc rule's consumer `paths:` tail) as audited.
**Fires on:** the author opening that discussion or picking an option, or either route above landing → promote to a GAP card restoring the thread from git.

## Sweep log

*(overwrite in place at each sweep — what was removed and why, no running chronicle)*
