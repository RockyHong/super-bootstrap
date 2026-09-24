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
