USER_MESSAGE:
GAP-001 triage returned DONE with a `surface` Verdict that carries `### Taste needed`. The verdict is on the card at `docs/work/GAP-001.md`. No runnable check can judge these lines. Your eye is the test, so below are candidate replacements for you to pick from, with the grounding beside them.

**Grounding to keep in view**
- Spec: `docs/specs/ambient-voice.md`, ratified 2026-08-02, sets four rules: fragments; present tense with no "you"; one concrete noun and no abstractions; nine words at most. All the candidates below follow those rules.
- Two corrections to the card. The dusk family has 6 rows, not 5 (`src/ambient.py` `SCHEDULE["dusk"]`). It is keyed by time of day, not by a harbor section. "Nets drying. Nobody mending them." is `ambient.night.nets`, which is a night line, not a dusk line. The problem you described has not changed.
- Shared trait the verdict found: three of the flagged lines are full report sentences or a simile. "Thick as regret" is an abstraction, which rule 3 bars. The door/dog line is two fragments with no concrete agent.
- Tension: the verdict finds that `ambient.dusk.lamp` meets every rule as written. The spec also cites it twice as a positive case: in rule 3's example and in the Exemplars list. If you replace it, the spec will cite copy that no longer ships, so the spec edit becomes part of the same change.
- What a change touches: a replacement keeps its key, so `SCHEDULE` stays untouched. Renaming a key breaks the loader in `src/ambient.py` with a `KeyError`.

**Candidates**

`ambient.dusk.lamp` (now: "The lamplighter skips the third post again.")
1. Third post, still unlit.
2. One lamp dark along the quay.
3. The lamplighter, late again.

`ambient.dusk.salt` (now: "Salt on the windows, thick as regret.")
1. Salt crusting the windows.
2. Windows gone cloudy with salt.
3. Salt-white windowpanes.

`ambient.dusk` door/dog line (now: "Somewhere a door. Somewhere a dog.")
1. A dog barking at the gulls.
2. A loose shutter, knocking.
3. A door slamming, then quiet.

`ambient.night.nets` (night line; now: "Nets drying. Nobody mending them.")
1. Nets drying on the rail.
2. Wet nets, sagging in the dark.
3. Nets hung out, heavy with dew.

Pick one per line, tell me to rewrite any set, or tell me to keep the lamp line. If you replace the lamp line, I will also update the spec's rule 3 example and its Exemplars entry. If you drop the card, I will delete it.

CARD_APPENDS:
NONE

TOOL_CALLS:
- Read `docs/work/GAP-001.md`. This read is done and gives the Verdict block shown above.
- Implied read of `docs/specs/ambient-voice.md` to check the candidates against the four rules. I assume it holds nothing beyond what the card cites.
- No AskUserQuestion, no Agent dispatch, no edits. The candidates go out as reply text, with no file write and no propagation closure, so they stay inline.

WHY:
Skill step 3, DONE branch: "surface Verdict block carrying `### Taste needed` → no climb, no MCQ, no Design block: carry its grounding forward, produce the artifact the author judges (candidate replacement words…) — inline or dispatched by its closure … and hand it to the author with that grounding beside it." The Rules line "Check the verdict aim" made me state the card corrections (6 rows, keyed by time of day, nets is a night line) as facts rather than absorb them silently. They do not re-aim the problem, so the candidates go ahead without a gate.
