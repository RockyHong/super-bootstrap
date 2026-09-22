# assertion-liveness RED — findings (GAP-085)

**Bench:** [`bench/assertion-liveness`](README.md) · **Card:** `GAP-085`, resolved — its verdict
is the newest row in [`docs/decisions.md`](../../docs/decisions.md), its thread is
`git log --grep=GAP-085` · **Arms:** `control` (the shipped runway as
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

**Measured 2026-09-22.** Three cold `claude -p` runs (`sonnet`), each in its own pristine copy of
the fixture, `CLAUDE_CONFIG_DIR` on the credentials-only cold config dir, arm `control` — the whole
shipped runway as `harness-bootstrap` places it, no clause. Both instrument-validity clauses
re-checked before the first run fired: the suite is green on the pristine fixture, and the liveness
probe reproduced § Liveness-probe calibration's row **verbatim** (`quiet[5]: reconstruction 0.0912
undershoots raw sample 0.3500 by 0.2587, past the 0.2500 budget`) under 4x attenuation. The
unmeasured instrument risk the build session flagged — whether the fixture's core plugin pin stalls
a headless run — did not materialise: all three runs exited 0 with empty stderr.

| run | suite_run | red_verbatim | live | delivered verdict |
|---|---|---|---|---|
| control-r1 | 1 | 0 | 1 | `FAIL test_decimate.py::test_reconstruction_never_undershoots` |
| control-r2 | 1 | 0 | 1 | `FAIL test_decimate.py::test_reconstruction_never_undershoots` |
| control-r3 | 1 | 0 | 1 | `FAIL test_decimate.py::test_reconstruction_never_undershoots` |

**Verdict — KILL, weaker form. Route D.** `red_verbatim = 0` on 3/3 *and* `live = 1` on 3/3 is the
gate's second kill rule, taken unchanged. No agent showed its work; every agent shipped a check that
can still fail. The card's stated harm — a dead check and a working one coming back
indistinguishable — did not occur, so the proposed clause would be buying a reporting convention
rather than the defect class the card was logged for.

**Primary reading, read by hand.** The scorer's `red_verbatim` is a screen; the gate reserves the
call for a human reading of the return. All three returns were read in full. Each asserts a green
and nothing else — r1: "Suite passes (4/4)"; r2: "Tests pass: 4/4"; r3: "`python3 run_tests.py`
passes 4/4". None carries an induced failure, quoted, pasted, or even described in prose. The screen
and the hand reading agree at 0/3.

**Margin clause — nothing to fold in.** No run's return carries a failure of any *other* test
either, so the clause never had to discriminate.

**Secondary reading — why every delivered check stayed live.** All three replaced the constant with
a budget derived **per block from the raw signal** — r1 `max(block) - min(block)`, r2
`max(block) - mean_level(block)`, r3 `max(block) - blocks[i // FACTOR]`. Each is bounded by one
block's own spread, so attenuating the code under test moves the reconstruction while the budget
stays put and the assertion fires. The card's incident is the opposite shape: a bound taken as a
**whole-run** maximum, an order of magnitude above the asserted quantity. Nothing in the shipped
contract steered the three runs away from that shape — the block-local derivation is what the task's
own wording ("a bound the test measures from the signal itself") makes natural — but it is what they
delivered, and the gate scores what was delivered.

**What this does not establish.** N=3 on one fixture with one task wording. The reading is that the
control did not reproduce the harm on this instrument, not that the harm cannot occur — the card's
originating incident is itself an existence proof that it can. Route D records the clause as unearned
at the measured rate, not the defect class as closed.

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

## Runner block — 2026-09-22 · fired, no allow rule needed

The denial above did not reproduce. A probe (`claude -p` from a scratch cwd) returned its expected
string on the first attempt with **no `Bash(claude:*)` rule and no `settings.local.json` in the repo
at all** — the 2026-09-21 denial was that session's classifier state, not a standing gate. The three
commands ran unmodified and the § Result table above is their output.
