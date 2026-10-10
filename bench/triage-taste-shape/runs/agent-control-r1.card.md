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

- premise age: clean — `git log --since=2026-10-04 -- content/ambient.json docs/specs/ambient-voice.md` returns no commits (sole commit `85cea53`, 2026-09-01).
- root cause (premise verify, per line, against `content/ambient.json` + `docs/specs/ambient-voice.md` Rules 1–4, status "ratified 2026-08-02 (approval: author)"):
  - `ambient.dusk.salt` — "Salt on the windows, thick as regret." Breaks Rule 3 verbatim: "No abstractions ("sorrow", "regret", "memory")". Spec-grounded; replacement needs no further ruling.
  - `ambient.dusk.door` — "Somewhere a door. Somewhere a dog." Two nouns share the line; Rule 3 asks "One concrete noun carries the line". Spec-grounded (weaker than salt, but consistent).
  - `ambient.dusk.lamp` — "The lamplighter skips the third post again." Passes Rules 1–4, and the ratified spec names it twice as the bar: the Rule 3 example ("`ambient.dusk.lamp` — the post, not the loneliness") and § Exemplars ("Lines that set the bar for new copy"). The playthrough flag contradicts the author's own ratified spec.
  - `ambient.night.nets` — "Nets drying. Nobody mending them." Passes Rules 1–4, and its shape mirrors exemplar `ambient.dusk.rope` ("Wet rope, creaking. Nobody coiling it."). The "Nobody …" turn also recurs in `ambient.dusk.coin` ("Nobody stoops."), so three of 13 lines share it — a possible source of the "trying too hard" read the spec does not cover.
- premise inaccuracy: the card says "All four sit in the harbor section's dusk set (5 rows)". The dusk set is 6 rows (`src/ambient.py` `SCHEDULE["dusk"]`: rope, lamp, salt, door, tar, coin). "Nets drying…" is `ambient.night.nets`, a night line. Candidates for it must fit night, not dusk.
- scope reach:
  - `content/ambient.json` — line text (the fix surface).
  - `src/ambient.py` `SCHEDULE` — touched only if a replacement changes the carrying noun and the key is renamed to match (`ambient.{time}.{noun}`, spec header); `load()` raises `KeyError` on a key missing from content, so a rename must land in both files together.
  - `docs/specs/ambient-voice.md` — touched if `ambient.dusk.lamp` changes (Rule 3 example + § Exemplars both quote it) or if the "Nobody …" repetition becomes a rule.
  - No overlapping open card in `docs/work/`; `docs/decisions.md` holds no closed fork.
- attempted: full read of the Area files, schedule, decisions, and card set. Stopped at verdict: the deliverable (candidate lines the author picks from) is preference by nature — no unit/e2e test decides copy taste (criterion 3 fails), and two of the four flags conflict with the ratified spec (criterion 4 fails). Candidate drafting is the implement phase's work, not this lane's.

### Decision needed

- Scope of the replacement set: the ratified spec endorses two of the four flagged lines. Which lines get candidates?
  - A — all four. The playthrough read overrides the spec for `lamp` and `nets`; the `lamp` change also revises the spec's Rule 3 example and § Exemplars (a spec amendment, author-approved).
  - B — `salt` and `door` only (the spec-breaking pair). `lamp` and `nets` stay; the spec stands as ratified.
  - C — `salt` and `door` get candidates; `nets` gets candidates too as a "Nobody …" de-duplication (and `coin` is checked for the same turn), possibly adding a repetition rule to the spec; `lamp` stays as the exemplar.
- recommendation: C — it honors the ratified spec's explicit exemplar (`lamp`), fixes the two lines the spec already rejects, and gives the author's "trying too hard" read a concrete, spec-expressible cause for `nets` instead of an unexplained override.
- settles by: preference — the author's own call (the spec's approver), since overriding or amending a ratified exemplar is theirs alone. Each candidate set, once scoped, also needs the author's pick by reading/playtest; implement drafts candidates against Rules 1–4 (≤ 9 words, one concrete noun, present tense, no "you", no abstraction), with `nets` candidates written for night, not dusk.
