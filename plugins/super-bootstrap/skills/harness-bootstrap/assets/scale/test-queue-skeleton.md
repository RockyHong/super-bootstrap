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
- **source:** {BUG|DEBT|GAP}-###   ← optional; the only backlog link — omit when no row exists
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

*(empty — seeded as manual-verification obligations are queued)*

## Failed (re-queued for fix)

*(empty — seeded as failed entries are re-queued)*
