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

### Docs-only bootstrap takes no code-touch pair; code arriving raises both as `⊕ new`

- **run on:** in-repo dev copy of `harness-bootstrap` (`plugins/super-bootstrap/skills/harness-bootstrap/`) against a scratch repo holding only `README.md` + `docs/*.md`
- **checklist:**
  - [ ] bootstrap the docs-only scratch repo → `CLAUDE.md` has no `## Coding Principles`, no root `CODING_STANDARDS.md`, receipt `covered` lists neither
  - [ ] add a `package.json` and re-run → both surface as `⊕ new`, insert on approval
  - [ ] re-run on a code repo (this one) → sync output unchanged
- **result:** pending
- **source:** GAP-073
- **on fail:** `/super-bootstrap:log` a bug + re-queue

### Seed-once stack facts: a re-run after code arrives advises, never rewrites

- **run on:** in-repo dev copy of `harness-bootstrap` (`plugins/super-bootstrap/skills/harness-bootstrap/`) against the GAP-073 docs-only scratch shape (`README.md` + `docs/*.md` only)
- **checklist:**
  - [ ] bootstrap the docs-only scratch repo → `docs/techstack.md` § Runtime / Framework / Key Dependencies / Build & Distribution hold the unfilled placeholders, `CLAUDE.md` § Tech Stack reads the docs-only one-liner
  - [ ] add a `package.json` and re-run → Phase 3 prints the stale-facts advisory naming all five sections plus the detected manifest / runtime / framework
  - [ ] same re-run → `.claude/bootstrap-sync-report.md` carries one `facts:` row with those detected facts (the advisory's source)
  - [ ] same re-run → those five sections are byte-unchanged on disk, and the four techstack rows read `✓ current` (never `⚠ drifted`)
  - [ ] re-run on this code repo (facts already filled) → no advisory, and the four techstack rows read `✓ current` not `⚠ drifted`
- **result:** pending
- **source:** GAP-074
- **on fail:** `/super-bootstrap:log` a bug + re-queue

### The executor contract seeds unconditionally — `⊕ new`, then `✓ current`

- **run on:** in-repo dev copy of `harness-bootstrap` (`plugins/super-bootstrap/skills/harness-bootstrap/`), against a docs-only scratch repo (`README.md` + `docs/*.md` only) and against this repo
- **checklist:**
  - [ ] bootstrap the docs-only scratch repo → root `AGENTS.md` lands `⊕ new`, inserts on approval, byte-identical to `plugins/super-bootstrap/skills/harness-bootstrap/assets/agents-md-skeleton.md`; the same run places no `CODING_STANDARDS.md` and no `## Coding Principles` — the new asset carries no code-presence gate
  - [ ] same run → `.claude/bootstrap-sync-report.md` carries an `AGENTS.md` row plus its `registration:` row, and `.claude/super-bootstrap-runway.json` `covered` lists `AGENTS.md` by path
  - [ ] re-run the scratch repo unchanged → `AGENTS.md` reads `✓ current`, file byte-unchanged
  - [ ] hand-edit one shipped line in the scratch `AGENTS.md`, re-run → `⚠ drifted`, diff shown; declining lands `declined` in the receipt and leaves the file untouched
  - [ ] re-run on this repo (code present) → `AGENTS.md` lands `⊕ new` on the first sync and `✓ current` on the second; the `CLAUDE.md` § Dispatch row surfaces `⚠ drifted` once and resolves `updated`
- **result:** pending
- **source:** GAP-072
- **on fail:** `/super-bootstrap:log` a bug + re-queue

## Failed (re-queued for fix)

*(empty — seeded as failed entries are re-queued)*
