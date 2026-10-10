# Test Queue

Batch list of open manual-verification obligations — plans whose verification a machine can't discharge, awaiting a human walk-through. Ordered oldest-first so they clear in batch. Verification is independent of merge: a plan may merge before, after, or without its queued test.

> **Auto-shrinking artifact.** Smoke is the residual layer — anything systematic and recurring belongs in an automated test. A smoke step repeated across two consecutive merges is a retire-rule trigger: the next work that touches that surface graduates it to an automated test (unit / e2e) in the same commit and deletes the smoke step. Smoke owns only subjective UX (feel, animation, copy tone) and verification genuinely infeasible to automate.

## Entry shape

```
### {what this verifies — one line}

- **run on:** {branch / built artifact / device — where the walker exercises it}
- **checklist:**
  - [ ] {step → observable result}
  - [ ] {step → observable result}
- **result:** pending
- **source:** {BUG|DEBT|GAP}-xxxx   ← optional; the only backlog link — omit when no row exists
- **on fail:** `/super-bootstrap:log` a bug + re-queue
```

## Lifecycle

- **Append** at the review-stage handoff — when a plan reaches review and its verification is manual (no automated surface a machine can drive), it enters here as the plan's manual-test contract.
- **Run** — the user walks the path on the `run on:` target and ticks each line.
- **Pass** — mark `result: pass`. The entry self-discharges: deleted in the same commit that records the pass, independent of merge.
- **Fail** — move the entry under `## Failed (re-queued for fix)`, mark `result: fail` with a one-line note, and `/super-bootstrap:log` a bug. Re-queueing flips it back to `result: pending` and moves it back under `## Pending`.

The only durable state here is a still-`pending` entry — `pass` discharges it, `fail` re-queues it.

---

## Pending

### Session boundary pair: park-close → session-continue → done-close round trip

- **run on:** an sb-harnessed repo with the in-repo dev copy of [`session-close`](../plugins/super-bootstrap/skills/session-close/SKILL.md) / [`session-continue`](../plugins/super-bootstrap/skills/session-continue/SKILL.md) loaded (or the released plugin), device `~/.claude/skills/session-{close,continue}` out of the way
- **checklist:**
  - [ ] mid-card break → `/super-bootstrap:session-close` → one confirm-pick; nothing written before it; on confirm the card gains a `## Progress` block (done step, next step, watch-outs), `SESSION-STATE/<label>-<id>.md` holds only the non-card delta or a pointer stub, and the commit lands through `/super-bootstrap:commit` with no second push prompt and no §7 handoff line
  - [ ] fresh session → `/super-bootstrap:needs-me` prints the `carries in flight` line; `/super-bootstrap:session-continue` finds the carry, renames it to the new session id, leads with the card's latest block of each type, confirms before acting
  - [ ] finish the card → `/super-bootstrap:session-close` done-close deletes the claimed carry in the close commit
  - [ ] a session that touched no card, with an open card superseded by a resolved successor and one whose Progress reports every Plan step done → `/super-bootstrap:session-close` offers both as resolve moves with evidence lines; an in-flight card stays out (`BUG-081`)
  - [ ] `/super-bootstrap:harness-bootstrap` on a scratch repo → its CLAUDE.md § Context Hygiene names the session-carry ledger
- **result:** pending
- **source:** GAP-096
- **on fail:** `/super-bootstrap:log` a bug + re-queue

## Failed (re-queued for fix)

*(empty — seeded as failed entries are re-queued)*
