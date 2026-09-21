# bench/triage-batch-fanout — micro-test for the triage one-card-per-dispatch batch rule

Test surface for [`skills/triage/SKILL.md`](../../plugins/super-bootstrap/skills/triage/SKILL.md)
§ Rules' `One card per dispatch` line — the clause that decides whether a gateway handed N
un-grounded cards issues the N triage dispatches together or one after another. Behavior-shaping
prose, so it ships behind the [`skill-authoring`](../../.claude/rules/skill-authoring.md) RED
floor: the wording is held against the wording it replaces, reading-only (no fixture repo — the
model is handed the scenario + three excerpts and asked what it would do).

## Protocol

Arms run headless (`claude -p --model haiku`, no tools) with the prompt on stdin — a scenario:
three cards (`DEBT-201`, `DEBT-202`, `GAP-203`), none carrying a Verdict block, the user asks the
gateway to ground all three. The model answers CONCURRENT (all three dispatches issued together)
or SERIAL (one, wait, next), citing which excerpt decided it. Both arms carry the same three
excerpts: the root `CLAUDE.md` § Dispatch parallel-within-a-phase bullet, `agents/triage.md`
§ Phase identity's one-write floor, and the `skills/triage/SKILL.md` § Rules block — whose
`One card per dispatch` bullet is the only line that differs between arms.

- **Control** — the pre-fix bullet: `Batch = sequential dispatches; verdicts stay per-card
  atomic.` Run 3×.
- **Arm** — the shipped bullet: `A batch fans out — each dispatch's write set is its own
  docs/work/{ID}.md (agents/triage.md § Phase identity), so concurrent grounding keeps verdicts
  per-card atomic. The gateway's absorb of each verdict (step 3) stays serial.` Run 3×.
- **Expectation** — control splits or lands SERIAL (the literal read) → RED; arm lands CONCURRENT
  3/3 → GREEN. If control lands CONCURRENT 3/3, the clause fails the cut test (the CLAUDE.md
  parallel bullet already resolves it) — report plainly rather than shipping a story.

## Findings

Run 2026-09-21, `claude -p --model haiku`, no tools, three trials per arm.

| Arm | Trial | Answer | Cited reasoning |
|---|---|---|---|
| Control (pre-fix, "Batch = sequential dispatches") | 1 | SERIAL | Quoted the bullet; "sequential dispatch preserves the isolation each triage judgment requires" |
| Control | 2 | SERIAL | Quoted the bullet, then overrode Excerpt 1 explicitly — "'Parallel within a phase, not across it' … doesn't override this because Excerpt 3's rule on verdict atomicity is the floor" |
| Control | 3 | SERIAL | Quoted the bullet; "even though Excerpt 1 permits parallelism within a phase — the triage rule takes precedence" |
| Arm (shipped, write-set wording) | 1 | CONCURRENT | Excerpt 1's fan-out bullet + "each dispatch's write set is its own `docs/work/{ID}.md` … so concurrent grounding keeps verdicts per-card atomic" |
| Arm | 2 | CONCURRENT | Excerpt 3's write-set clause — "no cross-card dependencies, so all three can dispatch together" |
| Arm | 3 | CONCURRENT | Excerpt 1's fan-out bullet, read together with Excerpt 3's write-set clause |

**Verdict: RED → GREEN.** Control landed SERIAL 3/3 and, in two of three trials, named the
pre-fix bullet as the reason to *override* the `CLAUDE.md` fan-out rule — the reader conflict the
card describes, reproduced. The arm landed CONCURRENT 3/3, citing the write set. The clause
passes the cut test: the general fan-out bullet alone did not carry the decision, so the triage
line is load-bearing either way and the wording is what flips it.

**Not measured here.** The card's `309s / 351s / 390s` telemetry is external observation carried
from the source issue; this bench is a reading-comprehension check on the wording, not a
wall-clock run. The reporter's runtime assertions — exactly one Verdict block per card, no card
written by more than one dispatch — hold by construction from the agent's one-write floor
(`agents/triage.md` § Phase identity grants no `Write` tool and floors the write at one append to
its own card), which is why they are not re-measured.
