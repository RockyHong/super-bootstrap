# Doc Link Discipline — SSOT-Home Links

Prose docs reference each other by authored markdown link to the concept's single
home. A link is a *reference to one home* (SSOT) — unlike copying the definition
into the referring doc, which forks the truth and drifts on first edit. The link
is also the retrieval breadcrumb: a reader (human or agent) lands on the home
instead of reconstructing it from a partial mention.

This file owns the **link-candidate predicate** — what makes a concept in one doc
worth linking to another. The emit rule (`.claude/rules/ssot-doc-link.md`) cites it
to author links at writing time (the warm path — gaps prevented at source). Auditing
for already-missing links is ad-hoc: run this predicate over the doc surface when
gaps are suspected.

## Link-candidate predicate

A concept used in doc A is a link-candidate to doc B when **all four** hold:

1. **Real home** — B *defines* the concept (B is its SSOT home), not merely
   mentions it. A link points at the definition, never at another passing use.
2. **Substantive use** — A leans on the concept (builds on it, assumes it,
   sends the reader to it), not a passing token that happens to match a name.
   Enumerative mention is not yet substantive: where prose catalogs many
   concepts in one breath (overview/guardrail rosters), link only the
   concepts A goes on to build on, not every name.
3. **A is not a catalog/index** — index docs enumerate many concepts by design
   and are not expected to link every entry. The predicate targets prose that
   *uses* concepts, not registries that *list* them — frozen tracker/backlog rows
   count as registries, not candidate prose.
4. **A is not ephemeral** — temporal docs (specs / plans in delete-after-merge
   locations) die on merge; the linking overhead doesn't earn its keep, same as
   catalog/index.

Fail any one → not a candidate. The guards are the noise filter: without them
every shared token reads as a missing link.

## Home selection edges

- **Two homes (concept vs surface).** A concept defined as an idea in one doc and
  as a surface (endpoint, storage, schema) in another → the link points at the
  **concept-definition** home; the surface home is a different concern.
- **Contradicting home.** If the candidate home contradicts the using line, do not
  link — that is a consistency defect (the docs disagree), not a missing link.
  Resolve the contradiction first.

## Boundary

Applies to authored prose docs (overview, architecture, specs, backlog, READMEs)
wherever the project keeps them — not harness MDs (skills / agents / rules carry
their own discipline). Consumer artifacts cite this file by path; the predicate
lives here only.
