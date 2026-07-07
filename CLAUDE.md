# super-bootstrap

## Development Workflow

Work enters by picking up a card — a `docs/backlog.md` row (`/super-bootstrap:todo` pickup or a prose ID) — or grounding a new one via `/super-bootstrap:log`. The card is the grounding artifact (root-cause claim for a bug, problem statement for a feature) and the unit/anchor/boundary/SSOT of the change. Fresh work and resumed work use the same door.

### The envelope

`ground → route → implement (ambient laws: test-driven-development, verification-before-completion, receiving-code-review, dispatching-parallel-agents) → verify → doc-sync → commit`. Red/failing-test-first runs inside implement wherever a test surface exists. Red and verify are structurally empty — no ceremony — on a diff with no test/runtime surface (docs-only). Verify on a harness-file change (CLAUDE.md, rules, skills, agents) = `audit-harness-edits`. Commit = `/super-bootstrap:commit`.

### Cluster routing

Route the card off the mapped upstream topology — [`docs/specs/superpowers-topology.md`](docs/specs/superpowers-topology.md) — not from memory.

| # | Cluster | Route |
|---|---|---|
| 1 | Bug / broken behavior | `systematic-debugging` whole — root cause before fix |
| 2 | Fuzzy feature / new capability | `brainstorming` whole — approved design hands to writing-plans |
| 3 | Design-intact multi-step | `writing-plans` direct |
| 4 | Refactor | ground the card; multi-step → cluster 3, atomic → envelope only |
| 5 | Config / taste / bounded tweak | inline; taste that iterates or drifts → card it |
| 6 | Docs / prose | envelope only |
| 7 | Harness edit | `load-harness-principles` pre, `audit-harness-edits` post |
| 8 | Triage / investigation-only | inline reads + dispatched probes |

### Route line — state, don't gate

Cluster + route resolvable from the card/SSOT → post the route in one line and proceed. Stop for the user's pick only on a genuine fork: ambiguous cluster, a conflict with a closed fork in [`docs/decisions.md`](docs/decisions.md), or high blast radius.

### Inside a route

Once a superpowers entry (`systematic-debugging` / `brainstorming` / `writing-plans`) is entered, run it whole — its gates, pointers, and artifacts govern until its own terminal handoff or a documented choice-point. Route at entry only, honoring every `REQUIRED SUB-SKILL` pointer between.

**User instructions override Superpowers defaults.** User can redirect any route.

Spec/plan locations: `docs/superpowers/specs/` and `docs/superpowers/plans/` (temporal). Persistent specs (kept after merge) go to `docs/specs/`.

## Dispatch — who holds each phase

The gateway orchestrates; it does not build. Inline lane = orchestration, reads, bounded live tweaks (aesthetic / config value, applied + checked in-app). Everything carrying a **propagation closure** — the edit plus every truth it must keep in sync — dispatches to a clean subagent. Judge by closure, not diff size: a one-line config tweak owns no closure → inline; a one-line fix that chains triage + multi-file reads + doc-sync has a closure → dispatch.

- **Build** (within Implement) → dispatch per phase, gateway integrates + verifies between. Build is never a live tweak.
- **Doc-sync scan** (envelope step) → dispatch the cold read across the § Doc Sync surface; gateway resolves findings with the user; writes land inline or dispatched by closure.
- **Parallel within a phase, not across it** — N build sub-goals or N doc surfaces fan out together; build → doc-sync stays ordered (doc-sync needs the finished diff).

## Doc Sync (non-negotiable)

Named pipeline step — every route includes it between user review and commit. Dispatch the staleness scan to a clean subagent (§ Dispatch).

Before every commit, scan for prose describing behavior touched by the diff — `docs/` (specs, overview, techstack, backlog) **and behavior-narrating prose outside `docs/`: the root `README`, plus any manifest/description field the diff's behavior changes**. If any looks stale:

1. Report it — path, what looks outdated, relevant diff context
2. Resolve together — update or acknowledge it's still accurate
3. Never silently fix. Never silently skip.

**Write boundary** — doc-sync writes narrative docs only: `docs/` and the root `README`. All harness — `CLAUDE.md`, `.claude/rules/`, skills, agents, plugin manifests — is **read-only within this step**: flag the drift and route the fix to its owner (a deliberate harness edit carrying its own verify pass; `/release` for manifests).

**Dimension routing (state XOR history — decide before writing any `docs/` file):**

State docs (`overview.md`, `techstack.md`, specs) hold what is **true now** — never timestamp precedent into them. Route by dimension:

- Decision still **binding** current work → present-tense constraint in the state doc it governs, stripped of when/why-decided. ("Refinement deferred behind the port" — not "on <date> we decided to defer refinement because…").
- Committed change history (what changed / when / why-of-a-change) → **git log + commit messages**. Don't hand-chronicle it into a doc.
- A direction evaluated and **closed** that left no diff (road-not-taken, wall foreseen) and would otherwise be re-proposed → [`docs/decisions.md`](docs/decisions.md).

**Temporal cleanup:** if work completes a feature branch, delete its spec and plan files from `docs/superpowers/specs/` and `docs/superpowers/plans/`. Once merged, they're noise.

**Backlog cleanup:** if work resolves a `BUG-###` / `DEBT-###` / `GAP-###` from `docs/backlog.md`, delete that item — including a shipped feature-`GAP`, which now belongs to the product narrative (Problem / Current State / Module Index). Git history is the archive.

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

- **`dimension-discipline.md`** — fires on `docs/**/*.md`, `README.md`
  • Before editing a prose doc, classify what it owns: state (overwrite in place) vs history (append-only, git's job).
- **`ssot-doc-link.md`** — fires on `docs/**/*.md`, `README.md`
  • Link each concept to its SSOT home as you write — born-linked, not back-filled.
- **`repo-boundary.md`** (native) — fires on `plugins/**`, `.claude/rules/**`, `.claude/guidelines/**`
  • State which copy is under test (published vs in-repo dev). Route findings: this repo's artifacts → `/super-bootstrap:log`; device/global config → `/contribute` (imported artifacts read-only).
  • Taste-coupling: dogfood harness (this repo's own CLAUDE.md/rules) may wire served guidelines; shipped skeletons (`plugins/*/skills/*/assets/**`) must be self-contained — downstream ≠ author.

First two served from the personal claude-config repo (predicates in `.claude/guidelines/work-discipline/`). Add a project-specific rule file when a path-scoped pattern emerges (e.g. a SKILL.md authoring convention), then mirror a one-line summary here.

If rule body needs more context than its summary provides during planning, read the rule file directly before designing — `Read .claude/rules/<name>.md`.

## Tech Stack

Markdown-authored Claude Code plugin + self-hosted marketplace — no language runtime or build step.

→ Full stack table, dependency philosophy, architecture rules, coding patterns in [`docs/techstack.md`](docs/techstack.md).

## Commands

```bash
# No build system — skills/agents are markdown, loaded by Claude Code's plugin loader.
# Release (bump plugin.json version, sync marketplace description mirror, commit, tag):
/release
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
- [`docs/backlog.md`](docs/backlog.md) — open items (`BUG-###` / `DEBT-###` / `GAP-###`), captured via `/super-bootstrap:log`, deleted on resolve.
- [`docs/decisions.md`](docs/decisions.md) — closed forks / rejected directions, all domains (history dimension). See its scope header for admission criteria; checked at triage.
- `docs/superpowers/specs/` — design specs from brainstorming (temporal — deleted after merge)
- `docs/superpowers/plans/` — implementation plans (temporal — deleted after merge)
- `.claude/rules/` — path-scoped rules, full-body fires on file match (see Rules section above)

> **Two kinds of specs:** `docs/specs/` = permanent source of truth. `docs/superpowers/specs/` = temporal work orders.
