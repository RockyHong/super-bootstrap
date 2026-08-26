---
paths:
  - "docs/work/README.md"
  - "docs/test-queue.md"
description: "Phase → run-location map. One map, two filters: /super-bootstrap:todo reads it drainable vs need-me, /super-bootstrap:drain reads it dispatch vs wall. Fires on work-space / test-queue reads."
---

# Venue Map — Phase → Run-Location

Single source for *where* a pipeline phase runs. One map, two filters — never two hand-maintained criteria.

## Venues

| Venue | Meaning | Cloud-run | Drainable |
|---|---|---|---|
| **T** | Tooling/headless — artifact via tooling alone | yes | yes, in-worktree |
| **S** | Stack-bound — needs a real runner (emulator/ports/browser), no human | no | via gateway merge-probe |
| **U** | User-walled — needs human eyes/decision | no | no — halts to user |
| **P** | Probe/stochastic — LLM-eval, cost-sensitive, non-deterministic | no | yes, in-worktree |

## Derivation

Venue is derived fresh per read — never stored. Chain: the caller-supplied **stage** → the item's **next phase** → that phase's venue. `stage` is supplied by the callers that index this table — `/super-bootstrap:todo` and `/super-bootstrap:drain`, out of their classification pass (`shared/classify-actionable.md`, inside the installed super-bootstrap plugin); this rule maps a supplied stage to a venue and never derives the stage itself. Classify by the item's **next** phase, never its terminal phase; modality fields govern only the phase they gate.

| Stage | Next phase | Venue |
|---|---|---|
| `raw` | Triage | **T** |
| `triaged` | Implement | derive — § Modality overrides over the card's Verdict block |
| `aimed` | Execute | derive — § Modality overrides |
| `executing` | Execute | derive — § Modality overrides |
| `review` | Review | **T** — manual-verification arm → **U** / **S** per Test-feel |

## Modality overrides

Downgrade an otherwise-**T** phase when the row carries the signal.

| Signal | Effect |
|---|---|
| `Stochastic: llm` | triage / build / test → **P**; plan-write / aim-settle / doc stay **T** |
| visual-taste acceptance | acting phase → **U** — who accepts this as done? the user's eyes → U (never keyword matching) |
| `Test-feel: e2e` | verify phase → **S** |
| `Test-feel: manual` | verify phase → **U** |

## Consumer boundary

This rule never overrides the `{action, intent, stage}` its callers supply — venue is advisory run-location metadata. Mapping: T≈Cloud, U≈Discuss/Device; S and P are refinements the drain lane consumes when wired.

One map, two filters — never re-derived by hand:

- **`/super-bootstrap:todo`** reads it **drainable vs need-me** — the todo skill's lane split owns the venue→group mapping.
- **`/super-bootstrap:drain`** reads it **dispatch vs wall** — the drain skill's admission gate owns the venue→admit mapping.
