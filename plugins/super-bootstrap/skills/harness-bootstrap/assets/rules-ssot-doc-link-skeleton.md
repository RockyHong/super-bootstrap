---
paths:
  - "docs/**/*.md"
  - "README.md"
  - "plugins/*/README.md"
description: "Fires on read of a prose doc. Link each concept to its SSOT home as you write — link-candidate predicate, home-selection edges and placement on the asserting line."
---

# SSOT Doc-Link — Emit at Authoring

When authoring or editing a prose doc, link each concept to its SSOT home as you
write — born-linked, not back-filled. A link points at the concept's one home;
copying the definition into the using doc forks the truth instead.

## Link-candidate predicate

A concept used in doc A is a link-candidate to doc B when **all four** hold:

1. **Real home** — B *defines* the concept (B is its SSOT home), not merely
   mentions it. Point the link at the definition, never at another passing use.
   Several docs define it → the home is the doc dedicated to the concept; a
   one-line gloss elsewhere (an overview summary) is itself a use, not a home.
2. **Substantive use** — A leans on the concept (builds on it, assumes it,
   sends the reader to it), not a passing token that happens to match a name.
   Where prose catalogs many concepts in one breath (an overview or guardrail
   roster), link only the concepts A goes on to build on, not every name.
3. **A is not a catalog/index** — an index doc enumerates many concepts by
   design and need not link every entry. Frozen tracker/backlog rows count as
   registries, not candidate prose.
4. **A is not ephemeral** — a temporal doc (a spec or plan in a
   delete-after-merge location) dies on merge; skip it, as for a catalog.

Fail any one → not a candidate.

## Home selection

- **Two homes (concept vs surface).** A concept defined as an idea in one doc and
  as a surface (endpoint, storage, schema) in another → link the
  **concept-definition** home.
- **Contradicting home — mandatory.** A home that contradicts the using line must
  be linked as a declared supersession: the using line names which side binds and
  cites the other (`supersedes [the earlier bound](path.md#anchor)` /
  `superseded by [...]`). Log the contradiction (`/super-bootstrap:log`) for the
  docs' owner to resolve.
  Where the using line cannot name the binding side, cite the other as contested
  and leave the binding call to the owner.

## Placement

Put the link on the **asserting line** — the sentence that leans on the concept —
not on the paragraph or section head above it. A citation on a heading leaves
every later assertion reading as self-standing. One link per concept per doc —
the first asserting use carries it.

## Scope

Applies to authored prose docs (overview, architecture, specs, backlog, READMEs).
Harness files (skills, agents, rules) carry their own discipline. To audit for
links already missing, run the predicate above over the doc surface
(`/super-bootstrap:check-docs-consistency`).
