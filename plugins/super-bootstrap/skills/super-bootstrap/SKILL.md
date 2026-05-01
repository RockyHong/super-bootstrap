---
name: super-bootstrap
description: "Bootstrap or sync the superpowers development pipeline in any repo. Walks all phases — creates what's missing, syncs what's drifted, skips what's current. Scaffolds fixed macro docs (overview, techstack, superpowers/) and adaptive persistent docs (specs/, building, help/) based on project needs. Bakes in doc-sync discipline — docs travel with code. Solo dev workflow."
tags: [bootstrap, scaffold, setup, meta, docs]
---

# Super Bootstrap — Superpowers Pipeline for Any Repo

Set up (or retrofit) the superpowers-driven development pipeline in a project. The pipeline bootstraps itself — scaffold first, then use the pipeline to complete its own setup across sessions.

Designed for a solo developer working across multiple Claude Code sessions and cloud Claude Code.

<INFO-NOTE>
This skill is tuned for **solo developer** workflows. During Phase 1, check contributor count (`git shortlog -sn --all | head -5`). If >1 active contributor, surface to user as info — don't block:
> "FYI: detected multiple contributors. The pipeline's CLAUDE.md assumes solo dev (simple branching, no PRs for self-review). You can edit those sections after bootstrap if your team's workflow differs."
</INFO-NOTE>

## Core Technique: Docs Travel With Code

The pipeline's real power isn't brainstorm→plan→execute. It's that **documentation and implementation stay in sync — always.** Two mechanisms make this work:

### Fixed Macro Docs (every project gets these)

```
docs/
  overview.md          ← product context, data flow, module index
  techstack.md         ← tech choices, architecture rules, coding patterns
  superpowers/
    specs/             ← design specs from brainstorming (temporal — deleted after merge)
    plans/             ← implementation plans (temporal — deleted after merge)
```

These are non-negotiable. `overview.md` and `techstack.md` are living documents — they evolve with the code.

### Adaptive Persistent Docs (project-specific, discovered during Q&A)

Some projects need more structure. Examples:

- `docs/specs/` + `index.md` — persistent feature specs (what each feature does and why). For multi-feature products.
- `docs/building.md` — build/distribution instructions. For projects with non-trivial builds.
- `docs/help/` — user-facing guides. For products with end users.
- `docs/backlog.md` — deferred items tracker (BUG / DEBT / GAP). For active or maintenance projects with shipping code.

What goes here is discovered during Q&A (Phase 2). A 3-file CLI? No specs folder needed. A multi-module product? Scaffold `docs/specs/` with an index and seed entries.

### The Sync Discipline (baked into CLAUDE.md, non-negotiable)

**Doc sync is a named pipeline step** — every route includes it between user review and commit. Before every commit, the pipeline requires:
1. Scan `docs/` for files that describe behavior touched by the diff
2. If any doc is potentially stale → report to user with doc path, what looks outdated, and relevant diff context
3. Resolve together — don't silently fix, don't silently skip
4. Stale docs are worse than missing ones

**Temporal cleanup** is part of doc sync: if the current work completes a feature branch, delete its spec and plan files. These are work orders — once merged, they're noise.

This isn't a nice-to-have. This is what makes the docs trustworthy. Without it, docs rot within a week.

### Two Kinds of Specs

| | Temporal (superpowers) | Persistent (project) |
|---|---|---|
| **Location** | `docs/superpowers/specs/` | `docs/specs/` (or project-specific path) |
| **Purpose** | Work orders — design exploration before implementation | Source of truth — what exists and why |
| **Lifecycle** | Deleted after merge | Updated as features evolve |
| **Created by** | Brainstorming skill | Bootstrap seeding, then maintained during development |
| **Content** | Options, trade-offs, decisions | Product-level behavior, user flows, design decisions |

---

## How It Works

The chicken-and-egg problem: you need the pipeline to track work, but setting up the pipeline IS work. Solution: **scaffold the pipeline cold, then use it to finish its own bootstrap.**

```
Session 1 (/super-bootstrap):
  Quick scan → Q&A alignment → scaffold/sync pipeline → write bootstrap plan → commit
  Pipeline is now LIVE (or synced). /todo works. Deep analysis is tracked as tasks.

Session 2+ (/todo → pick a task):
  - [ ] Deep techstack analysis → docs/techstack.md
  - [ ] Product overview distillation → docs/overview.md
  - [ ] Enhance CLAUDE.md with coding standards, commands
  - [ ] Seed persistent specs (if applicable)
  - [ ] Resolve skills/MCPs/hooks (Task 4 — auto-curated)
```

Each task is session-sized. Context window stays clean. User runs `/todo` to see what's next.

---

## Phase 1: Quick Scan (lightweight, parallel reads)

Gather just enough to scaffold. Do NOT deep-analyze yet.

### Sensitive-File Blocklist (applies to all source-file reads)

Throughout this skill — Phase 1 detection, Task 1 sampling, anywhere Claude reads source files — **skip paths matching:**

```
.env*           *secret*        *credential*
*.pem           *.key           id_rsa*
id_ed25519*     *.p12           *.pfx
*.jks           *.keystore      .npmrc
.netrc          *.crt           *.cer
```

When skipping, surface to user: `⊘ skipped <path> (matches secret blocklist)`. Reason: sampled file content lands in `techstack.md` / `overview.md` and gets auto-committed. Secrets in committed docs = secrets in git history forever.

### Manifest Detection

Check which of these exist (don't read fully — just detect presence and skim):

| File | Stack signal |
|---|---|
| `package.json` | Node.js — skim `scripts`, `type` field, top-level deps |
| `tsconfig.json` | TypeScript |
| `Cargo.toml` | Rust |
| `pyproject.toml` / `requirements.txt` | Python |
| `go.mod` | Go |
| `Gemfile` | Ruby |
| `pom.xml` / `build.gradle` | Java/Kotlin |
| `composer.json` | PHP |
| `pubspec.yaml` | Dart/Flutter |
| `CMakeLists.txt` / `Makefile` | C/C++ |
| `.csproj` / `*.sln` | C#/.NET |

### Quick Structure

- `ls` root directory
- Check for: `docs/`, `README.md`, `CLAUDE.md`, `.claude/`, monorepo indicators
- Note existing doc structure (don't read docs deeply yet)

### Git State

- `git log --oneline -10` — commit style, recent activity
- `git shortlog -sn --all | head -5` — contributor count
- Current branch

### Existing CLAUDE.md

If it exists, read it. The pipeline may already be partially or fully present — note what's already there.

**Output of Phase 1:** A mental model of "what kind of project is this" — stack name, structure shape, maturity level. NOT a deep analysis.

---

## Phase 2: Q&A Alignment

Before writing anything, confirm your understanding with the user. Ask these **one at a time**, serial:

### Required Questions

1. **"What does this project do?"** — Even if README exists, ask. The user's answer reveals what they think matters vs what the docs say. Compare with README if it exists; flag discrepancies.

2. **"Who uses it?"** — End users? Developers? Internal tool? Library consumers? This shapes how `overview.md` will be written later.

3. **"What's the current state?"** — Greenfield? Active development? Maintenance mode? Mid-rewrite? This determines how aggressive the bootstrap should be.

### Conditional Questions

4. **If monorepo detected:** "What are the packages/apps and how do they relate?"

5. **If existing CLAUDE.md:** "Anything in the current CLAUDE.md that's wrong or outdated? Anything you want to keep as-is?"

6. **If existing docs/:** "Are these docs current, or should I treat them as potentially stale?"

7. **If multi-feature product (not a tiny CLI or single-purpose lib):** "Do you want persistent feature specs? These are living docs that describe what each feature does and why — updated as the product evolves. They'd live in `docs/specs/` with an index. Worth it for your project, or overkill?"

8. **If non-trivial build/distribution:** "Do you need build docs (`docs/building.md`)? For things like multiple distribution targets, platform-specific steps, CI setup."

9. **If user-facing product:** "Do you want a `docs/help/` folder for user-facing guides (troubleshooting, privacy, FAQ)?"

10. **If active or maintenance project (not greenfield):** "Do you want `docs/backlog.md`? Single tracker for deferred items — `BUG-###` (broken, has fix), `DEBT-###` (working but rotting), `GAP-###` (design gap, needs brainstorm). Solo-dev queue, scanned at commit by doc sync. Default yes for shipping code, skip for greenfield."

### Alignment Confirmation

After questions, present a short summary:

```
Here's what I understand:
- Project: {name} — {one-line description}
- Stack: {runtime} + {framework} + {key tools}
- State: {greenfield/active/maintenance}
- User: {who uses it}
- Structure: {monorepo/single package/other}
{- Existing CLAUDE.md: {keep/enhance/replace}}

Doc structure I'll scaffold:
  docs/
    overview.md              ← always
    techstack.md             ← always
    superpowers/specs/       ← always (temporal)
    superpowers/plans/       ← always (temporal)
    {specs/ + index.md       ← if confirmed}
    {building.md             ← if confirmed}
    {help/                   ← if confirmed}
    {backlog.md              ← if confirmed}

Sound right?
```

Wait for confirmation before proceeding. If anything is off, correct and re-confirm.

---

## Phase 3: Scaffold / Sync

With alignment confirmed (or skipped on existing repos), scaffold or sync the pipeline. On a fresh repo this creates everything. On a bootstrapped repo it validates each artifact and only touches what's drifted.

**Sync logic** — for each pipeline-owned artifact:
- Missing → create it
- Exists, matches current template → skip ("✓ current")
- Exists, drifted from template → show diff to user, offer fix

**Pipeline-owned** (checked/synced): CLAUDE.md sections (Development Workflow, Doc Sync, Context Hygiene, Coding Principles, Edit Discipline, Solo Dev Assumptions, Git Notes, Planning), `docs/superpowers/specs/`, `docs/superpowers/plans/`, bootstrap plan lifecycle.

**Project-owned** (never touched): Project Structure, Tech Stack, Commands, Coding Standards, or any custom sections the project added.

### 3a: Folder Structure

**Always created (fixed macro):**
```
docs/
  superpowers/
    specs/       ← design specs from brainstorming (temporal)
    plans/       ← implementation plans (temporal)
```

**Created if confirmed during Q&A (adaptive):**
```
docs/
  specs/
    index.md     ← catalog of persistent feature specs
  building.md    ← build/distribution instructions
  help/          ← user-facing guides
  backlog.md     ← deferred items tracker (BUG / DEBT / GAP)
```

Add `.gitkeep` in each empty folder. If `docs/` already exists, nest alongside.

**On existing repos:** Check each expected directory exists. If missing, create it. If present, skip. Report status per directory.

If `docs/specs/` is scaffolded, create `index.md` with:

````markdown
# Feature Specs

Source of truth for what {project} does and why. Each spec covers product-level behavior — intent, user flows, cross-module interactions, and design decisions.

**Permanent source of truth.** Superpowers specs (`docs/superpowers/specs/`) are work orders deleted after merge. These specs describe what exists and why — updated as features evolve.

**Product-level, code-light.** Implementation details and module internals live in the code. Specs focus on the "why" and the product logic that connects modules.

---

## Specs

| Spec | Covers |
|---|---|
| *(seeded during bootstrap Task 5 or as features land)* | |
````

If `docs/backlog.md` is scaffolded, create it with:

````markdown
# Backlog

Single tracker for deferred items — things found but not fixing now. Solo-dev queue. Scanned by doc sync at commit. When picking up new work, scan related items here to bundle.

**Three categories** distinguished by ID prefix:

- **`BUG-###`** — broken behavior with a clear fix. Routes direct to implementation.
- **`DEBT-###`** — working but rotting (test fixture rot, stale dep, cleanup owed). Routes direct to implementation.
- **`GAP-###`** — design gap, never properly specced. Routes through `superpowers:brainstorming` first, then spec → plan → execute.

Format per item: stable ID, short title, affected area, why it matters, proposed fix (BUG/DEBT) or what's missing (GAP). Newest at top. When resolved, **delete the item** — git history is the archive.

---

## Open

*(seeded as items are surfaced during reviews, audits, or development)*
````

### 3b: Write Skeleton CLAUDE.md

If no CLAUDE.md exists, create one. If one exists, enhance it (add missing sections, preserve existing content).

**On existing repos with pipeline sections:** Diff each pipeline-owned section against the current skeleton template. **Never silently overwrite.** For each drifted section:

```
CLAUDE.md sync — drift detected:

  [{Section Name}] section drifted from current template:
  ───────────────────────────────────────────────
  - {removed line}
  + {added line}
  ───────────────────────────────────────────────

  Update? (y / n / show full diff)
```

User must approve each section's update before write. If current, skip. Never touch project-owned sections.

This protects against (a) legit template updates the user wants to review and (b) bad-actor template injection on a future re-run — you see what's about to change in your CLAUDE.md before it's overwritten.

The skeleton contains the **workflow engine** — enough for any Claude session to know the rules — but leaves techstack and coding standards as stubs pointing to the bootstrap plan.

```markdown
# {Project Name}

## Development Workflow

Before starting any work, **assess the task size and propose a route for the user to confirm.** Present it like:

\```
This looks [small/medium/large] because [reason].
Route: [steps]
Impact: [what changes, how many files, risk level]
OK to proceed?
\```

### Routes

**Small** — Single file, clear intent, no design decisions
→ implement → user review → doc sync → `/commit`

**Medium** — Multi-file, some design choices, completable in one session
→ Brainstorm (quick, inline) → implement → user review → doc sync → `/commit`

**Large** — Multi-session, architectural, unclear scope
→ Full pipeline: brainstorm → spec → plan → execute → user review → doc sync → `/commit`
→ Specs go to `docs/superpowers/specs/`, plans to `docs/superpowers/plans/`

The user always picks the route.

**User instructions override Superpowers defaults.**

### Doc Sync (non-negotiable)

This is a named pipeline step — every route includes it between user review and commit.

**Before every commit**, scan `docs/` for files that describe behavior touched by the diff (specs, overview, techstack, building, help, backlog). If any doc is potentially stale:

1. Report it to the user — doc path, what looks outdated, relevant diff context
2. Resolve together — update the doc or acknowledge it's still accurate
3. Never silently fix. Never silently skip. Stale docs are worse than missing ones.

**Temporal cleanup:** If the current work completes a feature branch, delete its spec and plan files from `docs/superpowers/specs/` and `docs/superpowers/plans/`. These are work orders — once merged, they're noise.

**Backlog cleanup:** If the current work resolves a `BUG-###`, `DEBT-###`, or `GAP-###` item from `docs/backlog.md`, delete that item from the file. Git history is the archive — keep `backlog.md` as a list of what's still open.

This is the pipeline's core discipline. Implementation without doc sync is incomplete.

## Context Hygiene

Multi-needle recall (cross-file reasoning, remembering earlier decisions) degrades past ~200k input tokens regardless of model version. Token cost is solved by prompt cache (~90% savings on hits); quality is the remaining constraint. Rules:

- **Subagent-first** when work is verbose — reading 10+ files, running noisy test suites, parallel-safe chunks, fresh-eye review. Subagent gets fresh context window; orchestrator stays sharp. Skip for <3-5k token tasks (init overhead 5-15k tokens swamps gain).
- **Compact while warm.** Run `/compact` only inside cache TTL (5min default, 1hr extended). Idle compact pays full price to summarize then writes back — wasteful. If you've been away, prefer `/clear` over `/compact`.
- **Clear on topic shift.** Cache is wasted across topic boundaries anyway. Free quality reset.
- **Split sessions** when next phase is a different domain. Cheaper and sharper than dragging accumulated context.
- **Park before /clear** mid-implementation. Write a short handoff note (current state, next step, open questions) so the next session can resume.

Default ordering when context feels heavy: subagent dispatch → compact (if warm) → clear (if cold or topic shifted) → park (if mid-implementation work at risk).

## Coding Principles

Behavioral guardrails to reduce common LLM coding mistakes. Adapted from [Andrej Karpathy's observations](https://github.com/forrestchang/andrej-karpathy-skills) (via `forrestchang/andrej-karpathy-skills`). Bias toward caution over speed; for trivial tasks use judgment.

### 1. Think Before Coding

Don't assume. Don't hide confusion. Surface tradeoffs.

- State assumptions explicitly. If uncertain, ask.
- If multiple valid interpretations exist, present them — don't pick silently.
- If a simpler approach exists, say so. Push back when warranted.
- If something is unclear, stop. Name what's confusing. Ask.

### 2. Simplicity First

Minimum code that solves the problem. Nothing speculative.

- No features beyond what was asked.
- No abstractions for single-use code.
- No "flexibility" or "configurability" that wasn't requested.
- No error handling for impossible scenarios.
- If 200 lines could be 50, rewrite.

Test: "Would a senior engineer say this is overcomplicated?" If yes, simplify.

### 3. Surgical Changes

Touch only what you must. Clean up only your own mess.

- Don't "improve" adjacent code, comments, or formatting.
- Don't refactor things that aren't broken.
- Match existing style, even if you'd do it differently.
- If you notice unrelated dead code, mention it — don't delete it.
- When your changes orphan imports/vars/functions, remove them. Don't remove pre-existing dead code unless asked.

Test: every changed line traces directly to the user's request.

### 4. Goal-Driven Execution

Define success criteria. Loop until verified.

- "Add validation" → "Write tests for invalid inputs, then make them pass"
- "Fix the bug" → "Write a test that reproduces it, then make it pass"
- "Refactor X" → "Ensure tests pass before and after"

Strong success criteria let you loop independently. Weak criteria ("make it work") require constant clarification.

## Edit Discipline — Renames & Replace-All

`Edit replace_all: true` is naive whole-file string replace — no AST, no scope, no token boundaries. Running on common identifiers silently corrupts unrelated code (`state` → `swipe` rewrites `SwipeState` to `SwipeSwipe`, import paths, comments, CSS selectors). The trap is invisible until the next type-check.

### Rule (preference order)

1. **LSP rename** — symbol-aware, scope-respecting. Best for typed languages (TS, Rust, Go, Java, Python with pyright, C#).
2. **Per-occurrence Edit with unique surrounding context** — when LSP unavailable. Find each call site via Grep, Edit each with enough surrounding text that `old_string` is unique to that call.
3. **`sed` or scripted bulk replace** — only when term is **8+ characters and unique to the domain** (`Conversation`, `MerchandiseInventory`). Always case-preserving pair: `s/OldName/NewName/g; s/oldName/newName/g; s/OLD_NAME/NEW_NAME/g`. Run build/test cycle immediately.
4. **`Edit replace_all: true`** — only on unique long string literals (URLs, full sentences, hash IDs). Never on identifiers shorter than 8 characters. Never on common English words.

### Pre-flight checklist (any bulk replace)

1. Grep the exact term. Look at count + sample matches.
2. If hits >5 OR length <8 OR common English word → switch to options 1–3.
3. Scan sample matches for false positives (substring inside other identifiers, inside string literals, inside CSS class names that overlap with HTML tags, inside comments).
4. If any doubt remains → per-occurrence Edit. Token cost of caution is far less than cost of debugging silent corruption.

### Banned terms for `replace_all` (always per-occurrence review)

`state`, `name`, `data`, `value`, `item`, `key`, `id`, `type`, `props`, `node`, `text`, `link`, `error`, `result`, `body`, `head`, `main`, `time`, `path`, `file`, `index`, `count`, `child`, `style`, `class`, `tag`, `event`, `target`, `source`, `from`, `to`, `next`, `prev`, `init`, `done`.

### When a `replace_all` slips through

1. `git diff` first — see damage scope.
2. If uncommitted, `git checkout` the file and redo with the right tool.
3. If committed, fix as a NEW commit, not amend (preserves mistake in history).
4. Run type-check / lint / test — usually points straight at remaining corruption.

### Build/test as safety net

Always run after bulk operations. TS: `pnpm check && pnpm test`. Rust: `cargo check && cargo test`. Python: `pyright && pytest`. Go: `go vet && go test ./...`.

## Solo Dev Assumptions

This project is operated by a single developer across multiple Claude Code sessions.

- **No PR self-review** — commit directly to working branch
- **Simple branching** — `main` + feature branches, no rebasing
- **No force push** — every commit is sacred, no rewriting history
- **Session isolation** — each Claude session commits only its own changes
- **No merge conflicts expected** — if one occurs, stop and ask the user

## Project Structure

\```
{detected tree — top-level only, brief annotations}
\```

## Tech Stack

- **Runtime**: {detected, e.g., Node.js 20+, ESM}
- **Framework**: {detected, e.g., Next.js 14}
{...other detected layers, one bullet each}

> Full techstack analysis pending — see `docs/superpowers/plans/bootstrap.md` task list.

## Commands

\```bash
{detected from scripts/Makefile/Cargo — only what exists right now}
\```

## Git Notes

- **Only commit current session's changes** — if unrelated uncommitted changes exist from prior work, leave them alone
- **Atomic commits** — one logical change per commit
- **Conventional commits** — `feat:`, `fix:`, `refactor:`, `docs:`, `test:`, `chore:`

## Planning

- `docs/overview.md` — Product context, data flow, module index (once written)
- `docs/techstack.md` — Tech choices and architecture rules (once written)
{- `docs/specs/` — **Persistent feature specs** — source of truth per feature ([index](docs/specs/index.md))}
{- `docs/building.md` — Build/distribution instructions}
{- `docs/help/` — User-facing guides}
{- `docs/backlog.md` — **Deferred items** — `BUG-###` / `DEBT-###` / `GAP-###` queue, deleted on resolve}
- `docs/superpowers/specs/` — Design specs from brainstorming (temporal — deleted after merge)
- `docs/superpowers/plans/` — Implementation plans (temporal — deleted after merge)

{plus any existing docs references}

> **Two kinds of specs:** `docs/specs/` = permanent source of truth (updated as features evolve). `docs/superpowers/specs/` = temporal work orders (deleted after merge).
```

### Adaptation Notes

- Only include sections relevant to the detected stack
- If CLAUDE.md already exists with good content (commands, structure, etc.), preserve it and layer workflow on top
- Shell notes, design system refs, protocol refs — only if the project has them
- The `> pending` markers tell future sessions that deep analysis hasn't happened yet

### 3c: Write Bootstrap Plan

Write to `docs/superpowers/plans/bootstrap.md`:

````markdown
# Pipeline Bootstrap Plan

> **For agentic workers:** Use `/todo` to see current progress. Each task is independent and session-sized.

**Goal:** Complete the superpowers pipeline setup for {project name}

**Context:** Pipeline scaffolded on {date}. Skeleton CLAUDE.md is live with workflow rules. These tasks complete the deep analysis and finalize the setup.

---

### Task 1: Techstack Analysis

Deep-dive into the project's technical stack and write `docs/techstack.md`.

**Input:** Read manifest files, config files, sample 3-5 source files, test files.

- [ ] **Read manifest files fully** — `package.json` (all fields), `tsconfig.json`, linter config, build config, CI config
- [ ] **Sample source files** — read main entry point, one typical module, one test file, one utility. Note: import style, error handling, naming conventions, class vs function, type usage
- [ ] **Identify architecture patterns** — data flow direction, module boundaries, file organization, dependency philosophy
- [ ] **Draft techstack.md** — stack table, dependency philosophy, architecture rules, coding patterns, build & distribution, rejected alternatives (if discoverable)
- [ ] **Present to user for review**
- [ ] **Write `docs/techstack.md`**
- [ ] **Commit**: `docs: add techstack analysis`

### Task 2: Product Overview

Distill the product context and write `docs/overview.md`.

**Input:** README, existing docs, code structure, git history, Q&A answers from bootstrap.

- [ ] **Read README and existing docs fully**
- [ ] **Trace data flow** — find entry points, follow the path through the code, identify inputs/transforms/outputs
- [ ] **Build module index** — scan all significant files/directories, one-line description each
- [ ] **Identify key boundaries** — API contracts, internal interfaces, external dependencies
- [ ] **Draft overview.md** — problem, solution, user, user flow, data flow, module index, key boundaries
- [ ] **Present to user for review**
- [ ] **Write `docs/overview.md`**
- [ ] **Commit**: `docs: add product overview`

### Task 3: Enhance CLAUDE.md

Replace stub sections with full content derived from techstack and overview analysis.

**Depends on:** Task 1 and Task 2 (needs their output)

- [ ] **Write Coding Standards section** — derived from techstack.md patterns (import style, error handling, naming, etc.)
- [ ] **Update Tech Stack section** — remove "pending" marker, add reference to `docs/techstack.md`
- [ ] **Update Planning section** — add references to `docs/overview.md` and `docs/techstack.md`. If `docs/specs/` exists, include the spec index reference with a note like: `docs/specs/` — **Feature specs** — source of truth per feature ([index](docs/specs/index.md))
- [ ] **Verify doc sync wording** — the CLAUDE.md should have doc sync as a named pipeline step in every route (between user review and commit), with temporal cleanup paragraph in the Doc Sync section. This is non-negotiable pipeline behavior.
- [ ] **Add any project-specific sections** — ownership boundaries, protocol references, design system refs — only if the project has them
- [ ] **Present changes to user**
- [ ] **Update CLAUDE.md**
- [ ] **Commit**: `docs: finalize CLAUDE.md with full analysis`

### Task 4: Skill / MCP / Hook Resolution

Auto-curate Claude Code tooling matched to detected stack. Harness-internal — user sees one batch, replies. No manual search, no plugin install gate.

**Depends on:** Task 1 (needs detected stack)

**Process — automated:**

1. **Take detected stack from Task 1** — runtime, framework, key tools, project size, monorepo state.
2. **Curate recommendations** across:
   - Anthropic plugin marketplace (`claude-plugins-official`)
   - [awesome-skills.com](https://awesome-skills.com) / [skills.sh](https://skills.sh)
   - [tonsofskills.com](https://tonsofskills.com) / `ccpi` CLI
   - [mcpmarket.com](https://mcpmarket.com) (MCP servers)
   - Fast-path: if `claude-code-setup` plugin installed, invoke `/setup` and merge its picks
3. **Filter to stack-matched only** — drop generic / spray suggestions.
4. **Trust signal lookup per pick** — for any plugin NOT from `claude-plugins-official`, fetch (via WebFetch or `gh api`):
   - Repo URL + GitHub stars
   - Last-commit recency (e.g. "3d ago", "14mo ago")
   - License (or "no license" — flag as ⚠)
   - Permissions exercised (read-only? shell? network? auto-exec hook?)

   Hooks are elevated risk: they auto-exec on every tool call (PreToolUse / PostToolUse / UserPromptSubmit). Always tag hooks with `⚠ HOOK = auto-executes. Audit source before accept.`

5. **Present batch to user with full trust signal per pick:**
   ```
   Recommendations for {project} ({stack}):

     [SKILL]    {name}@{source}
                ★ {stars} · last commit {recency} · {license}
                Permissions: {read-only / shell / network / etc.}
                Why: {matched signal, one-line value}

     [HOOK]     {name}@{source}
                ★ {stars} · last commit {recency} · {license}
                Permissions: ⚠ {what triggers + what it runs}
                Why: {matched signal}
                ⚠ HOOK = auto-executes. Audit source before accept.

     [MCP]      {name}@{source}
                ★ {stars} · last commit {recency} · {license}
                Permissions: {network / shell / file-system / etc.}
                Why: {matched signal}

     [SUBAGENT] {name}@{source}
                ★ {stars} · last commit {recency} · {license}
                Permissions: {what tools the subagent inherits}
                Why: {matched signal}

   Accept all / reject specific / discuss thoughts?
   ```

   Picks from `claude-plugins-official` can drop the trust block (Anthropic-vetted) — keep just `Why:`.
5. **Apply approved — write `.claude/settings.json` always.** This is the source of truth: project-scope intent, committed, travels with repo, cloud-friendly. Device install (`claude plugin install`) is optional convenience layered on top — not a substitute.
   - Add each pick to `enabledPlugins`.
   - For any plugin NOT from `claude-plugins-official`, add its source to `extraKnownMarketplaces` so cloud sessions / fresh machines can resolve.
   - Example shape:
     ```json
     {
       "enabledPlugins": {
         "superpowers@claude-plugins-official": true,
         "caveman@caveman": true
       },
       "extraKnownMarketplaces": {
         "caveman": { "source": { "source": "github", "repo": "JuliusBrussee/caveman" } }
       }
     }
     ```
   - One-line transparency to user: "Pinning plugins per-project in `.claude/settings.json` so cloud Claude and fresh machines reproduce this toolset."
6. **Commit if anything added.**

**Why settings.json is non-negotiable:** `enabledPlugins` declares intent. Resolution happens at session start — Claude reads settings.json, finds device-installed plugins or auto-resolves via marketplaces. Without settings.json, project intent is lost (cloud and fresh machines can't reproduce). Device install alone doesn't travel.

**Why device install is optional:** layering `claude plugin install <slug>` on top is fine — speeds local load, no conflict (Claude dedupes). Skill does NOT shell out to it; user's call.

### Task 5: Seed Feature Specs *(only if `docs/specs/` was scaffolded)*

Write initial persistent specs for the project's existing features.

**Depends on:** Task 2 (needs product overview to identify features)

- [ ] **Identify 3-5 major features** from overview.md module index and code structure
- [ ] **For each feature, write a spec** — product-level: intent, user flow, cross-module interactions, design decisions. Code-light — no API tables or implementation details.
- [ ] **Update `docs/specs/index.md`** — add each spec to the table with a one-liner describing what it covers
- [ ] **Present to user for review**
- [ ] **Commit**: `docs: seed persistent feature specs`

### Task 5b: Seed Backlog *(only if `docs/backlog.md` was scaffolded)*

Walk the project once and seed any obvious deferred items already visible in code or recent history.

**Depends on:** Task 1 and Task 2 (needs stack + overview to spot gaps)

- [ ] **Scan for `TODO` / `FIXME` / `XXX` / `HACK` markers** in source — each is a candidate `DEBT-###` or `BUG-###`
- [ ] **Review test output** — failing or skipped tests with no recent fix attempt → `BUG-###` or `DEBT-###`
- [ ] **Note design gaps surfaced during Q&A or overview drafting** — areas where behavior was hand-waved → `GAP-###`
- [ ] **Cap at ~5 items** — backlog is a queue, not a dump. If more candidates exist, list them but seed only the highest-signal ones
- [ ] **Present to user for review** — user prunes/approves
- [ ] **Commit**: `docs: seed backlog`

If no obvious items exist, leave the file with just its header — that's fine. The tracker grows organically as reviews surface things.

### Task 6: Cleanup

- [ ] **Delete this file** (`docs/superpowers/plans/bootstrap.md`) — bootstrap is complete
- [ ] **Verify `/todo` shows no active work** (unless the user has started real project work)
- [ ] **Commit**: `chore: complete pipeline bootstrap`
````

Adapt the plan to what the project actually needs:
- If `docs/techstack.md` already exists and is good, skip Task 1 or reduce it to a review
- If `docs/overview.md` already exists, same
- If CLAUDE.md is already comprehensive, Task 3 becomes a light touch-up
- Add tasks for any project-specific needs discovered during Q&A

### 3c-report: Sync Report (existing repos only)

On repos that already had the pipeline, present a summary before committing:

```
| Artifact                    | Status      | Action             |
|-----------------------------|-------------|--------------------|
| CLAUDE.md: Routes           | ⚠ drifted   | updated (approved)  |
| CLAUDE.md: Doc Sync         | ✓ current   | —                  |
| CLAUDE.md: Solo Dev         | ✓ current   | —                  |
| docs/superpowers/specs/     | ✓ exists    | —                  |
| docs/superpowers/plans/     | ✓ exists    | —                  |
| Temporal artifacts          | ⚠ stale     | flagged for cleanup |
| Served skills               | ✓ fresh     | —                  |
```

If everything is current, report that and skip the commit.

### 3d: Commit the Scaffold

Use `/commit` to stage and commit:
- `CLAUDE.md` (new or modified)
- `docs/superpowers/specs/.gitkeep`
- `docs/superpowers/plans/.gitkeep`
- `docs/superpowers/plans/bootstrap.md`
- `docs/specs/index.md` (if scaffolded)
- `docs/specs/.gitkeep` (if scaffolded)
- `docs/backlog.md` (if scaffolded)
- Any other adaptive doc files/folders created

Commit message: `chore: scaffold superpowers pipeline`

---

## Phase 4: Handoff

After committing (or reporting no changes needed), present results based on repo state:

**Fresh repos (just scaffolded):**

> **Pipeline is live.** Skeleton CLAUDE.md is driving workflow. Tasks remain to complete the bootstrap:
>
> 1. Techstack analysis → `docs/techstack.md`
> 2. Product overview → `docs/overview.md`
> 3. Enhance CLAUDE.md with full standards
> 4. Skill resolution
> {5. Seed feature specs → `docs/specs/` (if scaffolded)}
> {5b. Seed backlog → `docs/backlog.md` (if scaffolded)}
>
> Run `/todo` in any session to see what's next. Each task is session-sized — you can knock them out one at a time or batch them.
>
> Want to start Task 1 now, or pick this up later?

**Existing repos (sync pass):**

> **Pipeline synced.** {N} items updated, {M} already current.
> {If temporal artifacts flagged: "Flagged {K} stale temporal files for cleanup."}
> {If served skills stale: "Skill/MCP recommendations are >90 days old — consider re-running `/super-bootstrap` to refresh."}

If the user wants to continue, proceed with the next pending task from the bootstrap plan (if any remain).

## Principles

- **Scaffold first, analyze later** — get the pipeline running before doing deep work
- **The pipeline bootstraps itself** — deep analysis is tracked as pipeline tasks, provable by `/todo`
- **Session-sized tasks** — each task fits in one Claude session without blowing context
- **Pre-distillation Q&A** — confirm understanding before writing anything permanent
- **Detect, don't assume** — every section grounded in what was found in the repo
- **Solo dev first** — no team workflows, no complex branching
- **Docs travel with code** — every commit checks for stale docs. Implementation without doc sync is incomplete. This is the pipeline's real power.
- **Fixed macro, adaptive micro** — `overview.md`, `techstack.md`, `superpowers/` are always scaffolded. `specs/`, `building.md`, `help/`, `backlog.md` are scaffolded only when the project warrants them.
- **Two kinds of specs** — temporal (superpowers) = work orders, deleted after merge. Persistent (project) = source of truth, evolve with the product. Never confuse them.
- **Clear doc ownership** — `techstack.md` owns tech, `overview.md` owns product, `CLAUDE.md` owns workflow, `specs/` owns feature behavior. No duplication across docs.
- **One pipeline, adaptive** — fresh repos get scaffolded, existing repos get synced. Same phases, same walk-through, different actions per artifact state.
- **User approves everything** — present drafts, get approval, then write
