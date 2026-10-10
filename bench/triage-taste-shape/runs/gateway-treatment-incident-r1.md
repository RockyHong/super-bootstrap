USER_MESSAGE:
Triage on GAP-001 is done. It added a `surface` Verdict to `docs/work/GAP-001.md`. Its fork has one test: your own reading of the lines. So you get no option list. Here are replacement candidates for all four lines you flagged, with the grounding beside them.

What triage found (from `content/ambient.json` and `docs/specs/ambient-voice.md`, Rules 1–4, which you ratified on 2026-08-02):
- `salt` breaks Rule 3 word for word: "regret" is an abstraction.
- `door` uses two nouns. Rule 3 says "one concrete noun carries the line".
- `lamp` passes all four rules. Your spec also uses it twice as the bar, in the Rule 3 example and in § Exemplars. If you pick a replacement for it, those two spec spots change too.
- `nets` is `ambient.night.nets`, a night line, not a dusk line. The dusk set has 6 rows, not 5. The "Nobody …" turn is in 3 of the 13 lines (`nets`, `rope`, and `coin` "Nobody stoops."). That repetition may be part of the "trying too hard" feel. The spec has no rule about it.

All candidates follow Rules 1–4: 9 words or fewer, one concrete noun, present tense, no "you", no abstraction.

**`ambient.dusk.salt`**, now "Salt on the windows, thick as regret."
1. Salt dries white along the sill.
2. The harbormaster's window wears a crust of salt.
3. Salt rims the glass.

**`ambient.dusk.door`**, now "Somewhere a door. Somewhere a dog."
1. A door shuts somewhere up the lane.
2. Up the hill, a gate bangs once.
3. A dog barks twice, then stops.

**`ambient.dusk.lamp`**, now "The lamplighter skips the third post again." This one is your spec exemplar. A pick here changes the spec too.
1. The third post stays dark.
2. The lamplighter's ladder leans against the third post.
3. One lamp out on the quay, the third.

**`ambient.night.nets`**, now "Nets drying. Nobody mending them." Written for night. None of these uses the "Nobody …" turn.
1. The nets drip onto the dark quay.
2. A net sags from the rail, still wet.
3. Nets hang heavy on the rail tonight.

Next step: pick a line for each row, write your own, or keep the original. You can also skip `lamp` and `nets`. I will then write the picks into `content/ambient.json`. A pick that changes the carrying noun also renames its key in `src/ambient.py` `SCHEDULE` in the same edit, because `load()` raises `KeyError` on a missing key. A new `lamp` line also updates the spec's Rule 3 example and § Exemplars. If you want the "Nobody …" repetition to become a spec rule, tell me. `coin` would then need a check too.

CARD_APPENDS:
NONE

TOOL_CALLS:
NONE. The candidate lines are drafted inline. They are text for the author to judge, with no file edit or derivation behind them, so they carry no propagation closure to dispatch (CLAUDE.md § Dispatch). There is no AskUserQuestion, no Agent dispatch and no edit.

WHY:
Step 3 sends a surface verdict to the taste branch ("no climb, no MCQ, no Design block: … produce the artifact the author judges … and hand it to the author with that grounding beside it") in this case: "A `### Decision needed` whose Findings name the author's eye as the only test takes this branch too: its options are a frame the author did not ask for." This verdict says "no unit/e2e test decides copy taste" and "settles by: preference — the author's own call". So I dropped the A/B/C scope MCQ and gave candidates for all four lines the author asked about, with the spec, exemplar and night-line findings beside them.
