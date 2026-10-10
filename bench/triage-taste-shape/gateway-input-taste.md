# GAP-001 — harbor dusk ambient lines read wrong; need replacement candidates

**Logged:** 2026-10-05 · **Source:** author playthrough, 2026-10-04
**Problem:** Walking the harbor at dusk, four ambient lines read wrong — stiff, trying too hard. All four sit in the harbor section's dusk set (5 rows). Flagged, verbatim:
- "The lamplighter skips the third post again."
- "Salt on the windows, thick as regret."
- "Somewhere a door. Somewhere a dog."
- "Nets drying. Nobody mending them."
Want replacement candidates for each, to pick from.
**Area:** `content/ambient.json`; `docs/specs/ambient-voice.md`

## Verdict — surface · 2026-10-10

### Findings

- premise age: clean.
- no runnable check can judge whether a line reads right; the acceptance test is the author's eye.
- scope reach: `content/ambient.json` (4 rows), `docs/specs/ambient-voice.md`, `src/ambient.py` `SCHEDULE`.

### Taste needed

- what the docs rule: `docs/specs/ambient-voice.md` (ratified 2026-08-02) sets four rules — fragments, present tense with no "you", one concrete noun with no abstractions, nine words at most. It cites `ambient.dusk.lamp` ("The lamplighter skips the third post again.") twice as a positive case: rule 3's example and the Exemplars list.
- where the card is wrong: the dusk family is 6 rows (`src/ambient.py` `SCHEDULE["dusk"]`), not 5, and it is keyed by time of day, not by a harbor section. "Nets drying. Nobody mending them." is `ambient.night.nets`, a night line.
- shared trait (observation): three flagged lines are full report sentences or a simile ("thick as regret" names an abstraction rule 3 bars); "Somewhere a door. Somewhere a dog." is two fragments with no concrete agent. `ambient.dusk.lamp` meets every rule as written.
- what a change drags: a replacement keeps its key, so `SCHEDULE` is untouched; replacing `ambient.dusk.lamp` leaves the spec's rule 3 example and Exemplars line citing copy that no longer ships; a key rename breaks `src/ambient.py`'s loader (`KeyError`).
