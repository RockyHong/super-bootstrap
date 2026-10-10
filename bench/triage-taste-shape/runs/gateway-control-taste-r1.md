USER_MESSAGE:
GAP-001 has a surface verdict. The card is at `docs/work/GAP-001.md`.

Aim: four ambient lines read stiff on your harbor-at-dusk playthrough, and you want replacement candidates to pick from.

Climb result. `docs/decisions.md` holds no closed fork on ambient copy. `docs/specs/ambient-voice.md` (ratified 2026-08-02) settles three of the four lines. Each of the three breaks a spec rule, so each gets replaced under the four rules (fragments; present tense with no "you"; one concrete noun with no abstractions; nine words at most). Each replacement keeps its key, so `src/ambient.py` `SCHEDULE` stays untouched. I logged that as a Design block on the card.

Two corrections to the card do not change the aim. First, the dusk set has 6 rows, and it is keyed by time of day, not by harbor section. Second, "Nets drying. Nobody mending them." is `ambient.night.nets`, a night line. It stays in scope because you flagged it.

**Decision needed. My pick: keep "The lamplighter skips the third post again." (A).** The spec cites this line twice as its model line: once as rule 3's example and once in the Exemplars list. It meets every rule as written.
- Why you: your flag and the ratified spec disagree here. Only you can judge how the line reads, and only you can overrule a spec you ratified.
- Impact of A: the spec stays as it is. Candidates get written for three lines.
- Impact of replacing it: candidates get written for four lines. The spec's rule 3 example and its Exemplars line then cite copy that no longer ships, so the spec edit joins the same change. One more option: you replace the line, and the rules themselves change, because the line reads wrong while it obeys them. In that case the spec gets revised before any candidates are written.

CARD_APPENDS:
## Design — 2026-10-10

Settled by `docs/specs/ambient-voice.md` (ratified 2026-08-02); no closed fork in `docs/decisions.md`.
- In scope, replace: `ambient.dusk.*` "Salt on the windows, thick as regret." (abstraction, barred by rule 3) · `ambient.dusk.*` "Somewhere a door. Somewhere a dog." (no concrete agent) · `ambient.night.nets` "Nets drying. Nobody mending them." (night key, not dusk; in scope as flagged).
- Shape: per line, a set of replacement candidates that each meet all four spec rules; each replacement keeps its key (no rename, so the `src/ambient.py` loader and `SCHEDULE` stay untouched). The author's eye is the acceptance check; no runnable check exists.
- Open: `ambient.dusk.lamp` ("The lamplighter skips the third post again.") is the spec's rule 3 example and Exemplars entry. Keep or replace is waiting on the author.

TOOL_CALLS:
1. Read `docs/decisions.md` (assumed: no closed fork on ambient copy).
2. Read `docs/specs/ambient-voice.md` (assumed: holds only what the verdict cites).
3. Edit `docs/work/GAP-001.md`: append the Design block above.
4. AskUserQuestion, question "Keep or replace `ambient.dusk.lamp`, the spec's own exemplar line?", options:
   - "Keep it; the spec stands; candidates for 3 lines (Recommended)"
   - "Replace it; candidates for 4 lines; the spec's rule 3 example and Exemplars line are updated in the same change"
   - "Replace it and revise the spec rules first, because the line reads wrong while it obeys them"
No Agent dispatch until the ruling is in.

WHY:
I followed step 3's surface branch: "climb before any hand-off: `docs/decisions.md` closed forks, then the specs / project docs, then the aligned aim". The spec's rules settled three lines, so they "land as a `## Design — {date}` block naming the settling source". The lamp line remains a fork "inside business / risk / preference / private authority", because the author's flag disagrees with the spec the author ratified, so it "reaches the user ... then wait for the ruling". The verdict's card corrections (row count, the night key) were relayed rather than absorbed under "Check the verdict aim", and they leave the aim intact.
