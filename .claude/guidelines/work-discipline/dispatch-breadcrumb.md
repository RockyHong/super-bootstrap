# Dispatch Breadcrumb — Entry Doc Rides the Prompt

A subagent dispatch prompt carries the entry doc for its scope — the breadcrumb
head the agent reads first (the scope's index, overview, or SSOT entry point).
Project context is the caller's responsibility (skill-authoring axiom); the
entry doc is the minimum unit of that responsibility.

- **Name a path, not a topic** — "read `docs/architecture.md` § Hook
  Distribution first" beats "familiarize yourself with the hook system."
- **Entry point, not payload** — pass the breadcrumb head and let the agent
  pull; inline only what the agent cannot discover from it.
- **Cheaper tiers under-read most** — the colder the dispatched tier, the more
  a missing breadcrumb costs. Never assume a subagent infers the reading list.
