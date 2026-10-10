USER_MESSAGE:
Triage on GAP-001 is done. The verdict is **surface, with Taste needed**: no runnable check can judge whether a line reads right, so your eye is the test. The full verdict is at `docs/work/GAP-001.md`. Below are replacement candidates for each flagged line, each shown beside the grounding that applies to it. I wrote them against `docs/specs/ambient-voice.md` Rules 1–4: fragments, present tense, no "you", one concrete noun carrying the line, no abstractions, nine words at most. I kept every key unchanged, so a pick changes only text in `content/ambient.json` and needs no code change.

Two corrections to the card first:
- The dusk set has 6 rows, not 5.
- "Nets drying. Nobody mending them." is `ambient.night.nets`, in the night set. Its replacement reads against the night lines (`bell`, `hull`, `cards`), not the dusk lines.

**1. `ambient.dusk.salt`: "Salt on the windows, thick as regret."**
Grounding: "regret" is a banned abstraction under Rule 3, so the spec already rules against this line.
- a. "Salt whitening the glass." (4 words)
- b. "Salt, thick on every pane." (5)
- c. "Salt dried white in the window corners." (7)

**2. `ambient.dusk.lamp`: "The lamplighter skips the third post again."**
Grounding: the spec ratifies this line twice, as Rule 3's worked example ("the post, not the loneliness") and in § Exemplars. Your flag conflicts with that ratification. If you replace it, the spec example and the exemplar entry change in the same edit. If you keep it, this item drops.
- a. "The third post stays dark." (5)
- b. "The lamplighter's ladder, leaning on the third post." (8)
- c. "The lamplighter lights the third post last." (7)

**3. `ambient.dusk.door`: "Somewhere a door. Somewhere a dog."**
Grounding: the line has two nouns (door, dog), and Rule 3 asks for one. No other rule applies.
- a. "A screen door: open, shut, open." (6)
- b. "A door banging, somewhere uphill." (5)
- c. "One dog, barking at the tide." (6)

**4. `ambient.night.nets` (night set): "Nets drying. Nobody mending them."**
Grounding: the line passes Rules 1–4 as written, so the spec does not explain the flag. It shares the "Nobody …" construction with `ambient.dusk.rope` (a spec exemplar) and `ambient.dusk.coin`. None of these candidates uses that construction.
- a. "Wet nets, heavy on the rail." (6)
- b. "Nets dripping on the dark quay." (6)
- c. "Nets hung on the rail, still wet." (7)

Triage noticed one more thing: all four flagged lines turn on absence or omission (a skipped post, a named feeling, an unseen source, undone work). If that pattern is what reads wrong to you, I kept most of these candidates away from absence images. 1c and 2a still lean on it.

Pick one per line by number and letter (for example "1a, 2-keep, 3b, 4c"), or give your own wording. I will then record your picks on the card and route the edit.

CARD_APPENDS:
NONE

TOOL_CALLS:
NONE

WHY:
Step 3's DONE branch decided it: "surface Verdict block carrying `### Taste needed` → no climb, no MCQ, no Design block: carry its grounding forward, produce the artifact the author judges (candidate replacement words…) — inline or dispatched by its closure — and hand it to the author with that grounding beside it." The candidates write no file and own no propagation closure, so I produced them inline. The Design block waits for the author's picks. The card corrections and the lamp-line conflict with the ratified spec go beside the candidates as grounding, under "Check the verdict aim", and are not treated as a re-aim.
