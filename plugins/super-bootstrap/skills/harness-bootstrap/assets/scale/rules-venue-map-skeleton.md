---
paths:
  - "docs/backlog.md"
  - "docs/test-queue.md"
description: "Phase → run-location map. One map, two filters: /super-bootstrap:todo reads it cloud-vs-device, /super-bootstrap:drain reads it dispatch-vs-wall. Fires on backlog / test-queue reads."
---

# Venue Map — Phase → Run-Location

Single source for *where* a pipeline phase runs. One map, two filters — never two hand-maintained criteria.

## Venues

| Venue | Meaning | Cloud-run | Drainable |
|---|---|---|---|
| **T** | Tooling/headless — artifact via tooling alone | yes | yes, in-worktree |
| **S** | Stack-bound — needs a real runner (emulator/ports/browser), no human | no | via gateway merge-probe |
| **U** | User-walled — needs human eyes/decision | no | no — halts to user |
| **P** | Probe/stochastic — LLM-eval, cost-sensitive, non-deterministic | no | no — excluded |

## Derivation

Venue is derived fresh per read — never stored. Chain: the shared classification's **stage** (by file-presence) → the item's **next phase** → that phase's venue. Classify by the item's **next** phase, never its terminal phase; modality fields govern only the phase they gate.

| Stage | Next phase | Venue |
|---|---|---|
| `raw` | Triage | **T** |
| `triaged` | Implement | derive — § Modality overrides over `docs/superpowers/triage/{ID}-scope.md` |
| `spec` | Write plan | **T** |
| `plan` | Execute | derive — § Modality overrides |
| `review` | Review | **T** — manual-verification arm → **U** / **S** per Test-feel |

## Modality overrides

Downgrade an otherwise-**T** phase when the row carries the signal.

| Signal | Effect |
|---|---|
| `Stochastic: llm` | triage / build / test → **P**; plan / spec / doc stay **T** |
| visual-taste acceptance | acting phase → **U** — who accepts this as done? the user's eyes → U (never keyword matching) |
| `Test-feel: e2e` | verify phase → **S** |
| `Test-feel: manual` | verify phase → **U** |

## Consumer boundary

This rule never overrides `{action, intent, stage}` from the shared classification — venue is advisory run-location metadata. Mapping: T≈Cloud, U≈Discuss/Device; S and P are refinements the drain lane consumes when wired.

One map, two filters — never re-derived by hand:

- **`/super-bootstrap:todo`** reads it **drainable vs need-me** — its Lane split owns the venue→group mapping.
- **`/super-bootstrap:drain`** reads it **dispatch vs wall** — its admission gate owns the venue→admit mapping.
