---
name: super-bootstrap
description: "Bootstrap or sync the superpowers development pipeline in any repo. Walks all phases — creates what's missing, syncs what's drifted, skips what's current. Scaffolds fixed macro docs (overview, techstack, superpowers/) and adaptive persistent docs (specs/, backlog) based on project needs. Bakes in doc-sync discipline — docs travel with code. Solo dev workflow."
tags: [bootstrap, scaffold, setup, meta, docs]
---

# Super Bootstrap — Superpowers Pipeline for Any Repo

Set up (or sync) the superpowers-driven development pipeline in a project. Installs harness — workflow rules, doc-sync gate, skeleton docs, curated skill/MCP/hook picks — in one scaffold session. The doc-sync gate at every later commit grows the skeleton docs over time, so there's no deferred deep-scan stage.

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

`overview.md` and `techstack.md` are seeded as **skeletons** at scaffold time — Runtime / Framework / Build & Dist / Problem / User / State sections carry detected facts and Q&A answers. Grown sections (Architecture Rules / Coding Patterns / Rejected Alternatives / Module Index / Data Flow / Key Boundaries) start empty and fill incrementally via the doc-sync gate as features land. No deep one-shot pump-prime.

### Adaptive Persistent Docs (project-specific, discovered during Q&A)

Some projects need more structure. Examples:

- `docs/specs/` — persistent feature specs, one `.md` per feature. Each spec opens with `# {Feature Name}` + a one-paragraph intro, so `ls docs/specs/` and `head -n3 docs/specs/*.md` ARE the catalog (no separate index file). For multi-feature products.
- `docs/backlog.md` — deferred items tracker (BUG / DEBT / GAP). For active or maintenance projects with shipping code.

What goes here is discovered during Q&A (Phase 2). A 3-file CLI? No specs folder needed. A multi-module product? Scaffold `docs/specs/` and seed initial spec files.

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

Super-bootstrap installs **harness**, not **product**. Workflow rules, doc-sync gate, skill picks, skeleton docs — all land in one scaffold session. Doc-sync at every commit grows the skeleton docs over time as code lands. No deferred deep-scan tasks; the pipeline's own continuous mechanism IS the growth path.

```
/super-bootstrap session:
  Quick scan + greenfield gate → Q&A alignment → scaffold (folders, CLAUDE.md,
  skeleton techstack.md, skeleton overview.md, bootstrap-plan) →
  curate skill/MCP/hook against live sources → sync report + commit

  Pipeline is now LIVE. Skeleton docs carry detected facts. Picks pinned in
  .claude/settings.json. Any adaptive seeding (specs / backlog) queued in
  bootstrap-plan for later /todo sessions.

Per-commit (forever after):
  Doc-sync gate fires → if diff touches behavior covered by a doc, propose
  updating that doc → user approves → doc + code commit together.

/super-bootstrap re-run (any time):
  Drift-check pipeline-owned sections → refresh skill/MCP/hook picks against
  live sources → commit if anything changed. Adaptive seeding tasks dropped
  from regenerated bootstrap-plan if their docs already exist.
```

ICP: projects that already have code. True greenfield (empty repo, product still in ideation) is **out of scope** — Phase 1 has a friendly gate.

---

## Phase 1: Quick Scan (lightweight, parallel reads)

Gather just enough to scaffold. Do NOT deep-analyze yet.

### Sampling Discipline (applies to all source-file reads)

Throughout this skill — Phase 1 detection, anywhere Claude reads source files — **paraphrase structure into committed docs; never paste raw file contents.** Skip files whose names suggest secrets (e.g. `.env*`, `*.key`, `*.pem`, `id_*`, `*credential*`, `*secret*`, `.npmrc`, `.netrc`, `*.p12` / `*.pfx`, `*.keystore`, `kubeconfig` — illustrative, judge by name).

When skipping, surface to user: `⊘ skipped <path> (likely secret)`.

Reason: reading alone isn't the breach — Claude's context isn't shared. The breach is **quoting raw content into auto-committed docs** (`techstack.md`, `overview.md`): a gitignored secret becomes permanent in git history. Defense lives in the write step. The illustrative list seeds pattern recognition for the skip step; new secret-bearing patterns are judged by name, not table lookup.

### Manifest Detection

Detect language/runtime by manifest files at repo root (e.g. `package.json`, `tsconfig.json`, `pyproject.toml` / `requirements.txt`, `Cargo.toml`, `go.mod`, `Gemfile`, `pom.xml` / `build.gradle`, `composer.json`, `pubspec.yaml`, `CMakeLists.txt` / `Makefile`, `*.csproj` / `*.sln` — illustrative, not exhaustive). Don't read fully — skim each for runtime/version, top-level deps, scripts/build commands. Cover unlisted stacks (Bun, Deno, Zig, Elixir, Gleam, etc.) by analogy from the manifest's contents.

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

### Greenfield Gate

After Phase 1 detection: if **no manifests + no source files (any extension) + README missing or under 3 substantive lines**, abort with:

> Super-bootstrap installs **harness**, not **product**. Detected an empty repo: no manifests, no source files, no meaningful README.
>
> Add at least one of: a manifest (`package.json` / `pyproject.toml` / `Cargo.toml` / etc.), an entry-point source file, or a brief README describing the product. Then re-run.
>
> For greenfield product ideation, this isn't the right tool — try a product-ideation skill or just write a short README first.

User may explicitly override ("yes proceed anyway") → continue with stub-only scaffold (most skeleton sections will sit empty until code starts landing). Default = abort.

---

## Phase 2: Q&A Alignment

Before writing anything, confirm your understanding with the user. Ask these **one at a time**, serial:

### Required Questions

1. **"What does this project do?"** — Even if README exists, ask. The user's answer reveals what they think matters vs what the docs say. Compare with README if it exists; flag discrepancies.

2. **"Who uses it?"** — End users? Developers? Internal tool? Library consumers? This shapes how `overview.md` will be written later.

3. **"What's the current state?"** — Greenfield? Active development? Maintenance mode? Mid-rewrite? This determines how aggressive the bootstrap should be.

4. **"What external tools are in your workflow?"** — issue tracker / docs platform / comms (Notion / Linear / Jira / Slack / GitHub-only / etc.). Drives product-level MCP picks in Phase 3c. Accept "none" or "GitHub only" — both are signal.

### Conditional Questions

5. **If monorepo detected:** "What are the packages/apps and how do they relate?"

6. **If existing CLAUDE.md:** "Anything in the current CLAUDE.md that's wrong or outdated? Anything you want to keep as-is?"

7. **If existing docs/:** "Are these docs current, or should I treat them as potentially stale?"

8. **If multi-feature product (not a tiny CLI or single-purpose lib):** "Do you want persistent feature specs? These are living docs that describe what each feature does and why — updated as the product evolves. One `.md` per feature in `docs/specs/`, each starting with `# {Feature Name}` + a one-paragraph intro. Folder + filenames are the catalog — no separate index file. Worth it for your project, or overkill?"

9. **If active or maintenance project (not greenfield):** "Do you want `docs/backlog.md`? Single tracker for deferred items — `BUG-###` (broken, has fix), `DEBT-###` (working but rotting), `GAP-###` (design gap, needs brainstorm). Solo-dev queue, scanned at commit by doc sync. Default yes for shipping code, skip for greenfield."

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
    {specs/                  ← if confirmed (one .md per feature)}
    {backlog.md              ← if confirmed}

Sound right?
```

Wait for confirmation before proceeding. If anything is off, correct and re-confirm.

---

## Phase 3: Scaffold / Sync

With alignment confirmed, walk each pipeline artifact in order: folders → pipeline docs → curate picks → sync report + commit. Same flow on fresh and re-run repos — fresh just sees "all new" at every step.

**Per-artifact rule** (applied uniformly in 3a / 3b / 3c):
- Missing → write from template / curate fresh
- Exists, matches template → skip (`✓ current`)
- Exists, drifted from template → show diff, get approval per change, then write
- Project-owned content → never touch, even on drift

**Pipeline-owned** (subject to drift check):
- CLAUDE.md sections: Development Workflow, Doc Sync, Context Hygiene, Coding Principles, Edit Discipline, Solo Dev Assumptions, Git Notes, Planning
- `docs/techstack.md` skeleton sections: Runtime, Framework, Key Dependencies, Build & Distribution
- `docs/overview.md` skeleton sections: Problem, User, Current State
- `docs/superpowers/specs/`, `docs/superpowers/plans/`, `docs/superpowers/plans/bootstrap.md`
- `.claude/settings.json` plugin pins (`enabledPlugins`, `extraKnownMarketplaces`)

**Project-owned** (never touched):
- CLAUDE.md: Project Structure, Tech Stack summary, Commands, Coding Standards, any custom sections
- `docs/techstack.md` grown sections: Architecture Rules, Coding Patterns, Rejected Alternatives
- `docs/overview.md` grown sections: Module Index, Data Flow, Key Boundaries
- Other settings in `.claude/settings.json` outside the plugin-pin keys

### 3a: Folders

Folders don't drift — only two states: missing or present.

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
  specs/         ← persistent feature specs, one .md per feature (seeded by Task 1 of bootstrap-plan)
  backlog.md     ← deferred items tracker (BUG / DEBT / GAP)
```

For each: create if missing, skip if present. Add `.gitkeep` in empty folders. If `docs/` already exists, nest alongside. Report status per directory.

`docs/specs/` is scaffolded as an empty folder with `.gitkeep`. There is no index file — the folder + filename convention IS the catalog. Spec files are seeded by Task 1 of the bootstrap plan, each opening with `# {Feature Name}` and a one-paragraph intro.

If `docs/backlog.md` is scaffolded, copy `assets/backlog.md` to `docs/backlog.md` (no substitutions).

### 3b: Pipeline docs

Walk each pipeline doc and apply the per-artifact rule. Sources:

| Asset | Destination |
|---|---|
| `assets/claude-md-skeleton.md` | `CLAUDE.md` (project root) |
| `assets/techstack-skeleton.md` | `docs/techstack.md` |
| `assets/overview-skeleton.md` | `docs/overview.md` |
| `assets/bootstrap-plan.md` | `docs/superpowers/plans/bootstrap.md` |

**Per-doc handling:**

- **Missing** → fill placeholders, write.
- **Exists, drifted in pipeline-owned section** → diff that section vs template, present to user, get approval per section, write approved.
- **Exists, current** → skip, mark `✓ current`.
- **Project-owned content** → never touched, even on drift.

```
{file path} sync — drift detected:

  [{Section Name}] section drifted from current template:
  ───────────────────────────────────────────────
  - {removed line}
  + {added line}
  ───────────────────────────────────────────────

  Update? (y / n / show full diff)
```

Drift approval protects against (a) legit template updates the user wants to review and (b) bad-actor template injection on a future re-run — you see what's about to change before it's overwritten.

**Special case — `bootstrap.md`** carries user state (checkbox progress from prior session). Don't auto-merge. Prompt: **Keep existing** (default) / **Reset from template** / **Merge** (rare, task-by-task).

**Placeholders:**
- `{Project Name}` — repo name
- `{date}` — today's date
- `{detected tree — top-level only}` — Phase 1 root `ls` with brief annotations
- Manifest detection facts (Runtime / Framework / Key Dependencies / Build & Distribution) → fill into both CLAUDE.md Tech Stack summary AND `techstack.md` skeleton sections
- Q&A answers (Problem / User / Current State) → fill into `overview.md` skeleton sections
- Bracketed conditional lines `{- docs/specs/ — ...}` — keep only if the corresponding adaptive doc was confirmed in Phase 2 Q&A; drop the whole line otherwise

**Bootstrap-plan task adaptation:**

The slim plan is `Task 1: Seed feature specs` / `Task 2: Seed backlog` / `Task 3: Cleanup`. Adapt at write time:

- `docs/specs/` NOT scaffolded → drop Task 1
- `docs/backlog.md` NOT scaffolded → drop Task 2
- Re-run with `docs/specs/` already populated → drop Task 1
- Re-run with `docs/backlog.md` already populated → drop Task 2
- Add tasks for any project-specific needs surfaced during Q&A
- Task 3 (Cleanup) always retained

If both Task 1 and Task 2 drop, the plan becomes Task 3 (cleanup) only — that's fine, signals bootstrap is essentially complete.

### 3c: Curate skill / MCP / hook

Auto-curate Claude Code tooling matched to detected stack AND product context. **Runs every `/super-bootstrap`** — refresh on every run keeps picks fresh against upstream source updates (new skills published, deprecated removals, license changes). Harness-internal: user sees one batch, replies. No manual search, no plugin install gate.

**Inputs (no deferred deep work needed):**
- Phase 1 quick-scan: runtime, framework, key tools, monorepo state → drives **stack-matched picks** (e.g. `react-expert` for React, `postgres-pro` for Postgres)
- Phase 2 Q&A: user type, current state, **external tools** (Notion / Linear / Jira / Slack / GitHub-only / etc.) → drives **product/workflow-level MCP picks** (e.g. Notion MCP for docs-heavy, Linear MCP for active dev, Slack MCP for team comm, GitHub MCP for PR-heavy workflow)

**Process:**

1. **Curate recommendations** across:
   - Anthropic plugin marketplace (`claude-plugins-official`)
   - [awesome-skills.com](https://awesome-skills.com) / [skills.sh](https://skills.sh)
   - [tonsofskills.com](https://tonsofskills.com) / `ccpi` CLI
   - [mcpmarket.com](https://mcpmarket.com) (MCP servers)
   - Fast-path: if `claude-code-setup` plugin installed, invoke `/setup` and merge its picks

2. **Filter to matched picks only** — drop generic / spray suggestions. Match against stack signals AND product/workflow signals. A Notion MCP isn't "off-stack" if Q&A surfaced docs-heavy workflow.

3. **Trust signal lookup per pick** — for any plugin NOT from `claude-plugins-official`, fetch (via WebFetch or `gh api`):
   - Repo URL + GitHub stars
   - Last-commit recency (e.g. "3d ago", "14mo ago")
   - License (or "no license" — flag as ⚠)
   - Permissions exercised (read-only? shell? network? auto-exec hook?)

   Hooks are elevated risk: auto-exec on every tool call (PreToolUse / PostToolUse / UserPromptSubmit). Always tag hooks: `⚠ HOOK = auto-executes. Audit source before accept.`

4. **Re-run delta** — if `.claude/settings.json` already has pinned picks, diff the new curation against the pinned set:
   - Pinned + still recommended → keep silently, no surface
   - New pick recommended (upstream added it; or stack signal changed) → propose as **add**
   - Pinned but no longer recommended (deprecated upstream; license changed; stack changed) → propose as **drop** with reason
   - License / last-commit recency moved on a pinned pick → re-show that pick's trust block

5. **Present batch with full trust signal per new / changed pick:**
   ```
   Skill / MCP / hook curation for {project} ({stack}):

     [SKILL]    {name}@{source}                 [+ add | ✓ keep | − drop]
                ★ {stars} · last commit {recency} · {license}
                Permissions: {read-only / shell / network / etc.}
                Why: {matched signal, one-line value}

     [HOOK]     {name}@{source}                 [+ add]
                ★ {stars} · last commit {recency} · {license}
                Permissions: ⚠ {what triggers + what it runs}
                Why: {matched signal}
                ⚠ HOOK = auto-executes. Audit source before accept.

     [MCP]      {name}@{source}                 [+ add]
                ★ {stars} · last commit {recency} · {license}
                Permissions: {network / shell / file-system / etc.}
                Why: {matched signal}

   Accept all / reject specific / discuss thoughts?
   ```

   Picks from `claude-plugins-official` can drop the trust block (Anthropic-vetted) — keep just `Why:`.

6. **Apply approved — write `.claude/settings.json`.** Source of truth: project-scope intent, committed, travels with repo, cloud-friendly. Device install (`claude plugin install`) is optional convenience layered on top.
   - Add accepted picks to `enabledPlugins`. Drop rejected picks.
   - For any plugin NOT from `claude-plugins-official`, ensure its source is in `extraKnownMarketplaces` so cloud sessions / fresh machines can resolve.
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
   - One-line transparency: "Pinning plugins per-project in `.claude/settings.json` so cloud Claude and fresh machines reproduce this toolset."

**Why settings.json is non-negotiable:** `enabledPlugins` declares intent. Resolution happens at session start — Claude reads settings.json, finds device-installed plugins or auto-resolves via marketplaces. Without settings.json, project intent is lost (cloud and fresh machines can't reproduce). Device install alone doesn't travel.

### 3d: Sync report + commit

**Sync report** — always shown before commit. Fresh repos see "all new"; re-run repos see drift fixes, picks delta, and current items.

```
| Artifact                            | Status      | Action              |
|-------------------------------------|-------------|---------------------|
| CLAUDE.md: Workflow                 | ⚠ drifted   | updated (approved)  |
| CLAUDE.md: Doc Sync                 | ✓ current   | —                   |
| CLAUDE.md: Solo Dev                 | ✓ current   | —                   |
| docs/techstack.md: Runtime          | ⚠ drifted   | updated (approved)  |
| docs/techstack.md: Framework        | ✓ current   | —                   |
| docs/overview.md: Problem           | ✓ current   | —                   |
| docs/superpowers/specs/             | ✓ exists    | —                   |
| docs/superpowers/plans/             | ✓ exists    | —                   |
| docs/superpowers/plans/bootstrap.md | ⚠ exists    | kept (user state)   |
| .claude/settings.json: picks        | ⚠ delta     | +2 add, −1 drop     |
```

If every row is `✓ current` and nothing changed on disk, report and skip the commit.

Otherwise use `/commit` to stage:
- `CLAUDE.md` (new or modified)
- `docs/techstack.md` (new or skeleton-section drift)
- `docs/overview.md` (new or skeleton-section drift)
- `.claude/settings.json` (new or picks delta)
- `docs/superpowers/specs/.gitkeep`
- `docs/superpowers/plans/.gitkeep`
- `docs/superpowers/plans/bootstrap.md` (if newly written or regenerated)
- `docs/specs/.gitkeep` (if scaffolded)
- `docs/backlog.md` (if scaffolded)
- Any other adaptive files / folders created

Commit message: `chore: scaffold superpowers pipeline` on fresh repos, `chore: sync superpowers pipeline` when only drift fixes / picks delta shipped.

---

## Phase 4: Handoff

After committing (or reporting no changes needed), present results based on repo state:

**First-run (just scaffolded):**

> **Pipeline is live.** CLAUDE.md drives workflow. Skeleton `docs/techstack.md` and `docs/overview.md` carry detected facts — grown sections fill via doc-sync as features land. Skill / MCP / hook picks pinned in `.claude/settings.json`.
>
> {If bootstrap.md has Task 1 / Task 2 active: "Optional adaptive seeding queued in `docs/superpowers/plans/bootstrap.md` (specs / backlog). Next session: `/clear`, then `/todo`."}
> {If bootstrap.md is cleanup-only: "Bootstrap essentially complete — `/todo` will show the cleanup task."}

**Re-run / sync pass:**

> **Pipeline synced.** {N items updated, M already current.}{If picks delta: " Picks: +K added, −L dropped against live sources."}

## Principles

- **Harness, not product** — bootstrap installs workflow + skeleton docs + curated picks. Greenfield product ideation (empty repo, no code) is out of scope. Phase 1 has a friendly gate.
- **Skeleton at scaffold, grown via sync** — detected facts and Q&A answers seeded immediately into `techstack.md` / `overview.md`. Architecture Rules, Coding Patterns, Module Index, Data Flow, Key Boundaries start empty and fill incrementally per-commit. Doc-sync IS the growth mechanism — no deferred deep-scan tasks.
- **Refresh on every run** — picks curated against live sources every `/super-bootstrap`. Upstream marketplace changes (new picks, deprecations, license shifts) surface as a delta against `.claude/settings.json`.
- **Detect, then confirm** — Phase 1 grounds seeded facts in repo evidence; Phase 2 Q&A confirms; user approves drift / picks / drafts before any write.
- **Docs travel with code** — doc-sync gate on every commit. Implementation without doc-sync is incomplete. The pipeline's real power.
- **Fixed macro, adaptive micro** — `overview.md` / `techstack.md` / `superpowers/` always scaffolded. `specs/` / `backlog.md` only when the project warrants them.
- **Two kinds of specs** — temporal (`docs/superpowers/specs/`) = work orders, deleted after merge. Persistent (`docs/specs/`) = source of truth, evolves with product. Never confuse.
- **Clear doc ownership** — `techstack.md` owns tech, `overview.md` owns product, `CLAUDE.md` owns workflow, `docs/specs/` owns feature behavior. No duplication.
- **One pipeline, adaptive** — same phases on fresh and re-run; actions differ per artifact state. Solo dev first.
