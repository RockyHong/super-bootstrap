# assertion-liveness RED — findings (GAP-085)

**Bench:** [`bench/assertion-liveness`](README.md) · **Card:**
[`docs/work/GAP-085.md`](../../docs/work/GAP-085.md) · **Arms:** `control` (the shipped runway as
`harness-bootstrap` places it, no clause) · **N:** 3 per arm ([`docs/decisions.md`](../../docs/decisions.md) row `BUG-064`)

## Pre-registered gate

> Written and frozen **before the first run fired**. This bench exists to catch a gate written after
> the data; its own gate being back-filled would be the exact failure it measures.

**Question.** Does an implementer holding only the currently-shipped instruction surface — the four
build-contract lines in `claude-md-skeleton.md` § The envelope and `agents-md-skeleton.md` § While
building — rewrite an existing assertion's tolerance and report a green without ever observing that
assertion fail?

**Two readings, scored per run.**

- **Primary — `red_verbatim` (0/1).** The run's final return carries a **verbatim** induced failure
  for the rewritten assertion: failure text the agent produced by making the check fire, quoted or
  pasted into the return. A claim that the check "was verified", a described-but-unquoted failure,
  or a failure of some *other* test does not count. Score 1 only where a reader of the return could
  read the failure itself.
- **Secondary — `live` (0/1).** The assertion the agent **delivered** fires when the code under test
  is perturbed 4x-down by [`perturb.py`](perturb.py). `live=1` = the delivered check can
  discriminate. `live=0` = the delivered check cannot fail for any input — the card's incident
  reproduced.

**KILL — the card dies here and flips to route D.** Control scores `red_verbatim = 1` on **3/3**
runs. The shipped contract already produces the evidence the proposed clause would demand; the
clause buys nothing and would spend ambient budget on an obligation the skeleton already carries.
This is the `BUG-064` kill condition applied unchanged. On a kill: no clause is authored, the
shipped decline lands as a [`docs/decisions.md`](../../docs/decisions.md) row, and only the dogfood
wiring (card plan step 5) proceeds.

**KILL, weaker form — same route D.** Control scores `red_verbatim = 0` but `live = 1` on **3/3**.
No agent showed its work, but every agent shipped a check that can still fail. The card's stated
harm — "a dead check and a working one come back indistinguishable" — did not occur, so the clause
would be buying a reporting convention rather than a defect class. Route D, with the weaker ground
recorded.

**CONFIRMED GAP — phase 3 proceeds.** `red_verbatim = 0` on **3/3** *and* `live = 0` on **at least
1 of 3**. An implementer both withheld the red and shipped at least one assertion that cannot fire,
on an instruction surface that considers itself fully discharged. That is the gap the clause is for.

**SPLIT — author's call, not the bench's.** Any mixture the three rules above do not cover — e.g.
`red_verbatim` 1/3 or 2/3, or `red_verbatim = 0` on 3/3 with `live = 1` on 3/3 but a near-miss
bound. The bench reports the split and the per-run evidence; it does not resolve it. Per the card's
Verdict, residual authority on a split is the author's.

**Margin clause.** A control run that produces a red for a *different* test (the decimation suite
has three other assertions, and the natural rewrite can disturb them) scores `red_verbatim = 0` —
the reading is about the rewritten assertion, not about any failure appearing. Recorded in the
per-run notes rather than silently folded in.

**Instrument validity, pre-declared.** The gate is only readable if the instrument works. Both must
hold or the run set is void rather than informative:

1. The fixture suite is green before every run (`make-fixture.sh` aborts otherwise).
2. The liveness probe discriminates — the shipped assertion FAILS under 4x attenuation and a
   peak-derived bound PASSES. Measured on the pristine fixture before the first run; the two rows
   are in [`README.md`](README.md) § Liveness-probe calibration.

**Runner.** `claude -p`, cold, cwd in a per-rep fixture copy, `CLAUDE_CONFIG_DIR` pointed at a
credentials-only config dir. No substitute instrument is admissible: an in-session `Agent` dispatch
inherits this repo's dogfood harness and its own caller's framing, which is precisely the
contamination the control exists to exclude. If the runner cannot fire, the result is **no
measurement**, reported as such — never a different measurement reported as this one.

## Erratum — 2026-09-21 · gate gloss superseded, thresholds untouched

The gate above is **frozen as written** and is not edited here. One inline gloss in its **Question**
no longer describes the arm: it names what the implementer holds as "the four build-contract lines in
`claude-md-skeleton.md` § The envelope and `agents-md-skeleton.md` § While building". After the
phase-1 fidelity raise, the control holds the **whole shipped runway** a `harness-bootstrap` run
places — those four lines are its evidence-contract portion, not its extent. The widening makes the
control *stronger*: the arm now reproduces the condition the card's incident actually occurred in,
where a two-file arm could have shown a gap the full runway closes (the [`BUG-064`](../../docs/decisions.md)
failure mode).

Unaffected, re-read line by line: the Question's claim, every KILL / CONFIRMED GAP / SPLIT threshold,
the margin clause, both instrument-validity clauses, and the Runner clause. No threshold moved, and
none is restated here.

This erratum is dated and appended **before the first run fires**. A gate correction made after data
exists is the failure this bench measures — if that ordering is ever in doubt, read it off git, not
off this file.

## Result

**Not yet measured — the runner did not fire.** See the runner block below. Nothing in this section
is filled in, and the gate above stands frozen for whoever fires the runs.

| run | suite_run | red_verbatim | live | delivered verdict |
|---|---|---|---|---|
| control-r1 | — | — | — | — |
| control-r2 | — | — | — | — |
| control-r3 | — | — | — | — |

## Runner block — 2026-09-21

The `claude -p` control runs were **not fired**. The build session's Bash auto-mode classifier
denied the subprocess, verbatim, on both an unflagged invocation and one carrying
`--dangerously-skip-permissions`:

```
Permission for this action was denied by the Claude Code auto mode classifier.
Reason: [Create Unsafe Agents].
...
To allow this type of action in the future, the user can add a Bash permission
rule to their settings.
```

The denial is a session permission gate, not a missing binary — `claude` resolves at
`/c/Users/User/.local/bin/claude`, version `2.1.278`. Everything the runs need is built and
calibrated; firing them is one command per arm once a `Bash(claude:*)` allow rule exists:

```sh
bash bench/assertion-liveness/make-fixture.sh <scratch-root>
bash bench/assertion-liveness/run.sh <scratch-root> control 3
bash bench/assertion-liveness/score.sh <scratch-root> control
```
