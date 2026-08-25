---
paths:
  - "docs/**/*.md"
  - "README.md"
  - "plugins/*/README.md"
description: "Fires on read of a prose doc. Link each concept to its SSOT home as you write. Predicate, home-selection edges + placement in work-discipline/doc-link-discipline.md."
---

# SSOT Doc-Link — Emit at Authoring

When authoring or editing a prose doc, link each concept to its SSOT home as you
write — born-linked, not back-filled.

A concept is a link-candidate when B defines it, A uses it substantively, and A
is not a catalog/index — full predicate, home-selection edges + placement in
`.claude/guidelines/work-discipline/doc-link-discipline.md`.

For each candidate, add a markdown link to the home doc on the **asserting line** —
the sentence that leans on the concept, not the paragraph or section head above
it. One link per concept per doc — the first asserting use carries it.

A home that contradicts the using line is the mandatory case: link it as a
declared supersession — name which side binds, cite the other.
