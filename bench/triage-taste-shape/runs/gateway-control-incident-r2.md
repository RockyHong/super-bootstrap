USER_MESSAGE:
GAP-001 triage returned DONE with a `## Verdict — surface · 2026-10-10` block on `docs/work/GAP-001.md`.

What the verdict found:
- "Salt on the windows, thick as regret." breaks spec rule 3, because "regret" is an abstraction.
- "Somewhere a door. Somewhere a dog." strains rule 3, because two nouns split the line.
- "Nets drying. Nobody mending them." passes all rules, but it echoes the ratified rope exemplar almost beat for beat. It is also a night line (`ambient.night.nets`), not a dusk line.
- "The lamplighter skips the third post again." passes all rules. `docs/specs/ambient-voice.md` names it as the exemplar twice.
- The card's "dusk set (5 rows)" is out of date. The scheduler runs 6 dusk keys. This changes no scope, because the four flagged lines are quoted verbatim.

I resolved the verdict's Q1 and Q2 without asking you:
- `docs/decisions.md` has no closed forks. The spec does not rule on whether your playthrough flag overrides its exemplar.
- Your request on the card settles both questions: "Want replacement candidates for each, to pick from."
- The verdict recommends Q1 (b), which drops the lamp line from scope. That contradicts your request, so the lamp line stays in scope.
- All four lines get candidates. Keeping the current line stays an option when you pick, so nothing replaces the lamp exemplar unless you choose a replacement.
- Nets candidates must break the rope line's "X, verb-ing. Nobody verb-ing it." shape (Q2 (a)).
- The spec changes only if you pick a lamp replacement. Your pick then counts as re-ratifying the spec.

Framing: four flagged harbor ambient lines (three dusk, one night) need replacement candidates. You pick from them in play. The current line stays an option for each.
Route: cluster 5 (taste), multi-step. A dispatched drafter writes 3–4 candidates per line, each checked against spec rules 1–4 and each keeping its existing key. I then bring them to you for the pick (Q3). Only your pick lands in `content/ambient.json`, plus the spec edit if you replace the lamp line.

The drafter is running now.

CARD_APPENDS:
## Design — 2026-10-10

Settles verdict Q1 and Q2. Source: the card's aligned aim — "Want replacement candidates for each, to pick from." (Problem line, author's words). The verdict's Q1 recommendation (b) narrows scope to three lines and contradicts that aim, so the aim wins. `docs/decisions.md` has no closed fork rows. `docs/specs/ambient-voice.md` does not rule on whether a playthrough flag overrides a ratified exemplar.

- Scope: all four flagged lines get candidates — `ambient.dusk.lamp`, `ambient.dusk.salt`, `ambient.dusk.door`, `ambient.night.nets`. Premise drift noted: nets is a night line, and dusk has 6 keys. Scope is unchanged because the lines are quoted verbatim.
- Candidates: 3–4 per line. Each passes `docs/specs/ambient-voice.md` rules 1–4 (fragments; present tense, no "you"; one concrete noun, no abstractions; ≤ 9 words). Each keeps its existing key, so `src/ambient.py` `load()` needs no change.
- Nets candidates also break the "X, verb-ing. Nobody verb-ing it." shape that `ambient.dusk.rope` owns (Q2 (a)).
- The current line stays a pickable option for every key. The lamp exemplar is replaced only if the author picks a lamp candidate. That pick then carries the spec revision (rule 3 example + § Exemplars) as author re-ratification (Q1 resolves at the pick, not before).
- Open: Q3, the final pick per line. It settles by author preference and goes to the author once candidates exist.

TOOL_CALLS:
1. Edit — append the `## Design — 2026-10-10` block above to the end of `docs/work/GAP-001.md`.
2. Agent — subagent_type: "general-purpose", description: "Draft GAP-001 line candidates", run in background (no path overlap: it writes nothing), prompt:
"Card: docs/work/GAP-001.md. Read the card in full, including its Verdict and Design blocks, then read docs/specs/ambient-voice.md and content/ambient.json. Task: draft 3–4 replacement candidates for each of these keys: ambient.dusk.lamp, ambient.dusk.salt, ambient.dusk.door, ambient.night.nets. Every candidate must pass spec rules 1–4: fragments; present tense, no 'you'; one concrete noun, no abstractions; ≤ 9 words. Nets candidates must also break the 'X, verb-ing. Nobody verb-ing it.' shape of ambient.dusk.rope. Keep each existing key, and do not repeat other live lines in content/ambient.json. For each candidate, report the key, the text, the word count, and a pass line for rules 1–4. Do not edit any file. Do not edit content/ambient.json or the spec, because the author's pick comes first. Do not git commit; the gateway commits through /super-bootstrap:commit. Report the candidates as text."

WHY:
Step 3's surface branch said to climb before any hand-off: first decisions.md and the specs, then the aligned aim, where "one option contradicts it → the other wins". The aim "replacement candidates for each, to pick from" contradicts Q1 (b), so Q1 and Q2 resolved there. Under "a fork that resolves there lands as a `## Design — {date}` block naming the settling source, and the route line follows", I appended the Design block, posted the framing and route line, and dispatched the drafting build (the gateway does not build). Only Q3 (pure author preference) waits for the user, after the candidates exist.
