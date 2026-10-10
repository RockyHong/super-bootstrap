USER_MESSAGE:
Triage on GAP-001 is done. Verdict: **surface**, carrying `### Taste needed`. Card: `docs/work/GAP-001.md`.

No tool can judge whether a line reads right. The only test is your eye. So I wrote replacement candidates under the voice spec's four rules (`docs/specs/ambient-voice.md`, ratified 2026-08-02): fragments, present tense with no "you", one concrete noun with no abstractions, nine words at most. Pick one per line, edit one, or keep the original.

**Two card corrections from triage (your aim does not change):**
- The dusk set has 6 rows, not 5. It is keyed by time of day (`src/ambient.py` `SCHEDULE["dusk"]`), not by a harbor section.
- "Nets drying. Nobody mending them." is `ambient.night.nets`, a night line, not a dusk line.

**What a change costs:** each replacement keeps its key, so `SCHEDULE` and the loader stay untouched. A key rename breaks the loader (`KeyError`), so every replacement stays a text swap only.

---

**1. "Salt on the windows, thick as regret."**
Triage: "thick as regret" is a simile that names an abstraction, and rule 3 bars that.
- a. "Salt furring the window glass."
- b. "Windows gone white with salt."
- c. "Salt crusting the harbor-master's shutters."

**2. "Somewhere a door. Somewhere a dog."**
Triage: two fragments with no concrete agent.
- a. "A door banging somewhere down the quay."
- b. "The chandler's door, knocking in the wind."
- c. "A dog barking behind the net shed."

**3. "Nets drying. Nobody mending them."** (`ambient.night.nets`, night set)
Triage: "nobody mending them" turns the line into a report sentence.
- a. "Nets drying on the bollards."
- b. "Nets hung on the rail, still wet."
- c. "A net drying, half-mended."

**4. "The lamplighter skips the third post again."** (`ambient.dusk.lamp`)
Triage: this line meets every rule as written. The spec cites it twice as the positive case: once as rule 3's example and once in the Exemplars list. If you replace it, the spec cites copy that no longer ships, so the spec edit comes with the swap.
- a. Keep it as is.
- b. "The third post, dark again."
- c. "The lamplighter, slow past the third post."

---

Your picks for each line come next, or say if the line itself was not the issue. A pick goes on the card as a `## Design` block and starts the content edit. Line 4 also needs a spec update if you replace it.

CARD_APPENDS:
NONE

TOOL_CALLS:
Read `docs/specs/ambient-voice.md`. I assume it holds nothing beyond what the card cites: the four rules and the `ambient.dusk.lamp` exemplar. No AskUserQuestion. No Agent dispatch. No edits. The candidates are written inline because they write nothing to the repo and have no propagation closure.

WHY:
Step 3's DONE branch says that a surface Verdict block carrying `### Taste needed` gets "no climb, no MCQ, no Design block: carry its grounding forward, produce the artifact the author judges (candidate replacement words…) … and hand it to the author with that grounding beside it." The "Check the verdict aim" rule made me show the verdict's card corrections (6 rows keyed by time of day, the nets line being a night line) as notes beside the candidates. They correct facts on the card and do not re-aim the problem, so they do not block the hand-off.
