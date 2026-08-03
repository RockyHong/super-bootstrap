# DEBT-045 — help dispatch burns more than it saves; menu render is mechanically derivable

**Logged:** 2026-08-02 · **Source:** user direction, DEBT-044 per-item dispatch audit
**Problem:** `/super-bootstrap:help` dispatches the Haiku `help` agent, but the agent returns the menu verbatim and the gateway relays it — the rendered menu lands in gateway context regardless. Dispatch offloads only the manifest scan, at the cost of the full agent round-trip (agent instructions + manifest reads + return). The sources are structured — `~/.claude/plugins/installed_plugins.json` (JSON), `.claude/settings.json` `enabledPlugins` (JSON), `SKILL.md` frontmatter (YAML) — so extraction + grouping + render is deterministically scriptable (jq/sed): zero model tokens for the scan, one tool result = the finished menu (the menu's own size is the irreducible context cost either way).
**Area:** `plugins/super-bootstrap/skills/help/SKILL.md`; `plugins/super-bootstrap/agents/help.md`
**Prior:** Probe first — measure one live `/help` dispatch's total token cost vs the script path. If the script lands, retire `agents/help.md` and update the README § Inline vs Dispatch row in the same change.

## Amendment — 2026-08-03 · probe results (dispatch vs script)

Both arms measured live (published copy 2.25.0 under test, bare invoke, no category filter):

- **Dispatch arm:** 52,330 subagent tokens · 29 tool uses · 42 assistant turns · 95.7s wall, on Haiku. Transcript decomposition: output 7,188 · cache_creation 232,472 · cache_read 826,880 (cumulative). Worse than the family's carded figures (todo ~34.3k, log 23.3–35.3k) — the 15-row menu is fixed-floor + read-fan dominated, consistent with DEBT-022's fixed-floor finding.
- **Script arm:** Python prototype over the same three sources (`installed_plugins.json` → `enabledPlugins` filter → per-plugin `skills/*/SKILL.md` frontmatter + project skills) renders the menu in **0.17s, zero model tokens**. Menu itself ~1k tokens — the irreducible relay cost, identical on both arms.
- **Residual judgment located, and it is real:** prototype lists 32 commands where the agent rendered 15 — the delta is the user-invoke filter (agent judged superpowers process skills "reference material, not user-invocable"; the mechanical `Dispatched by`-regex filter misses that). Extraction, grouping (tag→category map), and render are fully mechanical; the *filter* is the only judgment in the pipeline.
- **Shape implication:** the probe supports retiring the dispatch, but not a pure script — the landing shape is script-extracts (one tool call, zero model tokens) + gateway-inline filter pass over the extracted rows (small: one judgment over ~30 one-line descriptions, no file reads). Prototype at scratchpad `help_menu_proto.py`; production home would be a skill asset.

Decision open (user): retire `agents/help.md` for script+inline-filter, or keep dispatch. Retirement touches `skills/help/SKILL.md` (protocol rewrite), `agents/help.md` (delete), README § Inline vs Dispatch row — harness edit, audit-gated.
