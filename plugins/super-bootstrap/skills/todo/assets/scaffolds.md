## Scaffolds

Date placeholder `{date}` = today's date in YYYY-MM-DD form. Agent fills it.

**Macro header** (sub-verb modes only — discuss / cloud / device / harness): single line right under title showing cross-mode counts. Always emit even when current mode is non-empty (free — agent classified all rows pre-filter). Format:

```
Macro: Discuss {D} · Cloud {C} · Device {V} · Harness {H} · Full {T}
```

Counts only — no IDs, no impact tags. Decision-is-yours; surface priors not calls. Full mode skips this header (full body IS the macro).

### Need-me (default — bare `/super-bootstrap:todo`)

Drainable rows collapse to the count line; the four need-me groups render as
tables. Omit any group whose row count is zero (drop its heading too). Groups
render in this fixed order.

```
# To-Do — {date}

Drainable: {N}  →  /super-bootstrap:drain

▸ Need me

## Decide / approve

| #  | Action                                  | unblocks | Impact       | Blast       |
| -- | ---------------------------------------- | -------- | ------------ | ----------- |
| 1  | {verb + what + one-line reason}         | {n}      | {tag}        | {tag}       |

## Device-bound

| #  | Action                                  | unblocks | Impact       | Blast       |
| -- | ---------------------------------------- | -------- | ------------ | ----------- |
| 1  | {verb + what + one-line reason}         | {n}      | {tag}        | {tag}       |

## Harness

| #  | Action                                  | unblocks | Impact       | Blast       |
| -- | ---------------------------------------- | -------- | ------------ | ----------- |
| 1  | Deliberate: {topic} / Apply: {rule}→{site} | {n} | {tag}        | {tag}       |

## Probe / grant

| #  | Action                                  | unblocks | Impact       | Blast       |
| -- | ---------------------------------------- | -------- | ------------ | ----------- |
| 1  | {verb + what + one-line reason}         | {n}      | {tag}        | {tag}       |

## Uncategorized

| #  | Action                                  | Why ambiguous                          |
| -- | ---------------------------------------- | --------------------------------------- |
| 1  | {verb + what}                           | {one-line — what signal was missing}   |

{pending unblock: {n} — only if n>0}
{footer per § Render footer-hint}
```

Empty state (no need-me rows AND no drainable):

```
# To-Do — {date}

No active work. Ground something with /super-bootstrap:log or give me a task.
```

Empty need-me but drainable pending:

```
# To-Do — {date}

Drainable: {N}  →  /super-bootstrap:drain

Nothing needs you right now — the board is all auto-runnable.

{footer per § Render footer-hint}
```

### Discuss

```
# To-Do (Discuss) — {date}

Macro: Discuss {D} · Cloud {C} · Device {V} · Harness {H} · Full {T}

| #  | Action                                              | Impact       | Context                                              |
| -- | --------------------------------------------------- | ------------ | ---------------------------------------------------- |
| 1  | {action — one sentence}                             | {tag}        | {one-line — why open, what unblocks}                 |

## Uncategorized

| #  | Action                                              | Why ambiguous                                    |
| -- | --------------------------------------------------- | ------------------------------------------------ |
| 1  | {verb + what}                                       | {one-line — what signal was missing}             |

more: /super-bootstrap:help
```

Empty state:

```
# To-Do (Discuss) — {date}

Macro: Discuss 0 · Cloud {C} · Device {V} · Harness {H} · Full {T}

Nothing to decide.

Macro priors (no recommendation):
- Cloud: {top 1-3 with file + one-line reason}
- Device: {top 1-3 with file + one-line reason, or "0"}
- Harness: {top 1-3 with file + one-line reason, or "0"}

Next mode: yours. /super-bootstrap:todo cloud · /super-bootstrap:todo device · /super-bootstrap:todo harness · /super-bootstrap:todo (full board)

more: /super-bootstrap:help
```

### Cloud

```
# To-Do (Cloud) — {date}

Macro: Discuss {D} · Cloud {C} · Device {V} · Harness {H} · Full {T}

| #  | Action                                              | Progress | Impact       | Blast       |
| -- | --------------------------------------------------- | -------- | ------------ | ----------- |
| 1  | {verb + what + one-line reason}                     | {x/y|—}  | {tag}        | {tag}       |

## Uncategorized

| #  | Action                                              | Why ambiguous                                    |
| -- | --------------------------------------------------- | ------------------------------------------------ |
| 1  | {verb + what}                                       | {one-line — what signal was missing}             |

more: /super-bootstrap:help
```

Empty state:

```
# To-Do (Cloud) — {date}

Macro: Discuss {D} · Cloud 0 · Device {V} · Harness {H} · Full {T}

Nothing cloud-runnable.

Macro priors (no recommendation):
- Discuss: {top 1-3 with file + one-line reason}
- Device: {top 1-3 with file + one-line reason}
- Harness: {top 1-3 with file + one-line reason, or "0"}

Next mode: yours. /super-bootstrap:todo discuss · /super-bootstrap:todo device · /super-bootstrap:todo harness · /super-bootstrap:todo (full board)

more: /super-bootstrap:help
```

### Device

```
# To-Do (Device) — {date}

Macro: Discuss {D} · Cloud {C} · Device {V} · Harness {H} · Full {T}

| #  | Action                                              | Progress | Impact       | Blast       |
| -- | --------------------------------------------------- | -------- | ------------ | ----------- |
| 1  | {verb + what + one-line reason}                     | {x/y|—}  | {tag}        | {tag}       |

## Uncategorized

| #  | Action                                              | Why ambiguous                                    |
| -- | --------------------------------------------------- | ------------------------------------------------ |
| 1  | {verb + what}                                       | {one-line — what signal was missing}             |

more: /super-bootstrap:help
```

Empty state:

```
# To-Do (Device) — {date}

Macro: Discuss {D} · Cloud {C} · Device 0 · Harness {H} · Full {T}

Nothing device-only.

Macro priors (no recommendation):
- Cloud: {top 1-3 with file + one-line reason}
- Discuss: {top 1-3 with file + one-line reason}
- Harness: {top 1-3 with file + one-line reason, or "0"}

Next mode: yours. /super-bootstrap:todo cloud · /super-bootstrap:todo discuss · /super-bootstrap:todo harness · /super-bootstrap:todo (full board)

more: /super-bootstrap:help
```

### Harness

```
# To-Do (Harness) — {date}

Macro: Discuss {D} · Cloud {C} · Device {V} · Harness {H} · Full {T}

Engine surface — careful handle. Ground in git log + the repo's rules before editing; harness edits carry a verify pass.

## Deliberate

| #  | Action                                              | Progress | Impact       | Blast       |
| -- | --------------------------------------------------- | -------- | ------------ | ----------- |
| 1  | Deliberate: {topic + one-line reason}               | {x/y|—}  | {tag}        | {tag}       |

## Apply

| #  | Action                                              | Progress | Impact       | Blast       |
| -- | --------------------------------------------------- | -------- | ------------ | ----------- |
| 1  | Apply: {rule} → {site}                              | {x/y|—}  | {tag}        | {tag}       |

## Uncategorized

| #  | Action                                              | Why ambiguous                                    |
| -- | --------------------------------------------------- | ------------------------------------------------ |
| 1  | {verb + what}                                       | {one-line — what signal was missing}             |

more: /super-bootstrap:help
```

Empty state:

```
# To-Do (Harness) — {date}

Macro: Discuss {D} · Cloud {C} · Device {V} · Harness 0 · Full {T}

Nothing harness-pending.

Macro priors (no recommendation):
- Discuss: {top 1-3 with file + one-line reason, or "0"}
- Cloud: {top 1-3 with file + one-line reason, or "0"}
- Device: {top 1-3 with file + one-line reason, or "0"}

Next mode: yours. /super-bootstrap:todo discuss · /super-bootstrap:todo cloud · /super-bootstrap:todo device · /super-bootstrap:todo (full board)

more: /super-bootstrap:help
```

### Full

One ranked table, one row per open item, every source (cards, test queue) in the same table. No grouping, no aggregate lines — a source that collapses to a count is not flat.

Column conventions — every row fills every column; a column inapplicable to a row renders `—`:

- **#** — rank position from agent §4, `1` = top. Sequential over the whole table, never restarted.
- **Action** — the classification spec's `action` string verbatim (`Triage: {ID} {title}`, `Continue execute: {ID} {title} ({done}/{total})`, `Approve design: {ID} {title}`, `Deliberate: {topic}`, `Apply: {rule} → {site}`). It already names the ID, so Full carries no separate File column.
- **Stage** — the spec's `stage`: `raw` | `triaged` | `aimed` | `executing` | `review`.
- **Progress** — `{x}/{y}` where the card's latest Progress block reports steps done; `—` on cards without a Plan/Progress block and test-queue rows.
- **Blocker** — `user` where the row awaits a user decision, else `none`.
- **Impact** / **Blast** — per agent §3, computed on every row including backlog rows.

```
# To-Do — {date}

| #  | Action                                              | Stage    | Progress | Blocker     | Impact       | Blast       |
| -- | --------------------------------------------------- | -------- | -------- | ----------- | ------------ | ----------- |
| 1  | {action string}                                     | {stage}  | {x/y|—}  | {none|user} | {tag}        | {tag}       |

## Uncategorized

| #  | Action                                              | Why ambiguous                                    |
| -- | --------------------------------------------------- | ------------------------------------------------ |
| 1  | {verb + what}                                       | {one-line — what signal was missing}             |

{pending unblock: {n} — count of rows the agent §4 Coupling gate held out as hard-blocked; only if n>0}
{footer per § Render footer-hint}
```

No macro header for Full — full IS the macro. Harness rows render inline in rank order, their `Deliberate:` / `Apply:` prefix riding the Action string (no separate group — grouping is `harness` mode's job). No "Next up" recommendation block in any mode. Momentum-driven surfacing is **computed foregrounding** — venue grouping + fan-out rank order the board by objective leverage, no opinion prose. The bar stands on strategizing ("Best next: Y" / "Recommend X"), never on ranked ordering: surface, don't editorialize.

Footer: fill per § Render footer-hint in the todo agent (`agents/todo.md`) — canonical home.

Empty state for Full: `No active work. Ground something with /super-bootstrap:log or give me a task.`
