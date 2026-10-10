USER_MESSAGE:
GAP-001 triage is done. The verdict is on `docs/work/GAP-001.md` (surface, 2026-10-10). You asked for replacement candidates for each of the four lines, so those are below, with the grounding from the verdict next to each line. Every candidate keeps its existing key and passes the spec rules in `docs/specs/ambient-voice.md` (fragment, present tense, no "you", concrete noun with no abstraction, 9 words or fewer). Pick one per line or keep the current line. I land your picks in `content/ambient.json`.

**`ambient.dusk.salt`**: "Salt on the windows, thick as regret."
Grounding: this line breaks rule 3, because "regret" is an abstraction that the spec bans.
- Salt crusting the windows, white at the corners.
- Salt on the window glass, thick as frost.
- Window salt, gone gold in the last light.

**`ambient.dusk.door`**: "Somewhere a door. Somewhere a dog."
Grounding: this line strains rule 3. Two nouns split the line, and the key names only the door.
- A door bangs somewhere up the hill.
- Somewhere uphill, a door swinging on its hinge.
- A door, left open, knocking in the wind.

**`ambient.dusk.lamp`**: "The lamplighter skips the third post again."
Grounding: this line passes all four rules. Your ratified spec names it as the bar twice, in rule 3's example and in § Exemplars. If you replace it, the same change edits those two spots in the spec, and you re-ratify the spec.
- The lamplighter, late again at the third post.
- Third post still dark. The lamplighter's ladder leans.
- The lamplighter's ladder, propped at the third post.

**`ambient.night.nets`**: "Nets drying. Nobody mending them."
Grounding: this line passes all four rules. It is a night line, not a dusk line (`src/ambient.py:18-23`). It also copies the shape of the exemplar `ambient.dusk.rope` ("Wet rope, creaking. Nobody coiling it."). That echo may be what reads as stiff, so none of these candidates use that shape.
- Nets hung over the rail, still dripping.
- A torn net draped across the bollard.
- Gulls picking at the drying nets.

One more correction to the card: the dusk set has 6 rows, not 5 (`src/ambient.py:10-17`).

CARD_APPENDS:
NONE

TOOL_CALLS:
NONE. No AskUserQuestion, no Agent dispatch, no edits. I drafted the candidates inline because they write nothing to the repo and have no propagation closure. The only reads are the skill text and the card, and the card holds the spec rules that I needed.

WHY:
The skill's absorb step says a `### Decision needed` whose Findings name the author's eye as the only test "takes this branch too: its options are a frame the author did not ask for". That branch is the `### Taste needed` branch: "no climb, no MCQ, no Design block: carry its grounding forward, produce the artifact the author judges ... and hand it to the author with that grounding beside it". This verdict's Findings call the nets flag pure taste, and they settle Q1–Q3 by "author preference — how the line lands in play". So I did not use the verdict's Q1/Q2 options and I did not ask an MCQ. I gave candidates for all four lines, which is what the card asked for, with the spec facts beside each line.
