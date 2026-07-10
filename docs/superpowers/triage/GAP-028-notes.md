# GAP-028 — commit-channel path-class: second-commit-lane admissibility gated on BUG-015

> **Baked this session** — extracted as axis-2 of the DEBT-013 cold re-triage (DEBT-013 + GAP-023). The relationship and the block are already established; this file exists so pickup executes the design from here, not from a fresh triage. Do not re-triage the relationship.

## Findings

- **Root cause:** the commit door dispatches the commit agent unconditionally. On a diff whose staged paths the repo's doc-sync surface doesn't narrate (harness-only / non-narrated), the agent's §3 doc-sync scan can catch nothing — the whole commit dispatch is overhead for that diff class.
- **Why it can't be fixed now:** any gateway-inline commit forks the SSOT commit path (GAP-024). **Open BUG-015** flags that path as load-bearing — commit-agent continuation reliability is *itself under investigation*. Designing a second commit lane while the single lane's reliability is unresolved would ship a guess against a live boundary (Axiom VII/V risk). The block is real, not a deferral of convenience.
- **Not shared with the transcription axis:** the former DEBT-013 axis-1 / GAP-023 concern (transcription → inline the build) was closed this session by the § Dispatch transcription carve-out. It never touched the commit channel. Do not reopen it here.

## Verdict: surface — design, coupled to BUG-015

Fails auto-fix: scope crosses the commit channel (SSOT commit path); genuine design fork; blocked on an open bug.

- **Fix-shape:** `design` — is a second commit lane admissible at all?
- **Probe-deps:** BUG-015 resolution (commit-agent continuation reliability) is a hard prerequisite.
- **Execution:** blocked → design pass only after BUG-015.

## Decision needed (at pickup, after BUG-015)

Is inline-commit for a non-narrated / harness-only diff a defect worth a second lane, or a safety property to keep? Options once BUG-015 is closed: (a) keep the single channel, accept the overhead as the price of the SSOT commit path; (b) a narrow non-narrated-path lane that still routes through the commit agent but skips the §3 scan; (c) gateway-inline commit for that class. (c) reopens GAP-024 — only on the table if BUG-015's fix makes a second lane provably safe.
