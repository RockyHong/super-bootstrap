# Phase loop — stage entry, status contract, halts

Per wave member: the gateway enters the item's phase chain at its `stage` (from the shared classification), runs phase-by-phase via headless subprocesses, and advances on the status the subprocess writes. Each phase:

```
cd .claude/worktrees/drain-{id}
claude -p "<phase prompt>" --setting-sources local,project --permission-mode acceptEdits --allowedTools "Skill"
```

The `<phase prompt>` is `assets/worktree-boundary.md` (embedded verbatim — the subprocess attention anchor) followed by the phase task. **Prompt is the first positional** — `--allowedTools` is variadic and swallows a trailing prompt (`parallel-worktrees.md §Dispatch step`). Embedding at dispatch is the delivery mechanism: a `.claude/worktrees/**` path-glob rule would never fire, since the subprocess's project root is the worktree and its own reads are root-relative.

Background (`Bash(run_in_background: true)`), notification-driven (push, not poll). The subprocess dispatches the right superpowers phase inside its worktree (`/brainstorm`, `/write-plan`, `/execute-plan`, review) and writes its status. `--allowedTools "Skill"` is required — without it bundled skills (`/code-review`) are permission-denied in `-p` mode and the review phase silently degrades.

## Stage entry → phase chain (polymorphic, lean default)

| Entry `stage` | Chain |
| ------------- | ----- |
| `raw` (backlog row) | triage → [escalate-or-build gate] → plan → execute (TDD) → review → **merge gate (halt)** |
| `spec` (spec, no plan) | plan → execute → review → **merge gate (halt)** |
| `plan` (executing) | continue execute → review → **merge gate (halt)** |
| `review` (all-checked) | review → **merge gate (halt)** |

Committed upstream phases are inherited from base (branched fresh) — drain never re-runs a phase already landed.

### Escalate-or-build gate (raw + spec entries)

After triage, before building: if the subprocess finds a **real design surface** — needs a spec, an unresolved decision, or a fork the user owns — it writes `DONE_WITH_CONCERNS` and **halts**. The gateway routes the item out (`/brainstorm` / `/super-bootstrap:todo discuss`), it does not build further. Lean fix-loop is the default; escalation is the exception that keeps drain from building past a design wall.

## Status contract

The subprocess writes its status to `.drain-status` at the worktree root — a single token (`DONE` / `DONE_WITH_CONCERNS` / `BLOCKED` / `NEEDS_CONTEXT`) written **atomically** (temp file + rename) and left **uncommitted**. `.drain-status` is gitignored (`ensure-infra.md` step 1 — keeps it off the branch).

The gateway reads it live from the worktree filesystem via `cat .claude/worktrees/drain-{id}/.drain-status` (a Bash read — exempt from the worktree Read-hook; never the `Read` tool). This is the source of truth; the subprocess exit code is advisory only.

| Status | Gateway action |
| ------ | -------------- |
| `DONE` | Advance to the next phase. |
| `DONE_WITH_CONCERNS` | Read the concerns; design/product → surface to user (halt); technical-only → may advance. |
| `BLOCKED` / `NEEDS_CONTEXT` | Provide context or route to user, then re-dispatch the *same* phase. |
| absent | Halt + surface, regardless of exit code. |

## Per-item tick

```
on subprocess-exit-notification(worktree):
  status = cat .claude/worktrees/drain-{id}/.drain-status   # live read (Bash) — never the Read tool
  if status advances this phase: dispatch next phase
  else:                          halt + surface (§Halts)    # absent / empty ⇒ halt
```

## Halts

`/super-bootstrap:drain` halts and surfaces when any fire:

| Condition | Where |
| --------- | ----- |
| Infra missing + user declines install | Pre-flight 0 |
| Concurrent drain worktree found | Pre-flight 1 |
| Orphan state drift | Pre-flight 2 |
| Base-sync conflict | Shape 1 |
| No eligible Cloud items | Shape 2 |
| Empty wave (all conflicting) | Shape 3 |
| User declines wave | Confirm gate |
| Design surface found (escalate) | Escalate-or-build gate |
| `BLOCKED` / `NEEDS_CONTEXT` | Any phase |
| Tests still red after the one TDD retry | Execute phase |
| Review surfaces a security touch / design concern | Review phase |
| Item needs manual / device verification | Review phase (`Device` reclassification mid-flight) |
| **Merge gate — never auto-merge** | Per item, success path |
| Wave dispatched → turn ends | After Shape 5 |

### Halt summary format

```
/super-bootstrap:drain halted: {reason}
Item:    {id}
Phase:   {phase name}
Branch:  {drain/{id-lower} or "not created"}
Claim:   {.claude/worktrees/drain-{id}/ or "released"}
Next:    {the one action the user takes — confirm merge / read concerns / fix blocker / route to /brainstorm}
```

The merge gate's `Next` is always: inspect the branch, then run `/super-bootstrap:merge drain/{id-lower}` to absorb it.
