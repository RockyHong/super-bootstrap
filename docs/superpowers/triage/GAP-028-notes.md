# GAP-028 — commit-channel path-class: second-commit-lane design unblocked (BUG-015 resolved)

> **Baked earlier** — extracted as axis-2 of the DEBT-013 cold re-triage (DEBT-013 + GAP-023). The relationship is established and BUG-015 (the prerequisite) is now resolved; this file exists so pickup executes the design from here, not from a fresh triage. Do not re-triage the relationship.

## Findings

- **Root cause:** the commit door dispatches the commit agent unconditionally. On a diff whose staged paths the repo's doc-sync surface doesn't narrate (harness-only / non-narrated), the agent's §3 doc-sync scan can catch nothing — the whole commit dispatch is overhead for that diff class.
- **Prerequisite (now met):** any gateway-inline commit forks the SSOT commit path (GAP-024), so the single lane's continuation reliability had to be settled first. **BUG-015 is now resolved** — continuation = a fresh `Agent` dispatch that walks §1→§6 in full (never a mid-protocol resume). With the single lane hardened, the second-commit-lane design can proceed without shipping a guess against a live boundary (the Axiom VII/V risk that gated it is cleared).
- **Not shared with the transcription axis:** the former DEBT-013 axis-1 / GAP-023 concern (transcription → inline the build) was closed this session by the § Dispatch transcription carve-out. It never touched the commit channel. Do not reopen it here.

## Verdict: surface — design (BUG-015 prerequisite met)

Fails auto-fix: scope crosses the commit channel (SSOT commit path); genuine design fork. BUG-015 (the prerequisite) is now resolved.

- **Fix-shape:** `design` — is a second commit lane admissible at all?
- **Probe-deps:** BUG-015 (commit-agent continuation reliability) — resolved; continuation = fresh-dispatch invariant.
- **Execution:** unblocked → ready for the design pass.

## Decision needed (at pickup)

Is inline-commit for a non-narrated / harness-only diff a defect worth a second lane, or a safety property to keep? Options: (a) keep the single channel, accept the overhead as the price of the SSOT commit path; (b) a narrow non-narrated-path lane that still routes through the commit agent but skips the §3 scan; (c) gateway-inline commit for that class. (c) reopens GAP-024 — only on the table if the second lane is provably safe under the now-hardened commit path (continuation = fresh-dispatch invariant).
