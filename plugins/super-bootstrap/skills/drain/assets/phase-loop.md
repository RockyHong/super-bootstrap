# Phase loop — scoped brief, drain-till-wall, status contract

Per wave member: the gateway renders one **scoped brief** from the item's card files and spawns **one** headless session that runs the item's remaining phases itself, halting at its first wall. The gateway is out of the loop between spawn and halt — no per-phase command dispatch.

## Dispatch

```
cd .claude/worktrees/drain-{id}
claude -p --model sonnet --setting-sources local,project --permission-mode acceptEdits --allowedTools "Skill,Agent" -- "<scoped brief>"
```

**`--` terminates option parsing** before the brief — `--allowedTools` is variadic and swallows a trailing prompt without it (`parallel-worktrees.md §Dispatch step`). Background (`Bash(run_in_background: true)`), notification-driven (push, not poll). Required-flags table (flag → consequence-if-missing): `parallel-worktrees.md §Required flags` — canonical, don't restate here.

### Scoped brief — anchor + breadcrumb, never payload

Rendered fresh from card files at spawn; a cold restart re-renders it — nothing lives only in the prompt:

1. **Boundary anchor** — `assets/worktree-boundary.md` embedded verbatim (the subprocess attention anchor; its own header owns the embed-at-dispatch rationale).
2. **Problem-aim** — the card's aim in one line, read from the origin + the thread's leading block.
3. **Breadcrumb** — the card path `docs/work/{ID}.md` with "read the whole thread first", the entry stage, and the Verdict tags when present. Paths, not payload — the thread is the entry doc.
4. **Work order** — the remaining chain for the item's lane + entry stage (§Lane select, §Stage entry), each phase named by the artifact it lands (§Phase → artifact). Discipline comes from the repo's own `CLAUDE.md`, which the worktree carries.
5. **Walls + exit** — the wall table (§Walls) and the status contract (§Status contract): land each artifact as a commit/block before the next segment; at a wall or ready-to-merge, write status and stop.

## Lane select (polymorphic — eng default, doc for prose-shaped items)

Two lane shapes; pick per item before rendering the work order:

| Lane | Item shape | Chain |
| ---- | ---------- | ----- |
| **eng** (default) | code-shaped — a fix/feature with a build + test surface | ground → plan → execute (TDD) → review → **merge gate (halt)** |
| **doc** (doc-hygiene) | prose-shaped — the doc edit **is** the deliverable, no build/test surface | doc-edit → review (dispatcher evaluates pre-spawn: skip if ≤1-file, grep-verifiable invariant) → **merge gate (halt)** |

**Lane derivation (file-presence + classification, no hand-maintained field):** doc lane when the item is prose-shaped — signalled by any of: the shared-classification `action` verb is `Doc-edit` / `Refine spec`; the triage Verdict block names only prose/doc surfaces (`## Files` all under `docs/**`, `*.md`, no code paths); or (scale module) the card carries `Test-feel: doc-only`. Everything else is the eng lane. In the doc lane the edit itself is the change — no separate build phase, no TDD.

## Stage entry → remaining chain (eng lane, lean default)

The work order enters at the item's `stage`; committed upstream phases are inherited from base (branched fresh) — never re-run:

| Entry `stage` | Remaining chain |
| ------------- | --------------- |
| `raw` (card, no Verdict) | ground → [wall check] → plan → execute (TDD) → review → **merge gate (halt)** |
| `triaged` (auto-fix Verdict, no Plan block) | [wall check] → plan → execute (TDD) → review → **merge gate (halt)** — ground inherited from the Verdict block |
| `aimed` (Design block, no plan) | plan → execute → review → **merge gate (halt)** |
| `executing` (Plan block in flight) | continue execute → review → **merge gate (halt)** |
| `review` (all plan steps reported done) | review → **merge gate (halt)** |

### Phase → artifact (the declared interface)

Each phase is named by what it lands, in this repo's own slots — the same slots the stage column reads by block presence (`../../shared/classify-actionable.md`). A phase with a repo door dispatches it; the rest run the discipline the worktree's `CLAUDE.md` declares.

| Phase | Lands | Door |
| ----- | ----- | ---- |
| ground | `## Verdict` block appended to `docs/work/{ID}.md` | `/super-bootstrap:triage` |
| plan | `## Plan` block appended to `docs/work/{ID}.md` — step sequence, no checkboxes | — |
| execute | code + tests; the plan's steps executed | — |
| review | findings against the branch diff | `/code-review` |
| doc-edit (doc lane) | the doc change itself | — |

## Walls — the session self-gates, typed

The session runs phase-to-phase and stops at the first wall; the wall's type rides the status (§Status contract). Admission already scored the *next* phase (`eligibility.md`), so walls here are the runtime backstop for everything downstream of it:

| Wall | Type | Fires |
| ---- | ---- | ----- |
| Ground verdict is `surface`, or auto-fix with `Fix-shape` ∉ {mechanical, systematic} — design/product judgment before build | user | after ground, before plan (the pre-build wall check) |
| Real design surface found mid-flight — needs a spec, an unresolved decision, a fork the user owns | user | any phase |
| Real external cost, user smoke test, or a harness-file deliverable discovered mid-flight | user | the phase itself |
| Security finding during review — vulnerability or irreversible-action concern | user | review phase |
| `Probe-deps` ≠ `none` — probe/tooling grant lane | shape | after ground |
| Phase needs a device-bound or unverified capability (e2e runner, browser MCP — capability unverified) | shape | the phase itself |

`Execution: phased(skip: …)` in the Verdict block → advance skipping exactly the named stages (the verdict already sized them out); `Execution: inline` never reaches here (rolled in-session per `eligibility.md §Inline / wave-of-one carve-out`).

A user wall resolves by thread append (the user's answer lands as a block); the next drain invocation re-renders the brief from the updated thread and re-spawns in the same worktree.

## Status contract

The session writes `.drain-status` at the worktree root — a single line, written **atomically** (temp file + rename), left **uncommitted** (gitignored; `ensure-infra.md` step 1):

`DONE` (ready-to-merge) · `WALL:{user|shape}:{phase} — {one-line finding}` · `BLOCKED — {why}` · `NEEDS_CONTEXT — {what}`

The gateway reads it live via `cat .claude/worktrees/drain-{id}/.drain-status` (a Bash read — exempt from the worktree Read-hook; never the `Read` tool). Source of truth; the exit code is advisory only.

| Status | Gateway action |
| ------ | -------------- |
| `DONE` | Merge gate — user inspects, `/super-bootstrap:merge` absorbs. Never auto-merge. |
| `WALL:user:*` | Surface to the user; the resolution appends to the thread; next invocation re-renders + re-spawns. |
| `WALL:shape:*` | Surface; the walled phase routes to its venue (device lane, probe grant) — the landed phases are progress. |
| `BLOCKED` / `NEEDS_CONTEXT` | Provide context or route to the user, then re-spawn with a refreshed brief. |
| absent | Halt + surface, regardless of exit code. |

**Milestone grain:** durable progress rides the thread — blocks appended + commits landed per phase — not the status file. A crashed session reconstructs from the card thread alone (state = file presence); `.drain-status` only carries the live halt signal.

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
| `WALL:user:*` — design/product judgment, security finding, cost, smoke, harness surface | §Walls (session self-gate) |
| `WALL:shape:*` — probe deps, device-bound or unverified capability | §Walls (session self-gate) |
| `BLOCKED` / `NEEDS_CONTEXT` | Any phase |
| Tests still red after the one TDD retry | Execute phase |
| Merge-probe (venue S) red → abort + re-spawn | Merge gate (`merge-probe.md`) |
| **Merge gate — never auto-merge** | Per item, success path |
| Wave dispatched → turn ends | After Shape 5 |

### Halt summary format

```
/super-bootstrap:drain halted: {reason}
Item:    {id}
Phase:   {phase name}
Branch:  {drain/{id-lower} or "not created"}
Claim:   {.claude/worktrees/drain-{id}/ or "released"}
Next:    {the one action the user takes — confirm merge / read finding / fix blocker / settle the design}
```

The merge gate's `Next` is always: inspect the branch, then run `/super-bootstrap:merge drain/{id-lower}` to absorb it.
