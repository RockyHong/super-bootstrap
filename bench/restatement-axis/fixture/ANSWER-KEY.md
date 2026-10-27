# Answer key — `bench/restatement-axis/fixture`

Ground truth for the restatement axis: one fact (a claim's content, not a term) stated
in K places, where at least one copy carries no one-hop link to a single home. Judge
input never includes this file.

The corpus is six docs: `README.md` plus `docs/{overview,operations,sensors,door-interlock,recipes}.md`.
Four cases are planted; everything else is filler written to hold no restatement, no
contradiction, no broken link, and no orphan.

| # | Case | Fact (content) | K | Locations | Home | Expected (target axis) |
|---|------|----------------|---|-----------|------|------------------------|
| A | Pinned — intra-doc ×4, unlinked | A proof schedule is the ordered stages of `schedules/<name>.toml`; each stage = temperature + humidity + minutes; stages run strictly in file order; after the last stage the cabinet holds at 4 °C until unloaded. | 4 | `README.md:19-22` (§ How it works), `:43-45` (§ Writing a schedule), `:73-76` (§ Troubleshooting), `:90-92` (§ FAQ) | none designated (§ How it works is the natural candidate; either "no home" or that section is accepted) | **Finding, P2** — K = 4, all four locations, home named or "no home". No copy links anywhere. |
| B | Cross-doc ×2, unlinked | The controller samples each probe every 15 s and acts on the mean of the last 8 samples (a 2-minute rolling window), so an opened-door spike takes up to two minutes to wash out. | 2 | `docs/overview.md:23-25` (§ How a reading becomes an action), `docs/operations.md:20-23` (§ Starting a run) | none designated (overview's section is the natural candidate; either accepted) | **Finding, P2** — K = 2, both locations, home named or "no home". |
| C | Negative control — ×3 copies, every copy linked | Opening the door pauses the active stage's timer and blocks any stage change until the door has been shut for 30 s. | 3 copies + home | copies `README.md:64-66` (§ Safety), `docs/overview.md:34-37` (§ The door), `docs/operations.md:27-29` (§ During a run); home `docs/door-interlock.md:8-9` (§ Interlock rule) | `docs/door-interlock.md#interlock-rule` | **No finding.** Every copy links one hop to the home on the asserting line; doctrine admits a linked restatement. |
| D | Bare-pointer decoy | "Probe calibration has its own section further down." — names where calibration lives, carries none of its content. | 1 (the pointer is not a copy) | pointer `docs/sensors.md:4-5`; content `docs/sensors.md:20-29` (§ Calibration) | `docs/sensors.md` § Calibration | **No finding.** A naive counter scores K = 2 with an unlinked copy; the pointer carries no content, so K = 1. Intra-doc, so the current P3 link-gap class (cross-doc only) does not apply either. |

## Scoring

- **Recall** — cases A and B each reported as a restatement / duplicated-fact finding,
  naming every location (A: all four README spans; B: both docs). A hit missing a
  location is partial: recall counts, location precision does not. Any P-level counts
  for recall; P2 is the target level.
- **False positives** — any restatement or duplication finding on case C or case D.
- **Unplanted findings** — any other finding is read against the corpus by hand: the
  filler is meant clean, so an unplanted finding is either a fixture defect (fix the
  fixture, re-run) or a false positive.

### RED read (current skill text)

The RED question is narrow: does the current Step 1–2 text already report case A?

- **Case A reported** (as a restatement, duplicated fact, or any finding that names
  the fact and at least two of its README locations as the defect) → RED did not go
  red. Per the card's Plan, stop: no axis diff, outcome lands as a
  `docs/decisions.md` row.
- **Case A absent** → RED is red; the axis build proceeds.
- **Case B** is read but does not decide RED. The current P3 link-gap class can
  plausibly catch it if the judge reads one copy as the home and the other as an
  unlinked use. Record which class fired, if any; that is the baseline the new axis
  must not regress.
- A P3 link-gap suggestion on C's copies, or any finding on D, is a false positive
  for the current text as well.
