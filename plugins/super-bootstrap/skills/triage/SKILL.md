---
name: triage
description: 'Read-only verdict phase for a backlog card. `/super-bootstrap:triage {ID}` dispatches the `triage` subagent (Opus) to trace the card''s root cause cold and emit a verdict artifact — auto-fix → docs/superpowers/triage/{ID}-scope.md (Fix-shape / Probe-deps / Execution tags) or surface → {ID}-notes.md (decision for the user). No code changes — the fix is a separate phase. Use at raw-card pickup (todo board `Triage:` rows) or when the user asks to triage/investigate a BUG/DEBT/GAP item. Investigation doctrine is superpowers:systematic-debugging; this lane adds the read-only container, the verdict contract, and pipeline sizing.'
tags: [triage, verdict, backlog, pipeline, superpowers]
---

# Triage — Read-Only Verdict Phase

Investigate-only pickup lane for a backlog card. The thinking runs in the `triage` subagent (`agents/triage.md`, `model: opus`); this skill is the dispatch shell + absorption protocol. The agent traces root cause cold, sizes the fix, lands one verdict artifact; the fix is a later phase that inherits the verdict.

## Arguments

| Invocation | Behavior |
| --- | --- |
| `/super-bootstrap:triage BUG-012` (any `BUG/DEBT/GAP-###` ID) | Dispatch the `triage` subagent on that card. |
| `/super-bootstrap:triage` (bare) | List open backlog rows with no verdict file yet; the user picks one, then dispatch. |

## Execution

1. Resolve the card: the ID's `### {ID}` heading exists under `docs/backlog.md` § Open. Missing → report "no open row {ID}", stop. A verdict file for this ID already in `docs/superpowers/triage/` → surface its path instead of re-dispatching (re-triage only on explicit user ask; delete the stale verdict file first).
2. Dispatch: `Agent` tool, `subagent_type: "triage"`, prompt = the card ID + today's date + the gateway-aligned problem-aim when framing sharpened or corrected the card claim (premise / problem / scenario only). Exclude cause theories and fix preferences (bias-input exclusion) — the aligned aim is the user-validated target, not a prior; the card row carries the frozen claim.
3. Absorb the agent's report (`agents/triage.md` § Reporting):
   - **DONE / DONE_WITH_CONCERNS** — relay verdict + path. scope.md → post the route line off its `Execution:` tag (inline / phased → implement within the envelope, skipping what the tag skips; full → cluster route per CLAUDE.md). notes.md → surface its `## Decision needed` to the user.
   - **NEEDS_CONTEXT** — relay the named gaps; the user (or a follow-up `/super-bootstrap:log` amendment) supplies them.
   - **NEEDS_GRANTS** — grant the named tooling and re-dispatch; user round-trip only when the grant itself is user-owned (cost, consent).
   - **BLOCKED** — premise wrong; relay the counter-diagnosis to the user.
4. The verdict artifact rides the session's normal envelope commit — no in-phase commit.

## Rules

- **Dispatch, don't investigate.** The verdict judgment runs in the subagent's clean context; gateway priors corrupt it.
- **Check the verdict aim.** The gateway holds the aligned problem-aim; a verdict that re-aims the problem gets surfaced to the user, not absorbed (CLAUDE.md § Framing + Route).
- **Weigh the verdict's grounding.** A verdict resting on design-prose deduction over direct evidence is unproven — surface it for re-grounding, not adoption and not a competing gateway theory.
- **One card per dispatch.** Batch = sequential dispatches; verdicts stay per-card atomic.
- **Verdict files are the state.** No status fields anywhere — `{ID}-scope.md` / `{ID}-notes.md` presence IS the stage signal (`shared/classify-actionable.md` reads it for the todo board and drain).
- **Cleaner:** the session resolving the card deletes its verdict file together with the row (doc-sync temporal cleanup).
