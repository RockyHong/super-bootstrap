USER_MESSAGE:
GAP-001 has a triage verdict: **surface · Taste needed**. The full verdict is in `docs/work/GAP-001.md`. You asked for replacement candidates, so here they are, each with the grounding that bears on it. Pick, mix, or reject them. Your eye is the test.

**Card corrections from triage.** The dusk set holds 6 rows, not 5. "Nets drying. Nobody mending them." is not a dusk line. It is `ambient.night.nets` and it plays at night.

**Shared trait (observation only).** Each flagged line puts a second beat after its object: a recurrence ("again"), a simile ("thick as regret"), a doubled "Somewhere", or an absence ("Nobody mending"). Two lines you did not flag use the same absence beat: `ambient.dusk.rope` ("Nobody coiling it", a spec exemplar) and `ambient.dusk.coin` ("Nobody stoops"). Most candidates below drop the second beat, so you can see whether that beat is what reads stiff.

Spec rules (`docs/specs/ambient-voice.md`): (1) fragments, not reports; (2) present tense, no "you"; (3) one concrete noun carries the line, no abstractions; (4) nine words at most. Every candidate below passes all four.

**1. `ambient.dusk.lamp`: "The lamplighter skips the third post again."**
Grounding: this line is a ratified Exemplar in the spec and is also Rule 3's worked example ("the post, not the loneliness"). If you replace it, the Exemplars list and the Rule 3 example change too. That is a spec change, and you approved the spec.
- a. "One lamp unlit at the end of the quay." (9)
- b. "The lamplighter's ladder against the third post." (7)
- c. "Lamplighter's pole, hooked on the harbor rail." (7)
- d. Keep the line and leave the spec as it is.

**2. `ambient.dusk.salt`: "Salt on the windows, thick as regret."**
Grounding: Rule 3 bans "regret" by name, so the spec already rules against this line. The noun "salt" stays in each candidate, so this is a text edit only.
- a. "Salt crusting the window frames." (5)
- b. "Salt on the glass, white at the corners." (8)
- c. "Salt dried in the window seams." (6)

**3. `ambient.dusk.door`: "Somewhere a door. Somewhere a dog."**
Grounding: two nouns share the line, and Rule 3 asks for one. Each candidate keeps "door", so this is a text edit only.
- a. "A door banging somewhere up the hill." (7)
- b. "A door on the latch, knocking." (6)
- c. "A door shutting, two streets over." (6)

**4. `ambient.night.nets`: "Nets drying. Nobody mending them."**
Grounding: this line passes all four rules on a read, and its shape matches the exemplar `ambient.dusk.rope`. It plays at night, not at dusk. A replacement stays in the night set unless the key moves to the dusk set. These candidates fit either time.
- a. "Nets drying on the seawall." (5)
- b. "Nets heaped by the bollards, still wet." (7)
- c. "Nets on the rail, stiff with salt." (7)

**Cost of each kind of change.** A text-only change edits `content/ambient.json` and nothing else. A change to the carrying noun also renames the key in `content/ambient.json` and in `src/ambient.py` `SCHEDULE` in the same change, because `load()` raises `KeyError` on a missing key. Tell me your picks per line, or point me in a direction for another round.

CARD_APPENDS:
NONE

TOOL_CALLS:
NONE

WHY:
Step 3's DONE branch says: "surface Verdict block carrying `### Taste needed` → no climb, no MCQ, no Design block: carry its grounding forward, produce the artifact the author judges (candidate replacement words…) … and hand it to the author with that grounding beside it." The candidates are reply text with no file write and no propagation closure, so I wrote them inline instead of dispatching. No Design block is appended until the author rules.
