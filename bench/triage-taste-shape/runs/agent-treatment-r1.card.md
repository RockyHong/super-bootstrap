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

- premise age: clean — `git log --since=2026-10-04 -- content/ambient.json docs/specs/ambient-voice.md` returns no commits; the only commit (6c22f8e, 2026-09-01) predates the observation.
- root cause: not a defect — a copy-quality claim. All four flagged lines exist verbatim in `content/ambient.json` (lines 6, 7, 8, 12). No runnable check can judge "stiff, trying too hard"; the author's eye is the test (criterion 3 fails).
- scope reach: `content/ambient.json` (line text, and keys if a carrying noun changes); `src/ambient.py` `SCHEDULE` (enumerates keys; `load()` raises `KeyError` on a missing key); `docs/specs/ambient-voice.md` (Rule 3 example + Exemplars cite `ambient.dusk.lamp`).
- aim: no overlapping open card in `docs/work/`; `docs/decisions.md` has no closed-fork rows; no `docs/techstack.md` § Probes table, so no probes fired.
- attempted: static read of the card, spec, content, scheduler, decisions; stopped at the taste wall.

### Taste needed

- docs rule:
  - `docs/specs/ambient-voice.md` (ratified 2026-08-02, approval: author) — Rules: 1 fragments not reports; 2 present tense, no "you"; 3 one concrete noun carries the line, no abstractions ("sorrow", "regret", "memory"); 4 nine words at most.
  - `ambient.dusk.lamp` — "The lamplighter skips the third post again." — is a ratified **Exemplar** ("Lines that set the bar for new copy") and is also Rule 3's worked example ("the post, not the loneliness"). The flag collides with the author-ratified spec; replacing it unseats an exemplar and Rule 3's example.
  - `ambient.dusk.salt` — "Salt on the windows, thick as regret." — uses "regret", a word Rule 3 names as a banned abstraction. The spec already rules against this line.
  - `ambient.dusk.door` — "Somewhere a door. Somewhere a dog." — two nouns share the line; Rule 3 asks for one carrying noun. Word count and tense pass.
  - `ambient.night.nets` — "Nets drying. Nobody mending them." — passes Rules 1–4 on a read; its "X-ing. Nobody Y-ing" shape matches the exemplar `ambient.dusk.rope` ("Wet rope, creaking. Nobody coiling it.").
  - Word counts all within Rule 4: lamp 7, salt 7, door 6, nets 5.
- card corrections:
  - The dusk set holds 6 rows, not 5 (`content/ambient.json` lines 5–10; `src/ambient.py` `SCHEDULE["dusk"]`).
  - Only three of the four flagged lines are in the dusk set. "Nets drying. Nobody mending them." is `ambient.night.nets`, scheduled at night (`SCHEDULE["night"]`, 4 rows).
- shared trait (observation): each flagged line pairs its object with a second beat — a recurrence ("again"), a simile ("thick as regret"), a doubled "Somewhere", or an absence ("Nobody mending"). The same absence beat recurs in two unflagged dusk lines: `ambient.dusk.rope` (exemplar, "Nobody coiling it") and `ambient.dusk.coin` ("Nobody stoops").
- drags:
  - Any line: text edit in `content/ambient.json` only, if the carrying noun stays.
  - Noun change (key is `ambient.{time}.{noun}`): rename the key in `content/ambient.json` and in `src/ambient.py` `SCHEDULE` in the same change — `load()` raises `KeyError` on a key missing from content.
  - `ambient.dusk.lamp`: also `docs/specs/ambient-voice.md` Rule 3 example and the Exemplars list — a change to a ratified spec (approval: author).
  - `ambient.night.nets`: night set, not dusk — a replacement written for dusk would be scheduled at night unless the key moves sets.
