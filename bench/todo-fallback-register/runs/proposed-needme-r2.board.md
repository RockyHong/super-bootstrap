# To-Do — 2026-09-24

Drainable: 4  →  /super-bootstrap:drain

▸ Need me

## Decide / approve

| #  | ID      | Action                                                                                                         | unblocks | Impact     | Blast |
| -- | ------- | -------------------------------------------------------------------------------------------------------------- | -------- | ---------- | ----- |
| 1  | GAP-104 | Approve design: settings import wizard. It settles the parser.ts ingestion convention, which BUG-101 works on, and it holds BUG-108 and BUG-113. | 3        | impactful  | pkg   |
| 2  | BUG-111 | Decide: retry backoff resets on socket errors. Triage verdict: cap total attempts or cap elapsed time.        | 0        | quick-pop  | local |
| 3  | GAP-109 | Decide: telemetry opt-in copy. Waiting on user for the final consent wording.                                  | 0        | quick-pop  | local |
| 4  | GAP-102 | Decide: export command shape. Triage verdict: single-file or directory bundle.                                 | 0        | quick-pop  | local |

## Device-bound

| #  | ID      | Action                                                                                                         | unblocks | Impact     | Blast |
| -- | ------- | -------------------------------------------------------------------------------------------------------------- | -------- | ---------- | ----- |
| 1  | GAP-105 | Continue execute: onboarding flow revamp (2/4). Navigation wiring is next; the plan ends with a manual mobile-viewport test. | 0        | quick-pop  | local |
| 2  | —       | Manually verify: Snapshot suite re-run after flake fix. Run the suite twice and expect identical output (source DEBT-106; this row covers its review). | 0        | quick-pop  | local |
| 3  | —       | Manually verify: New-user tour on tablet. Walk the tour end to end with no dead step.                          | 0        | quick-pop  | local |

## Harness

| #  | ID      | Action                                                                                          | unblocks | Impact     | Blast |
| -- | ------- | ----------------------------------------------------------------------------------------------- | -------- | ---------- | ----- |
| 1  | GAP-107 | Deliberate: dispatch-grade rule for probe scripts. New rule `.claude/rules/probe-dispatch.md` declaring the grade ladder. | 0        | impactful  | repo  |

## Uncategorized

| #  | Action                     | Why ambiguous                                                     |
| -- | -------------------------- | ----------------------------------------------------------------- |
| 1  | docs/work/notes-scratch.md | not a card — see docs/work/README.md § Routing                    |

pending unblock: 2
flat list: /super-bootstrap:todo full · drainable detail: /super-bootstrap:todo cloud
more: /super-bootstrap:help