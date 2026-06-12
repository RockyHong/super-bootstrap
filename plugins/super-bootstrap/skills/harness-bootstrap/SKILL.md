---
name: harness-bootstrap
description: "Install or sync the superpowers harness in a repo with code already present. Scaffolds CLAUDE.md, skeleton docs (overview, techstack, superpowers/), path-scoped rules, and curated skill/MCP/hook picks; bakes in doc-sync discipline. Greenfield repos route through /super-bootstrap first to seed overview + techstack + backlog. Solo dev workflow."
tags: [harness, scaffold, setup, meta, docs]
---

# Super Bootstrap — Superpowers Pipeline for Any Repo

Set up (or sync) the superpowers-driven development pipeline in a project. Installs harness — workflow rules, doc-sync gate, skeleton docs, curated skill/MCP/hook picks — in one scaffold session. The doc-sync gate at every later commit grows the skeleton docs over time, so there's no deferred deep-scan stage.

Designed for a solo developer working across multiple Claude Code sessions and cloud Claude Code.

## Phase 1: Quick Scan (lightweight, parallel reads)

Gather just enough to scaffold — skim manifests for stack/version, note structure shape, stop.

Check contributor count (`git shortlog -sn --all | head -5`). If >1 active contributor, surface as info — don't block:
> "FYI: detected multiple contributors. The pipeline's CLAUDE.md assumes solo dev (simple branching, no PRs for self-review). You can edit those sections after bootstrap if your team's workflow differs."

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

> `/super-bootstrap:harness-bootstrap` installs the harness for a repo with code (or at least intent encoded in seed docs). Detected: empty repo with no `docs/overview.md` and no `docs/techstack.md`.
>
> Run `/super-bootstrap` first — it gates greenfield, runs ideation Q&A, and seeds those two docs (plus an empty `docs/backlog.md`; roadmap lives in `docs/overview.md` § Roadmap). Then it dispatches back here automatically.
>
> If you want to force the harness onto an empty repo anyway: re-invoke with `/super-bootstrap:harness-bootstrap force` (rare — most output sections will sit empty until code lands).

If `docs/overview.md` + `docs/techstack.md` exist (seeded by `/super-bootstrap` greenfield path), proceed normally — the seed docs feed Phase 2 Q&A defaults and Phase 3b skeleton placeholders. Accept re-invoke with `force` token only; absent that token, surface the redirect — empty-repo harness is a useless artifact.

### Rot signals (harnessed-but-stale)

Symmetric counterpart to Greenfield Redirect. Greenfield catches "no harness, can't install yet." Rot catches "harness installed but carries renamed-away literals" — re-run is the right entry, but the user deserves a heads-up before Phase 3b churns through migrations.

Trigger: any pipeline-owned file (`CLAUDE.md`, `docs/overview.md`, `docs/techstack.md`, `docs/superpowers/plans/bootstrap.md`, `.claude/rules/*.md`) contains a literal listed as `old` in `assets/rename-map.md`. Whole-token match; one hit is enough.

When the trigger fires, surface ONCE up front (single message, not a redirect — re-run is the correct entry point):

```
Renamed-away literals detected in pipeline-owned files.
Phase 3b will propose migrations alongside the normal drift check.
Affected files: {list of files where rot was observed}.

Continue? (y / dry-run report only)
```

If user answers `dry-run`, walk Phases 1–3b without writing — output the sync report + rename-map migration rows + per-section diff listing, then exit. Otherwise proceed normally; Phase 3b's rot scan (see § 3b) handles the actual migrations.

**Output of Phase 1 (rot lane):** record `rot_hits[]` so Phase 3b can re-use the scan instead of grepping twice.

---

## Phase 2: Q&A Alignment

**Phase 2 ALWAYS runs, including on re-run.** Don't skip because "the repo is already bootstrapped" or "answers are encoded in existing docs." Required Q1-Q4 are non-skippable every invocation. Q4 (external tools) is especially load-bearing — it is the fresh product-level signal for Phase 3c MCP curation and is **not derivable from any existing doc**. On re-run, prefill defaults from existing artifacts (overview.md → Q1/Q2/Q3, settings.json picks → Q4 hint) so confirms collapse to one keystroke — but the user still confirms. Conditional Q5-Q9 fire only if signal triggers.

**Hard precondition before Phase 3 dispatch.** Read `docs/superpowers/plans/bootstrap-qa.md`; if present and complete (all required Q1-Q4 answered), proceed. If absent or any required Q missing, halt Phase 3, surface the specific missing Q, re-prompt. Tier-1 collapse counts only when the synthesis line covered all four required answers verbatim and the user replied `y` (not `(y, but…)`, not silent assumption). Consent is a live user response this invocation (recorded in `bootstrap-qa.md`); prefilled defaults are prompts, not consent. The assertion is mandatory: skipping it produces the same silent-skip class of bug as skipping the per-section diff or the rot scan.

Before writing anything, confirm understanding with the user. Each question is an LLM-prefilled MCQ — infer the answer from Phase 1 detection (and existing docs on re-run), present it as the default with 2-4 alternatives + an `(other: __)` slot. Cite the signal so the user can sanity-check the inference at a glance.

Rendering protocol: read `assets/phase2-qa-protocol.md` before presenting Q&A. If unavailable, apply Tier 3 rendering.

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

Once the synthesis `y` is received, write confirmed Q&A answers to `docs/superpowers/plans/bootstrap-qa.md` — one key-value pair per question (e.g. `Q1: {confirmed answer}`) plus the confirmed synthesis line. This makes Phase 2 → Phase 3 session-break-safe: if the session is interrupted, the next invocation reads this file instead of re-running Q&A.

---

## Phase 3: Scaffold / Sync

With alignment confirmed, walk each pipeline artifact in order: folders → pipeline docs → curate picks → sync report + commit. Same flow on fresh and re-run repos — fresh just sees "all new" at every step.

**Per-artifact rule** (applied uniformly in 3a / 3b / 3c):
- Missing → write from template / curate fresh
- Exists, matches template → skip (`✓ current`)
- Exists, drifted from template → show diff, get approval per change, then write
- Project-owned content → never touch, even on drift

**Pipeline-owned** (subject to drift check):
- CLAUDE.md sections: Development Workflow, Doc Sync, Coding Principles, Edit Discipline, Context Hygiene, Finding Triage, Rules, Git Notes, Planning
- `docs/techstack.md` skeleton sections: Runtime, Framework, Key Dependencies, Build & Distribution, Edit Discipline
- `docs/overview.md` skeleton sections: Problem, User, Current State
- `docs/superpowers/specs/`, `docs/superpowers/plans/`, `docs/superpowers/plans/bootstrap.md`
- `.claude/rules/index.md` (machinery summary)
- `.claude/rules/<seeded>.md` skeleton bodies (drift checked against `assets/rules-*-skeleton.md`)
- `.claude/settings.json` plugin pins (`enabledPlugins`, `extraKnownMarketplaces`)

**Project-owned** (never touched):
- CLAUDE.md: Tech Stack one-line, Commands, any user-added custom sections
- `docs/techstack.md` grown sections: Architecture Rules, Coding Patterns, Rejected Alternatives
- `docs/overview.md` grown sections: Roadmap, Module Index, Data Flow, Key Boundaries
- `.claude/rules/<rule>.md` grown sections (additions the user/doc-sync added below the skeleton scaffold)
- `.claude/rules/<rule>.md` files the user authored without a matching skeleton (treat as fully project-owned)
- Other settings in `.claude/settings.json` outside the plugin-pin keys

### 3a: Folders & core plugin pin

Folders + core plugin pin don't drift — only two states: missing or present.

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

**Core plugin pins (pre-resolve).** The harness CLAUDE.md skeleton names two skills by trigger rule:

- `superpowers` — slash-command routes (`/brainstorm`, `/write-plan`, `/execute-plan`).
- `karpathy-guidelines` — invoked before every code edit (see CLAUDE.md § Coding Principles).

Both are **core deps, not adaptive picks** — pinned before Phase 3c so `/super-bootstrap:resolve-plugins` curates adaptive picks on top of a guaranteed base. Dangling-rule risk: if CLAUDE.md names a skill that isn't installed, the trigger rule misfires silently. Pin first.

Ensure `.claude/settings.json` contains:

```json
{
  "enabledPlugins": {
    "superpowers@claude-plugins-official": true,
    "andrej-karpathy-skills@karpathy-skills": true
  },
  "extraKnownMarketplaces": {
    "karpathy-skills": {
      "source": { "source": "github", "repo": "forrestchang/andrej-karpathy-skills" }
    }
  }
}
```

- File missing → create with this minimal shape.
- File exists, key absent → merge the key in.
- Key already present → skip (`✓ pinned`).
- Other `.claude/settings.json` content → never touched.

`superpowers@claude-plugins-official` resolves from Anthropic's official marketplace — no `extraKnownMarketplaces` entry needed. `andrej-karpathy-skills@karpathy-skills` lives outside the official marketplace, so the `karpathy-skills` marketplace entry is required for cloud / fresh-machine resolution. Phase 3c (`/super-bootstrap:resolve-plugins`) treats both pins as locked: never proposes drop, never re-prompts the user. Adaptive picks (stack-matched skills / MCPs / hooks) layer on top.

### 3b: Pipeline docs

Walk each pipeline doc and apply the per-artifact rule. Sources:

| Asset | Destination | Notes |
|---|---|---|
| `assets/claude-md-skeleton.md` | `CLAUDE.md` (project root) | Includes Rules summary section — fill bullets from seeded rule files |
| `assets/techstack-skeleton.md` | `docs/techstack.md` | Coding Patterns grown section absorbs migrated CLAUDE.md content |
| `assets/overview-skeleton.md` | `docs/overview.md` | `<!-- harness-meta -->` block at top: fill `external-tools:` with Q4 multi-select answer as YAML list (default `[github]`). Read by `/super-bootstrap:resolve-plugins` as Tier-2 fallback. Treat as pipeline-owned for drift checks — re-runs propose update if Q4 answer changes. |
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
- **User approves** → write content into destination with proper format conversion (rule files get `paths:` frontmatter; techstack grown sections get conventional headings). Remove from CLAUDE.md. Add summary bullet to CLAUDE.md § Rules for any rule-file destination.
- **User rejects** → leave content in CLAUDE.md, mark section project-owned for future runs (no further drift attempts on that section).
- **User selects per-section** → walk one at a time.

**This migration runs once per legacy section.** After successful migration, the section is gone from CLAUDE.md and lives in its right home; future re-runs see clean structure and skip migration logic.

**Never destructive without confirmation.** Show source → dest mapping, get explicit approval, only then move content.

**Per-section diff output is mandatory.** Required shape for every pipeline-owned section in every targeted file — `✓ current` is **not** allowed without the listing. The two-block contract:

Block 1 (always, one row per pipeline-owned section in the file):

```
{file path} sync — per-section comparison:

  [{Section A}] ✓ matches template     (lines N–M)
  [{Section B}] ⚠ drifted               (see diff below)
  [{Section C}] ✓ matches template     (lines P–Q)
```

Block 2 (only for `⚠ drifted` rows — one expansion per drifted section):

```
{file path} sync — drift detected:

  [{Section Name}] section drifted from current template:
  ───────────────────────────────────────────────
  - {removed line}
  + {added line}
  ───────────────────────────────────────────────

  Update? (y / n / show full diff)
```

Hand-wave assertions ("skeleton sections match the template") without Block 1's per-section listing are a hard failure — block commit, re-run the check. Drift approval (Block 2) protects against (a) legit template updates the user wants to review and (b) bad-actor template injection on a future re-run — you see what's about to change before it's overwritten.

**Rot scan (mandatory pre-step on re-run).** Before Block 1 renders, read `assets/rename-map.md` and grep every pipeline-owned file in scope for each entry's `old` literal (whole-token match — avoid URL / identifier false hits). Each hit becomes a migration row in the sync report:

```
{file path}:{line} — stale literal `{old}` → propose `{new}`
  Reason: {map entry reason}
```

Acceptance pattern matches legacy migration: `y / n / per-row`. The rot scan runs even when every per-section diff is `✓ current` — a stale slash command literal inside a current-shaped doc is invisible to per-section diff (template hasn't drifted; only the literal inside it has). Together, per-section diff + rot scan cover both axes of drift: section shape AND inline literals.

**Special case — `bootstrap.md`** carries user state (checkbox progress from prior session). Don't auto-merge. Prompt: **Keep existing** (default) / **Reset from template** / **Merge** (rare, task-by-task).

**Special case — `bootstrap.md` missing on mature repo.** When the file is **missing** AND the repo has ≥5 commits past the most recent bootstrap-shaped commit (`chore: scaffold superpowers pipeline` / `chore: sync superpowers pipeline` / `chore: complete pipeline bootstrap`), don't silently re-template — the file was almost certainly Task-3-cleanup-deleted by a prior session, and re-templating resurfaces completed work as fresh tasks. Surface an advisory instead:

```
docs/superpowers/plans/bootstrap.md is missing.
Repo has {N} commits since last bootstrap-shaped commit ({sha} — {date}).
File was likely cleanup-deleted (Task 3 of prior bootstrap).

Options:
  (a) skip re-seed (bootstrap complete)        ← default
  (b) re-seed (Tasks 1/2 still applicable per current Q&A)
  (c) re-seed cleanup-only (Task 3 stub for next session)
```

Fresh repos (no bootstrap-shaped commit yet) keep current behavior — write from template, no advisory.

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
- Task 3 (Cleanup) always retained — includes deleting `docs/superpowers/plans/bootstrap.md` and `docs/superpowers/plans/bootstrap-qa.md`

If both Task 1 and Task 2 drop, the plan becomes Task 3 (cleanup) only — that's fine, signals bootstrap is essentially complete.

### 3c: Curate skill / MCP / hook

**Delegated to `/super-bootstrap:resolve-plugins`.** Phase 3c is one Skill invocation — `Skill(resolve-plugins)`. The full curation logic (live-query source pool, dedupe, trust tiers, batch presentation, `.claude/settings.json` write) lives in `plugins/super-bootstrap/skills/resolve-plugins/SKILL.md`. Single source of truth.

`/super-bootstrap:resolve-plugins` is also runnable standalone — useful when upstream marketplaces drift but nothing in the repo changed (no need to walk Phase 1-3b just to refresh picks).

Phase 3c invokes `/super-bootstrap:resolve-plugins`, which gates picks via earn-right (≥1 hard invocation path required) and atomic install + verify per accepted candidate. Re-running `/super-bootstrap:harness-bootstrap` safely re-evaluates all picks against current upstream state and current harness wiring.

**Inputs the harness has prepared by Phase 3c:**
- `docs/techstack.md` — written in Phase 3b. `/super-bootstrap:resolve-plugins` reads § Runtime / Framework / Key Dependencies for stack-matched picks.
- `docs/overview.md` — written in Phase 3b. `/super-bootstrap:resolve-plugins` reads § User / Current State for additional workflow signal.
- Phase 2 Q4 (external tools) answer — flows via `docs/overview.md` content (the harness embeds the answer when seeding the doc) or via `.claude/settings.json` pinned MCPs on re-run.

**Output:** `.claude/settings.json` updated with `enabledPlugins` + `extraKnownMarketplaces`. Commit handled by `/super-bootstrap:resolve-plugins` itself if delta non-empty.

### 3d: Sync report + commit

**Sync report** — always shown before commit. Fresh repos see "all new"; re-run repos see drift fixes, picks delta, and current items.

```
| Artifact                            | Status       | Action              |
|-------------------------------------|--------------|---------------------|
| CLAUDE.md: Doc Sync                 | ✓ current    | —                   |
| docs/techstack.md: Runtime          | ⚠ drifted    | updated (approved)  |
| .claude/rules/mv3.md                | ⊕ new        | seeded (signal: MV3 manifest) |
```

If every row is `✓ current` and nothing changed on disk, report and skip the commit.

Otherwise use `/super-bootstrap:commit` to stage:
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
> {If bootstrap.md has Task 1 / Task 2 active: "Optional adaptive seeding queued in `docs/superpowers/plans/bootstrap.md` (specs / backlog). Next session: `/clear`, then `/super-bootstrap:todo`."}
> {If bootstrap.md is cleanup-only: "Bootstrap essentially complete — `/super-bootstrap:todo` will show the cleanup task."}

**Re-run / sync pass:**

> **Pipeline synced.** {N items updated, M already current.}{If migration performed: " Migrated {sections moved} from CLAUDE.md to {destinations} — `CLAUDE.md` now {old line count} → {new line count} lines."}{If picks delta: " Picks: +K added, −L dropped against live sources."}{If rule files added: " Rules: +K seeded, summary updated in CLAUDE.md § Rules."}

## Principles

- **Layer by decision-moment** — every rule has a moment-of-need: ambient (CLAUDE.md, every turn) for workflow + always-true safety; path-scoped (`.claude/rules/`, fires on file match) for full-body precision when relevant; on-demand (`docs/techstack.md`, `docs/specs/`) for reference Claude reads when intent surfaces. Skills are for thinking modes / structured processes — **not** a rule-storage layer.
- **Precision per always-on byte** — every CLAUDE.md line answers "what decision does this sharpen, at what moment?" Length is downstream of that. The Anthropic / community ~120-line target is a smoke alarm on bloat, not a hard cap. Sweet-spot session quality (~80k context = 100% recall) requires the orchestrator brief stays lean enough that opening file reads + workflow + actual task fit.
- **Default-to-rules when ambiguous** — enforcement-shaped content (imperatives: must / never / always) goes to `.claude/rules/<scope>.md` even when the heading sounds like reference. Silent-miss in a cold file costs more than slight over-attach.
- **Subagent dispatch protects orchestrator focus** — verbose work (10+ file reads, noisy test runs, parallel-safe chunks, fresh-eye review) belongs in a subagent's clean window. Orchestrator's attention budget is too valuable to spend on tool churn.
