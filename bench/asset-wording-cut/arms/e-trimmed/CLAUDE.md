# ledgerline

Workflow doctrine — pipeline, dispatch, doc sync, git — loads from [`.claude/rules/harness.md`](.claude/rules/harness.md). This file holds the project's own sections.

## This repo's additions to the harness doctrine

These lines bind in this repo together with `.claude/rules/harness.md`; a line labelled *takes over* wins over the doctrine line it names.

**§ Git Notes** — added to "Conventional commits":

- Scope is the package name: `feat(api): …`, `fix(web): …`.

**§ Development Workflow** — takes over "Commit in flow":

- Commit once per card, at the card's close — a card's verified units ride one commit.

## Rules (auto-load on file match)

`.claude/rules/*.md` files attach to file reads via `paths:` frontmatter — full-body rule fires at the decision moment, zero ambient cost when irrelevant (`harness.md` aside: no frontmatter, loaded every session).

- **`dimension-discipline.md`** — fires on `docs/**/*.md`, `/README.md` (root), `plugins/*/README.md` (plus any `paths:` entries the repo appends)
  • Before editing a prose doc, classify what it owns: state (overwrite in place) vs history (append-only, git's job).
- **`ssot-doc-link.md`** — fires on `docs/**/*.md`, `/README.md` (root), `plugins/*/README.md` (plus any `paths:` entries the repo appends)
  • Link each concept to its SSOT home as you write — born-linked, not back-filled.

If rule body needs more context than its summary provides during planning, read the rule file directly before designing — `Read .claude/rules/<name>.md`.

## Tech Stack

Node 20 + Fastify + Postgres 15 + pnpm

→ Full stack table, dependency philosophy, architecture rules, observed coding patterns in [`docs/techstack.md`](docs/techstack.md).

## Commands

```bash
pnpm test
pnpm build
```

## Planning

- [`docs/overview.md`](docs/overview.md) — product context, data flow, module index.
- [`docs/techstack.md`](docs/techstack.md) — stack, architecture rules, observed coding patterns.
- [`docs/specs/`](docs/specs/) — feature specs, one `.md` per feature. Filename + heading is the catalog; no index.
- [`docs/work/`](docs/work/README.md) — open cards (`BUG` / `DEBT` / `GAP`, append-only threads), captured via `/super-bootstrap:log`, deleted on resolve; `README.md` holds the thread contract + ID shape.
- [`docs/terminology.md`](docs/terminology.md) — the project's term home: one canonical word per concept, `_Avoid_` aliases; a doc's first substantive use of a term links this file.
- [`docs/decisions.md`](docs/decisions.md) — closed forks, all domains (history dimension). See its scope header for admission criteria; checked at triage.
- `.claude/rules/` — path-scoped rules, full-body fires on file match (see Rules section above)

> `docs/specs/` = permanent source of truth; working design and plan live as blocks on the owning card's thread.
