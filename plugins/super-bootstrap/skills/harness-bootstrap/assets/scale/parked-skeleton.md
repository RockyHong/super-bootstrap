# Parked

Items not in the active pipeline — actionable, but waiting on a named trigger. Delete an entry when it resolves (promoted to a card in `docs/work/`, or killed). Git holds the history.

**Admission:** Parked = actionable-but-waits-on-a-named-trigger; every entry MUST carry that trigger (observer + fire-moment), else it drops. This header owns the admission bar — an item that can't name what it watches for and what fires it is not parked, it's dropped.

**ID convention:** Every entry carries a stable `PARK-xxxx` ID, in the shape and from the generator that [`docs/work/README.md`](work/README.md#categories)'s **ID shape** line states, never made by hand; legacy numeric IDs (`PARK-001`) stay valid. A resolved or promoted entry's ID is never reused (history = `git log --grep="<id>"`). On promotion the `PARK-xxxx` retires; the new card file in `docs/work/` is the live handle. IDs index and cross-reference only — no ordering, no priority.

**Entry shape** — an `### PARK-xxxx — {summary}` heading (so every entry indexes by ID in the outline), then the fields:

```
### PARK-xxxx — {one-line summary}

**Logged:** {date} · **Source:** {where this surfaced}
**Watching for:** {the observer — the signal that says the wait is over}
**Fires on:** {the trigger — the concrete event that promotes this to a backlog row}
```

Spec-coupled items may replace **Watching for** / **Fires on** with a `surface-on:feature=X` tag — the item carries rationale that must surface when a spec for feature X is written, and the tag is the grep target.

**Consumer note:** Untagged entries are NOT surfaced every session — their trigger's observer fires them when work touches the same surface, not a standing watch. `surface-on:feature=X` entries surface when their feature's spec is written. `/super-bootstrap:needs-me` does not list either kind on its own.

## Entries

*(empty — seeded as items are parked)*

## Sweep log

*(overwrite in place at each sweep — what was removed and why, no running chronicle)*
