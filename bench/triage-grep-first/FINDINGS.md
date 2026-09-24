# triage-grep-first — findings (DEBT-118 M4)

**Bench:** [`bench/triage-grep-first`](README.md) · **Card:** `DEBT-118` finding M4 ·
**Arms:** `current` (agents/triage.md body as shipped) vs `removed` (line 27 `Grep before reading.`
deleted) · **Model:** `claude -p --model opus` · **N:** 3 per arm per card (12 runs)

## Pre-registered gate

> Written before any scored run was read. One instrument smoke run (`BUG-002 / current`) preceded
> it; it exposed a blocked `grounding-discipline.md` read (fixed with `--add-dir`), was discarded,
> and survives only as the `bite/BUG-002-good` real-verdict specimen.

Per card, compare arms on: `cause` passes (of 3), contract failures (`origin` + `one_block` +
`shape` fails), `budget` exits, and on `BUG-002` the median `read_tok`.

- **`removed < current`** — on either card: `removed` scores ≥2 fewer `cause` passes; or more
  contract failures; or more `budget` exits; or on `BUG-002` `removed`'s median `read_tok` exceeds
  `current`'s maximum by more than 50%.
- **`inconclusive`** — a `cause` gap of exactly 1 run in `current`'s favour (N=3 noise), or the
  instrument invalid: a run exits non-zero, the agent cannot read `grounding-discipline.md`, or a
  run leaves no card.
- **`removed ≥ current`** — neither of the above.

Tool-call counts, partial-Read counts and `whole_target` are descriptive, not gate inputs.

## Instrument validity

12/12 runs exit 0; 12/12 read `grounding-discipline.md` (2109 chars each); 12/12 leave exactly one
modified file — their own card (`git status --short`). Bite check: [`bite.sh`](bite.sh) — every
assertion fails on an induced bad verdict (decoy verdict → `cause`; dropped `Execution:` +
`Test Strategy` → `shape`; edited Prior + second block → `origin` + `one_block`; budget-truncated
surface → `cause` fail, `budget`=1); both good verdicts pass all four.

## Per-run scores

`python3 score.py runs`:

| run | kind | origin | one_block | shape | cause | decoy | budget | tools | reads | greps | partial | read_tok | intake_tok | whole_target |
|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|
| BUG-001-current-r1 | auto-fix | 1 | 1 | 1 | 1 | 0 | 0 | 15 | 9 | 2 | 0 | 6594 | 7807 | 1 |
| BUG-001-current-r2 | auto-fix | 1 | 1 | 1 | 1 | 0 | 0 | 6 | 1 | 0 | 0 | 233 | 8624 | 0 |
| BUG-001-current-r3 | auto-fix | 1 | 1 | 1 | 1 | 0 | 0 | 14 | 9 | 1 | 0 | 6484 | 7143 | 1 |
| BUG-001-removed-r1 | auto-fix | 1 | 1 | 1 | 1 | 0 | 0 | 16 | 10 | 2 | 0 | 6848 | 7629 | 1 |
| BUG-001-removed-r2 | auto-fix | 1 | 1 | 1 | 1 | 0 | 0 | 16 | 10 | 1 | 0 | 6848 | 7626 | 1 |
| BUG-001-removed-r3 | auto-fix | 1 | 1 | 1 | 1 | 0 | 0 | 14 | 11 | 1 | 0 | 7859 | 8564 | 1 |
| BUG-002-current-r1 | auto-fix | 1 | 1 | 1 | 1 | 0 | 0 | 14 | 7 | 3 | 0 | 2788 | 4767 | 1 |
| BUG-002-current-r2 | auto-fix | 1 | 1 | 1 | 1 | 0 | 0 | 12 | 6 | 2 | 0 | 2650 | 4322 | 1 |
| BUG-002-current-r3 | auto-fix | 1 | 1 | 1 | 1 | 0 | 0 | 13 | 8 | 2 | 0 | 3200 | 5781 | 1 |
| BUG-002-removed-r1 | auto-fix | 1 | 1 | 1 | 1 | 0 | 0 | 13 | 7 | 2 | 0 | 2986 | 5560 | 1 |
| BUG-002-removed-r2 | auto-fix | 1 | 1 | 1 | 1 | 0 | 0 | 15 | 8 | 3 | 0 | 3997 | 6394 | 1 |
| BUG-002-removed-r3 | auto-fix | 1 | 1 | 1 | 1 | 0 | 0 | 15 | 8 | 3 | 0 | 3124 | 5495 | 1 |

`BUG-001-current-r2` read every file through Bash `cat` (one 23k-char `cat` of engine.py +
refunds.py + events.py + docs), so its `read_tok` / `whole_target` under-read; `intake_tok` (all
tool output) is the honest figure for it — it did read engine.py whole.

Hand-read of all 12 cause sections confirms the rubric: every BUG-001 verdict traces `run()`
`engine.py:89-90` emitting before the final `_rollover(None)` (orphan Statement, balance written
without the refund) and falsifies the `is_duplicate` Prior — most also derive the replay-skip log
line from `_apply_refund`'s `record()` call. Every BUG-002 verdict names `dunning.py:45`'s swapped
`(locale, currency)` and falsifies the `SYMBOLS` Prior against `money.py:16`.

## Spread per arm

| card | arm | cause | contract fails | budget | intake_tok median (range) | read_tok median (range) |
|---|---|---|---|---|---|---|
| BUG-001 | current | 3/3 | 0 | 0 | 7807 (7143–8624) | 6484 (233–6594) |
| BUG-001 | removed | 3/3 | 0 | 0 | 7629 (7626–8564) | 6848 (6848–7859) |
| BUG-002 | current | 3/3 | 0 | 0 | 4767 (4322–5781) | 2788 (2650–3200) |
| BUG-002 | removed | 3/3 | 0 | 0 | 5560 (5495–6394) | 3124 (2986–3997) |

## Verdict — `removed ≥ current`

No gate condition fires: `cause` 3/3 both arms both cards; 0 contract failures; 0 budget exits;
BUG-002 `removed` median `read_tok` 3124 vs `current` max 3200 (threshold 4800).

What the readings show: **no arm made a single partial (offset/limit) Read in 12 runs, and every
run read the cause file whole — the `current` arm included.** The shipped bullet did not steer the
reader into grep-then-partial reads, so it neither paid on the grep-first card nor hurt on the
whole-file card. The only lean is a small intake increase for `removed` on BUG-002 (~12–17% at the
median, ranges barely overlapping), far inside the pre-registered margin.

**Not measured.** Budget pressure: fixture intake ran ~4–9k tokens against the agent's ~30k read
budget, so whether the bullet matters on a repo large enough to press the budget is untested.

## Side observation (both arms, not M4)

The agent's Bash floor ("read-only: `git status/diff/log`, `ls`") is not what it does: 9/12 runs
tried to append the verdict via a Bash `cat >> card <<EOF` heredoc (rejected by the harness parser,
fell back to Edit), one run read files with `cat`/`sed`/`find` (auto-allowed read-only commands),
one tried to run python (denied). Arm-independent.

## DEBT-121 option A — per-action Bash floor (`floor` arm)

**Card:** `DEBT-121` · **Arm:** `floor` ([`arm-floor.md`](arm-floor.md)) — the shipped body with
`Bash stays read-only (git status/diff/log, ls).` restated per action: verdict append through Edit
(anchor on the card's final lines), reads through Read/Grep/Glob, Bash for `git status/diff/log`,
`ls` and the `§ Probes` commands, "no redirect, heredoc, or interpreter call of your own" ·
**Baseline:** the 12 M4 runs above (both arms carry the old floor sentence) · **Model:**
`claude-opus-5-5` (`--model opus`) · **N:** 6 per card under `acceptEdits` (12), plus 3 per card
under `--permission-mode auto` (6). Fixture rebuilt with `make-fixture.sh`; `diff -r` against the
M4 fixture repo is empty.

**Gate (set in the dispatch brief before any `floor` run):** `floor` holds `b_write` and
`b_interp` runs at ≤1/12 each, with `cause` and contract assertions unchanged → ship option A;
otherwise fall back to option C.

**Instrument.** 18/18 runs exit 0; 18/18 leave exactly one modified file — their own card. The
auto-mode reminder is confirmed present under `--permission-mode auto` and absent under
`acceptEdits`, by a one-shot probe with the cold config asking the model to quote it (the
stream-json transcript does not echo injected reminders). The classifier's bite on the baseline:
9/12 runs flag `b_write`, each a `cat >> docs/work/<card>.md <<'EOF'` call, e.g.
`BUG-001-current-r1 … bash 3 b_write 1 b_interp 0 b_read 2`; one run flags `b_interp`
(`BUG-002-current-r3`, `PYTHONIOENCODING=utf-8 … python -c "from tally.money import fmt_money …"`).

`python3 score.py runs` — per-arm summary (runs with ≥1 call in the class; call totals in brackets):

| arm | runs | cause | contract fails | b_write | b_interp | b_read |
|---|---|---|---|---|---|---|
| baseline (`current` + `removed`) | 12 | 12/12 | 0 | 9/12 [9] | 1/12 [1] | 12/12 [24] |
| `floor` (acceptEdits) | 12 | 12/12 | 0 | **0/12** [0] | **0/12** [0] | 3/12 [3] |
| `floor` (auto) | 6 | 6/6 | 0 | 0/6 [0] | 0/6 [0] | 3/6 [11] |

Per-card `floor` intake is in range of the baseline: BUG-001 `intake_tok` 7502–7576 (baseline
7143–8624), BUG-002 5025–6796 (baseline 4322–6394); every `floor` run reads the cause file whole.
Hand-read spot check of the cause sections matches the rubric (engine.py:89-90 emit-before-rollover;
dunning.py:45 swapped `(locale, currency)`), each falsifying the planted Prior.

## Verdict — gate passes; option A shipped

`floor` under `acceptEdits`: 0/12 heredoc/redirect writes (baseline 9/12), 0/12 interpreter calls
(baseline 1/12), every verdict appended through a single Edit; `cause` 12/12 and 0 contract
failures, same as baseline. The body shipped as `arm-floor.md` byte-identical
(`agents/triage.md` line 19).

What remains in `b_read`: all 3 acceptEdits hits are a `find . -path ./.git -prune -o -type f -print`
tree listing in the orientation call (the rest use `ls -R`) — a listing, within the floor's `ls`
intent. Under auto mode the reminder's pull shows up on reads, not writes: 3/6 runs
(`BUG-001-floor-auto-r3`, `BUG-002-floor-auto-r2`, `BUG-002-floor-auto-r3`) read file content
through Bash `cat -n` / `grep -rn` / `sed -n` instead of Read (11 calls across 3 runs),
while still appending through Edit and running no interpreter. The per-action floor holds the write
and interpreter lines against the reminder; it does not fully hold the read line — read-only, so
inside the phase identity.
