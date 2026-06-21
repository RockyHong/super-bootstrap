# Eligibility — drain wave admission

Called from `SKILL.md §Shape` step 2, after the shared classification (`../../shared/classify-actionable.md`) has produced `{action, intent, stage}` for every open item across specs/plans/backlog.

The gate is `intent == Cloud` plus claim-freedom. Type (BUG/DEBT/GAP) is **not** a gate — a clear GAP that classifies `Cloud` drains; a `Device` BUG does not.

```
isEligible(item):
  if item.intent != "Cloud":              return false, "Device/Discuss — defers, not a wave member"
  if item.stage == "done":                return false, "cleanup-only — not drain work"
  if claimed(item):                       return false, "already in flight"   # .claude/worktrees/drain-{id}/ exists
  if onUnmergedBranch(item):              return false, "work already on an unmerged branch — no double-claim"
  if item.uncategorized:                  return false, "foreign prefix — route to /super-bootstrap:log"
  return true, "eligible"
```

- `claimed(item)` — a `drain-{id}` worktree dir exists (`Grep`/`Glob` on `OWNED_BY`). Read-around discipline: never `Read` inside the worktree.
- `onUnmergedBranch(item)` — `git branch --no-merged {base}` names a branch for this item (e.g. an in-flight `drain/{id-lower}` or a manual feature branch). Excludes it so drain never branches a second worktree over live work.

## Mislabel is fixed upstream, not overridden here

A `Device`/`Discuss` verdict you disagree with is an upstream signal problem: the item's row content (Problem/Area) or the shared `cloud-safe criterion` drove it. Fix it there — clarify the row so it re-classifies, or refine the criterion — then drain re-evaluates cold on the next invocation. drain consumes the classification; it does not carry an override path (SoC: the gate stays on one side of the pipeline boundary).

## Runtime walls are the backstop

The gate is a cheap pre-filter on the *known* — it never spawns for an already-`Device` item. An item that passes (`Cloud`) but turns out mid-flight to need a human still halts at its wall (`SKILL.md §Phase loop`, `phase-loop.md §Halts`). That halt is an outcome, not a waste — the surfaced finding plus any committed earlier phases are progress.
