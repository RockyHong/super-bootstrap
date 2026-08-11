# Domain Docs

How the engineering skills should consume this repo's domain documentation when exploring
the codebase.

## Before exploring, read these

This repo keeps its domain context under `docs/`, not at the root:

- **[`docs/overview.md`](../overview.md)** — product context: Problem, User, Current State,
  Module Index, Data Flow, Key Boundaries. This fills the `CONTEXT.md` role.
- **[`docs/techstack.md`](../techstack.md)** — stack, architecture rules, coding patterns.
- **[`docs/specs/`](../specs/)** — one spec per feature; the permanent source of truth for a
  feature's design.
- **[`docs/decisions.md`](../decisions.md)** — closed forks and rejected directions across
  tech / product / business / design. This fills the ADR role: read it before proposing a
  direction, so a fork already closed is not re-walked.

Read the ones relevant to the topic. If a file doesn't exist, proceed silently.

## Writing is quarantined

Read the docs above; **do not write to them.** They are this repo's canonical SSOT with
their own dimension rules (`docs/decisions.md` is append-only history with stated admission
criteria and one bounded additive-annotation form its own header defines; `docs/overview.md`
and `docs/techstack.md` are state-dimension docs) and their own
write door (the `/super-bootstrap:commit` [doc-sync step](../../CLAUDE.md#doc-sync-non-negotiable)).

If `/domain-modeling` needs to record a glossary or a decision, write it to its own homes —
`CONTEXT.md` at the repo root, `docs/adr/` for ADRs — and surface the addition so it can be
reconciled with the docs above.

## Use the glossary's vocabulary

When your output names a domain concept (in a card title, a refactor proposal, a hypothesis,
a test name), use the term as defined in the docs above. Don't drift to synonyms they
explicitly avoid.

If the concept you need isn't defined yet, that's a signal — either you're inventing language
the project doesn't use (reconsider) or there's a real gap (note it for `/domain-modeling`).

## Flag decision conflicts

If your output contradicts a closed fork in `docs/decisions.md` or a shipped spec in
`docs/specs/`, surface it explicitly rather than silently overriding:

> _Contradicts the closed fork "…" in `docs/decisions.md` — but worth reopening because…_
