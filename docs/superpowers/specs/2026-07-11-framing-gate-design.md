# Framing Gate — align problem-aim before machinery (GAP-030)

**Card:** `docs/backlog.md` → GAP-030 · **Triage:** `docs/superpowers/triage/GAP-030-notes.md` (surface verdict)
**Route:** cluster 2 (first-of-shape harness design) · `load-harness-principles` pre / `audit-harness-edits` post

## Problem (aligned)

No gate forces the gateway to align **what the problem is** with the user before
processing machinery (triage, routing, solution) runs. The gateway states its
*route* ("how I'll process this") but never its *problem-aim* ("what I understand
the problem to be"), so a mis-aimed problem is only discovered after build/verdict
spend. Two live failure modes:

- **Gateway card-misread** — gateway reads the card wrong, dispatches machinery on
  the wrong aim (this session: `GAP 030 開工` → immediate triage dispatch, no
  problem stated to the user; triage then itself mis-located the gate at
  route→implement).
- **Absorbed misframe** — triage returns a verdict whose options smuggle a wrong
  premise; gateway absorbs it uncritically (GAP-027: misframed A/B/C options).

Root cause is an **absence split across two levers**, (a) load-bearing:

- **Lever (a)** — no gateway problem-aim checkpoint before machinery. Covers *both*
  failure modes and *all* entry paths (triage-routed and direct-cluster). Primary.
- **Lever (b)** — triage's own framing discipline has no option-correctness rubric.
  Triage-lane-only; cannot cover gateway card-misread or non-triage entries.
  Secondary hardening.

`aligned ≠ correct` — alignment means the user confirms "this is the problem I
mean," not that the aim is objectively right. It sharpens the target; triage still
finds the cause skeptically.

## Design

### Pipeline shape

```
pickup card → FRAME (align problem-aim) → route → [triage on aligned aim] → implement → verify → doc-sync → commit
```

FRAME is a discipline ordered before route, not a new heavyweight step. It shares
the existing "state, don't gate" scaling — for a known-shape card it is one stated
line alongside the route line; it escalates to a full brief + explicit OK only on a
fork.

### Lever (a) — framing gate (gateway-owned, primary)

- **Produces:** before routing or dispatching machinery, the gateway states its
  reading of the card's problem back to the user — **premise / problem / scenario** —
  synthesized and self-coherent. Excludes the card's Prior (proposed fix) and does
  **not** paste raw index-quotes / file:line citations. Problem-aim only, no solution.
- **Holds the aim as a check:** the gateway retains the aligned aim and checks every
  verdict/solution the machinery returns against it. A return that re-aims the
  problem is **surfaced, not absorbed**.
- **Card Prior is a hypothesis:** even when the card carries a proposed fix, the
  solution phase treats it as a hypothesis, not a given (reinforces triage's
  existing priors-skepticism).

### Scaling — "state, don't gate" (extends § Sizing)

- **Known-shape repeat / low blast** → one-line problem statement, stated with the
  route line, proceed. **Non-blocking** (post-and-proceed).
- **Fuzzy / first-of-shape / high blast / suspected mis-aim** → full
  premise/problem/scenario brief + **explicit user OK** before machinery.
- **Fork triggers:** the existing Route-line three (ambiguous cluster,
  `docs/decisions.md` conflict, high blast radius) **plus** a new one — card-claim
  ambiguity / suspected mis-aim.

### Placement

Extend the existing `### Route line — state, don't gate` section into
`### Framing + Route — state, don't gate`, with the **framing line ordered before**
the route line and both under the same scaling. Reuses the fork triggers and
§ Sizing; minimal surface; honors the card's ceremony concern (no confirm
round-trip on every pickup). Rejected alt: a distinct new envelope step `frame`
(more visible, more surface, ceremony-bloat risk — YAGNI).

### Lever (b) — triage lane (secondary hardening)

- **Aligned-aim as input.** The triage dispatch carries the aligned problem
  statement alongside the card ID. The bias-exclusion rule tightens to explicitly
  exclude **CAUSE theories + FIX preferences** (still excluded) — the problem-aim is
  the validated target, not a prior. Triage still traces the cause cold and
  skeptically; only the problem it explains is user-validated.
  - Reconciliation with cold-dispatch: the current rule already excludes cause/fix
    priors, never the problem statement (the card claim *is* triage's problem
    input). The aligned aim is a sharpened card claim, so feeding it preserves the
    unbiased property.
- **Verdict framing rubric.** `agents/triage.md` `## Decision needed` gains an
  option-correctness rubric: mutual-exclusivity, premise-accuracy, no wrong-premise
  smuggling. Guards the GAP-027 misframed-options failure.

## Surfaces (propagation closure)

| Surface | Change |
|---|---|
| `CLAUDE.md` § Development Workflow | rename+extend `Route line` → `Framing + Route` section (framing line first) |
| `plugins/super-bootstrap/skills/harness-bootstrap/assets/claude-md-skeleton.md:26-28` | skeleton mirror of that section — propagate, stripped of dogfood-only refs (repo-boundary sync direction) |
| `plugins/super-bootstrap/agents/triage.md` | bias-exclusion wording (exclude cause/fix, admit aligned aim) + `## Decision needed` option-correctness rubric |
| `plugins/super-bootstrap/skills/triage/SKILL.md` | dispatch step passes the aligned aim; absorption note that gateway checks verdict vs aligned aim |

## Verification

- Behavior-shaping harness prose (the gate discipline, the rubric wording) →
  `superpowers:writing-skills` RED (micro-test the wording against a no-guidance
  control) before authoring the shipped-skill/agent edits.
- `load-harness-principles` before authoring; `audit-harness-edits` on the diff
  before commit (ambient CLAUDE.md = highest centrality, full cold audit).

## Out of scope

- No new envelope step, no new skill/agent files — extends existing surfaces only.
- No change to the cold-dispatch property beyond admitting the aligned aim.
