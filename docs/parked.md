# Parked

Items not in the active pipeline — actionable, but waiting on a named trigger. Delete an entry when it resolves (promoted to a card in `docs/work/`, or killed). Git holds the history.

**Admission:** Parked = actionable-but-waits-on-a-named-trigger; every entry MUST carry that trigger (observer + fire-moment), else it drops. This header owns the admission bar — an item that can't name what it watches for and what fires it is not parked, it's dropped.

**ID convention:** Every entry carries a stable `PARK-###` ID. IDs are monotonic and **never reused** — a resolved or promoted entry's ID stays consumed (history = `git log --grep="<id>"`). On promotion the `PARK-###` retires; the new card file in `docs/work/` is the live handle. IDs index and cross-reference only — no ordering, no priority.

**ID high-water mark:** `PARK-001` — last consumed parked ID. `/super-bootstrap:log` assigns max+1 from this line and bumps it in the same write.

**Entry shape** — an `### PARK-### — {summary}` heading (so every entry indexes by ID in the outline), then the fields:

```
### PARK-### — {one-line summary}

**Logged:** {date} · **Source:** {where this surfaced}
**Watching for:** {the observer — the signal that says the wait is over}
**Fires on:** {the trigger — the concrete event that promotes this to a backlog row}
```

Spec-coupled items may replace **Watching for** / **Fires on** with a `surface-on:feature=X` tag — the item carries rationale that must surface when a spec for feature X is written, and the tag is the grep target.

**Consumer note:** Untagged entries are NOT surfaced every session — their trigger's observer fires them when work touches the same surface, not a standing watch. `surface-on:feature=X` entries surface when their feature's spec is written. `/super-bootstrap:todo` does not list either kind on its own.

## Entries

### PARK-001 — doc-sync link-graph walk as a consult-catalog pruning layer

**Logged:** 2026-09-01 · **Source:** GAP-070 demotion — no observed hook failure (bench gates all green, no live recall miss on record), and the win condition exists in no current repo: post-sync catalogs render far under the 1700-char cap (largest real project, 61 docs, renders ~1000). Graph pruning also runs against the measured mechanism (forced evaluation + no pre-filter — the model is the better classifier; [`bench/consult-hook/FINDINGS-gap045.md`](../bench/consult-hook/FINDINGS-gap045.md) § Mechanism finding). The consult/doc-sync artifact split stays as decided in [`docs/decisions.md`](decisions.md); this parks mechanism reuse only.
**Watching for:** a consumer repo's `.claude/.consult-catalog` render (current deriver) approaching the cap — say >1200 chars — or one live consult recall miss through the shipped hook (that instance becomes the fixture).
**Fires on:** either signal → promote to a GAP card carrying this measurement recipe, in order, each stage gating the next: (1) static link-coverage audit via `doc-links.sh index` — orphan rate + k-hop reachability; high orphan rate kills the direction (link graphs err false-negative, per the reverse-link-lookup row in [`docs/decisions.md`](decisions.md)); (2) live shadow read-out from session-store JSONL — per real prompt, compare the model's stated YES set, actual Read events, and the set a graph walk from prompt-named seeds would return; tests GAP-070's entry-node-asymmetry prior on real traffic at zero fixture cost; (3) hermetic A/B on the [`bench/consult-hook/`](../bench/consult-hook/README.md) harness only if 1–2 pass — baseline is the shipped forcedeval-compact (not no-wire), a graph-oracle ceiling arm runs first, the fixture's doc surface must overflow the flat catalog's token band (else the saturated-baseline flaw recurs), and probes must hit both error directions (keyed doc in a link-reachable unnamed neighbor, and in an orphan doc).

## Sweep log

*(overwrite in place at each sweep — what was removed and why, no running chronicle)*
