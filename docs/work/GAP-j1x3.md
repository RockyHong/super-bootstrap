# GAP-j1x3 — runway re-sync re-prompts every declined row even when its template text is unchanged

**Logged:** 2026-10-27 · **Source:** device note from claude-config-manager (its 5.3.0 → 5.5.0 runway re-sync)
**Problem:** Block 2 renders "previously declined: {reason}", but each declined row still takes its own y/n on every re-sync. A consumer whose fork is deliberate answers the same question at every sync.
**Area:** `plugins/super-bootstrap/skills/harness-bootstrap/SKILL.md` Block 2 + § 2c receipt (`declined` entries)
**Prior:** carry a decline forward without a prompt when the template section is unchanged since the decline was recorded — report it as `declined (carried)` with its reason; prompt only when the section changed. Needs the receipt to record what the decline was made against, e.g. a hash of the template section beside `reason`.
