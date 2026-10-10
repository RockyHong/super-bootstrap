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

- premise age: clean — `git log --since=2026-10-04 -- content/ambient.json docs/specs/ambient-voice.md` returns no commits; the only commit is `85cea53` (2026-09-01).
- root cause: not a defect — a taste-shaped capability ask. Need-check against current content, per flagged line, held against the ratified spec `docs/specs/ambient-voice.md` § Rules (1 fragments, 2 present tense / no "you", 3 one concrete noun / no abstractions, 4 ≤ 9 words):
  - `ambient.dusk.salt` — "Salt on the windows, thick as regret." (`content/ambient.json:7`) — breaks rule 3: "regret" is a named abstraction the spec bans by example. The spec confirms this line is off; replacement is spec-driven.
  - `ambient.dusk.door` — "Somewhere a door. Somewhere a dog." (`content/ambient.json:8`) — strains rule 3: two nouns split the line, neither carries it, and the key names only `door`. The spec supports the flag.
  - `ambient.night.nets` — "Nets drying. Nobody mending them." (`content/ambient.json:12`) — passes all four rules. It mirrors the ratified exemplar `ambient.dusk.rope` ("Wet rope, creaking. Nobody coiling it.") almost beat for beat. The flag is pure taste, or a reaction to that echo.
  - `ambient.dusk.lamp` — "The lamplighter skips the third post again." (`content/ambient.json:6`) — passes all four rules, and the spec names it twice as the bar: rule 3's worked example and § Exemplars ("Lines that set the bar for new copy"). The author's playthrough flag contradicts the author's own ratified spec (`Status: ratified 2026-08-02 (approval: author)`).
- premise drift: the card says "All four sit in the harbor section's dusk set (5 rows)". Current code disagrees on both counts — `src/ambient.py:10-17` schedules 6 dusk keys, and "Nets drying…" is `ambient.night.nets`, scheduled under `night` (`src/ambient.py:18-23`), not dusk. Three flagged lines are dusk, one is night.
- scope reach: `content/ambient.json` (4 values; keys unchanged, so `src/ambient.py` `load()` key check at lines 29-32 stays satisfied — no code touch); `docs/specs/ambient-voice.md` § Exemplars and rule 3's example only if the lamp line is replaced. No overlapping open card in `docs/work/`; `docs/decisions.md` has no closed fork rows. No `docs/techstack.md`, so no § Probes — static read only. No served/imported provenance markers on any touched file.
- attempted: full static read of the Area files, the scheduler, decisions, and the work index. Stopped before drafting candidates: candidate copy is the implement-phase deliverable, and the pick among them is the author's taste.

### Decision needed

- Q1 — the lamp line is the spec's own exemplar. Does the author's flag overturn the ratified exemplar?
  - (a) Yes — replace `ambient.dusk.lamp`, and the same change revises `docs/specs/ambient-voice.md` rule 3's example and § Exemplars (a spec change needing the author's re-ratification).
  - (b) No — keep the lamp line; the spec stands and the card narrows to three lines.
  - (c) Keep the line in the spec as an exemplar but swap it out of the dusk rotation only — rejected as an option: the spec's exemplars point at live keys (`ambient.dusk.lamp`), so this leaves the spec citing copy that no longer ships.
  - recommendation: (b) — the author ratified this line as the bar five weeks before the playthrough; "reads wrong" in context may come from neighbors (salt, door) rather than the lamp line itself. Generating lamp candidates anyway is cheap, so (a) can stay open until the author sees them beside the current line.
- Q2 — "Nets drying…" is a night line, not dusk, and it passes every rule. Is the flag about the line, or about its echo of the rope exemplar?
  - (a) Replace it — candidates must pass rules 1-4 and must break the "X, verb-ing. Nobody verb-ing it." shape the rope line owns.
  - (b) Keep it — the flag came from the wrong time slot or the card misremembered the section.
  - recommendation: (a) — the echo of `ambient.dusk.rope` is a concrete, spec-independent reason a reader hears it as stiff; breaking the shape gives the author a real alternative.
- Q3 — the final pick among candidates for every line (salt, door, and any of lamp / nets kept in scope).
  - settles by: author preference — how the line lands in play. No spec, decisions row, or measurable proxy decides it. Rules 1-4 filter candidates mechanically (word count, no "you", no abstraction noun, present tense) — `inline read` against the spec — but they do not pick.
- recommendation for the route: implement phase drafts 3-4 candidates per in-scope line, each checked against rules 1-4, each keeping its existing key; the author picks; the pick lands in `content/ambient.json` (plus the spec edit only under Q1 (a)).
- settles by: Q1 and Q2 — preference (author, private authority over the ratified spec); Q3 — preference.
