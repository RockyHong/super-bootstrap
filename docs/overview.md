# Overview

<!-- harness-meta: read by /super-bootstrap:resolve-plugins (tier-2 curation). Keep YAML shape; list values in [...].
Default [github]; add any of: notion, linear, jira, slack, trello, clickup, other.
external-tools: [github]
-->

> Living doc. Skeleton sections (Problem / User / Current State) carry their placeholder body verbatim at scaffold and fill at GAP-card pickup. Grown sections (Module Index / Data Flow / Key Boundaries) start empty and grow via doc-sync — every commit that adds, removes, or reshapes a module triggers a sync proposal, admitted per § Doc Sync. See [`CLAUDE.md` Doc Sync](../CLAUDE.md#doc-sync-non-negotiable).

## Problem

Per-project Claude Code setup is a repeated grind: write `CLAUDE.md`, pick skills/MCPs/hooks, pin config, establish a workflow. super-bootstrap collapses that into one command (`/super-bootstrap:setup`) that inspects a repo and installs a development pipeline — CLAUDE.md, skeleton docs, path-scoped rules, curated skill/MCP/hook picks — plus a **phase-gated workflow** so every session runs only the pipeline phases the work actually needs (workflow, not just a toolbelt). The harness names disciplines rather than skill entries, so no process-harness plugin is a dependency ([`docs/specs/harness-architecture.md`](specs/harness-architecture.md)) — the only pin it seeds is its own core self-pin. Greenfield repos get three seed GAP cards (overview, techstack, tech curation) whose pickup settles the product shape — no upfront product Q&A; repos with code get scanned and scaffolded. It also bundles the companion skills that run the pipeline day-to-day: commit, needs-me, session-close, session-continue, log, triage, triage-report, help, merge, autorun, check-docs-consistency, and optional release-init.

## User

Solo devs juggling multiple repos — **agentic builders, not pure engineers**. They hold
product intent (what problem, for whom) alongside the code, so the harness covers the
product dimension and not only the engineering pipeline: `/super-bootstrap:log` admits
[feature `GAP`s](work/README.md#categories) beside defects, this doc carries Problem / User, and
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
- `skills/` — 15 bundled skills; per-skill contract in each `SKILL.md`; full catalog → [`plugins/super-bootstrap/README.md § Skill catalog`](../plugins/super-bootstrap/README.md#skill-catalog)
- `agents/` — 6 dispatched subagents: `doc-sync-scan`, `plugin-digest`, `premise-closure`, `review-intake`, `triage-report`, `triage`; each runs cold-context and read-only
- `shared/` — 2 cross-skill specs: [`user-wall.md`](../plugins/super-bootstrap/shared/user-wall.md) (the one needs-the-user judgment `needs-me` + `autorun` share), [`grounding-discipline.md`](../plugins/super-bootstrap/shared/grounding-discipline.md) (cold-judge rules SSOT for 4 grounding agents)
- `hooks/` — 1 plugin-owned hook: [`hooks.json`](../plugins/super-bootstrap/hooks/hooks.json) (SessionStart manifest) + [`runway-version.sh`](../plugins/super-bootstrap/hooks/runway-version.sh) (receipt-vs-installed-plugin version advisory); runs from the installed plugin tree, never placed ([Key Boundaries](#key-boundaries))
- `.claude-plugin/plugin.json` — plugin manifest: name, description, version, and metadata; carries no `skills` array ([`techstack.md § Framework`](techstack.md#framework))

`.claude-plugin/marketplace.json` — self-hosted marketplace declaration; `source` field pins the install boundary
`docs/` — dev-workspace docs (this file, [`techstack.md`](techstack.md), [`specs/`](specs/), [`work/`](work/README.md), the scale-module containers [`parked.md`](parked.md) / [`test-queue.md`](test-queue.md) / [`outward/`](outward/README.md)); never ships to users
`tests/` — 6 shell unit tests (`closed-forks.test.sh`, `commit-channel.test.sh`, `doc-links.test.sh`, `frontmatter.test.sh`, `render-menu.test.sh`, `runway-version.test.sh`)
`bench/` — 20 measured fixtures kept beside the SSOT they test: `assertion-liveness/` (RED for an assertion-liveness clause in the two shipped skeletons' build contract — does an implementer rewrite an assertion's tolerance and report green without ever observing it fail), `catalog-axis/` (RED fixture + tier probe for `check-docs-consistency`'s catalog-row axis), `code-presence-scope/` (micro-test for `harness-bootstrap` § Code presence — does a docs-only repo read as code present once the pipeline's own hook scripts sit under `.claude/hooks/`), `commit-guard/` (test surface for the commit door's index readback and stamp ordering), `commit-push/` (test surface for the commit door's push probe — no remote / remote without upstream / upstream), `consult-hook/` (test surface for the shipped `consult-check` pair), `doc-links/` (golden test for the commit door's `doc-links.sh` gate enumeration), `doc-sync/` (container read-out for the commit door's doc-sync judgment — cold dispatch vs warm gateway-inline, diff and scan scope held fixed), `log-closed-forks/` (RED for the `log` door's Closed-forks gate — does a clean read leave a per-entry outcome line, or the same silence as an unread source), `lean-brief-numbers/` (light RED for `harness-bootstrap` § Principles' precision-per-byte bullet without its dated numbers), `merge-cd/` (no-guidance control for the merge skill's working-directory line), `merge-push/` (test surface for the merge door's push probe — no remote / remote without upstream / upstream), `plugin-digest-fabricate/` (A/B for the Haiku-pinned `plugin-digest` agent's anti-fabrication instances), `rot-row-contract/` (micro-test for `harness-bootstrap` § 2b's rot-scan row contract, the § 2c gate + receipt that consume it, and § 2c's commit predicate), `rot-scan-frozen-skip/` (micro-test for the rot scan's `dimension: history` frozen-provenance skip), `rot-scan-liveness/` (micro-test for the rot scan's swept-set clause — is a scan that swept zero literals recorded as a clean or as an instrument failure), `scale-fact-fields/` (micro-test for `harness-bootstrap` § 2a-scale's marker-present vs drift precedence), `triage-batch-fanout/` (micro-test for the triage skill's one-card-per-dispatch batch rule), `triage-grep-first/` (arms for the triage agent's body — the grep-first bullet and the per-action tool floor), `triage-taste-shape/` (RED + treatment arms for the triage verdict's `### Taste needed` shape — does the agent invent options on a taste card, and does the gateway's absorb put an MCQ or Design block to the author)

## Data Flow

> Grows via doc-sync as entry points and pipelines crystallize. Inputs → transforms → outputs through the code.

**Setup** — `/super-bootstrap:setup` → `harness-bootstrap` installs/syncs runway (CLAUDE.md, skeleton docs, rules, hooks) → code present: seeds 2 GAP cards (spec seeding, marker sweep), commits, works what it can in the same run → seed-doc gate → filled: `resolve-plugins` curates picks, writes `.claude/settings.json`; empty: seeds 3 GAP cards, holds at resolve gate (mermaid entry-point diagram in root README).

**Capture** — `/super-bootstrap:log <observation>` → gateway-inline classify + dedup-surface → card written to `docs/work/{ID}.md`.

**Triage** — `/super-bootstrap:triage {ID}` → dispatches `agents/triage.md` (inherits the session model — the top tier; clean context) → reads card + live tree → appends `## Verdict` block to `docs/work/{ID}.md`.

**Needs-me** — `/super-bootstrap:needs-me` → gateway reads every open card's origin block (plus the scale module's test queue, outward threads and parked items when present) → sorts by [`shared/user-wall.md`](../plugins/super-bootstrap/shared/user-wall.md) → one `AskUserQuestion` over lenses cut from what is open → ≤ 5 recommendations in the chosen lens; reply with an ID = pickup.

**Session boundary** — [`/super-bootstrap:session-close`](../plugins/super-bootstrap/skills/session-close/SKILL.md) → one confirm-pick over every closeout move → park appends `## Progress` to the card + writes the volatile rest to `SESSION-STATE/<label>-<id>.md` → commit through `/super-bootstrap:commit`; [`/super-bootstrap:session-continue`](../plugins/super-bootstrap/skills/session-continue/SKILL.md) → reads every carry → claims the picked one by rename → resumes from its card's latest block of each type, or hands off to needs-me.

**Commit** — `/super-bootstrap:commit` → gateway-inline stage + classify → [mechanical doc-sync gate](../CLAUDE.md#doc-sync-non-negotiable) → doc-surface hit judged warm gateway-inline (`agents/doc-sync-scan.md` (Sonnet) dispatches only past the scope ceiling) → stale candidates resolved → `git commit`; product-anchor hit dispatches `agents/premise-closure.md`.

**Autorun** — `/super-bootstrap:autorun` → admits every open card whose next step needs no user (same `user-wall.md` test) → spawns one `claude -p` per card in an isolated git worktree → each runs the whole card to done and writes `.autorun-status`; gateway renders one sheet — merge lines for DONE, resolve / park / drop for each WALL.

## Key Boundaries

> Grows via doc-sync as API contracts, internal interfaces, and external dependencies stabilize.

**Plugin-loader contract** — Claude Code reads `plugin.json` for the plugin's identity and, where it declares a `skills` array, for the exact set to load; with that key absent (this plugin's case) it discovers `skills/*/` by folder scan. It loads each skill's `SKILL.md` frontmatter at invocation. No runtime execution; skills and agents are markdown. The loader never reads outside the `source` subtree.

**Install boundary** — `.claude-plugin/marketplace.json` `source: ./plugins/super-bootstrap` pins what ships to installers; all repo-root files (`docs/`, `tests/`, `CLAUDE.md`, `README.md`) are dev-workspace-only. Layout + `marketplace.json`/`plugin.json` relationship: [`docs/techstack.md § Framework`](techstack.md#framework).

**Shipped-skeleton self-containment** — assets `harness-bootstrap` seeds into consumer repos (`plugins/*/skills/*/assets/`) must resolve with only the installed plugin — no wire to `.claude/guidelines/`, no reference to a plugin-internal path a consumer repo lacks. Rule: [`.claude/rules/repo-boundary.md`](../.claude/rules/repo-boundary.md).

**Frozen-asset install contract** — hook assets (the `commit-channel` and `consult-check-{check,sessionstart}` script/snippet pairs) and autorun infra (`read-hook.json`, `worktree-settings.local.json`) are frozen in `plugins/super-bootstrap/skills/{harness-bootstrap,autorun}/assets/`; installed into consumer repos by idempotent `ensure-infra` procedures, [never edited in place](techstack.md#architecture-rules). The `commit-channel` hook confines raw `git commit` to the session commit door in every installed repo; the `consult-check` pair injects prompt-time doc recall. Placed assets are one of two hook classes: [`plugins/super-bootstrap/hooks/hooks.json`](../plugins/super-bootstrap/hooks/hooks.json) is plugin-owned — loaded from the installed plugin tree via `${CLAUDE_PLUGIN_ROOT}`, never placed, updated with plugin `autoUpdate` — and its one entry, [`runway-version.sh`](../plugins/super-bootstrap/hooks/runway-version.sh) (SessionStart), prints a single advisory routing to `/super-bootstrap:harness-bootstrap` when a consumer's runway receipt `version` lags the installed `plugin.json` — the same compare [`harness-bootstrap` runs at Phase 1](../plugins/super-bootstrap/skills/harness-bootstrap/SKILL.md#version-staleness-signal-harnessed-but-stale).

**Files-as-contract handoff** — skills communicate via committed docs (`docs/overview.md`, `docs/techstack.md`, `.claude/settings.json`), not in-memory state, so each skill runs standalone. SSOT map: [`plugins/super-bootstrap/README.md § Source of truth boundaries`](../plugins/super-bootstrap/README.md#source-of-truth-boundaries).
