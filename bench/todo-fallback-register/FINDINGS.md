# todo-fallback-register — findings (DEBT-118 M1+M2)

**Bench:** [`bench/todo-fallback-register`](README.md) · **Card:** `DEBT-118`,
findings M1 + M2 · **Arms:** `current` (shipped text, `HEAD`) · `proposed` (the card's
rewrite, applied by [`make-arms.py`](make-arms.py)) · **Reader:** `claude -p --model sonnet`
→ `claude-sonnet-5` on all 12 runs · **N:** 3 per arm per mode, modes `needme` + `full`

## Pre-registered gate

> Frozen before the first scored run. One instrument smoke run (`current`/`full`) fired earlier
> to prove the runner; it sits in [`runs/smoke/`](runs/smoke/), outside the scored set.

**Question.** M1/M2 remove caps/prohibition pressure (`render EXACTLY`, three `Do NOT`,
`(Read this FIRST)`, `Classify EXACTLY per it`) and one restated "read the spec" line, and add
the reason (the board script encodes the same spec). A removal: does the fallback lane, briefed
by the proposed text, render a board no worse than the shipped text's?

**Readings** ([`score.py`](score.py) docstring): `rows` — golden rows whose verb + intent bucket
(needme group / full Blocker) + stage (full) the board matches; `drain`, `pending`; `shape` —
title, headings, columns, no invented/duplicated rows, no recommendation, footer (k/6); `spec`
— the spec was Read (`spec_n`, how often).

**Verdict rule**, per mode, per summary reading (`rows`, `shape`, `spec`), C = current's 3 runs,
P = proposed's: **worse** when `max(P) < min(C)`; **no worse** when `mean(P) ≥ min(C)`; else
**unclear**. `proposed ≥ current` — all readings no worse in both modes; `proposed < current` —
any reading worse; `inconclusive` — otherwise. A ceiling tie counts as `≥` (equivalence claim).

**Instrument validity** (all required): golden re-render equals `bench/todo-board/expected/<mode>.md`
bar the title date; arm prompts differ on exactly the three M1 lines, agent bodies on exactly the
M2 lines; every assertion bites (below); every run resolves to `claude-sonnet-5`. All four held.

## Bite check

`bash bite.sh <fixture-root>` — one mutation of the golden per case; output verbatim:

    case                   target    rows	drain	pending	title	heads	cols	invented	reco	footer	shape	spec	spec_n	misses
    control-needme         -         9/9	1	1	1	1	1	1	1	1	6/6	1	1	-
    control-full           -         13/13	1	1	1	1	1	1	1	1	6/6	1	1	-
    wrong-group            rows      8/9	1	1	1	1	1	1	1	1	6/6	1	1	GAP-102
    wrong-verb             rows      8/9	1	1	1	1	1	1	1	1	6/6	1	1	GAP-104
    wrong-stage            rows      12/13	1	1	1	1	1	1	1	1	6/6	1	1	BUG-103
    wrong-blocker          rows      12/13	1	1	1	1	1	1	1	1	6/6	1	1	BUG-111
    wrong-drain            drain     9/9	0	1	1	1	1	1	1	1	6/6	1	1	-
    wrong-pending          pending   9/9	1	0	1	1	1	1	1	0	5/6	1	1	-
    bad-title              title     9/9	1	1	0	1	1	1	1	1	5/6	1	1	-
    renamed-heading        heads     8/9	1	1	1	0	0	1	1	1	4/6	1	1	GAP-107
    merged-groups          heads     2/9	1	1	1	0	0	0	1	1	3/6	1	1	GAP-104,BUG-111,GAP-109,GAP-102,GAP-105,snapshot,new-user
    bad-columns            cols      9/9	1	1	1	1	0	1	1	1	5/6	1	1	-
    invented-row           invented  13/13	1	1	1	1	1	0	1	1	5/6	1	1	-
    duplicated-row         invented  13/13	1	1	1	1	1	0	1	1	5/6	1	1	-
    recommendation         reco      9/9	1	1	1	1	1	1	0	0	4/6	1	1	-
    lost-footer            footer    9/9	1	1	1	1	1	1	1	0	5/6	1	1	-
    spec-not-read          spec      9/9	1	1	1	1	1	1	1	1	6/6	0	0	-

All sixteen cases bite on their target (`wrong-pending` and `recommendation` also trip `footer`
— both live in the footer block).

## Results

Per run ([`runs/scores.tsv`](runs/scores.tsv)):

    run	rows	drain	pending	title	heads	cols	invented	reco	footer	shape	spec	spec_n	misses
    current-full-r1	13/13	1	1	1	1	1	1	1	1	6/6	1	1	-
    current-full-r2	13/13	1	1	1	1	1	1	1	1	6/6	1	1	-
    current-full-r3	13/13	1	1	1	1	1	1	1	1	6/6	1	1	-
    current-needme-r1	9/9	1	1	1	1	1	1	1	1	6/6	1	1	-
    current-needme-r2	8/9	1	1	1	1	1	0	1	1	5/6	1	1	snapshot
    current-needme-r3	9/9	1	1	1	1	1	1	1	1	6/6	1	1	-
    proposed-full-r1	13/13	1	1	1	1	1	1	1	1	6/6	1	1	-
    proposed-full-r2	13/13	1	1	1	1	1	1	1	1	6/6	1	1	-
    proposed-full-r3	13/13	1	1	1	1	1	1	1	1	6/6	1	1	-
    proposed-needme-r1	8/9	1	1	1	1	1	0	1	1	5/6	1	1	snapshot
    proposed-needme-r2	9/9	1	1	1	1	1	1	1	1	6/6	1	1	-
    proposed-needme-r3	8/9	1	1	1	1	1	0	1	1	5/6	1	1	snapshot

| arm / mode | rows (min–max, mean) | shape (min–max, mean) | spec |
|---|---|---|---|
| current / needme | 0.889–1.0, 0.963 | 5–6, 5.67 | 3/3, read once each |
| proposed / needme | 0.889–1.0, 0.926 | 5–6, 5.33 | 3/3, read once each |
| current / full | 1.0–1.0 | 6–6 | 3/3, read once each |
| proposed / full | 1.0–1.0 | 6–6 | 3/3, read once each |

Gate: needme `rows` mean(P) 0.926 ≥ min(C) 0.889 → no worse; `shape` 5.33 ≥ 5 → no worse;
`spec` 1 ≥ 1 → no worse. Full: ceiling tie on all three.

**Verdict: `proposed ≥ current`.**

**The one miss is shared, and it is not the register.** Every needme deduction (current r2,
proposed r1 + r3) is the same cell: the snapshot test-queue row rendered with ID `DEBT-106`
(its `source:` back-pointer) instead of `—`. Group (Device-bound) and verb (Manually verify)
were right every time. The scorer counts the slip twice — `rows` (item key lost) and
`invented` (an ID outside the golden). Cause, pre-existing in both arms: SKILL.md Step 2 embeds
only the chosen-mode section of `assets/scaffolds.md`, while the `—`-for-test-queue rule lives in
that file's preamble (§ Sheet columns), which never reaches the agent; the embedded Full section
even says "per § Sheet columns above". 1/3 vs 2/3 at N=3 is noise around the same gap.
