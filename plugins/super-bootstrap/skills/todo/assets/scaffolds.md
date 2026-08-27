## Scaffolds

Date placeholder `{date}` = today's date in YYYY-MM-DD form. Agent fills it.

**Macro header** (sub-verb modes only — discuss / cloud / device / harness): single line right under title showing cross-mode counts. Always emit even when current mode is non-empty (free — agent classified every row before filtering). Counts are **body rows only** — rows the coupling gate held as hard-blocked are excluded, so each count equals the rows that mode's board renders; the footer `pending unblock` line carries the held ones. Format:

```
Macro: Discuss {D} · Cloud {C} · Device {V} · Harness {H} · Full {T}
```

Counts only — no IDs, no impact tags. Decision-is-yours; surface priors not calls. Full mode skips this header (full body IS the macro).

**Sheet columns** — every board table opens with an **Action** cell cut to the budget below, and all but Uncategorized also carry an **ID** ahead of it, so a row fits one terminal line; the card holds the rest:

- **ID** — the row's handle: the owning card's ID (whether or not the action string carries it — `Deliberate:` / `Apply:` rows included), the outward entry's `OUT-###`, `—` for a test-queue row.
- **Action** — the classification spec's `action` string with its ID token (if any) lifted into the ID column, then hard-cut so the cell is at most 60 characters, the 60th being `…` (59 kept + `…`; no word-boundary search). Shapes, e.g.: `Triage: {title}`, `Approve design: {title}`, `Start execute: {title}`, `Continue execute: {title} ({done}/{total})`, `Decide: {title} — triage verdict`, `Manually verify: {entry title}`, `Outward: {summary} — {next move} · waiting on {party}`, `Deliberate: {topic}`, `Apply: {rule} → {site}`.

The Uncategorized table carries no **ID**: its **Action** is the file name — or the condition label for the substrate row — hard-cut the same way, and its **Why ambiguous** is a one-line pointer or missing-signal within the same 60-character budget (literals in `shared/classify-actionable.md` § a and the todo agent's stale-scaffold rule).

### Need-me (default — bare `/super-bootstrap:todo`)

Drainable rows collapse to the count line; the six need-me groups render as
tables. Omit any group whose row count is zero (drop its heading too). Groups
render in this fixed order.

```
# To-Do — {date}

Drainable: {N}  →  /super-bootstrap:drain

▸ Need me

## Decide / approve

| #  | ID      | Action                                  | unblocks | Impact       | Blast       |
| -- | ------- | ---------------------------------------- | -------- | ------------ | ----------- |
| 1  | {ID}    | {verb + what + one-line reason}         | {n}      | {tag}        | {tag}       |

## Outward — your move

| #  | ID      | Action                                  | unblocks | Impact       | Blast       |
| -- | ------- | ---------------------------------------- | -------- | ------------ | ----------- |
| 1  | {ID}    | Outward: {summary} — {next move} · waiting on author | {n} | quick-pop | —           |

## Outward — waiting on others

| #  | ID      | Action                                  | unblocks | Impact       | Blast       |
| -- | ------- | ---------------------------------------- | -------- | ------------ | ----------- |
| 1  | {ID}    | Outward: {summary} — {next move} · waiting on {party} | {n} | quick-pop | —           |

## Device-bound

| #  | ID      | Action                                  | unblocks | Impact       | Blast       |
| -- | ------- | ---------------------------------------- | -------- | ------------ | ----------- |
| 1  | {ID}    | {verb + what + one-line reason}         | {n}      | {tag}        | {tag}       |

## Harness

| #  | ID      | Action                                  | unblocks | Impact       | Blast       |
| -- | ------- | ---------------------------------------- | -------- | ------------ | ----------- |
| 1  | {ID}    | Deliberate: {topic} / Apply: {rule}→{site} | {n} | {tag}        | {tag}       |

## Probe / grant

| #  | ID      | Action                                  | unblocks | Impact       | Blast       |
| -- | ------- | ---------------------------------------- | -------- | ------------ | ----------- |
| 1  | {ID}    | {verb + what + one-line reason}         | {n}      | {tag}        | {tag}       |

## Uncategorized

| #  | Action                                  | Why ambiguous                          |
| -- | ---------------------------------------- | --------------------------------------- |
| 1  | {file name or condition}                | {one-line — pointer or missing signal} |

{pending unblock: {n} — only if n>0}
{footer per § Render footer-hint}
```

Empty state (no need-me rows AND no drainable AND nothing held by the coupling gate — a held row keeps the board on the drainable-pending shape below, with its `pending unblock` count):

```
# To-Do — {date}

No active work. Ground something with /super-bootstrap:log or give me a task.
```

Empty need-me but drainable pending:

```
# To-Do — {date}

Drainable: {N}  →  /super-bootstrap:drain

Nothing needs you right now — the board is all auto-runnable.

{pending unblock: {n} — only if n>0}
{footer per § Render footer-hint}
```

### Discuss

```
# To-Do (Discuss) — {date}

Macro: Discuss {D} · Cloud {C} · Device {V} · Harness {H} · Full {T}

| #  | ID      | Action                                              | Impact       | Context                                              |
| -- | ------- | --------------------------------------------------- | ------------ | ---------------------------------------------------- |
| 1  | {ID}    | {action — one sentence}                             | {tag}        | {one-line — why open, what unblocks}                 |

## Uncategorized

| #  | Action                                              | Why ambiguous                                    |
| -- | --------------------------------------------------- | ------------------------------------------------ |
| 1  | {file name or condition}                            | {one-line — pointer or missing signal}           |

{pending unblock: {n} — only if n>0}
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

{pending unblock: {n} — only if n>0}
more: /super-bootstrap:help
```

### Cloud

```
# To-Do (Cloud) — {date}

Macro: Discuss {D} · Cloud {C} · Device {V} · Harness {H} · Full {T}

| #  | ID      | Action                                              | Progress | Impact       | Blast       |
| -- | ------- | --------------------------------------------------- | -------- | ------------ | ----------- |
| 1  | {ID}    | {verb + what + one-line reason}                     | {x/y|—}  | {tag}        | {tag}       |

## Uncategorized

| #  | Action                                              | Why ambiguous                                    |
| -- | --------------------------------------------------- | ------------------------------------------------ |
| 1  | {file name or condition}                            | {one-line — pointer or missing signal}           |

{pending unblock: {n} — only if n>0}
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

{pending unblock: {n} — only if n>0}
more: /super-bootstrap:help
```

### Device

```
# To-Do (Device) — {date}

Macro: Discuss {D} · Cloud {C} · Device {V} · Harness {H} · Full {T}

| #  | ID      | Action                                              | Progress | Impact       | Blast       |
| -- | ------- | --------------------------------------------------- | -------- | ------------ | ----------- |
| 1  | {ID}    | {verb + what + one-line reason}                     | {x/y|—}  | {tag}        | {tag}       |

## Uncategorized

| #  | Action                                              | Why ambiguous                                    |
| -- | --------------------------------------------------- | ------------------------------------------------ |
| 1  | {file name or condition}                            | {one-line — pointer or missing signal}           |

{pending unblock: {n} — only if n>0}
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

{pending unblock: {n} — only if n>0}
more: /super-bootstrap:help
```

### Harness

```
# To-Do (Harness) — {date}

Macro: Discuss {D} · Cloud {C} · Device {V} · Harness {H} · Full {T}

Engine surface — careful handle. Ground in git log + the repo's rules before editing; harness edits carry a verify pass.

## Deliberate

| #  | ID      | Action                                              | Progress | Impact       | Blast       |
| -- | ------- | --------------------------------------------------- | -------- | ------------ | ----------- |
| 1  | {ID}    | Deliberate: {topic + one-line reason}               | {x/y|—}  | {tag}        | {tag}       |

## Apply

| #  | ID      | Action                                              | Progress | Impact       | Blast       |
| -- | ------- | --------------------------------------------------- | -------- | ------------ | ----------- |
| 1  | {ID}    | Apply: {rule} → {site}                              | {x/y|—}  | {tag}        | {tag}       |

## Uncategorized

| #  | Action                                              | Why ambiguous                                    |
| -- | --------------------------------------------------- | ------------------------------------------------ |
| 1  | {file name or condition}                            | {one-line — pointer or missing signal}           |

{pending unblock: {n} — only if n>0}
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

{pending unblock: {n} — only if n>0}
more: /super-bootstrap:help
```

### Full

One ranked table, one row per open item, every source (cards, test queue, outward file) in the same table. No grouping, no aggregate lines — a source that collapses to a count is not flat.

Column conventions — every row fills every column; a column inapplicable to a row renders `—`:

- **#** — rank position from agent §4, `1` = top. Sequential over the whole table, never restarted.
- **ID** / **Action** — per § Sheet columns above.
- **Stage** — the spec's `stage`: `raw` | `triaged` | `aimed` | `executing` | `review`.
- **Progress** — `{x}/{y}` where the card's latest Progress block reports steps done; `—` on cards without a Plan/Progress block, test-queue rows, and outward rows.
- **Blocker** — `user` where the row awaits a user decision — a fork to rule, or an external wait only the user can chase or drop — else `none`.
- **Impact** / **Blast** — per agent §3, computed on every row including backlog rows.

```
# To-Do — {date}

| #  | ID      | Action                                              | Stage    | Progress | Blocker     | Impact       | Blast       |
| -- | ------- | --------------------------------------------------- | -------- | -------- | ----------- | ------------ | ----------- |
| 1  | {ID}    | {action string}                                     | {stage}  | {x/y|—}  | {none|user} | {tag}        | {tag}       |

## Uncategorized

| #  | Action                                              | Why ambiguous                                    |
| -- | --------------------------------------------------- | ------------------------------------------------ |
| 1  | {file name or condition}                            | {one-line — pointer or missing signal}           |

{pending unblock: {n} — count of rows the agent §4 Coupling gate held out as hard-blocked; only if n>0}
{footer per § Render footer-hint}
```

No macro header for Full — full IS the macro. Harness rows render inline in rank order, their `Deliberate:` / `Apply:` prefix riding the Action string (no separate group — grouping is `harness` mode's job). No "Next up" recommendation block in any mode. Momentum-driven surfacing is **computed foregrounding** — venue grouping + fan-out rank order the board by objective leverage, no opinion prose. The bar stands on strategizing ("Best next: Y" / "Recommend X"), never on ranked ordering: surface, don't editorialize.

Footer: fill per § Render footer-hint in the todo agent (`agents/todo.md`) — canonical home.

Empty state for Full: `No active work. Ground something with /super-bootstrap:log or give me a task.`
