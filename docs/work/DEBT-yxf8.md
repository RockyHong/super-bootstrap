# DEBT-yxf8 — Overview calls all five subagents read-only; triage edits the card

**Logged:** 2026-11-24 · **Source:** docs-consistency scan 2026-11-24 (`.review/docs-consistency-2026-11-24.md`), via `/super-bootstrap:triage-report`
**Problem:** `docs/overview.md:169` says the 5 dispatched subagents each run "cold-context and read-only", while `agents/triage.md` holds `Edit` and `Bash` and appends a Verdict block (scope per docs-consistency scan 2026-11-24, unconfirmed)
**Area:** `docs/overview.md`, `plugins/super-bootstrap/agents/triage.md`
**Prior:** Narrow the wording (no product edits) or restrict the agent.
