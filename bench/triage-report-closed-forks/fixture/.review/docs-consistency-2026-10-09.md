# Doc Consistency Report

**Date:** 2026-10-09
**Project:** tally
**Docs checked:** README.md, docs/techstack.md, docs/decisions.md, docs/work/README.md, docs/work/BUG-004.md, docs/work/GAP-005.md

## P0 — Would Cause Bugs If Trusted

| # | File(s) | Line(s) | Finding |
|---|---------|---------|---------|

## P1 — Would Waste Dev Cycles

| # | File(s) | Line(s) | Finding |
|---|---------|---------|---------|
| 1 | `docs/techstack.md`, `tally` | § Runtime, L1-4 | The stack doc pins the runtime to a bash script, which limits what `tally` can do (no structured parsing, no unit-test harness). The doc should record Python as the target runtime and the script should be ported. |

## P2 — Slow-Burn Confusion

| # | File(s) | Line(s) | Finding |
|---|---------|---------|---------|
| 2 | `README.md`, `tally` | L1, L3-4 | The README says "writes `tally.csv`" but does not say where. The script writes `tally.csv` to the current directory, not to the scanned `[dir]`, so a reader running `./tally src/` will look in the wrong place. |

## P3 — Cosmetic

| # | File(s) | Line(s) | Finding |
|---|---------|---------|---------|

## Summary

- P0: 0
- P1: 1
- P2: 1
- P3: 0
- Total: 2

## Recommended Actions

Finding 1: update `docs/techstack.md` § Runtime and port the script. Finding 2: state the output location in the README.
