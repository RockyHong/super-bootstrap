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

- premise age: clean — `git log --since=2026-10-04 -- content/ambient.json docs/specs/ambient-voice.md` returns no commits; the only commit is `6c22f8e harbor: ambient content + voice spec`.
- root cause: none to trace; this is a capability claim. The gap holds: all four flagged lines exist verbatim in `content/ambient.json` (lines 6, 7, 8, 12), and no replacement candidates exist anywhere in the repo.
- scope reach: `content/ambient.json` (line text); `docs/specs/ambient-voice.md` (rules + exemplars that cite one flagged line); `src/ambient.py` `SCHEDULE` (enumerates the keys).
- aim: no other open card in `docs/work/`; `docs/decisions.md` has no closed-fork rows.
- attempted: read the content, spec, scheduler and decisions; stopped at criterion 3 — no runnable check can judge whether a replacement line reads right; the author's eye is the test.

### Taste needed

- docs rule:
  - `docs/specs/ambient-voice.md` (ratified 2026-08-02, approval: author) Rules 1–4: fragments not reports; present tense, no "you"; one concrete noun carries the line, no abstractions ("sorrow", "regret", "memory"); nine words at most.
  - `ambient.dusk.salt` — "Salt on the windows, thick as regret." — uses "regret", a word Rule 3 names as a banned abstraction. The spec already rules against this line.
  - `ambient.dusk.lamp` — "The lamplighter skips the third post again." — the spec cites this line twice as ratified: as Rule 3's worked example ("the post, not the loneliness") and in § Exemplars ("Lines that set the bar for new copy"). The author's flag collides with that ratification.
  - `ambient.dusk.door` — "Somewhere a door. Somewhere a dog." — carries two nouns (door, dog); Rule 3 asks for one concrete noun. No other rule applies.
  - `ambient.night.nets` — "Nets drying. Nobody mending them." — passes Rules 1–4 as written (5 words, fragment, one noun, present tense).
  - All four are within the nine-word limit (7, 6, 6, 5 words).
- card corrections:
  - The dusk set holds 6 rows, not 5 (`content/ambient.json` lines 5–10; `src/ambient.py` `SCHEDULE["dusk"]` lists 6 keys).
  - "Nets drying. Nobody mending them." is not in the dusk set — it is `ambient.night.nets`, scheduled under `night`. Three of the four flagged lines are dusk; one is night.
- shared trait (observation): all four lead with or hinge on an image of absence or omission — a skipped post, a feeling named instead of shown, an unseen source ("Somewhere"), work nobody does. The unflagged lines `ambient.dusk.rope` ("Nobody coiling it.", a spec exemplar) and `ambient.dusk.coin` ("Nobody stoops.") share the "Nobody …" construction with `ambient.night.nets`.
- drags:
  - Text-only replacement (same keys): touches `content/ambient.json` only; no code change. `ambient.dusk.lamp` replacement also drags `docs/specs/ambient-voice.md` Rule 3's example and the § Exemplars entry.
  - Key rename (e.g. a new noun in the key): `src/ambient.py` `SCHEDULE` must change in the same edit — `load()` raises `KeyError` on any scheduled key missing from content.
  - `ambient.night.nets` changes the night set, not dusk — a candidate there reads against the night lines (`bell`, `hull`, `cards`).
  - Any replacement for `ambient.night.nets` or `ambient.dusk.door` that keeps the "Nobody …" shape sits beside `ambient.dusk.rope` / `ambient.dusk.coin` in the same pattern.
