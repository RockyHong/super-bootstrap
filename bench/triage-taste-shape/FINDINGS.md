# triage-taste-shape — findings (BUG-084)

**Bench:** [`bench/triage-taste-shape`](README.md) · **Card:** `BUG-084` · **Model:** in-session
`general-purpose` subagents at `opus` (the agent is `model: inherit`) · **Run:** 2026-10-10 ·
**N:** 2 per arm per input (16 runs).

Copy under test: the in-repo dev copy (`plugins/super-bootstrap/`), snapshotted by `make-arms.sh` —
`control` before the prose edit, `treatment` after it.

## Pre-registered expectation

From the card's Verdict test strategy, written before any run:

- agent control: a `surface` block with lettered options + a recommendation → `no_options` /
  `no_reco` / `no_settles` red.
- gateway control: absorbing such a block puts an MCQ or a `## Design` block to the author →
  `no_design` and/or `no_ask_tool` red.
- treatment: both arms green on every input. If control did not fail, stop and ship no prose.

## Instrument validity

16/16 runs returned; 4/4 agent runs left exactly one modified file, their own card
(`git status --short` → ` M docs/work/GAP-001.md`). Bite check ([`bite.sh`](bite.sh), exit 0) —
every assertion reds on a violating input and passes on a clean one:

```
agent-bad.card.md: one_verdict=1 no_options=0 no_reco=0 no_settles=0 kind=surface shape=taste cites_spec=1 corrects_claim=1
FAIL agent-bad.card.md no_options: option line: '- (a)'
FAIL agent-bad.card.md no_reco: line: '- recommendation: (a)'
FAIL agent-bad.card.md no_settles: line: '- settles by: preference'
agent-twoverdicts.card.md: one_verdict=0 ...
FAIL agent-twoverdicts.card.md one_verdict: 2 Verdict headers
gateway-bad.md: no_design=0 no_ask_tool=0
FAIL gateway-bad.md no_design: CARD_APPENDS holds a ## Design block
FAIL gateway-bad.md no_ask_tool: TOOL_CALLS holds AskUserQuestion
```

Two scorer fixes landed after the first score pass, both re-bitten: `no_options` widened to catch
`- (a)` sub-options (control r2's shape); `no_ask_tool` stopped counting a declared
"No AskUserQuestion" (every treatment gateway run wrote that sentence and scored a false red).
A regex `candidates` reading was dropped — candidates arrive quoted, bare or numbered, so it
could not tell them from quoted grounding; candidate production is hand-read below.

## Control — RED on both arms

`python score.py agent runs/agent-control-*.card.md` / `gateway runs/gateway-control-*.md`:

| run | result |
|---|---|
| agent-control-r1 | `no_options` `no_reco` `no_settles` red — shape `decision` |
| agent-control-r2 | `no_options` `no_reco` `no_settles` red — shape `decision` |
| gateway-control-taste-r1 | `no_design` `no_ask_tool` red |
| gateway-control-taste-r2 | `no_design` `no_ask_tool` red |
| gateway-control-incident-r1 | `no_design` red |
| gateway-control-incident-r2 | `no_design` red |

Agent control reproduced the incident: both runs grounded well (both cite the exemplar and catch
the night line) and both still forked. Verbatim, r1:

> - A — all four. The playthrough read overrides the spec for `lamp` and `nets`; the `lamp` change also revises the spec's Rule 3 example and § Exemplars (a spec amendment, author-approved).
> - recommendation: C — it honors the ratified spec's explicit exemplar (`lamp`), fixes the two lines the spec already rejects, …
> - settles by: preference — the author's own call (the spec's approver), …

r2 framed the incident's own fork, "rule stands / rule narrows":

> - Q1 — the lamp line is the spec's own exemplar. Does the author's flag overturn the ratified exemplar?
>   - (a) Yes — replace `ambient.dusk.lamp`, and the same change revises `docs/specs/ambient-voice.md` …
>   - (b) No — keep the lamp line; the spec stands and the card narrows to three lines.
>   - recommendation: (b) — …

Gateway control failed even on the fixed grounding-only block (`taste` input — no options in it):
it climbed, ruled three lines into a Design block, and put the exemplar to the author as an MCQ.
taste-r2, verbatim:

> ## Design — 2026-10-10
>
> Settled by `docs/specs/ambient-voice.md` (ratified 2026-08-02), its four rules: …
>
> 2. AskUserQuestion. Question: "Keep or replace `ambient.dusk.lamp` …? Your spec cites it twice as an exemplar." Options:
>    - "Replace it and update the spec's rule 3 example + Exemplars entry (Recommended)"

On the incident input it settled the agent's forks itself and wrote a Design block ruling them —
incident-r2, verbatim: "I resolved the verdict's Q1 and Q2 without asking you" … "## Design —
2026-10-10 / Settles verdict Q1 and Q2."

## Treatment — GREEN on both arms

| run | result |
|---|---|
| agent-treatment-r1 | all pass — shape `taste`, `cites_spec=1`, `corrects_claim=1` |
| agent-treatment-r2 | all pass — shape `taste`, `cites_spec=1`, `corrects_claim=1` |
| gateway-treatment-taste-r1/r2 | all pass; candidates drafted inline, `CARD_APPENDS: NONE` |
| gateway-treatment-incident-r1/r2 | all pass; candidates drafted inline, `CARD_APPENDS: NONE` |
| gateway-treatment-e2e-r1/r2 | all pass; candidates drafted inline, `CARD_APPENDS: NONE` |

Agent treatment kept every grounding item the control found and dropped the fork. r1, verbatim:

> - docs rule: … `ambient.dusk.lamp` … is a ratified **Exemplar** … and is also Rule 3's worked example … The flag collides with the author-ratified spec; replacing it unseats an exemplar and Rule 3's example.
> - card corrections: … "Nets drying. Nobody mending them." is `ambient.night.nets`, scheduled at night …
> - shared trait (observation): each flagged line pairs its object with a second beat — a recurrence ("again"), a simile ("thick as regret"), a doubled "Somewhere", or an absence ("Nobody mending"). …

Gateway treatment handed the author words, the grounding beside them. e2e-r1, verbatim:

> **1. `ambient.dusk.lamp`: "The lamplighter skips the third post again."**
> Grounding: this line is a ratified Exemplar in the spec … If you replace it, the Exemplars list and the Rule 3 example change too. …
> - a. "One lamp unlit at the end of the quay." (9)
> - b. "The lamplighter's ladder against the third post." (7)
> - …
> - d. Keep the line and leave the spec as it is.

The `incident` input tests the treatment skill's fallback clause on a control-shaped verdict (a
`### Decision needed` whose Findings name the author's eye as the only test): 2/2 took the taste
branch and cited the clause — incident-r1, verbatim: "This verdict says "no unit/e2e test decides
copy taste" and "settles by: preference — the author's own call". So I dropped the A/B/C scope MCQ
and gave candidates for all four lines the author asked about".

## Verdict — RED → GREEN

Control failed every assertion the incident predicts, on both arms; treatment passed every
assertion on every input. Every treatment gateway run drafted the candidates inline (no
dispatch) and named the author's pick as the next step, landing no Design block before it.

**Not measured here.** N=2 per cell; no headless cold-config run (in-session subagents inherit
this repo's ambient context, held equal across arms). A real fork that sits beside a taste call
(a business or risk call on the same card) is not exercised — the fixture has none.
