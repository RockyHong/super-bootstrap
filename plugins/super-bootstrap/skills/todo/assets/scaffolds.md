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
| 1  | Deliberate: {topic} / Apply: {rule}→{site} | {n}   | {tag}        | {tag}       |

## Probe / grant

| #  | Action                                  | unblocks | Impact       | Blast       |
| -- | ---------------------------------------- | -------- | ------------ | ----------- |
| 1  | {verb + what + one-line reason}         | {n}      | {tag}        | {tag}       |

## Uncategorized

| #  | Action                                  | Why ambiguous                          |
| -- | ---------------------------------------- | --------------------------------------- |
| 1  | {verb + what}                           | {one-line — what signal was missing}   |

{pending unblock: {n} — only if n>0}
flat list: /super-bootstrap:todo full · drainable detail: /super-bootstrap:todo cloud
more: /super-bootstrap:help
```

Empty state (no need-me rows AND no drainable):

```
# To-Do — {date}

No active work. Start something with /brainstorm or give me a task.
```

Empty need-me but drainable pending:

```
# To-Do — {date}

Drainable: {N}  →  /super-bootstrap:drain

Nothing needs you right now — the board is all auto-runnable.

flat list: /super-bootstrap:todo full
more: /super-bootstrap:help
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

```
# To-Do — {date}

| File                                  | Stage         | Progress | Blocker          | Impact       | Blast       |
| ------------------------------------- | ------------- | -------- | ---------------- | ------------ | ----------- |
| specs/{date}-{slug}.md                | {stage}       | {x/y|—}  | {none|user|...}  | {tag}        | {tag}       |
| plans/{date}-{slug}.md                | {stage}       | {x/y|—}  | {none|user|...}  | {tag}        | {tag}       |

{Backlog: N BUG, M DEBT, K GAP open (see docs/backlog.md) — only if backlog.md exists}

## Uncategorized

| #  | File                                                | Why ambiguous                                    |
| -- | --------------------------------------------------- | ------------------------------------------------ |
| 1  | {file}                                              | {one-line}                                       |

{pending unblock: {n} — only if n>0}
{footer per § Render footer-hint}
```

No macro header for Full — full IS the macro. Harness-intent spec/plan files render as normal Full rows with no `Deliberate:`/`Apply:` prefix (no column carries it — the Stage/Impact/Blast cells carry the signal); harness backlog rows ride the backlog count line. No "Next up" recommendation block in any mode. Momentum-driven surfacing is **computed foregrounding** — venue grouping + fan-out rank order the board by objective leverage, no opinion prose. The bar stands on strategizing ("Best next: Y" / "Recommend X"), never on ranked ordering: surface, don't editorialize.

Footer: fill per § Render footer-hint in the todo agent (`agents/todo.md`) — canonical home.

Empty state for Full: `No active work. Start something with /brainstorm or give me a task.`
