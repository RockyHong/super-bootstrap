# {Project Name}

## Development Workflow

Work enters by picking up a card — a `docs/backlog.md` row (`/super-bootstrap:todo` pickup or a prose ID) — or grounding a new one via `/super-bootstrap:log`. The card is the grounding artifact (root-cause claim for a bug, problem statement for a feature) and the unit/anchor/boundary/SSOT of the change. Fresh work and resumed work use the same door.

### The envelope

`ground → route → implement (ambient laws: test-driven-development, verification-before-completion, receiving-code-review, dispatching-parallel-agents) → verify → doc-sync → commit`. Red/failing-test-first runs inside implement wherever a test surface exists. Red and verify are structurally empty — no ceremony — on a diff with no test/runtime surface (docs-only). Commit = `/super-bootstrap:commit`.

### Cluster routing

Route the card by cluster:

| # | Cluster | Route |
|---|---|---|
| 1 | Bug / broken behavior | `systematic-debugging` whole — root cause before fix |
| 2 | Fuzzy feature / new capability | `brainstorming` whole — approved design hands to writing-plans |
| 3 | Design-intact multi-step | `writing-plans` direct |
| 4 | Refactor | ground the card; multi-step → cluster 3, atomic → envelope only |
| 5 | Config / taste / bounded tweak | inline; taste that iterates or drifts → card it |
| 6 | Docs / prose | envelope only |
| 7 | Harness edit (CLAUDE.md, rules, skills, agents) | git log + `.claude/rules/index.md` pre-edit; verify pass post-edit |
| 8 | Triage / investigation-only | backlog card → `/super-bootstrap:triage {ID}` (read-only verdict phase → scope.md or notes.md); ad-hoc question → inline reads + dispatched probes |

### Framing + Route — state, don't gate

State the card's **problem-aim** before routing — premise / problem / scenario only, synthesized self-coherent (hold back the card's Prior; restate rather than paste index-quotes) — then state cluster + route. Both scale together: resolvable from the card/SSOT → post in one line and proceed (framing line + route line); stop for the user's explicit OK only on a genuine fork — ambiguous cluster, a conflict with a closed fork in [`docs/decisions.md`](docs/decisions.md), high blast radius, or card-claim ambiguity / suspected mis-aim. Hold the aligned aim as the check on everything machinery returns: a verdict or solution that re-aims the problem is surfaced, not absorbed (`aligned ≠ correct` — the user confirms the target, not the answer).

### Inside a route

Once a superpowers entry (`systematic-debugging` / `brainstorming` / `writing-plans`) is entered, run it whole — its gates, pointers, and artifacts govern until its own terminal handoff or a documented choice-point. Route at entry only, honoring every `REQUIRED SUB-SKILL` pointer between.

**User instructions override Superpowers defaults.** User can redirect any route.

### Sizing — scale ceremony to the work's shape

Route and writing-plans defaults assume worst-case — fuzzy-new work, a cold executor, every task equally central. Scale each down to the shape in hand; § Dispatch's closure valves scale dispatch grade the same way.

- **Route depth keys on shape-familiarity, not cluster alone** — a known-shape repeat (the Nth same-shape artifact) routes lighter than its nominal cluster, skipping the discovery phases (brainstorming, full plan) a first-of-shape needs.
- **Task boundary = logical-change-unit, not surface-group** — one change narrated across N file clusters is one task + one commit, not N. Batch same-logical-change surfaces.
- **Per-task verify depth scales to surface centrality** — an ambient-loaded harness surface (CLAUDE.md, a rule, an agent) earns a full cold verify pass whatever the change size; an isolated low-centrality surface (a README line, a manifest field, a docs paragraph) earns a light pass.
- **Same-session author == executor → reference, don't embed** — writing-plans embeds full file bodies for a cold executor; when the authoring session also executes, reference draft bodies by section instead of re-embedding full file text.

Spec/plan locations: `docs/superpowers/specs/` and `docs/superpowers/plans/` (temporal). Persistent specs (kept after merge) go to `docs/specs/`.

## Dispatch — who holds each phase

The gateway orchestrates; it does not build. Inline lane = orchestration, reads, bounded live tweaks (aesthetic / config value, applied + checked in-app). Everything carrying a **propagation closure** — the edit plus every truth it must keep in sync — dispatches to a clean subagent. Judge by closure, not diff size: a one-line config tweak owns no closure → inline; a one-line fix that chains triage + multi-file reads + doc-sync has a closure → dispatch.

- **Build** (within Implement) → dispatch per phase, gateway integrates + verifies between. Build is never a live tweak.
- **Transcription is not a build** — when the exact content is already in hand (a plan supplies verbatim old/new text, or the gateway already holds the final text) with no runtime to derive against, applying it carries zero closure: inline it, even mid-dispatch-regime. Reserve dispatch for content a container must derive: reads, integration, judgment.
- **Build inside a superpowers chain** (a `writing-plans` artifact in hand) → the chain's own executor governs — take its documented choice-point (`subagent-driven-development` / fallback); the lanes here carry envelope work outside a chain. **SDD carve-out:** subagent commits route through the commit door, so an SDD implementer implements + tests + reports (built + file list) and the gateway commits via `/super-bootstrap:commit` (gateway-inline mechanics; the cold doc-sync scan dispatches only when its grep-gate hits). SDD's fix→re-review loop scales to fix grade — a transcription-grade fix (shape fully supplied) → dispatcher verifies against the diff, no re-review dispatch; a judgment-grade fix (shape left to the implementer) → re-review dispatches. For free per-implementer commits, use the drain-worktree path — isolated commits, doc-sync deferred to the merge boundary.
- **Doc-sync scan** (envelope step) → gateway-inline; a grep-gate dispatches the cold `doc-sync-scan` agent only on a doc-surface hit (mechanism: § Doc Sync); resolving writes land inline or dispatched by closure.
- **Parallel within a phase, not across it** — N build sub-goals or N doc surfaces fan out together; build → doc-sync stays ordered (doc-sync needs the finished diff).
- **Create-new-file subagents dispatch foreground** — a subagent tasked to CREATE a new harness/skill file runs foreground, not `run_in_background`: backgrounded, its new-file Write fails and the subagent stalls before writing. Editing an existing file and creating a non-harness file background cleanly.

## Doc Sync (non-negotiable)

Named pipeline step — every route includes it between user review and commit. The commit door (`/super-bootstrap:commit`) runs gateway-inline; a mechanical grep-gate dispatches the cold `doc-sync-scan` agent when the diff touches the doc surface, and its `stale-docs` return goes to the gateway, which resolves with the user before the commit lands. Coverage backstop: `/check-docs-consistency` (on-demand, whole-repo).

Before every commit, scan for prose describing behavior touched by the diff — `docs/` (specs, overview, techstack, backlog) **and behavior-narrating prose outside `docs/`: the root `README`, plus any manifest/description field the diff's behavior changes**. If any looks stale:

1. Report it — path, what looks outdated, relevant diff context
2. Resolve together — update or acknowledge it's still accurate
3. Never silently fix. Never silently skip.

**Write boundary** — doc-sync writes narrative docs only: `docs/` and the root `README`. All harness — `CLAUDE.md`, `.claude/rules/`, skills, agents, release-owned manifests — is **read-only within this step**: flag the drift and route the fix to its owner (a deliberate harness edit carrying its own verify pass; the project's release step for manifests).

**Dimension routing (state XOR history — decide before writing any `docs/` file):**

State docs (`overview.md`, `techstack.md`, specs) hold what is **true now** — never timestamp precedent into them. Route by dimension:

- Decision still **binding** current work → present-tense constraint in the state doc it governs, stripped of when/why-decided. ("Refinement deferred behind the port" — not "on <date> we decided to defer refinement because…").
- Committed change history (what changed / when / why-of-a-change) → **git log + commit messages**. Don't hand-chronicle it into a doc.
- A direction evaluated and **closed** that left no diff (road-not-taken, wall foreseen) and would otherwise be re-proposed → [`docs/decisions.md`](docs/decisions.md).

**Temporal cleanup:** if work completes a feature branch, delete its spec and plan files from `docs/superpowers/specs/` and `docs/superpowers/plans/`. Once merged, they're noise.

{**Backlog cleanup:** if work resolves a `BUG-###` / `DEBT-###` / `GAP-###` from `docs/backlog.md`, delete that item and any `docs/superpowers/triage/{ID}-*` verdict file — including a shipped feature-`GAP`, which now belongs to the product narrative (Problem / Current State / Module Index). Git history is the archive.}

## Coding Principles

Before writing, reviewing, or refactoring code, invoke the `karpathy-guidelines` skill.

It owns four principles (think-before-coding, simplicity-first, surgical-changes, goal-driven-execution). Skill body is upstream — don't paraphrase it here.

## Edit Discipline — Renames & Replace-All

Rename preference order: LSP rename → per-occurrence Edit → `sed` (unique 8+ char literals) → `replace_all` (long unique literals only).

Banned-terms list + pre-flight checklist + recovery protocol: [`docs/techstack.md` § Edit Discipline](docs/techstack.md#edit-discipline).

## Context Hygiene

Subagent-first is the default container for build and doc phases (§ Dispatch); context weight is an additional dispatch trigger, not the only one. Compact while warm, clear on topic shift. Park mid-implementation state to docs before `/clear`.

## Finding Triage — Log vs Fix Now

Decide on two axes: **context budget** (is the window heavy?) and **topic distance** (on-goal, or far blast radius?).

- Context heavy **OR** off-topic / far blast → **log** via `/super-bootstrap:log`.
- On-topic **AND** context clean **AND** fix small + safe → **fix now**.

Surface a real fork to the user as an MCQ with the recommended path badged `(recommended)`. No real fork (trivial fix or trivial tangent) → act and mention, skip the MCQ.

## Rules (auto-load on file match)

`.claude/rules/*.md` files attach to file reads via `paths:` frontmatter — full-body rule fires at the decision moment, zero ambient cost when irrelevant.

{seeded by sp-bootstrap based on Phase 1 stack signals — examples:}

{- **`rules/<framework>.md`** — fires on `{framework component glob}`}
{  • {one-line key rule}}
{  • {one-line key rule}}

{- **`rules/mv3.md`** — fires on `src/background/**`, `src/content/**`}
{  • {one-line key rule}}
{  • {one-line key rule}}

{If rule body needs more context than its summary provides during planning, read the rule file directly before designing — `Read .claude/rules/<name>.md`.}

## Tech Stack

{detected one-line summary, e.g. "Node 20 + Next 14 + Postgres + pnpm"}

→ Full stack table, dependency philosophy, architecture rules, coding patterns in [`docs/techstack.md`](docs/techstack.md).

{## Monorepo — Cross-Package Build Pre-flight}

{Workspace repo ({workspace tool}; packages in [`docs/techstack.md`](docs/techstack.md#packages)). Before committing a change that touches a shared package, build/typecheck its dependents — a package green on its own can still break its consumers.}
{Run the workspace-aware filtered build first, commit only on green (e.g. `{turbo run build --filter=...[HEAD]}` / `nx affected -t build` / `pnpm -r --filter '...[origin/main]' build`). Package boundaries live in `.claude/rules/` path globs (`apps/*/...`), not nested CLAUDE.md.}

## Commands

```bash
{detected from scripts/Makefile/Cargo — only what exists right now}
```

## Git Notes

- Only commit current session's changes — leave unrelated uncommitted work alone
- Atomic commits — one logical change per commit
- Conventional commits — `feat:`, `fix:`, `refactor:`, `docs:`, `test:`, `chore:`
- No PR self-review — commit directly. Main + feature branches. No force push.
- Merge conflict → stop and ask.

## Planning

- [`docs/overview.md`](docs/overview.md) — product context, data flow, module index.
- [`docs/techstack.md`](docs/techstack.md) — stack, architecture rules, coding patterns.
{- [`docs/specs/`](docs/specs/) — persistent feature specs, one `.md` per feature. Filename + heading is the catalog; no index.}
{- [`docs/backlog.md`](docs/backlog.md) — open items (`BUG-###` / `DEBT-###` / `GAP-###`), captured via `/super-bootstrap:log`, deleted on resolve.}
{- [`docs/parked.md`](docs/parked.md) — deferred items with named triggers (scale module)}
{- [`docs/test-queue.md`](docs/test-queue.md) — manual-verification queue (scale module)}
- [`docs/decisions.md`](docs/decisions.md) — closed forks / rejected directions, all domains (history dimension). See its scope header for admission criteria; checked at triage.
- `docs/superpowers/specs/` — design specs from brainstorming (temporal — deleted after merge)
- `docs/superpowers/plans/` — implementation plans (temporal — deleted after merge)
- `.claude/rules/` — path-scoped rules, full-body fires on file match (see Rules section above)

> **Two kinds of specs:** `docs/specs/` = permanent source of truth. `docs/superpowers/specs/` = temporal work orders.
