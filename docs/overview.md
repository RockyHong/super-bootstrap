# Overview

<!-- harness-meta: read by /super-bootstrap:resolve-plugins (tier-2 curation). Keep YAML shape; list values in [...].
Default [github]; add any of: notion, linear, jira, slack, trello, clickup, other.
external-tools: [github]
-->

> Living doc. Skeleton sections (Problem / User / Current State) start empty at scaffold and fill at GAP-card pickup. Grown sections (Module Index / Data Flow / Key Boundaries) start empty and grow via doc-sync — every commit that adds, removes, or reshapes a module triggers a sync proposal. See `CLAUDE.md` Doc Sync.

## Problem

Per-project Claude Code setup is a repeated grind: write `CLAUDE.md`, pick skills/MCPs/hooks, pin config, establish a workflow. super-bootstrap collapses that into one command (`/super-bootstrap`) that inspects a repo and installs a development pipeline — CLAUDE.md, skeleton docs, path-scoped rules, curated skill/MCP/hook picks — plus a **phase-gated workflow** so every session runs only the pipeline phases the work actually needs (workflow, not just a toolbelt). The harness names disciplines rather than skill entries, so no process-harness plugin is a dependency ([`docs/specs/harness-architecture.md`](specs/harness-architecture.md)). Greenfield repos get lean ideation Q&A first; repos with code get scanned and scaffolded. It also bundles the companion skills that run the pipeline day-to-day: commit, todo, log, triage, triage-report, help, merge, drain, check-docs-consistency, and optional release-init.

## User

Solo devs juggling multiple repos — **agentic builders, not pure engineers**. They hold
product intent (what problem, for whom) alongside the code, so the harness covers the
product dimension and not only the engineering pipeline: `/super-bootstrap:log` admits
feature `GAP`s beside defects, this doc carries Problem / User, and
[`docs/decisions.md`](decisions.md) admits product and business forks beside technical
ones.

A codebase answers *solution* only. An agent asked whether something should be built has
no premise to judge against unless the product anchor is written down somewhere it reads
([`docs/specs/harness-architecture.md`](specs/harness-architecture.md) §2).

The runway is deliberately light enough for a consumer to modify — it seeds disciplines
and doors, not a framework to conform to.

## Current State

Active development.

## Module Index

> Grows via doc-sync as modules are added or refactored. One-line description per significant file or directory.

`plugins/super-bootstrap/` — install subtree; the only tree that ships to users (see [Key Boundaries](#key-boundaries))
- `skills/` — 13 bundled skills; per-skill contract in each `SKILL.md`; full catalog → [`plugins/super-bootstrap/README.md § Skill catalog`](../plugins/super-bootstrap/README.md#skill-catalog)
- `agents/` — 7 dispatched subagents: `doc-sync-scan`, `plugin-digest`, `premise-closure`, `review-intake`, `todo`, `triage-report`, `triage`; each runs cold-context and read-only
- `shared/` — 2 cross-skill specs: [`classify-actionable.md`](../plugins/super-bootstrap/shared/classify-actionable.md) (item classification SSOT for `todo` + `drain`), [`grounding-discipline.md`](../plugins/super-bootstrap/shared/grounding-discipline.md) (cold-judge rules SSOT for 4 grounding agents)
- `.claude-plugin/plugin.json` — plugin manifest: name, version, skills list

`.claude-plugin/marketplace.json` — self-hosted marketplace declaration; `source` field pins the install boundary
`docs/` — dev-workspace docs (this file, [`techstack.md`](techstack.md), [`specs/`](specs/), [`work/`](work/README.md)); never ships to users
`tests/` — 2 shell smoke tests (`commit-channel.test.sh`, `render-menu.test.sh`)

## Data Flow

> Grows via doc-sync as entry points and pipelines crystallize. Inputs → transforms → outputs through the code.

**Setup** — `/super-bootstrap` → `harness-bootstrap` installs/syncs runway (CLAUDE.md, skeleton docs, rules, hook) → seed-doc gate → filled: `resolve-plugins` curates picks, writes `.claude/settings.json`; empty: seeds 3 GAP cards, holds at resolve gate (mermaid entry-point diagram in root README).

**Capture** — `/super-bootstrap:log <observation>` → gateway-inline classify + dedup-surface → card written to `docs/work/{ID}.md`.

**Triage** — `/super-bootstrap:triage {ID}` → dispatches `agents/triage.md` (Opus, clean context) → reads card + live tree → appends `## Verdict` block to `docs/work/{ID}.md`.

**Board** — `/super-bootstrap:todo` → dispatches `agents/todo.md` (Sonnet) → reads `docs/work/` → renders intent-filtered board.

**Commit** — `/super-bootstrap:commit` → gateway-inline stage + classify → grep-gate → doc-surface hit dispatches `agents/doc-sync-scan.md` (Sonnet) → stale-doc report resolved → `git commit`; product-anchor hit also dispatches `agents/premise-closure.md`.

**Drain** — `/super-bootstrap:drain` → selects admissible wave → spawns one `claude -p` per item in an isolated git worktree → each runs the full envelope and writes `.drain-status`; gateway collects statuses at wave close.

## Key Boundaries

> Grows via doc-sync as API contracts, internal interfaces, and external dependencies stabilize.

**Plugin-loader contract** — Claude Code reads `plugin.json` to discover skills; loads each skill's `SKILL.md` frontmatter at invocation. No runtime execution; skills and agents are markdown. The loader never reads outside the `source` subtree.

**Install boundary** — `.claude-plugin/marketplace.json` `source: ./plugins/super-bootstrap` pins what ships to installers; all repo-root files (`docs/`, `tests/`, `CLAUDE.md`, `README.md`) are dev-workspace-only. Layout + `marketplace.json`/`plugin.json` relationship: [`docs/techstack.md § Framework`](techstack.md#framework).

**Shipped-skeleton self-containment** — assets `harness-bootstrap` seeds into consumer repos (`plugins/*/skills/*/assets/`) must resolve with only the installed plugin — no wire to `.claude/guidelines/`, no reference to a plugin-internal path a consumer repo lacks. Rule: [`.claude/rules/repo-boundary.md`](../.claude/rules/repo-boundary.md).

**Frozen-asset install contract** — hook assets (`commit-channel.hook.json`, `commit-channel.sh`) and drain infra (`read-hook.json`, `worktree-settings.local.json`) are frozen in `plugins/super-bootstrap/skills/{harness-bootstrap,drain}/assets/`; installed into consumer repos by idempotent `ensure-infra` procedures, never edited in place. The `commit-channel` hook confines raw `git commit` to the session commit door in every installed repo.

**Files-as-contract handoff** — skills communicate via committed docs (`docs/overview.md`, `docs/techstack.md`, `.claude/settings.json`), not in-memory state, so each skill runs standalone. SSOT map: [`plugins/super-bootstrap/README.md § Source of truth boundaries`](../plugins/super-bootstrap/README.md#source-of-truth-boundaries).
