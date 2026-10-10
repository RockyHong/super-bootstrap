USER_MESSAGE:
Triage on GAP-001 returned DONE with a `surface` verdict. Card: `docs/work/GAP-001.md`.

Climb results:
- `docs/decisions.md`: I read it. It has no closed fork on ambient copy.
- `docs/specs/ambient-voice.md` (ratified 2026-08-02) settles three of the four flagged lines. "Salt on the windows, thick as regret.", "Somewhere a door. Somewhere a dog." and "Nets drying. Nobody mending them." each break a spec rule (a full sentence, a simile with an abstraction, or no concrete agent). They get replaced. Each replacement keeps its key, so `src/ambient.py` `SCHEDULE` and the loader stay as they are. I logged this as a Design block on the card.
- Two card facts were corrected. The dusk set has 6 rows, not 5, and it is keyed by time of day, not by a harbor section. "Nets drying. Nobody mending them." is `ambient.night.nets`, which is a night line. It stays in scope because you flagged it.

One decision is yours: keep or replace "The lamplighter skips the third post again." (`ambient.dusk.lamp`).

- My recommendation: replace it and update the spec. You flagged it from a playthrough, and only your ear can judge how a line reads.
- Why this is your call: the spec you ratified uses this exact line as a positive example twice (rule 3's example and the Exemplars list), and it meets every rule as written. The docs say keep and your playthrough says replace. Only the author can overrule the author's own spec.
- If you replace it: `docs/specs/ambient-voice.md` needs a new rule 3 example and a new Exemplars entry in the same change. Otherwise the spec cites copy that no longer ships.
- If you keep it: three replacement sets get drafted and the spec stays as it is.

After your ruling, I will post the route line and dispatch the drafting of replacement candidates for you to pick from.

CARD_APPENDS:
## Design — 2026-10-10

Settled by `docs/specs/ambient-voice.md` (ratified 2026-08-02), its four rules: fragments, present tense with no "you", one concrete noun with no abstractions, nine words at most.
- Replace `"Salt on the windows, thick as regret."`, `"Somewhere a door. Somewhere a dog."`, and `ambient.night.nets` (`"Nets drying. Nobody mending them."`). Each breaks a spec rule, as the Verdict's shared-trait finding records. The author's flag stands for `ambient.night.nets`, even though it is a night line and not a dusk line.
- Shape: each replacement keeps its key. `src/ambient.py` `SCHEDULE` and the loader stay untouched. Deliverable = replacement candidates per line, written to the four rules, for the author to pick from. The author's eye is the acceptance test.
- Card corrections: the dusk family is 6 rows, keyed by time of day (`SCHEDULE["dusk"]`), not a 5-row harbor section.
- Open: `ambient.dusk.lamp` (keep vs replace). The spec cites it as rule 3's example and in the Exemplars list, so only the author can rule. The ruling lands as its own Design block.

TOOL_CALLS:
1. Edit `docs/work/GAP-001.md`: append the Design block above after the Verdict block.
2. AskUserQuestion. Question: "Keep or replace `ambient.dusk.lamp` ("The lamplighter skips the third post again.")? Your spec cites it twice as an exemplar." Options:
   - "Replace it and update the spec's rule 3 example + Exemplars entry (Recommended)"
   - "Keep it. It stays as the exemplar, and only the other three get replacement candidates."
   - "Drop GAP-001. No changes."
No Agent dispatch now. The candidate-drafting build waits for the ruling.

WHY:
Step 3's surface branch says to climb `docs/decisions.md`, then the specs, then the aligned aim, and that a fork resolved there "lands as a `## Design — {date}` block naming the settling source". The spec's four rules settle the three lines that break them, so those three got a Design block. Its next clause says "only a fork inside business / risk / preference / private authority reaches the user… then wait for the ruling". The lamp line meets the ratified spec but the author flagged it, so that fork falls under the author's preference authority. It goes to the user, and the route line and build wait for the ruling.
