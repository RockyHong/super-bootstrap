# Phase loop — stage entry, status contract, halts

Per wave member: the gateway enters the item's phase chain at its `stage` (from the shared classification), runs phase-by-phase via headless subprocesses, and advances on the status the subprocess writes. Each phase:

```
cd .claude/worktrees/drain-{id}
claude -p --model sonnet --setting-sources local,project --permission-mode acceptEdits --allowedTools "Skill,Agent" -- "<phase prompt>"
```

The `<phase prompt>` is `assets/worktree-boundary.md` (embedded verbatim — the subprocess attention anchor) followed by the phase task. **`--` terminates option parsing** before the prompt — `--allowedTools` is variadic and swallows a trailing prompt without it (`parallel-worktrees.md §Dispatch step`). Embedding at dispatch is the delivery mechanism: a `.claude/worktrees/**` path-glob rule would never fire, since the subprocess's project root is the worktree and its own reads are root-relative.

Background (`Bash(run_in_background: true)`), notification-driven (push, not poll). The phase task names its **artifact transition** — what the phase produces and where it lands (§Phase → artifact) — and the discipline it runs under comes from the repo's own `CLAUDE.md`, which the worktree carries. The subprocess then writes its status. Required-flags table (flag → consequence-if-missing, includes `--model` and `--allowedTools`): `parallel-worktrees.md §Required flags` — canonical, don't restate here.

## Lane select (polymorphic — eng default, doc for prose-shaped items)

Two lane shapes; pick per item before entering the stage chain:

| Lane | Item shape | Chain |
| ---- | ---------- | ----- |
| **eng** (default) | code-shaped — a fix/feature with a build + test surface | triage → [escalate-or-build gate] → plan → execute (TDD) → review → **merge gate (halt)** |
| **doc** (doc-hygiene) | prose-shaped — the doc edit **is** the deliverable, no build/test surface | doc-edit → review (dispatcher evaluates pre-spawn: skip if ≤1-file, grep-verifiable invariant) → **merge gate (halt)** |

**Lane derivation (file-presence + classification, no hand-maintained field):** doc lane when the item is prose-shaped — signalled by any of: the shared-classification `action` verb is `Doc-edit` / `Refine spec`; the triage Verdict block names only prose/doc surfaces (`## Files` all under `docs/**`, `*.md`, no code paths); or (scale module) the card carries `Test-feel: doc-only`. Everything else is the eng lane. In the doc lane the edit itself is the change — there is no separate build phase and no TDD; the dispatcher evaluates pre-spawn: review is spawned only when the edit is not a trivial grep-checkable invariant.

## Stage entry → phase chain (eng lane, lean default)

| Entry `stage` | Chain |
| ------------- | ----- |
| `raw` (card, no Verdict) | triage → [escalate-or-build gate] → [pre-plan confirm gate] → plan → execute (TDD) → review → **merge gate (halt)** |
| `triaged` (auto-fix Verdict, no Plan block) | [pre-plan confirm gate] → plan → execute (TDD) → review → **merge gate (halt)** — triage inherited from the Verdict block, never re-run |
| `aimed` (Design block, no plan) | plan → execute → review → **merge gate (halt)** |
| `executing` (Plan block in flight) | continue execute → review → **merge gate (halt)** |
| `review` (all plan steps reported done) | review → **merge gate (halt)** |

Committed upstream phases are inherited from base (branched fresh) — drain never re-runs a phase already landed.

### Phase → artifact (the declared interface)

Each phase is named by what it lands, in this repo's own slots — the same slots the stage column above reads by file presence (`../../shared/classify-actionable.md`). A phase with a repo door dispatches it; the rest run the discipline the worktree's `CLAUDE.md` declares.

| Phase | Lands | Door |
| ----- | ----- | ---- |
| triage | `## Verdict` block appended to `docs/work/{ID}.md` | `/super-bootstrap:triage` |
| plan | `## Plan` block appended to `docs/work/{ID}.md` — step sequence, no checkboxes | — |
| execute | code + tests; the plan's steps executed | — |
| review | findings against the branch diff | `/code-review` |
| doc-edit (doc lane) | the doc change itself | — |

### Escalate-or-build gate (raw + aimed entries)

After triage, before building: if the subprocess finds a **real design surface** — needs a spec, an unresolved decision, or a fork the user owns — it writes `DONE_WITH_CONCERNS` and **halts**. The gateway surfaces it and the item leaves the drain lane — design-settling is a user wall; the item re-enters the board via `/super-bootstrap:todo discuss`. drain does not build further. Lean fix-loop is the default; escalation is the exception that keeps drain from building past a design wall.

### Pre-plan confirm gate (raw + triaged entries)

A gateway-side gate on the triage verdict, before the plan/build fan-out — the runtime backstop for the venue-**P** wall (admission scored the *next* phase, so a build phase that resolves to a probe/stochastic venue is caught here) plus fix-shape branching. Read the Verdict block header tags from `docs/work/{ID}.md` (`triage` agent §Verdict block schema — drain reads, never redefines):

```
on triage-phase complete (auto-fix verdict), or on entry with stage=triaged before plan:
  fix_shape  = scope_header("Fix-shape")     # mechanical | systematic | design | prompt | product | ambiguous
  probe_deps = scope_header("Probe-deps")    # labels, comma-listed | none

  if probe_deps != "none":
    halt + surface   # next-phase venue P — probe/tooling grant lane, not a wave-runner
  elif fix_shape in {mechanical, systematic}:
    advance to execute (skip plan)            # deterministic — plan carries nothing new
  else:                                        # design | prompt | product | ambiguous
    halt + surface   "fix-shape {fix_shape} needs user confirm before build"
```

- `Execution: phased(skip: …)` in the Verdict block — advance skipping exactly the named stages (the triage verdict already sized them out); `Execution: inline` never reaches here (it rolled in-session at `eligibility.md §Inline / wave-of-one carve-out`).
- The gate is the pre-fan-out user wall: deterministic, self-contained fixes flow straight through; anything carrying a design/product judgment or a probe dependency halts for the user before drain spends the build.

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
| No eligible items | Shape 2 |
| Item whose next phase is a wall (venue U/P, or `Device`/`Discuss`) | Shape 2 (skip & surface) |
| Empty wave (all conflicting) | Shape 3 |
| User declines wave | Confirm gate |
| Design surface found (escalate) | Escalate-or-build gate |
| `Probe-deps` non-`none` → venue P | Pre-plan confirm gate |
| Fix-shape ∉ {mechanical, systematic} | Pre-plan confirm gate |
| `BLOCKED` / `NEEDS_CONTEXT` | Any phase |
| Tests still red after the one TDD retry | Execute phase |
| Review surfaces a security touch / design concern | Review phase |
| Item needs manual / device verification | Review phase (`Device`/venue-U reclassification mid-flight) |
| Merge-probe (venue S) red → abort + re-dispatch | Merge gate (`merge-probe.md`) |
| **Merge gate — never auto-merge** | Per item, success path |
| Wave dispatched → turn ends | After Shape 5 |

### Halt summary format

```
/super-bootstrap:drain halted: {reason}
Item:    {id}
Phase:   {phase name}
Branch:  {drain/{id-lower} or "not created"}
Claim:   {.claude/worktrees/drain-{id}/ or "released"}
Next:    {the one action the user takes — confirm merge / read concerns / fix blocker / settle the design}
```

The merge gate's `Next` is always: inspect the branch, then run `/super-bootstrap:merge drain/{id-lower}` to absorb it.
