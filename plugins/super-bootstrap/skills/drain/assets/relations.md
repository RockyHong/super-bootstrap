# Relation analysis — wave selection

Called from `SKILL.md §Shape` step 3. Input: the eligible Cloud items (`eligibility.md`). Output: the **current wave** — items dispatched this invocation. No projected future waves.

Worktrees isolate the git tree, not semantic merge conflicts. Two items touching the same files can't safely run concurrently — one's merge invalidates the other's base. So classify by file overlap, then admit only what's safe to run now.

```
relationAnalysis(eligibles):
  for each pair (a, b):
    overlap = scopeFiles(a) ∩ scopeFiles(b)
    empty(overlap)        -> disjoint
    acyclic dep order     -> chain      (a must land before b)
    else                  -> conflict   (irreconcilable overlap)

  wave = all disjoint orphans + the HEAD of each chain
  chain-tails defer (their upstream hasn't merged yet)
  conflicts defer (surface at scan summary only, never in the wave)
  return wave   # flat list, no future-wave structure
```

`scopeFiles(item)` — best-available file estimate: the backlog row's `**Area:**` field, the plan's task-bullet paths, or the spec's named surfaces. Imperfect overlap estimates are fine — a missed overlap surfaces as a merge conflict at the gate (handled by `/super-bootstrap:merge`'s conflict doctrine), not as silent corruption.

## Edge cases

- **N=1 eligible** — wave of 1; the confirm gate still fires (never silently skip). By default a lone dispatchable item rolls in-session (no worktree) — the wave-of-one carve-out (`eligibility.md §Inline / wave-of-one carve-out`); the user can force isolation.
- **All in one chain** — wave = head only; tails defer to the next invocation after the head merges.
- **All in one conflict** — empty wave; surface "no progressable items, conflicts pending user resolution" + clean exit.
- **User declines** — clean exit; no worktrees, no claims.

## No forward projection

Render the current wave only. The next `/super-bootstrap:drain` re-runs this analysis cold on whatever the board looks like then — walls may have rearranged it, so any "wave 2" preview would be a lie. This is discipline, not optimization (`pipeline-design.md §State = file presence`: the next session reconstructs from files, not from a prior projection).
