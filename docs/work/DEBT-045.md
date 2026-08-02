# DEBT-045 — help dispatch burns more than it saves; menu render is mechanically derivable

**Logged:** 2026-08-02 · **Source:** user direction, DEBT-044 per-item dispatch audit
**Problem:** `/super-bootstrap:help` dispatches the Haiku `help` agent, but the agent returns the menu verbatim and the gateway relays it — the rendered menu lands in gateway context regardless. Dispatch offloads only the manifest scan, at the cost of the full agent round-trip (agent instructions + manifest reads + return). The sources are structured — `~/.claude/plugins/installed_plugins.json` (JSON), `.claude/settings.json` `enabledPlugins` (JSON), `SKILL.md` frontmatter (YAML) — so extraction + grouping + render is deterministically scriptable (jq/sed): zero model tokens for the scan, one tool result = the finished menu (the menu's own size is the irreducible context cost either way).
**Area:** `plugins/super-bootstrap/skills/help/SKILL.md`; `plugins/super-bootstrap/agents/help.md`
**Prior:** Probe first — measure one live `/help` dispatch's total token cost vs the script path. If the script lands, retire `agents/help.md` and update the README § Inline vs Dispatch row in the same change.
