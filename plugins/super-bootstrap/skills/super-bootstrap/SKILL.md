---
name: super-bootstrap
description: "Bootstrap or sync the superpowers development pipeline in any repo. Walks all phases — creates what's missing, syncs what's drifted, skips what's current. Scaffolds fixed macro docs (overview, techstack, superpowers/) and adaptive persistent docs (specs/, backlog) based on project needs. Bakes in doc-sync discipline — docs travel with code. Solo dev workflow."
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

8. **If active or maintenance project (not greenfield):** "Do you want `docs/backlog.md`? Single tracker for deferred items — `BUG-###` (broken, has fix), `DEBT-###` (working but rotting), `GAP-###` (design gap, needs brainstorm). Solo-dev queue, scanned at commit by doc sync. Default yes for shipping code, skip for greenfield."

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
  backlog.md     ← deferred items tracker (BUG / DEBT / GAP)
```

Add `.gitkeep` in each empty folder. If `docs/` already exists, nest alongside.

**On existing repos:** Check each expected directory exists. If missing, create it. If present, skip. Report status per directory.

If `docs/specs/` is scaffolded, copy `assets/specs-index.md` to `docs/specs/index.md` and substitute `{project}`.

If `docs/backlog.md` is scaffolded, copy `assets/backlog.md` to `docs/backlog.md` (no substitutions).

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

**Source:** `assets/claude-md-skeleton.md`. Read it, fill placeholders, write to project root as `CLAUDE.md`.

**Placeholders:**
- `{Project Name}` — repo name
- `{detected tree — top-level only}` — output of Phase 1 root `ls`, with brief annotations
- `{detected, e.g., Node.js 20+}` — Tech Stack bullets from manifest detection
- `{detected from scripts/Makefile/Cargo}` — runnable commands as they exist now
- Bracketed conditional lines `{- docs/specs/ — ...}` — keep only if the corresponding adaptive doc was confirmed in Phase 2 Q&A; drop the whole line otherwise

#### Adaptation notes

- Only include sections relevant to the detected stack
- If CLAUDE.md already exists with good content (commands, structure, etc.), preserve it and layer workflow on top
- Shell notes, design system refs, protocol refs — only if the project has them
- The `> pending` markers tell future sessions that deep analysis hasn't happened yet

### 3c: Write Bootstrap Plan

Copy `assets/bootstrap-plan.md` to `docs/superpowers/plans/bootstrap.md`. Substitute `{project name}` and `{date}`.

Adapt the plan to what the project actually needs:
- If `docs/techstack.md` already exists and is good, skip Task 1 or reduce it to a review
- If `docs/overview.md` already exists, same
- If CLAUDE.md is already comprehensive, Task 3 becomes a light touch-up
- If `docs/specs/` was NOT scaffolded, drop Task 5
- If `docs/backlog.md` was NOT scaffolded, drop Task 5b
- Add tasks for any project-specific needs discovered during Q&A

### 3d: Sync Report (existing repos only)

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

### 3e: Commit the Scaffold

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
- **Fixed macro, adaptive micro** — `overview.md`, `techstack.md`, `superpowers/` are always scaffolded. `specs/`, `backlog.md` are scaffolded only when the project warrants them.
- **Two kinds of specs** — temporal (superpowers) = work orders, deleted after merge. Persistent (project) = source of truth, evolve with the product. Never confuse them.
- **Clear doc ownership** — `techstack.md` owns tech, `overview.md` owns product, `CLAUDE.md` owns workflow, `specs/` owns feature behavior. No duplication across docs.
- **One pipeline, adaptive** — fresh repos get scaffolded, existing repos get synced. Same phases, same walk-through, different actions per artifact state.
- **User approves everything** — present drafts, get approval, then write
