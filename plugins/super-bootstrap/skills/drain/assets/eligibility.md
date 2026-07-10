# Eligibility — drain wave admission

Called from `SKILL.md §Shape` step 2, after the shared classification (`../../shared/classify-actionable.md`) has produced `{action, intent, stage}` for every open item across specs/plans/backlog, plus the test queue when present.

Admission has two layers: **lane guards** (venue-independent — claim-freedom, harness exclusion) always apply, then an **admission gate** that is venue-keyed when the scale module is wired and Cloud-keyed otherwise. Type (BUG/DEBT/GAP) is **never** a gate — a clear GAP that admits drains; a device-bound BUG does not.

## isEligible

```
isEligible(item):
  # --- Lane guards (always apply, independent of the admission gate) ---
  if item.intent == "Harness":  return false, "Harness — orchestration engine, never drains"
  if item.stage == "done":      return false, "cleanup-only — not drain work"
  if claimed(item):             return false, "already in flight"                 # .claude/worktrees/drain-{id}/ exists
  if onUnmergedBranch(item):    return false, "work already on an unmerged branch — no double-claim"
  if item.uncategorized:        return false, "foreign prefix — route to /super-bootstrap:log"

  # --- Admission gate ---
  if exists(".claude/rules/venue-map.md"):            # scale module wired
    venue = nextPhaseVenue(item)                       # T | S | U | P
    if venue in {U, P}:  return false, "next phase is a wall/exclusion (venue " + venue + ") — skip & surface"
    return true, "eligible (venue " + venue + ")"      # T = in-worktree; S = gateway merge-probe (`merge-probe.md`)
  else:                                                # no venue map — fall back to the Cloud-gate
    if item.intent != "Cloud":  return false, "not cloud-safe (Device/Discuss) — defers"
    return true, "eligible (Cloud-gate — no venue map)"
```

- `claimed(item)` — a `drain-{id}` worktree dir exists (`Grep`/`Glob` on `OWNED_BY`). Read-around discipline: never `Read` inside the worktree.
- `onUnmergedBranch(item)` — `git branch --no-merged {base}` names a branch for this item (e.g. an in-flight `drain/{id-lower}` or a manual feature branch). Excludes it so drain never branches a second worktree over live work.
- `item.intent == "Harness"` — the harness layer is the orchestration engine; it never rides the autonomous queue (`../../shared/classify-actionable.md §Harness pre-filter`). Harness rows are excluded in both the venue and the Cloud-gate paths — they route to `/super-bootstrap:todo`'s harness lane, never drain.

## Admission gate — venue when wired, Cloud-gate when not

The plugin's baseline gate is `intent == Cloud` (cloud-safe: phase produces a verifiable artifact via tooling alone). The scale module refines it: `.claude/rules/venue-map.md` maps each phase to a **run-location venue** (T/S/U/P), and drain reads the item's **next-phase** venue.

| Layer | Detect | Gate |
| ----- | ------ | ---- |
| **Venue (scale module wired)** | `.claude/rules/venue-map.md` present | Next-phase venue ∈ {T, S} admits — **T** = in-worktree headless, **S** = gateway merge-probe (`merge-probe.md`). Venue ∈ {U, P} → skip & surface (the phase self-judges "I am the wall"): **U** = user-walled, **P** = probe/stochastic. |
| **Cloud-gate (fallback)** | no `.claude/rules/venue-map.md` | `intent == Cloud` admits; `Device`/`Discuss` defer. The plugin's original predicate, unchanged. |

- `nextPhaseVenue(item)` resolves the item's next phase from its `stage` and reads that phase's venue — canonical in `.claude/rules/venue-map.md` (`§Derivation`, `§Modality overrides`). drain **consumes** the map; it never re-derives venue by hand.
- **Graceful degrade is a file-presence branch, not a code path fork.** Without the venue map, `T ≈ Cloud` (drainable in-worktree) and the `S`/`U`/`P` refinements collapse: an e2e item that the venue map would call **S** classifies `Device` under the bare cloud-safe criterion and defers, and a manual-verify item that would be **U** likewise. The consumer without the scale module gets exactly the plugin's prior behavior; the consumer with it gets the merge-probe (S) lane on top.

## Inline / wave-of-one carve-out (skip the worktree)

Worktree isolation earns its cost only when the wave carries parallelism. Two ways a wave sheds it — one per-item (inline riders), one whole-wave (a wave of one):

```
isInlineExecution(item):
  return scope_header(item, "Execution") starts with "inline"   # docs/superpowers/triage/{ID}-scope.md
```

```
rollInSession(wave):                                                       # per-item worktree-skip (multi-item wave)
  return [i for i in wave if isInlineExecution(i)]                         # inline riders roll in-session; siblings take worktrees

isSingleItemWave(wave):                                                    # whole-wave short-circuit
  return len(wave) == 1
```

- **`Execution: inline` (per-item, inside a multi-item wave)** — the triage verdict already sized the item inline (deterministic fix-shape **and** self-contained closure; `triage` agent `§scope.md` tag schema). It stays in the eligible set (still surfaced), but skips the `mkdir` claim + `claude -p` phase dispatch — the gateway rolls it in-session in the main workspace, alongside its worktree-bound siblings. `SKILL.md §Confirm gate` renders it on the "roll in-session" line, not the dispatch table; `SKILL.md §Worktree warm` skips it entirely. (`Execution: phased` items still dispatch — the pre-plan gate skips their named stages; only `inline` skips the worktree.)
- **Wave-of-one (whole-wave short-circuit)** — when admission + relation analysis leave exactly one item, drain has no parallelism to offer, so it does not run drain at all: it short-circuits **before** the confirm gate, surfaces the one item, and hands it to the normal in-session pipeline (the standard single-card envelope — route by cluster, no drain machinery), then exits. No confirm-gate wave table, no worktree, no phase loop. The gateway offers "isolate" to force a drain worktree for the lone item. Fires at `SKILL.md §Shape` step 4 / `§Confirm gate`.

## Mislabel is fixed upstream, not overridden here

A `Device`/`Discuss`/`Harness` verdict — or a venue `U`/`P` — you disagree with is an upstream signal problem: the item's row content (Problem/Area), the shared `cloud-safe criterion`, or the venue map's modality fields drove it. Fix it there — clarify the row so it re-classifies, or refine the criterion / venue map — then drain re-evaluates cold on the next invocation. drain consumes the classification; it does not carry an override path (SoC: the gate stays on one side of the pipeline boundary).

## Runtime walls are the backstop

The gate is a cheap pre-filter on the *known* — it scores only the **next** phase, and never spawns for an already-walled item. An item that passes but turns out mid-flight to need a human (a downstream phase resolving to venue U/P, a `Probe-deps` tag, a design fork) still halts at its wall (`SKILL.md §Phase loop` + `§Pre-plan confirm gate`, `phase-loop.md §Halts`). That halt is an outcome, not a waste — the surfaced finding plus any committed earlier phases are progress.
