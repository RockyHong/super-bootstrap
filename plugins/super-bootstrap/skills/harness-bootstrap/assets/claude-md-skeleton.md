# {Project Name}

Workflow doctrine — pipeline, dispatch, doc sync, git — loads from [`.claude/rules/harness.md`](.claude/rules/harness.md): plugin-owned, re-placed whole by `/super-bootstrap:harness-bootstrap`. This file holds the project's own sections.

## Rules (auto-load on file match)

`.claude/rules/*.md` files attach to file reads via `paths:` frontmatter — full-body rule fires at the decision moment, zero ambient cost when irrelevant.

- **`dimension-discipline.md`** — fires on `docs/**/*.md`, `/README.md` (root), `plugins/*/README.md` (plus any `paths:` entries the repo appends)
  • Before editing a prose doc, classify what it owns: state (overwrite in place) vs history (append-only, git's job).
- **`ssot-doc-link.md`** — fires on `docs/**/*.md`, `/README.md` (root), `plugins/*/README.md` (plus any `paths:` entries the repo appends)
  • Link each concept to its SSOT home as you write — born-linked, not back-filled.

{example scaffolding — this label goes with the example bullets below}

{- **`rules/<framework>.md`** — fires on `{framework component glob}`}
{  • {one-line key rule}}
{  • {one-line key rule}}

{- **`rules/mv3.md`** — fires on `src/background/**`, `src/content/**`}
{  • {one-line key rule}}
{  • {one-line key rule}}

If rule body needs more context than its summary provides during planning, read the rule file directly before designing — `Read .claude/rules/<name>.md`.

## Tech Stack

{detected one-line summary, e.g. "Node 20 + Next 14 + Postgres + pnpm"}

→ Full stack table, dependency philosophy, architecture rules, observed coding patterns in [`docs/techstack.md`](docs/techstack.md).

{## Monorepo — Cross-Package Build Pre-flight}

{Workspace repo ({workspace tool}; packages in [`docs/techstack.md`](docs/techstack.md#packages)). Before committing a change that touches a shared package, build/typecheck its dependents — a package green on its own can still break its consumers.}
{Run the workspace-aware filtered build first, commit only on green (e.g. `{turbo run build --filter=...[HEAD]}` / `nx affected -t build` / `pnpm -r --filter '...[origin/main]' build`). Package boundaries live in `.claude/rules/` path globs (`apps/*/...`), not nested CLAUDE.md.}

## Commands

```bash
{detected from scripts/Makefile/Cargo — only what exists right now}
```

## Planning

- [`docs/overview.md`](docs/overview.md) — product context, data flow, module index.
- [`docs/techstack.md`](docs/techstack.md) — stack, architecture rules, observed coding patterns.
- [`docs/specs/`](docs/specs/) — feature specs, one `.md` per feature. Filename + heading is the catalog; no index.
- [`docs/work/`](docs/work/README.md) — open cards (`BUG` / `DEBT` / `GAP`, append-only threads), captured via `/super-bootstrap:log`, deleted on resolve; `README.md` holds the thread contract + ID shape.
{- [`docs/parked.md`](docs/parked.md) — deferred items with named triggers}
{- [`docs/test-queue.md`](docs/test-queue.md) — manual-verification queue}
{- [`docs/outward/`](docs/outward/README.md) — outward threads: next move + waiting-on party, one file per item}
- [`docs/terminology.md`](docs/terminology.md) — the project's term home: one canonical word per concept, `_Avoid_` aliases; a doc's first substantive use of a term links this file.
- [`docs/decisions.md`](docs/decisions.md) — closed forks / rejected directions, all domains (history dimension). See its scope header for admission criteria; checked at triage.
- `.claude/rules/` — path-scoped rules, full-body fires on file match (see Rules section above)

> `docs/specs/` = permanent source of truth; working design and plan live as blocks on the owning card's thread.
