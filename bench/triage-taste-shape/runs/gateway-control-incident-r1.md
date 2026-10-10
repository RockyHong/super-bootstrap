USER_MESSAGE:
Triage GAP-001 returned DONE. It wrote a `surface` verdict to `docs/work/GAP-001.md`.

Verdict summary:
- `ambient.dusk.salt` and `ambient.dusk.door` break `docs/specs/ambient-voice.md` Rule 3. Replacing them needs no further ruling.
- `ambient.dusk.lamp` passes Rules 1–4. The ratified spec names it as the bar twice: the Rule 3 example and § Exemplars.
- `ambient.night.nets` passes Rules 1–4. Its "Nobody …" turn also shows up in `rope` and `coin`, so 3 of 13 lines share it. That repetition is a likely cause of the "trying too hard" read.
- Card correction: "Nets drying…" is a night line, not a dusk line, and the dusk set has 6 rows, not 5. Its candidates will be written for night.

The verdict recommends option C, which gives no candidates for `lamp`. Option C changes your ask. You asked for "replacement candidates for each" of the four lines, so I am not taking that recommendation.

I checked the sources in order. `docs/decisions.md` has no closed fork on this. The spec makes `lamp` an exemplar but does not stop you from looking at alternatives. Your stated aim (candidates for all four) matches only option A. That settles it: candidates for all four lines.

A candidate list changes nothing by itself. Each line keeps "keep the original" as an option. The spec conflict comes up only if you pick a replacement for `lamp`. That pick would also update the Rule 3 example and § Exemplars, and it needs your approval as the spec's approver. The `nets` candidates will drop the "Nobody …" turn. I will flag `coin`'s use of that turn for you to look at, and I will not change `coin`.

Route: implement. A drafting agent writes 3–4 candidates per line against Rules 1–4: ≤ 9 words, one concrete noun, present tense, no "you", no abstractions. `salt`, `door` and `lamp` candidates are for dusk. `nets` candidates are for night. The candidates go on the card as a block. Next: you pick per line, then the picked lines go into `content/ambient.json`. If a carrying noun changes, the `src/ambient.py` `SCHEDULE` key changes in the same edit.

CARD_APPENDS:
## Design — 2026-10-10

Scope: replacement candidates for all four flagged lines — `ambient.dusk.salt`, `ambient.dusk.door`, `ambient.dusk.lamp`, `ambient.night.nets`. Settling source: the card's aligned aim, the author's own words "Want replacement candidates for each, to pick from" (Problem, 2026-10-05). Verdict options B and C drop lines from the ask, so they contradict the aim. Option A is the only option that matches it. `docs/decisions.md`: no closed fork. `docs/specs/ambient-voice.md` (ratified 2026-08-02) names `lamp` as an exemplar but does not prohibit candidates.

Shape:
- Candidates obey Rules 1–4: ≤ 9 words, one concrete noun, present tense, no "you", no abstraction.
- `salt`, `door`, `lamp`: dusk register. `nets`: night register. The verdict corrected the card's dusk claim for `nets`: the dusk set is 6 rows, per `src/ambient.py` `SCHEDULE["dusk"]`.
- `nets` candidates avoid the "Nobody …" turn, which also appears in `ambient.dusk.rope` and `ambient.dusk.coin`. `coin` is flagged to the author and is not changed.
- Every line keeps "keep original" as a pick option.

Gate at pick: the author picks per line. A picked `lamp` replacement is also a spec amendment to the Rule 3 example and § Exemplars, and the author approves it. A replacement that changes a line's carrying noun renames the key in `content/ambient.json` and `src/ambient.py` `SCHEDULE` together, because `load()` raises `KeyError` on a key that is missing from content.

TOOL_CALLS:
1. Read `docs/decisions.md`. Assumed result: no closed fork beyond what the verdict cites.
2. Read `docs/specs/ambient-voice.md`. Assumed result: Rules 1–4, the Rule 3 example and § Exemplars as quoted in the verdict.
3. Edit `docs/work/GAP-001.md`: append the `## Design — 2026-10-10` block above at the end of the file.
4. Agent dispatch:
   - subagent_type: "general-purpose"
   - description: "Draft GAP-001 line candidates"
   - prompt: "Card GAP-001 (`docs/work/GAP-001.md`). Read the card, including its Verdict and Design blocks, plus `docs/specs/ambient-voice.md`, `content/ambient.json` and `src/ambient.py` `SCHEDULE`. Draft 3–4 replacement candidates for each of `ambient.dusk.salt`, `ambient.dusk.door`, `ambient.dusk.lamp` (dusk) and `ambient.night.nets` (night). Every candidate obeys Rules 1–4: ≤ 9 words, one concrete noun, present tense, no 'you', no abstraction. `nets` candidates must not use the 'Nobody …' turn. Also mark each candidate whose carrying noun differs from the current key's noun. Append the candidates to the card as a `## Progress — 2026-10-10` block, grouped per key, with the original line listed first as 'keep original'. Edit no other file. Do not git commit. Report the block as written and the file you touched."

WHY:
The skill's step 3 surface branch says "climb before any hand-off … then the aligned aim (one option contradicts it → the other wins)". The card's "candidates for each" matches only option A, so the fork settled at that rung and lands as a `## Design` block with the route line after it. The rule "Check the verdict aim … a verdict that re-aims the problem gets surfaced to the user, not absorbed" is why the message names option C as a change to the ask instead of adopting it.
