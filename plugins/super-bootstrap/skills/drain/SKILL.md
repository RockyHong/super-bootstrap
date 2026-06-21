---
name: drain
description: "Parallel-worktree auto-drain of the board. One `/super-bootstrap:drain` turn = scan the three pipeline sources (specs/plans/backlog) → keep only Cloud-safe items → relation-analyze into a conflict-free wave → confirm with the user → spawn one isolated git worktree + headless `claude -p` per item, each resuming at its pipeline stage and running phase-by-phase to the next user wall (merge, surfaced concern, manual test), then halting. State lives in files; the next invocation cold-reads and picks the next wave. Merge is never automatic — it delegates to `/super-bootstrap:merge`. Sub-verbs: `status`, `release {id}`, `--dry-run`. Manual invocation only."
disable-model-invocation: true
tags: [drain, worktree, parallel, pipeline, superpowers]
---

# drain — Parallel-Worktree Auto-Drain

One wave per invocation over the board. Scan → Cloud-gate → wave-select → confirm → spawn one isolated subprocess per item → each halts at a user wall. The orchestrator (gateway) holds no in-head state; every tick re-reads from files. Capacity ceiling = how many halts the user can resolve, not machine throughput.

**Consumer contract:** assumes the super-bootstrap harness shape — `docs/backlog.md`, `docs/superpowers/specs|plans/`, `/super-bootstrap:merge`, `/super-bootstrap:commit`. Not portable below that line. First run self-installs the worktree infra (§Pre-flight step 0).

Trigger: user types `/super-bootstrap:drain`. Never auto-fires.

## Invariants

- **One wave, one shot per invocation.** No internal loop across waves, no `--all`. Turn ends after the wave is dispatched. Next invocation cold-reads files and re-picks.
- **No auto-merge — ever.** Each subprocess stops at a ready-to-merge state. The user confirms; the merge runs via `/super-bootstrap:merge` (the destructive-git lane). Subprocesses are denied push/merge/rebase/branch-delete/worktree at the permission layer.
- **Cloud-gate, not type-gate.** Eligible = item classifies `Cloud` (cloud-safe), across BUG/DEBT/GAP and across specs/plans. `Device`/`Discuss` items defer — drain never spawns for them. A mislabel is fixed upstream (clarify the row, or the shared criterion), never overridden here.
- **Stage-resume.** Each item enters its phase chain at its current pipeline stage (file presence): `raw`→triage, `spec`→plan, `plan`→execute, `review`→review. Committed upstream phases are inherited, not re-run.
- **Halts are outcomes.** A wall surfaces a finding; that finding plus any committed earlier phases are progress, not waste.
- **Wave member = no blocker.** Orphans + chain-heads enter; chain-tails and conflicts defer to a later invocation. No forward projection — render the current wave only.

## Pre-flight

Run in order; any HALT exits the turn with a §Halt summary.

0. **Ensure infra (idempotent).** Confirm the worktree infra is installed in this repo; install if missing. Procedure + file list: `assets/ensure-infra.md`. First run surfaces a one-time confirm; subsequent runs pass silently when present.
1. **Concurrent-drain check.** `Grep`/`Glob` for `.claude/worktrees/drain-*/OWNED_BY`. Found → surface count + IDs + each worktree's stage; HALT. User merges in-flight branches (`/super-bootstrap:merge`) or `/super-bootstrap:drain release {id}` per abandoned worktree, then re-fires.
2. **Orphan check.** Any `drain-{id}` worktree dir without a matching open item, or vice-versa → state drift; HALT + surface for repair (gateway, not auto-fix).

## Shape

1. **Sync base.** Fast-forward / rebase the base branch (`git fetch` + `git rebase origin/{base}`) so worktrees branch from current head. Conflict → surface + exit.
2. **Scan + classify.** Read `docs/superpowers/specs/*.md`, `docs/superpowers/plans/*.md`, `docs/backlog.md`; derive each item's `{action, intent, stage}` per the **shared classification spec** (`../../shared/classify-actionable.md` — embed verbatim, do not paraphrase). Then apply `assets/eligibility.md` to keep only the drain-eligible Cloud items.
3. **Relation analysis + wave selection.** `assets/relations.md`. Output: current wave (disjoint orphans + chain-heads). Tails and conflicts defer.
4. **Confirm gate.** §Confirm gate. Decline = clean exit — no worktrees, no claims.
5. **Spawn.** One subprocess per wave member — `assets/ensure-infra.md` (warm) → §Phase loop. Background dispatch; notification-driven.
6. **Turn ends** after the wave is dispatched. User resolves walls; next invocation cold-reads and picks the next wave.

## Eligibility

`Cloud`-gate + drain-domain filter. Full predicate: `assets/eligibility.md`. Summary: item is eligible when `intent == Cloud`, it is not already claimed (no `drain-{id}` worktree) and not on an existing unmerged branch, and it carries no unresolved decision. `Device`/`Discuss` defer; foreign-prefix backlog rows route to `/super-bootstrap:log`.

## Confirm gate

Render the current wave only — no future-wave preview, no deferred list:

```
/super-bootstrap:drain wave over {N} items.
Wave:
  {id}  {stage}  {one-line action}
  ...
OK to dispatch? [y/N]
```

Accept → §Worktree warm. Decline → clean exit (zero side effects).

## Worktree warm + claim

Atomic `mkdir .claude/worktrees/drain-{id}/` is the claim (first mkdir wins). `OWNED_BY` follows immediately. Branch: `drain/{id-lower}` (e.g. `drain/bug-12`). Full warm procedure (worktree add, settings copy, marker, dependency provisioning) + the hard-FS-boundary mechanism: `assets/parallel-worktrees.md`.

## Read discipline (gateway-side)

Never `Read` a path under `.claude/worktrees/{id}/` — a worktree-internal Read re-injects that worktree's nested CLAUDE.md + rules per file and blows the context budget. Use the read-around paths (`git show {branch}:<path>` for committed state, `Grep`/`Glob`/`git status` for markers, background task-output for subprocess return). Mechanically backed by the `PreToolUse(Read)` hook installed at §Pre-flight step 0. Table + mechanism: `assets/parallel-worktrees.md §Read discipline`.

## Phase loop

Per item: enter at the item's `stage` (§Invariants stage-resume), run phase-by-phase until a user wall. Each phase = one headless subprocess from the worktree cwd:

```
cd .claude/worktrees/drain-{id}
claude -p --setting-sources local,project --permission-mode acceptEdits --allowedTools "Skill" "<phase prompt>"
```

Dispatched `Bash(run_in_background: true)`. Phase chain, stage-entry map, status contract (`DONE` / `DONE_WITH_CONCERNS` / `BLOCKED` / `NEEDS_CONTEXT`), and the polymorphic escalate-or-build branch: `assets/phase-loop.md`.

**Polymorphic depth (locked).** Lean by default — triage → implement (TDD) → review → halt at merge. If a subprocess discovers a real design surface (needs spec / a decision), it halts and the item routes out to brainstorming rather than building further.

## Merge gate

A subprocess builds, tests, and reviews inside its worktree, then halts at ready-to-merge (the no-auto-merge invariant). The user inspects and confirms; the merge runs via **`/super-bootstrap:merge`** — the orchestrator-exclusive destructive-git lane (per-branch rebase/merge recommendation, conflict doctrine, push-on-confirm). drain does not re-implement merge; it hands off the branch.

## Halt points

Full halt table + the §Halt summary format: `assets/phase-loop.md §Halts`.

## Crash recovery

1. Committed `tasks.md` / status is the source of truth (read via `git show {branch}:<path>`, never worktree-internal `Read`). Subprocess exit code is advisory only.
2. **Status set ⇒ advance; status absent ⇒ halt + surface**, regardless of exit code. Diagnose a halted worktree via `git -C .claude/worktrees/{id} status|diff|log`, never the `Read` tool.
3. No phase-level auto-retry beyond the one TDD retry inside the build phase.

## Sub-verbs

- **`/super-bootstrap:drain status`** — list in-flight drain worktrees with stage + age + branch. Read-only.
- **`/super-bootstrap:drain release {id}`** — manual unclaim of a crashed/abandoned worktree (gateway-only teardown, platform-safe path in `assets/parallel-worktrees.md §Cleanup`).
- **`/super-bootstrap:drain --dry-run`** — scan + classify + relation-analysis + wave render, then exit before the confirm gate. No claims, no dispatch.

## Rules

- **Inline orchestrator.** Gateway reasoning owns the user thread, the wave loop, the halts; do not spawn a subagent for the orchestration itself.
- **State = file presence.** Worktree dir + `OWNED_BY` + committed status. Every tick re-reads; survives `/clear`, crash, multi-session.
- **Destructive git is one lane.** Only the gateway merges / pushes / removes worktrees / deletes branches, always behind a user prompt. Subprocesses hand off via status.
- **No forward projection.** Confirm gate and `--dry-run` render the current wave only.
