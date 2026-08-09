# Carry — after the mattpocock pairing shipped

## Anchor

`GAP-056` is **done and pushed** (`b2055b9`) — bootstrap now seeds the paired pin, prompts
the human, and ships the tracker recipe. What remains is the two loose ends the pairing
exposed, plus the untouched board.

## Read first

- `docs/work/DEBT-059.md` — this repo owes itself the project pin its own §2a now seeds
- `docs/work/DEBT-060.md` — `harness-architecture.md` mixes chronicle into a state doc
- `docs/specs/mattpocock-coexistence.md` — the operating posture, now stating the shipped
  shape rather than a pending one
- `plugins/super-bootstrap/skills/harness-bootstrap/SKILL.md` §2a — the paired-pin class as
  shipped; `assets/mattpocock-tracker-recipe.md` is the one paste-able copy in the repo

## State

The paired pin is a third class beside locked core pins and adaptive picks: seeded
unconditionally, droppable per repo, never re-proposed once dropped. The drop spelling is
`false` — deleting the key gets it merged back on the next sync. Awareness deliberately
never enters the shipped skeleton; it rides the Phase 3 handoff message, which is chat
output, so dropping the pin needs no doc change. The §4 grep contract was scoped, not
spent: a named setup-time-composition class, runtime claim still grep-verifiable.

Board: `BUG-034`, `DEBT-057`, `DEBT-058`, `DEBT-059`, `DEBT-060`, `GAP-057`. All raw —
none triaged, none in flight.

## Next step

Owner's pick. `DEBT-059` is the smallest and closes the dogfood gap; `GAP-057` (does
karpathy retire now that mattpocock covers the lane?) is the one that was deferred
*until* the pairing landed, so it is now unblocked.

## Watch-outs

- `~/.claude/settings.json` has `mattpocock-skills@mattpocock` **true** at device scope,
  where the runbook says disabled. Device config — `/contribute` lane, not a card here.
- The §4 grep contract now sanctions mattpocock hits in exactly three site classes. An
  audit reading them as violations is reading the pre-pairing contract.
- Still unverified: a clean `/reload-plugins` run. Carried unresolved from the previous
  session and never observed error-free.
- The Phase 3 handoff enumerates 13 of his user-invoked commands by name. Accepted drift
  surface — the list has no sync mechanism if upstream renames anything.
- This session ran with the Agent tool gated behind an explicit user ask. A fresh session
  may carry the same block; check before assuming dispatch is available.
