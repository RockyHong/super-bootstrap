## Scaffolds

Date placeholder `{date}` = today's date in YYYY-MM-DD form. Agent fills it.

**Macro header** (sub-verb modes only — discuss / cloud / device): single line right under title showing cross-mode counts. Always emit even when current mode is non-empty (free — agent classified all rows pre-filter). Format:

```
Macro: Discuss {D} · Cloud {C} · Device {V} · Full {T}
```

Counts only — no IDs, no impact tags. Decision-is-yours; surface priors not calls. Full mode skips this header (full body IS the macro).

### Discuss

```
# To-Do (Discuss) — {date}

Macro: Discuss {D} · Cloud {C} · Device {V} · Full {T}

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

Macro: Discuss 0 · Cloud {C} · Device {V} · Full {T}

Nothing to decide.

Macro priors (no recommendation):
- Cloud: {top 1-3 with file + one-line reason}
- Device: {top 1-3 with file + one-line reason, or "0"}

Next mode: yours. /super-bootstrap:todo cloud · /super-bootstrap:todo device · /super-bootstrap:todo (full board)

more: /super-bootstrap:help
```

### Cloud

```
# To-Do (Cloud) — {date}

Macro: Discuss {D} · Cloud {C} · Device {V} · Full {T}

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

Macro: Discuss {D} · Cloud 0 · Device {V} · Full {T}

Nothing cloud-runnable.

Macro priors (no recommendation):
- Discuss: {top 1-3 with file + one-line reason}
- Device: {top 1-3 with file + one-line reason}

Next mode: yours. /super-bootstrap:todo discuss · /super-bootstrap:todo device · /super-bootstrap:todo (full board)

more: /super-bootstrap:help
```

### Device

```
# To-Do (Device) — {date}

Macro: Discuss {D} · Cloud {C} · Device {V} · Full {T}

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

Macro: Discuss {D} · Cloud {C} · Device 0 · Full {T}

Nothing device-only.

Macro priors (no recommendation):
- Cloud: {top 1-3 with file + one-line reason}
- Discuss: {top 1-3 with file + one-line reason}

Next mode: yours. /super-bootstrap:todo cloud · /super-bootstrap:todo discuss · /super-bootstrap:todo (full board)

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

No macro header for Full — full IS the macro. No "Next up" recommendation block in any mode (solo-dev momentum-driven; user picks from list, system doesn't strategize).

Footer: fill per § Render footer-hint in the todo agent (`agents/todo.md`) — canonical home.

Empty state for Full: `No active work. Start something with /brainstorm or give me a task.`
