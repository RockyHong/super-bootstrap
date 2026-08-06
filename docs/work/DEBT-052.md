# DEBT-052 — docs/overview.md grown sections empty in a mature repo

**Logged:** 2026-08-06 · **Source:** DEBT-047 live-run pass — real doc debt surfaced while staging the drain verification wave
**Problem:** `docs/overview.md` § Module Index, § Data Flow, § Key Boundaries carry only their seed blockquotes — zero rows — while the repo ships 14+ skills, 7 agents, shared classify specs, hook assets, and a marketplace manifest. The doc-sync growth loop never seeded them; a cold reader gets no map of what exists.
**Area:** `docs/overview.md` (grown sections only — Problem / User / Current State are current)
**Prior:** derive rows from the live tree (`plugins/super-bootstrap/{skills,agents,shared}/`, `.claude-plugin/`, root `.claude-plugin/marketplace.json`); one line each, no restating SKILL.md contracts (link, don't copy).
