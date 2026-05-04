---
name: harness-bootstrap
description: "Install or sync the superpowers harness in a repo with code already present. Scaffolds CLAUDE.md, skeleton docs (overview, techstack, superpowers/), path-scoped rules, and curated skill/MCP/hook picks; bakes in doc-sync discipline. Greenfield repos route through /super-bootstrap first to seed overview + techstack + backlog. Solo dev workflow."
tags: [harness, scaffold, setup, meta, docs]
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
/harness-bootstrap session:
  Quick scan + greenfield gate → Q&A alignment → scaffold (folders, CLAUDE.md,
  skeleton techstack.md, skeleton overview.md, bootstrap-plan) →
  curate skill/MCP/hook against live sources → sync report + commit

  Pipeline is now LIVE. Skeleton docs carry detected facts. Picks pinned in
  .claude/settings.json. Any adaptive seeding (specs / backlog) queued in
  bootstrap-plan for later /sb-todo sessions.

Per-commit (forever after):
  Doc-sync gate fires → if diff touches behavior covered by a doc, propose
  updating that doc → user approves → doc + code commit together.

/harness-bootstrap re-run (any time):
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

### Existing CLAUDE.md

If it exists, read it. The pipeline may already be partially or fully present — note what's already there. **Also note legacy-skeleton blocks** (Coding Standards code-block walls, framework-specific patterns under pipeline-owned headings, large Project Structure trees) — these become migration candidates in Phase 3b. Default route for enforcement-shaped content (imperatives, "must / never / always") is `.claude/rules/<scope>.md`; only browsable reference goes to `docs/techstack.md` grown sections. See Phase 3b migration table.

### Rule-signal detection

Phase 1 also flags which `.claude/rules/*.md` files Phase 3b should seed. Signals (illustrative — judge by analogy):

- **Frontend component dir** detected (e.g. `src/components/`, `src/pages/`, `app/`, `components/`) + framework manifest (React / Vue / Svelte / Angular / Solid) → seed `rules/<framework>.md` from `assets/rules-frontend-skeleton.md`.
- **Chrome MV3 manifest** (`manifest.json` with `"manifest_version": 3` + `service_worker` field) OR `src/background/` dir → seed `rules/mv3.md` from `assets/rules-mv3-skeleton.md`.
- **Migrations dir** (`migrations/`, `db/migrate/`, `prisma/migrations/`) → flag `rules/migrations.md` for body-fill via doc-sync (machinery-only seed at scaffold).
- **Tests dir** with non-trivial structure (`tests/`, `__tests__/`, `*.test.*` patterns) → flag `rules/tests.md` for body-fill via doc-sync.

**ECC-first seed source for language-scoped rules.** Before scaffolding from local `assets/rules-*-skeleton.md`, check ECC (`gh api repos/affaan-m/everything-claude-code/contents/rules`) for a matching language/framework rule. If ECC ships one, propose seeding from ECC (with attribution comment + license note) — defer to specialists. Local skeletons are the fallback. Cross-cutting / project-specific rules (e.g. MV3, custom service-worker patterns) stay on local skeletons.

Adjacent stacks (Bun + Next, Deno + Fresh, Tauri + React, etc.) infer by analogy. Unknown stacks → skip rule-seeding for that signal; user can add later.

**Output of Phase 1:** A mental model of "what kind of project is this" — stack name, structure shape, maturity level, **which rule files to seed in Phase 3b**, **which legacy CLAUDE.md sections need migration**. NOT a deep analysis.

### Greenfield Redirect

After Phase 1 detection: if **no manifests + no source files (any extension) + README missing or under 3 substantive lines** AND `docs/overview.md` + `docs/techstack.md` are missing, abort with redirect:

> `/harness-bootstrap` installs the harness for a repo with code (or at least intent encoded in seed docs). Detected: empty repo with no `docs/overview.md` and no `docs/techstack.md`.
>
> Run `/super-bootstrap` first — it gates greenfield, runs ideation Q&A, and seeds those two docs (plus `docs/backlog.md` with one roadmap item). Then it dispatches back here automatically.
>
> If you want to force the harness onto an empty repo anyway: re-invoke with `/harness-bootstrap force` (rare — most output sections will sit empty until code lands).

If `docs/overview.md` + `docs/techstack.md` exist (seeded by `/super-bootstrap` greenfield path), proceed normally — the seed docs feed Phase 2 Q&A defaults and Phase 3b skeleton placeholders. **Never accept force without explicit token** — empty-repo harness is a useless artifact and the redirect surfaces the right tool.

---

## Phase 2: Q&A Alignment

**Phase 2 ALWAYS runs, including on re-run.** Don't skip because "the repo is already bootstrapped" or "answers are encoded in existing docs." Required Q1-Q4 are non-skippable every invocation. Q4 (external tools) is especially load-bearing — it is the fresh product-level signal for Phase 3c MCP curation and is **not derivable from any existing doc**. On re-run, prefill defaults from existing artifacts (overview.md → Q1/Q2/Q3, settings.json picks → Q4 hint) so confirms collapse to one keystroke — but the user still confirms. Conditional Q5-Q9 fire only if signal triggers.

Before writing anything, confirm understanding with the user. **Each question is an LLM-prefilled MCQ:** based on Phase 1 detection (and existing docs on re-run), infer the answer, present it as the default option with 2-4 alternatives + an `(other: __)` slot for elaboration. Cite the signal so the user can sanity-check the inference at a glance.

**Render-tier pattern — pick the cheapest one that fits.** Don't render full per-Q MCQ when a one-line synthesis carries the same information.

- **Tier 1 — all required Q's high-confidence + unambiguous** (every signal concrete: README explicit, manifest clear, git activity unambiguous, no missing tool config) → **collapse to a single synthesis line + one y/n**. Don't render Q1-Q4 prose. Skipping the per-Q ceremony is the default for clean, well-described projects.

  Example:
  ```
  Detected: {one-line synthesis covering project / user / state / tools}.
  Sound right? (y) confirm all  /  (n) show per-Q breakdown
  ```

- **Tier 2 — mixed confidence** (some Q's obvious, some ambiguous) → fold the confident Q's into the synthesis sentence; render full MCQ only for the ambiguous Q's.

- **Tier 3 — low confidence on most required Q's** (sparse README, ambiguous package type, contradictory signals) → full per-Q MCQ format, presented serially so user reads each inference.

If the user replies `(n)` or pushes back on Tier 1, **promote to Tier 3** for the breakdown — show full per-Q MCQ so they can correct specific items.

Format pattern:

```
Q{n}. {Question}

Inferred: {default answer}  ({signal — what scan found})

  (a) {default answer}              ← pre-checked
  (b) {alternative 1}
  (c) {alternative 2}
  ...
  (e) other: __
```

User responds with a single key for the obvious case, or types in `e: ...` to elaborate / correct.

### Required Questions (always asked, prefilled)

1. **What does this project do?** — Signal: README first paragraph, manifest description (`package.json` / `Cargo.toml` / `pyproject.toml`), root doc files, repo name. Default: synthesized one-line summary. Options: confirm / elaborate.

2. **Who uses it?** — Signal: package type (CLI / library / web app / desktop / mobile / internal tool), distribution channel (npm / PyPI / cargo / web), README badges. Defaults: developers (library) / end users (app) / internal team (CLI) / library consumers / other.

3. **Current state?** — Signal: git log recency (`git log --oneline --since="30 days ago"` count), branch count, last-commit age, test fixture freshness, "deprecated" / "WIP" / "alpha" markers in README. Defaults: active development / maintenance mode / greenfield / mid-rewrite / other. Cite the signal (e.g. "12 commits last 30 days" or "no commits since 2024-08").

4. **External tools in your workflow?** — Signal: `.github/`, `.gitlab/`, config files for Linear / Notion / Jira / Slack, deps with service-name hints, README mentions. Multi-select (comma-separated). Defaults: GitHub-only / Notion / Linear / Jira / Slack / Trello / ClickUp / other. Default GitHub-only if nothing else detected.

### Conditional Questions (only if signal triggers)

5. **Monorepo — confirm packages and their roles?** (only if workspace config detected: `pnpm-workspace.yaml`, `turbo.json`, Cargo workspace, etc.) — Default: list packages from workspace config; user confirms or elaborates roles.

6. **Existing CLAUDE.md — keep / drift-review / replace?** (only if `CLAUDE.md` exists) — Defaults: keep as-is + layer pipeline sections / per-section drift review with approval / replace entirely with skeleton / other.

7. **Existing `docs/` — current / stale / replace?** (only if `docs/` has files) — Defaults: current and authoritative / potentially stale (flag during doc-sync) / replace during scaffold / other.

8. **Persistent feature specs in `docs/specs/`?** (only if multi-feature signal — not a 3-file CLI or single-purpose lib) — Defaults: yes scaffold + seed via Task 1 of bootstrap-plan / no overkill for this project / other. Cite the signal (e.g. "8 top-level `src/` modules").

9. **Backlog tracker (`docs/backlog.md`)?** (only if active or maintenance) — Defaults: yes (default for shipping code) / no / other.

### Alignment Confirmation

After Q's, brief one-line summary so user catches any misread:

```
Plan: scaffold {fixed macro docs} {+ adaptive: specs} {+ adaptive: backlog};
curate skills/MCPs for {stack signal} + {workflow tools}.

Sound right? (y / push back)
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
- CLAUDE.md sections: Development Workflow, Doc Sync, Coding Principles, Edit Discipline, Context Hygiene, Rules, Solo Dev Assumptions, Git Notes, Planning
- `docs/techstack.md` skeleton sections: Runtime, Framework, Key Dependencies, Build & Distribution
- `docs/overview.md` skeleton sections: Problem, User, Current State
- `docs/superpowers/specs/`, `docs/superpowers/plans/`, `docs/superpowers/plans/bootstrap.md`
- `.claude/rules/index.md` (machinery summary)
- `.claude/rules/<seeded>.md` skeleton bodies (drift checked against `assets/rules-*-skeleton.md`)
- `.claude/settings.json` plugin pins (`enabledPlugins`, `extraKnownMarketplaces`)

**Project-owned** (never touched):
- CLAUDE.md: Tech Stack one-line, Commands, any user-added custom sections
- `docs/techstack.md` grown sections: Architecture Rules, Coding Patterns, Rejected Alternatives
- `docs/overview.md` grown sections: Module Index, Data Flow, Key Boundaries
- `.claude/rules/<rule>.md` grown sections (additions the user/doc-sync added below the skeleton scaffold)
- `.claude/rules/<rule>.md` files the user authored without a matching skeleton (treat as fully project-owned)
- Other settings in `.claude/settings.json` outside the plugin-pin keys

### 3a: Folders

Folders don't drift — only two states: missing or present.

**Always created (fixed macro):**
```
docs/
  superpowers/
    specs/       ← design specs from brainstorming (temporal)
    plans/       ← implementation plans (temporal)
.claude/
  rules/         ← path-scoped rules, full-body fires on file match
    index.md     ← orchestrator-facing summary of seeded rules
```

**Created if confirmed during Q&A (adaptive):**
```
docs/
  specs/         ← persistent feature specs, one .md per feature (seeded by Task 1 of bootstrap-plan)
  backlog.md     ← deferred items tracker (BUG / DEBT / GAP)
```

For each: create if missing, skip if present. Add `.gitkeep` in empty folders. If `docs/` or `.claude/` already exists, nest alongside. Report status per directory.

`docs/specs/` is scaffolded as an empty folder with `.gitkeep`. There is no index file — the folder + filename convention IS the catalog. Spec files are seeded by Task 1 of the bootstrap plan, each opening with `# {Feature Name}` and a one-paragraph intro.

If `docs/backlog.md` is scaffolded, copy `assets/backlog.md` to `docs/backlog.md` (no substitutions).

`.claude/rules/` machinery is **always** scaffolded (zero-cost when empty). `index.md` is seeded from `assets/rules-index-skeleton.md`. Individual rule bodies fill in Phase 3b based on Phase 1 signal detection.

### 3b: Pipeline docs

Walk each pipeline doc and apply the per-artifact rule. Sources:

| Asset | Destination | Notes |
|---|---|---|
| `assets/claude-md-skeleton.md` | `CLAUDE.md` (project root) | Includes Rules summary section — fill bullets from seeded rule files |
| `assets/techstack-skeleton.md` | `docs/techstack.md` | Coding Patterns grown section absorbs migrated CLAUDE.md content |
| `assets/overview-skeleton.md` | `docs/overview.md` | |
| `assets/bootstrap-plan.md` | `docs/superpowers/plans/bootstrap.md` | |
| `assets/rules-index-skeleton.md` | `.claude/rules/index.md` | Always — machinery |
| `assets/rules-frontend-skeleton.md` | `.claude/rules/<framework>.md` | Only if frontend signal fired in Phase 1 |
| `assets/rules-mv3-skeleton.md` | `.claude/rules/mv3.md` | Only if MV3 signal fired in Phase 1 |

**Per-doc handling:**

- **Missing** → fill placeholders, write.
- **Exists, drifted in pipeline-owned section** → diff that section vs template, present to user, get approval per section, write approved.
- **Exists, current** → mark `✓ current`. **Still show the per-section comparison briefly** (one-line per pipeline-owned section: `[Runtime] ✓ matches`, `[Framework] ✓ matches`, etc.) — asserting "current" without showing the comparison is a gap.
- **Project-owned content** → never touched, even on drift.
- **Legacy / unrecognized format** — if existing doc structure doesn't align with template sections (different headings, merged sections, doc was written by an older version of this skill or by hand) → surface as **legacy format detected**, propose: `(a) rewrite to current skeleton format (preserves grown sections), (b) leave as-is and accept template drift, (c) show full template-vs-current diff`. **Do not silently skip drift detection** because section names don't match — that hides real drift.

**Legacy CLAUDE.md migration (re-run on already-installed repos):**

Older sp-bootstrap skeletons baked content into CLAUDE.md that now belongs in `.claude/rules/` (path-scoped) or `docs/techstack.md` Coding Patterns (reference). When Phase 1 flagged legacy blocks in pipeline-owned slots, propose per-section migration BEFORE running the normal drift check on those sections.

Migration patterns (illustrative — judge by content shape, not heading exact-match):

| Legacy CLAUDE.md content | Proposed destination | Reason |
|---|---|---|
| Enforcement rules with clear file-scope (component patterns, Tailwind tokens, async style, framework idioms) | `.claude/rules/<scope>.md` | Path-scoped — full body fires when matching file is read. **Cold-file alternative would silent-miss enforcement.** |
| Reference material — rejected alternatives, design rationale, architecture decisions, deep examples for browsing | `docs/techstack.md` § Coding Patterns (grown section) | On-demand reading, not enforcement. Safe to be cold. |
| MV3 / service-worker rules path-bound to `src/background/**` | `.claude/rules/mv3.md` | Path-scoped |
| `## Project Structure` directory tree | drop | `ls` / `tree` covers it; not load-bearing for any decision |
| Cross-cutting items inside a path-scoped list (storage-key constants, type-centralization across UI ↔ background, message-contract types) | keep in CLAUDE.md (no clean glob — every layer touches them) | Genuinely ambient |

**Default-to-rules when ambiguous.** A "Coding Standards" block named like reference but written as imperatives (must / never / always) is enforcement — silent-miss in a cold file costs more than slight rule over-attach.

Surface the migration plan as a single proposal. Format below pins shape — one row per legacy block, judged via the migration table above. Destinations: `.claude/rules/<scope>.md` | `docs/techstack.md` § Coding Patterns | keep in CLAUDE.md | drop.

```
{path}: legacy content detected — propose migrations:

  [<legacy heading>: <area> (<role>, <scope>)]
    → <destination>
    Reason: <one line tying content shape to destination choice>

  ... (one row per legacy block)

Apply migrations? (y / n / select-per-section)
```

Concrete fill-in (one example, not a template — judge by analogy for the actual repo):

```
  [Coding Standards: Components/Tailwind (enforcement, frontend-scoped)]
    → .claude/rules/components.md
    Reason: imperatives — path-scoped fires on component reads, cold-file would silent-miss.
```

Per-migration handling:
- **User approves** → write content into destination with proper format conversion (rule files get globs frontmatter; techstack grown sections get conventional headings). Remove from CLAUDE.md. Add summary bullet to CLAUDE.md § Rules for any rule-file destination.
- **User rejects** → leave content in CLAUDE.md, mark section project-owned for future runs (no further drift attempts on that section).
- **User selects per-section** → walk one at a time.

**This migration runs once per legacy section.** After successful migration, the section is gone from CLAUDE.md and lives in its right home; future re-runs see clean structure and skip migration logic.

**Never destructive without confirmation.** Show source → dest mapping, get explicit approval, only then move content.

**Per-section diff output is mandatory** — even when conclusion is `✓ current`, show the comparison so the user (and the next session's audit) can verify. Hand-wave assertions like "skeleton sections match the template" without a per-section listing are insufficient.

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
- Manifest detection facts (Runtime / Framework / Key Dependencies / Build & Distribution) → fill into CLAUDE.md Tech Stack one-liner AND `techstack.md` skeleton sections
- Q&A answers (Problem / User / Current State) → fill into `overview.md` skeleton sections
- Bracketed conditional lines `{- docs/specs/ — ...}` — keep only if the corresponding adaptive doc was confirmed in Phase 2 Q&A; drop the whole line otherwise
- CLAUDE.md § **Rules** summary bullets — fill from seeded `.claude/rules/*.md` files (one bullet per rule with glob + 2-4 one-line key points). If no rules seeded, drop the example placeholders and keep only the explanatory paragraph.
- Rule skeleton placeholders (`{component path glob}`, `{Framework}`, body bullets in `assets/rules-*-skeleton.md`) → fill from Phase 1 detection. Lines that don't apply get dropped during scaffold.

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

Auto-curate Claude Code tooling matched to detected stack AND product context. **Runs every `/harness-bootstrap`** — refresh on every run keeps picks fresh against upstream source updates (new skills published, deprecated removals, license changes). Harness-internal: user sees one batch, replies. No manual search, no plugin install gate.

**Inputs (no deferred deep work needed):**
- Phase 1 quick-scan: runtime, framework, key tools, monorepo state → drives **stack-matched picks** (e.g. `react-expert` for React, `postgres-pro` for Postgres)
- Phase 2 Q&A: user type, current state, **external tools** (Notion / Linear / Jira / Slack / GitHub-only / etc.) → drives **product/workflow-level MCP picks** (e.g. Notion MCP for docs-heavy, Linear MCP for active dev, Slack MCP for team comm, GitHub MCP for PR-heavy workflow)

**Process:**

1. **Live source query — non-skippable, runs every invocation.** Stable project ≠ stable upstream. Marketplaces add picks, deprecate picks, change licenses, between any two `/harness-bootstrap` runs. The only way to detect that drift is to actually query — even when the project hasn't changed.

   Issue WebFetch / Bash queries against each source. **GitHub-only pool — sites without backing repos can't surface trust signals (stars / recency / license).** Examples:
   - **Anthropic plugin marketplace** — `gh api repos/anthropics/claude-plugins-official/contents/plugins` — Anthropic-vetted picks (🛡 tier).
   - **MCP official registry** — `gh api repos/modelcontextprotocol/registry/contents` (or query the registry API directly) — official MCP discovery service. Indexes both steering-group reference impls AND community-published servers. Primary source for MCP picks. Picks authored under `modelcontextprotocol/*` org auto-tier as 🛡 vetted.
   - **everything-claude-code (affaan-m / ECC)** — `gh api repos/affaan-m/everything-claude-code/contents` — 172k-star MIT-licensed harness component bundle (skills + agents + rules + hooks + MCP configs). Strongest source for **language-specific rules** (TS / Python / Go / etc.) — Phase 3b rule-seed step should check ECC's `rules/` first before scaffolding from generic skeleton.
   - **awesome-claude-skills (ComposioHQ)** — `gh api repos/ComposioHQ/awesome-claude-skills/contents/README.md` (or WebFetch) — actively-curated category index (~200 entries, "production ready" bar). Strongest source for **workflow / external-tools** picks (78 Composio SaaS workflow skills covering Notion / Slack / Jira / Linear / CRM) — matches Phase 2 Q4 external-tools signal.
   - **VoltAgent/awesome-agent-skills** — `gh api repos/VoltAgent/awesome-agent-skills/contents` — 1000+ skills from official dev teams (Anthropic, Vercel, Stripe, Cloudflare, Sentry, Hugging Face, Figma) + community. MIT-licensed, ~20k stars. Cross-reference for cross-team picks the Claude-only catalogs miss.
   - **jeffallan/claude-skills** — `gh api repos/Jeffallan/claude-skills/contents` — broad fullstack-skills marketplace (~65 skills covering fullstack workflows, project-mgmt integration). Direct query > aggregator listing for freshness.
   - **Fast-path** — if `claude-code-setup` plugin is installed locally, invoke `/setup` and merge its picks.

   If a single source is unreachable (404 / rate limit / network), note the failure inline and continue with the others — **never skip the whole step**. Skipping = stale picks = silent failure mode of the entire phase.

2. **Filter to matched picks only** — drop generic / spray suggestions. Match against stack signals AND product/workflow signals. A Notion MCP isn't "off-stack" if Q&A surfaced docs-heavy workflow.

3. **Dedupe by canonical name across sources.** Same skill / MCP often appears in multiple sources (e.g. `react-expert` in Anthropic + ECC + jeffallan with different versions / licenses / recency). Sources are peers, not ranked — never silently default to one. Process:
   - Group hits by canonical plugin name (case-insensitive, ignore source suffix)
   - Pick the **primary row** by highest composite signal: stars × recency × license-clean. Tie-break by Anthropic-vetted if present.
   - Collapse other variants into a single `also in: <source-A> · <source-B>` line under the primary row, with provenance: stars / last-commit / license per alternate.
   - User can expand alternates at present-batch step if the primary's trust signal looks weaker than an alternate's.

4. **Trust signal lookup per pick** — for any plugin NOT from `claude-plugins-official`, fetch (via WebFetch or `gh api`):
   - Repo URL + GitHub stars
   - Last-commit recency (e.g. "3d ago", "14mo ago")
   - License (or "no license" — flag as ⚠)
   - Permissions exercised (read-only? shell? network? auto-exec hook?)

   Hooks are elevated risk: auto-exec on every tool call (PreToolUse / PostToolUse / UserPromptSubmit). Always tag hooks: `⚠ HOOK = auto-executes. Audit source before accept.`

5. **Re-run delta** — if `.claude/settings.json` already has pinned picks, diff the new curation against the pinned set. **Re-fetch trust signals on every pinned pick** (not just new ones) — license can change, last-commit can age, repo can be archived.
   - Pinned + still recommended + trust block unchanged → keep silently, mark `✓ pinned`
   - Pinned + still recommended + trust block moved (license / last-commit / archive status changed) → re-show that pick's trust block, ask user to re-confirm
   - New pick recommended (upstream added it; or stack signal changed) → propose as **add**
   - Pinned but no longer recommended (deprecated upstream; license changed; stack changed) → propose as **drop** with reason
   - **Pinned but source missing** — `enabledPlugins` entry exists with no resolvable source (not in `extraKnownMarketplaces`, not Anthropic-vetted). **Live-query source pool first** to find the plugin's real marketplace; if found, propose **resolve** (add marketplace to `extraKnownMarketplaces`) with trust block; if not found in any source, propose **drop** (orphan, can't reproduce on cloud / fresh machine).

6. **Present batch with full trust signal per new / changed pick.** Each row leads with a **trust tier** so user judges on the right axis (sharpness vs. audit-depth, not source rank):
   - `🛡 vetted` — authored under `anthropics/*` or `modelcontextprotocol/*` org (Anthropic-audited or MCP steering-group authored, license-clean, slower to land sharp picks). Includes `claude-plugins-official` and any `modelcontextprotocol/*` reference impls surfaced via the registry.
   - `★ popular` — outside the vetted orgs above, ≥1k stars + commit ≤90d ago + license clean
   - `🆕 fresh` — recent activity (≤30d) but lower stars / smaller pool
   - `⚠ unaudited` — no license, archived, last-commit >12mo, or stars <100

   ```
   Skill / MCP / hook curation for {project} ({stack}):

     [SKILL]   🛡 {name}@{source}                  [+ add | ✓ keep | − drop]
                Why: {matched signal, one-line value}
                (vetted picks: trust block omitted)

     [SKILL]   ★ {name}@{source}                   [+ add | ✓ keep | − drop]
                ★ {stars} · last commit {recency} · {license}
                Permissions: {read-only / shell / network / etc.}
                Why: {matched signal, one-line value}
                also in: {alt-source-A} (★{stars} · {recency} · {license}) · {alt-source-B} (...)

     [HOOK]    ⚠ {name}@{source}                   [+ add]
                ★ {stars} · last commit {recency} · {license}
                Permissions: ⚠ {what triggers + what it runs}
                Why: {matched signal}
                ⚠ HOOK = auto-executes. Audit source before accept.

     [MCP]     🆕 {name}@{source}                  [+ add]
                ★ {stars} · last commit {recency} · {license}
                Permissions: {network / shell / file-system / etc.}
                Why: {matched signal}

   Accept all / reject specific / discuss thoughts / expand alternates?
   ```

   `also in:` line collapses dedupe alternates from Step 3. User can ask to expand if primary's signal looks weaker than an alternate.

7. **Apply approved — write `.claude/settings.json`.** Source of truth: project-scope intent, committed, travels with repo, cloud-friendly. Device install (`claude plugin install`) is optional convenience layered on top.
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
| Artifact                            | Status       | Action              |
|-------------------------------------|--------------|---------------------|
| CLAUDE.md: Workflow                 | ⚠ drifted    | updated (approved)  |
| CLAUDE.md: Doc Sync                 | ✓ current    | —                   |
| CLAUDE.md: Coding Standards (enforcement) | ⚠ legacy | migrated → rules/components.md |
| CLAUDE.md: MV3 Architecture (path-scoped) | ⚠ legacy | migrated → rules/mv3.md |
| CLAUDE.md: Rules summary            | ⚠ drifted    | regenerated from rules/ |
| docs/techstack.md: Runtime          | ⚠ drifted    | updated (approved)  |
| docs/techstack.md: Coding Patterns  | ✓ current    | (no enforcement migration this run) |
| docs/overview.md: Problem           | ✓ current    | —                   |
| docs/superpowers/specs/             | ✓ exists     | —                   |
| docs/superpowers/plans/bootstrap.md | ⚠ exists     | kept (user state)   |
| .claude/rules/                      | ⊕ new        | scaffolded          |
| .claude/rules/index.md              | ⊕ new        | seeded              |
| .claude/rules/mv3.md                | ⊕ new        | seeded (signal: MV3 manifest) |
| .claude/rules/components.md         | ⊕ new        | seeded (signal: React + tsx dir) |
| .claude/settings.json: picks        | ⚠ delta      | +2 add, −1 drop     |
```

If every row is `✓ current` and nothing changed on disk, report and skip the commit.

Otherwise use `/sb-commit` to stage:
- `CLAUDE.md` (new, modified, or post-migration)
- `docs/techstack.md` (new, skeleton-section drift, or post-migration absorbed content)
- `docs/overview.md` (new or skeleton-section drift)
- `.claude/settings.json` (new or picks delta)
- `.claude/rules/index.md` (always — at minimum machinery seed)
- `.claude/rules/<seeded>.md` (any rule files newly seeded or migrated to)
- `docs/superpowers/specs/.gitkeep`
- `docs/superpowers/plans/.gitkeep`
- `docs/superpowers/plans/bootstrap.md` (if newly written or regenerated)
- `docs/specs/.gitkeep` (if scaffolded)
- `docs/backlog.md` (if scaffolded)
- Any other adaptive files / folders created

Commit message: `chore: scaffold superpowers pipeline` on fresh repos, `chore: sync superpowers pipeline` when only drift fixes / picks delta shipped, `refactor: migrate CLAUDE.md to rules layer + sync pipeline` when re-run performed legacy migration.

---

## Phase 4: Handoff

After committing (or reporting no changes needed), present results based on repo state:

**First-run (just scaffolded):**

> **Pipeline is live.** CLAUDE.md drives workflow. Skeleton `docs/techstack.md` and `docs/overview.md` carry detected facts — grown sections fill via doc-sync as features land. Skill / MCP / hook picks pinned in `.claude/settings.json`.
>
> {If any rule files were seeded: "Path-scoped rules seeded in `.claude/rules/` ({list seeded rules}). They auto-load on file match — full ammo at the decision moment, summary mirrored in CLAUDE.md § Rules. Add more rule files when path-scoped patterns emerge."}
>
> {If bootstrap.md has Task 1 / Task 2 active: "Optional adaptive seeding queued in `docs/superpowers/plans/bootstrap.md` (specs / backlog). Next session: `/clear`, then `/sb-todo`."}
> {If bootstrap.md is cleanup-only: "Bootstrap essentially complete — `/sb-todo` will show the cleanup task."}

**Re-run / sync pass:**

> **Pipeline synced.** {N items updated, M already current.}{If migration performed: " Migrated {sections moved} from CLAUDE.md to {destinations} — `CLAUDE.md` now {old line count} → {new line count} lines."}{If picks delta: " Picks: +K added, −L dropped against live sources."}{If rule files added: " Rules: +K seeded, summary updated in CLAUDE.md § Rules."}

## Principles

- **Harness, not product** — bootstrap installs workflow + skeleton docs + curated picks. Greenfield product ideation (empty repo, no code) is out of scope. Phase 1 has a friendly gate.
- **Skeleton at scaffold, grown via sync** — detected facts and Q&A answers seeded immediately into `techstack.md` / `overview.md`. Architecture Rules, Coding Patterns, Module Index, Data Flow, Key Boundaries start empty and fill incrementally per-commit. Doc-sync IS the growth mechanism — no deferred deep-scan tasks.
- **Refresh on every run** — picks curated against live sources every `/harness-bootstrap`. Upstream marketplace changes (new picks, deprecations, license shifts) surface as a delta against `.claude/settings.json`.
- **Detect, then confirm** — Phase 1 grounds seeded facts in repo evidence; Phase 2 Q&A confirms; user approves drift / picks / drafts before any write.
- **Docs travel with code** — doc-sync gate on every commit. Implementation without doc-sync is incomplete. The pipeline's real power.
- **Fixed macro, adaptive micro** — `overview.md` / `techstack.md` / `superpowers/` always scaffolded. `specs/` / `backlog.md` only when the project warrants them.
- **Two kinds of specs** — temporal (`docs/superpowers/specs/`) = work orders, deleted after merge. Persistent (`docs/specs/`) = source of truth, evolves with product. Never confuse.
- **Clear doc ownership** — `techstack.md` owns tech (incl. coding patterns), `overview.md` owns product, `CLAUDE.md` owns workflow + always-on rules + rules summary, `.claude/rules/` owns path-scoped rules, `docs/specs/` owns feature behavior. No duplication.
- **Layer by decision-moment** — every rule has a moment-of-need: ambient (CLAUDE.md, every turn) for workflow + always-true safety; path-scoped (`.claude/rules/`, fires on file match) for full-body precision when relevant; on-demand (`docs/techstack.md`, `docs/specs/`) for reference Claude reads when intent surfaces. Skills are for thinking modes / structured processes — **not** a rule-storage layer.
- **Precision per always-on byte** — every CLAUDE.md line answers "what decision does this sharpen, at what moment?" Length is downstream of that. The Anthropic / community ~120-line target is a smoke alarm on bloat, not a hard cap. Sweet-spot session quality (~80k context = 100% recall) requires the orchestrator brief stays lean enough that opening file reads + workflow + actual task fit.
- **Subagent dispatch protects orchestrator focus** — verbose work (10+ file reads, noisy test runs, parallel-safe chunks, fresh-eye review) belongs in a subagent's clean window. Orchestrator's attention budget is too valuable to spend on tool churn.
- **One pipeline, adaptive** — same phases on fresh and re-run; actions differ per artifact state. Re-run on legacy CLAUDE.md proposes per-section migration to the right layer (rules / techstack patterns) before drift-checking. Solo dev first.
