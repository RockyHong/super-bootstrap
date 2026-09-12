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

### Seed-once stack facts: a re-run after code arrives advises, never rewrites

- **run on:** in-repo dev copy of `harness-bootstrap` (`plugins/super-bootstrap/skills/harness-bootstrap/`) against the GAP-073 docs-only scratch shape (`README.md` + `docs/*.md` only)
- **checklist:**
  - [x] bootstrap the docs-only scratch repo → `docs/techstack.md` § Runtime / Framework / Key Dependencies / Build & Distribution hold the unfilled placeholders, `CLAUDE.md` § Tech Stack reads the docs-only one-liner
  - [ ] add a `package.json` and re-run → Phase 3 prints the stale-facts advisory naming all five sections plus the detected manifest / runtime / framework
  - [x] same re-run → `.claude/bootstrap-sync-report.md` carries one `facts:` row with those detected facts (the advisory's source)
  - [x] same re-run → those five sections are byte-unchanged on disk, and the four techstack rows read `✓ current` (never `⚠ drifted`)
  - [x] re-run on this code repo (facts already filled) → no advisory, and the four techstack rows read `✓ current` not `⚠ drifted`
- **result:** pending — file layer discharged by a scratch-repo fixture run; the one open item is terminal-output only (does Phase 3 actually emit the advisory). Its inputs are verified present: the `facts:` row carries the detected manifest / runtime / framework, and the five sections it names are byte-unchanged. Bound on the discharged items: the executor was a normal session, not a cold container — the shipped-asset byte comparisons hold regardless, the sync-report row spellings were written and then read back by that same session.
- **source:** GAP-074
- **on fail:** `/super-bootstrap:log` a bug + re-queue

### The executor contract seeds unconditionally — `⊕ new`, then `✓ current`

- **run on:** in-repo dev copy of `harness-bootstrap` (`plugins/super-bootstrap/skills/harness-bootstrap/`), against a docs-only scratch repo (`README.md` + `docs/*.md` only) and against this repo
- **checklist:**
  - [x] bootstrap the docs-only scratch repo → root `AGENTS.md` lands `⊕ new`, inserts on approval, byte-identical to `plugins/super-bootstrap/skills/harness-bootstrap/assets/agents-md-skeleton.md`; the same run places no `CODING_STANDARDS.md` and no `## Coding Principles` — the new asset carries no code-presence gate
  - [x] same run → `.claude/bootstrap-sync-report.md` carries an `AGENTS.md` row plus its `registration:` row, and `.claude/super-bootstrap-runway.json` `covered` lists `AGENTS.md` by path
  - [x] re-run the scratch repo unchanged → `AGENTS.md` reads `✓ current`, file byte-unchanged
  - [ ] hand-edit one shipped line in the scratch `AGENTS.md`, re-run → `⚠ drifted`, diff shown; declining with `n — {reason}` lands `{ "section": "AGENTS.md", "reason": "{reason}" }` under `declined` in the receipt and leaves the file untouched; a further re-run prints `previously declined: {reason}` beside the row's diff before re-prompting
  - [x] re-run on this repo (code present) → `AGENTS.md` lands `⊕ new` on the first sync and `✓ current` on the second; the `CLAUDE.md` § Dispatch row surfaces `⚠ drifted` once and resolves `updated` — this repo: `⊕ new` landed; § Dispatch read `declined` (dogfood already co-edited), so the `updated` expectation is consumer-shaped
- **result:** pending — file layer discharged by the same fixture run. The open item's first three clauses are verified (re-run after a hand-edit reads `⚠ drifted` with the diff in Block 2; declining lands exactly `{ "section": "AGENTS.md", "reason": … }` under `declined`; the file's sha is untouched). What remains is its tail alone — whether a further re-run actually renders the `previously declined:` line; the receipt input that line reads from is confirmed present and correctly shaped.
- **source:** GAP-072
- **on fail:** `/super-bootstrap:log` a bug + re-queue

## Failed (re-queued for fix)

*(empty — seeded as failed entries are re-queued)*
