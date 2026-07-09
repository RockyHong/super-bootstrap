---
name: harness-bootstrap
description: "Install or sync the generic superpowers runway in any repo — greenfield or with code present. Scaffolds CLAUDE.md, skeleton docs (overview, techstack, superpowers/), path-scoped rules, and core plugin pins; bakes in doc-sync discipline. On greenfield it writes empty product skeletons; stack-matched skill/MCP/hook curation is gated tier-2, orchestrated by /super-bootstrap; opt-in earn-gated scale module (parked + test-queue containers, venue-map rule, backlog fact fields). Monorepo tier fans path-scoped rules out per package; adopt mode retires superseded harness forks on re-run. Solo dev workflow."
tags: [harness, scaffold, setup, meta, docs]
---

# Super Bootstrap — Superpowers Pipeline for Any Repo

Set up (or sync) the superpowers-driven development pipeline in a project. Installs harness — workflow rules, doc-sync gate, skeleton docs, core plugin pins — in one scaffold session. The doc-sync gate at every later commit grows the skeleton docs over time, so there's no deferred deep-scan stage.

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

### Monorepo detection

Check the repo root for a **workspace manifest** — the marker that one root hosts multiple packages (e.g. `pnpm-workspace.yaml`, `turbo.json`, `nx.json`, `lerna.json`, a `package.json` carrying a `"workspaces"` field, `Cargo.toml` with a `[workspace]` table — illustrative, judge by analogy). Present → set **monorepo tier**.

On monorepo tier, enumerate packages from the workspace globs (`apps/*`, `packages/*`, etc. — read the actual globs from the manifest, don't assume the layout). Each resolved directory with its own manifest is a package; record `{ name, path, role, build command }` per package for the Phase 2b `techstack.md` § Packages table rows (§ 2b) and the CLAUDE.md monorepo block.

Rule-signal detection (below) then **fans out per package** instead of scanning root-only: the frontend-component-dir signal is checked inside each package, and a fired signal seeds its rule file with a package-scoped path glob (`apps/*/src/components/**`) rather than a root glob (`src/components/**`). One path-scoped rule carries the whole boundary — no nested CLAUDE.md needed.

No workspace manifest → single-package repo; skip, everything stays root-scoped.

### Existing CLAUDE.md

If it exists, read it. The pipeline may already be partially or fully present — note what's already there. **Also note legacy-skeleton blocks** (Coding Standards code-block walls, framework-specific patterns under pipeline-owned headings, large Project Structure trees) — these become migration candidates in Phase 2b. Default route for enforcement-shaped content (imperatives, "must / never / always") is `.claude/rules/<scope>.md`; only browsable reference goes to `docs/techstack.md` grown sections. See Phase 2b migration table.

### Rule-signal detection

Phase 1 also flags which `.claude/rules/*.md` files Phase 2b should seed. Signals (illustrative — judge by analogy):

- **Frontend component dir** detected (e.g. `src/components/`, `src/pages/`, `app/`, `components/`) + framework manifest (React / Vue / Svelte / Angular / Solid) → seed `rules/<framework>.md` from `assets/rules-frontend-skeleton.md`.
- **Chrome MV3 manifest** (`manifest.json` with `"manifest_version": 3` + `service_worker` field) OR `src/background/` dir → seed `rules/mv3.md` from `assets/rules-mv3-skeleton.md`.
- **Migrations dir** (`migrations/`, `db/migrate/`, `prisma/migrations/`) → flag `rules/migrations.md` for body-fill via doc-sync (machinery-only seed at scaffold).
- **Tests dir** with non-trivial structure (`tests/`, `__tests__/`, `*.test.*` patterns) → flag `rules/tests.md` for body-fill via doc-sync.

On **monorepo tier** (§ Monorepo detection), each signal is evaluated **per package**, not root-only, and a fired signal's seeded glob is package-scoped (`apps/*/src/components/**`) so one rule file spans every package that shares the pattern.

**ECC-first seed source for language-scoped rules.** Before scaffolding from local `assets/rules-*-skeleton.md`, check ECC (`gh api repos/affaan-m/everything-claude-code/contents/rules`) for a matching language/framework rule. If ECC ships one, propose seeding from ECC (with attribution comment + license note) — defer to specialists. Local skeletons are the fallback. Cross-cutting / project-specific rules (e.g. MV3, custom service-worker patterns) stay on local skeletons.

Adjacent stacks (Bun + Next, Deno + Fresh, Tauri + React, etc.) infer by analogy. Unknown stacks → skip rule-seeding for that signal; user can add later.

**Output of Phase 1:** A mental model of "what kind of project is this" — stack name, structure shape, maturity level, **which rule files to seed in Phase 2b**, **which legacy CLAUDE.md sections need migration**. NOT a deep analysis.

### Greenfield (no seed docs)

The generic runway runs on greenfield. If Phase 1 detects no manifests + no source files + missing `docs/overview.md` / `docs/techstack.md`, scaffold normally and write `overview.md` / `techstack.md` as empty skeletons in Phase 2b. The entry `/super-bootstrap` seeds GAP cards against those empty skeletons and surfaces the gate.

When `docs/overview.md` + `docs/techstack.md` already carry substantive content, manifest facts and existing content feed the Phase 2b skeletons normally.

### Rot signals (harnessed-but-stale)

Catches "harness installed but carries renamed-away literals" — re-run is the right entry, flag before Phase 2b churns through migrations.

Trigger: any pipeline-owned file (`CLAUDE.md`, `docs/overview.md`, `docs/techstack.md`, `docs/superpowers/plans/bootstrap.md`, `.claude/rules/*.md`) contains a literal listed as `old` in `assets/rename-map.md`. Whole-token match; one hit is enough.

When the trigger fires, surface ONCE up front (single message, not a redirect — re-run is the correct entry point):

```
Renamed-away literals detected in pipeline-owned files.
Phase 2b will propose migrations alongside the normal drift check.
Affected files: {list of files where rot was observed}.

Continue? (y / dry-run report only)
```

If user answers `dry-run`, walk Phases 1–2b without writing — render the sync report (per-section listing + rename-map migration rows) inline without persisting `bootstrap-sync-report.md`, then exit. Otherwise proceed normally; Phase 2b's rot scan (see § 2b) handles the actual migrations.

**Output of Phase 1 (rot lane):** record `rot_hits[]` so Phase 2b can re-use the scan instead of grepping twice.

### Version-staleness signal (harnessed-but-stale)

Rot signals catch renamed literals; they miss template drift that shifted structure without renaming a token. The version stamp closes that gap.

Read `.claude/super-bootstrap-runway.json` in the target repo (the runway version marker — shape `{ "version": "x.y.z" }`). Compare its `version` to the running plugin's own version — read `version` from the plugin's `.claude-plugin/plugin.json`, located at the plugin root two directory levels above this skill's base directory (`skills/harness-bootstrap/` → `skills/` → plugin root). That is the version currently installing/syncing.

- **Marker matches plugin version** → normal path.
- **Marker stale (older) or absent** → set `version_stale`, consumed by Phase 2b to enforce the full drift check (see § 2b). Surface ONCE up front:
  - Stale: `runway stamped v{old} < plugin v{new} — full drift re-check enforced.`
  - Absent: `runway carries no version stamp — full drift re-check enforced.`

Detection only — Phase 1 reads the stamp's old value and stops; it does not act on the flag or alter its own scan. Phase 2c overwrites the stamp later, after sync completes.

**Output of Phase 1 (version lane):** record `version_stale` (plus the old/new version strings) for Phase 2b to consume.

---

The runway scaffolds with no product Q&A. Drift on existing files is resolved inline per-section at Phase 2b.

---

## Phase 2: Scaffold / Sync

Walk each pipeline artifact in order: folders → pipeline docs → sync report + commit. Same flow on fresh and re-run repos — fresh just sees "all new" at every step.

**Per-artifact rule** (applied uniformly in 2a / 2b):
- Missing → write from template / curate fresh
- Exists, matches template → skip (`✓ current`)
- Exists, drifted from template → show diff, get approval per change, then write
- Project-owned content → never touch, even on drift

**Pipeline-owned** (subject to drift check):
- CLAUDE.md sections: Development Workflow, Dispatch, Doc Sync, Coding Principles, Edit Discipline, Context Hygiene, Finding Triage, Rules, Git Notes, Planning, Monorepo (monorepo tier only — the conditional cross-package build block)
- `docs/techstack.md` skeleton sections: Runtime, Framework, Key Dependencies, Build & Distribution, Edit Discipline, Packages (monorepo tier only — the § header + column shape; table rows are consumer-grown, project-owned)
- `docs/overview.md` skeleton sections: Problem, User, Current State
- `docs/decisions.md` scope header (the blockquote + `## Closed Forks` heading)
- `docs/superpowers/specs/`, `docs/superpowers/plans/`, `docs/superpowers/plans/bootstrap.md`
- `.claude/rules/index.md` (rule-authoring guide)
- `.claude/rules/<seeded>.md` skeleton bodies (drift checked against `assets/rules-*-skeleton.md`)
- `.claude/settings.json` plugin pins (`enabledPlugins`, `extraKnownMarketplaces`)
- `.claude/super-bootstrap-runway.json` (runway version stamp — presence + value checked, not diffed section-by-section; read at Phase 1, written at 2c; durable marker, no cleaner — persists for the life of the harness)
- Scale module — checked only when installed (detected by `docs/parked.md` presence): `docs/parked.md` + `docs/test-queue.md` header/shape sections, `.claude/rules/venue-map.md` skeleton body (drift-checked against `assets/scale/rules-venue-map-skeleton.md`), the `docs/backlog.md` fact-fields marker block (`<!-- scale-module: fact fields -->` … `<!-- /scale-module -->`)

**Project-owned** (never touched):
- CLAUDE.md: Tech Stack one-line, Commands, any user-added custom sections
- `docs/techstack.md` grown sections: Architecture Rules, Coding Patterns
- `docs/overview.md` grown sections: Module Index, Data Flow, Key Boundaries
- `docs/decisions.md` § Closed Forks table rows (consumer-filled history)
- `.claude/rules/<rule>.md` grown sections (additions the user/doc-sync added below the skeleton scaffold)
- `.claude/rules/<rule>.md` files the user authored without a matching skeleton (treat as fully project-owned)
- Scale-module container content — `docs/parked.md` `## Entries` + `## Sweep log` content, `docs/test-queue.md` `## Pending` / `## Failed (re-queued for fix)` rows (consumer-filled, like backlog rows; only the skeleton headers/shape stay pipeline-owned)
- Other settings in `.claude/settings.json` outside the plugin-pin keys

### 2a: Folders & core plugin pin

Folders + core plugin pin don't drift — only two states: missing or present.

**Always created (fixed macro):**
```
docs/
  decisions.md   ← closed forks / rejected directions (history dimension — always scaffolded, starts empty)
  backlog.md     ← backlog tracker (BUG / DEBT / GAP — capture-first, triaged on pickup)
  superpowers/
    specs/       ← design specs from brainstorming (temporal)
    plans/       ← implementation plans (temporal)
.claude/
  rules/         ← path-scoped rules, full-body fires on file match
    index.md     ← rule-authoring guide (path-scoped — loads when editing rules)
```

**Created when source code is present (adaptive):**
```
docs/
  specs/         ← persistent feature specs, one .md per feature (seeded by Task 1 of bootstrap-plan)
```

For each: create if missing, skip if present. Add `.gitkeep` in empty folders. If `docs/` or `.claude/` already exists, nest alongside. Report status per directory.

`docs/specs/` is scaffolded as an empty folder with `.gitkeep`. There is no index file — the folder + filename convention IS the catalog. Spec files are seeded by Task 1 of the bootstrap plan, each opening with `# {Feature Name}` and a one-paragraph intro.

**Hard gate — `docs/specs/` requires source-code features to document.** Scaffold `docs/specs/` only when the repo has feature modules in source code. **No source files → skip it** (e.g. a greenfield repo: `overview.md`/`techstack.md` present, no code). A `docs/specs/` file with no built feature behind it is speculative, and invisible to `/super-bootstrap:todo`.

`docs/decisions.md` is **always** scaffolded — copy `assets/decisions-skeleton.md` to `docs/decisions.md` if missing (no substitutions). Starts empty (header + `## Closed Forks` table). Its scope header is pipeline-owned (drift-checked); the table rows are project-owned (never touched).

Copy `assets/backlog.md` to `docs/backlog.md` if missing (no substitutions).

`.claude/rules/` machinery is **always** scaffolded (zero-cost when empty). `index.md` is seeded from `assets/rules-index-skeleton.md`. Individual rule bodies fill in Phase 2b based on Phase 1 signal detection.

**Core plugin pins (pre-resolve).** The harness CLAUDE.md skeleton names two skills by trigger rule:

- `superpowers` — slash-command routes (`/brainstorm`, `/write-plan`, `/execute-plan`).
- `karpathy-guidelines` — invoked before every code edit (see CLAUDE.md § Coding Principles).

Both are **core deps, not adaptive picks** — pinned here at 2a so tier-2 curation (`/super-bootstrap:resolve-plugins`, run later by `/super-bootstrap`) layers adaptive picks on a guaranteed base. Dangling-rule risk: if CLAUDE.md names a skill that isn't installed, the trigger rule misfires silently. Pin first.

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

`superpowers@claude-plugins-official` resolves from Anthropic's official marketplace — no `extraKnownMarketplaces` entry needed. `andrej-karpathy-skills@karpathy-skills` lives outside the official marketplace, so the `karpathy-skills` marketplace entry is required for cloud / fresh-machine resolution. Tier-2 curation (`/super-bootstrap:resolve-plugins`) treats both pins as locked: never proposes drop, never re-prompts the user. Adaptive picks (stack-matched skills / MCPs / hooks) layer on top when curation runs.

### 2a-hooks: Harness hooks (default-on)

Three hook assets ship as frozen files and install **unconditionally** — no
opt-in confirm, unlike drain's worktree infra (§2a-drain below); all are
safe-by-default (rationale + full procedure:
[`assets/hooks-ensure-infra.md`](assets/hooks-ensure-infra.md)).

| # | Asset | Fires on | Effect |
| - | - | - | - |
| 1 | `harness-grounding` (PreToolUse) | `Edit\|Write` matched to a harness path (`CLAUDE.md`, `.claude/rules/**`, `.claude/skills/**`, `.claude/agents/**`) | Inject a 2-3 line grounding checklist via `additionalContext` — never denies |
| 2 | `entry-nudge` (UserPromptSubmit) | every prompt (no matcher) | Inject one card-grounded-entry pointer line via `additionalContext` — injector-only, never blocks, never exits non-zero |
| 3 | `commit-channel` (PreToolUse) | `Bash(git commit *)` | Deny raw `git commit` from any subagent other than the commit agent (namespaced or bare) — deny text routes the worker back to `/super-bootstrap:commit`; main session and separate-process workers pass. Doc-sync runs in-process in that commit door — no separate gate hook |

Execute the procedure in [`assets/hooks-ensure-infra.md`](assets/hooks-ensure-infra.md) — copies the three scripts to `.claude/hooks/` and merges the settings snippets into `.claude/settings.json` (`hooks.PreToolUse[]`: harness-grounding, commit-channel; `hooks.UserPromptSubmit[]`: entry-nudge). Content-aware (copy-on-drift — a version-marker mismatch re-copies the asset, so an upstream fix reaches existing repos), silent when already current; stage the placed files with the Phase 2c commit. Same asset-copy + guarded-merge mechanism as drain's `read-hook.json` (`../drain/assets/ensure-infra.md` step 3) — one pattern, reused here rather than re-derived.

### 2a-drain: Drain infra (opt-in)

`/super-bootstrap:drain` (parallel-worktree auto-drain) needs three committed infra pieces. Most active-dev repos use drain; skill / plugin / docs-only repos usually don't. Ask once:

> Install `/super-bootstrap:drain` worktree infra? — worktree settings template + `PreToolUse(Read)` guard + `.claude/worktrees/` gitignore. Most dev repos: yes. Skill / plugin / docs repos: skip (drain self-installs on first use anyway).
> Install now? (y / skip)

On `y`: execute the procedure in [`../drain/assets/ensure-infra.md`](../drain/assets/ensure-infra.md) — the same idempotent 4-piece install drain self-runs on first invocation. One install home; harness-bootstrap delegates to it, never carries its own copy. Stage the placed files with the Phase 2c commit.

On `skip`: nothing placed; drain's own §Pre-flight step 0 installs on first `/super-bootstrap:drain`.

### 2a-scale: Scale module (opt-in, earn-gated)

The scale module adds backlog-adjacent runway — a parked-items artifact, a manual-verification queue, and a phase→venue map — for repos whose backlog has outgrown one flat list. Earn-gated: offer only when a signal shows the repo has grown into it, silent skip otherwise (no prompt spam on small repos).

Signals — any one arms the offer:
- Open `docs/backlog.md` rows ≥ 10.
- Drain worktree infra installed (`.claude/worktrees/` gitignore present — the module's venue map feeds drain's dispatch-vs-wall filter).
- User asked for it.

None hold → skip silently, place nothing. A later re-run re-offers once a signal fires.

When armed, ask once:

> Install the scale module? — `docs/parked.md` (deferred items with named triggers) + `docs/test-queue.md` (manual-verification queue) + `.claude/rules/venue-map.md` (phase → run-location map, feeds `/super-bootstrap:todo` + `/super-bootstrap:drain`) + backlog fact-field guidance.
> Install now? (y / skip)

On `y`, place the four `assets/scale/` skeletons per Phase 2's per-artifact rule (all copy verbatim — no substitutions):
- `parked-skeleton.md` → `docs/parked.md`
- `test-queue-skeleton.md` → `docs/test-queue.md`
- `rules-venue-map-skeleton.md` → `.claude/rules/venue-map.md`
- `backlog-fact-fields.md` → insert its marker-delimited block (`<!-- scale-module: fact fields -->` … `<!-- /scale-module -->`) into the `docs/backlog.md` header, immediately after the `---` divider that follows the Row-shape fenced block, before `## Open`; skip if the markers are already present.

Add one summary bullet to CLAUDE.md § Rules for the seeded `venue-map.md` (existing mechanism — glob + 2–4 one-line key points). Stage the placed files with the Phase 2c commit.

On `skip`: nothing placed; a re-run re-offers while a signal holds.

### 2b: Pipeline docs

Walk each pipeline doc and apply the per-artifact rule. Sources:

| Asset | Destination | Notes |
|---|---|---|
| `assets/claude-md-skeleton.md` | `CLAUDE.md` (project root) | Includes Rules summary section — fill bullets from seeded rule files |
| `assets/techstack-skeleton.md` | `docs/techstack.md` | Coding Patterns grown section absorbs migrated CLAUDE.md content |
| `assets/overview-skeleton.md` | `docs/overview.md` | `<!-- harness-meta -->` block at top: seed `external-tools:` as a YAML list defaulting to `[github]`. Read by `/super-bootstrap:resolve-plugins` (tier-2 curation) as the external-tools source. Update manually or via the entry skill when the tool list changes. Treat as pipeline-owned for drift checks. |
| `assets/decisions-skeleton.md` | `docs/decisions.md` | Always — scope header pipeline-owned (drift-checked), `## Closed Forks` table rows project-owned |
| `assets/bootstrap-plan.md` | `docs/superpowers/plans/bootstrap.md` | |
| `assets/rules-index-skeleton.md` | `.claude/rules/index.md` | Always — machinery |
| `assets/rules-frontend-skeleton.md` | `.claude/rules/<framework>.md` | Only if frontend signal fired in Phase 1 |
| `assets/rules-mv3-skeleton.md` | `.claude/rules/mv3.md` | Only if MV3 signal fired in Phase 1 |

On greenfield (no manifest, no source files), `overview.md` / `techstack.md` write as unfilled skeletons — manifest-derived facts fill only when code is present. The empty skeleton is intentional: it is the unsolved-product state the entry `/super-bootstrap` detects to seed GAP cards.

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

**The drift check is produce-then-judge — enumerate first, read the verdict off the rows.** The per-section enumeration is the *first* output, written to the sync-report artifact `docs/superpowers/plans/bootstrap-sync-report.md` before any "current / drifted" conclusion exists. Per pipeline-owned file in scope, append one row per applicable § Pipeline-owned section: section name, line range in the existing file, verdict (`✓ matches` / `⚠ drifted` / `⊕ new`), and — for drifted rows — the diff. The verdict is a column filled while enumerating, never a headline asserted over the file: there is no "all current" to state until every row is written. Overwrite any stale report from a prior run.

**Version-stale enforcement.** When Phase 1 set `version_stale`, this enumeration is mandatory in full this run — every pipeline-owned section gets an actual read-and-compare row; the "sections look similar → `✓ current`" skim is forbidden. No new mechanism — the 2c gate already refuses commit on any uncovered section (see § 2c). Print the Phase 1 surfaced line once at the top of Block 1 as the reminder.

Block 1 (shown to the user, rendered from the report — one row per pipeline-owned section in the file):

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

The report is the forcing function: Phase 2c refuses to commit unless it exists and carries a row for every pipeline-owned section in scope (§ 2c gate). A collapsed "skeleton sections match" with no rows fails that gate mechanically — there is no assertion to trust, so there is nothing to collapse into one. Drift approval (Block 2) protects against (a) legit template updates the user wants to review and (b) bad-actor template injection on a future re-run — you see what's about to change before it's overwritten.

**Rot scan (mandatory pre-step on re-run).** Before Block 1 renders, read `assets/rename-map.md` and grep every pipeline-owned file in scope for each entry's `old` literal (whole-token match — avoid URL / identifier false hits). Each hit becomes a rot row appended to `bootstrap-sync-report.md` and surfaced to the user:

```
{file path}:{line} — stale literal `{old}` → propose `{new}`
  Reason: {map entry reason}
```

Acceptance pattern matches legacy migration: `y / n / per-row`. The rot scan runs even when every per-section diff is `✓ current` — a stale slash command literal inside a current-shaped doc is invisible to per-section diff (template hasn't drifted; only the literal inside it has). Together, per-section diff + rot scan cover both axes of drift: section shape AND inline literals.

**Backlog ID re-plant (re-run, if `docs/backlog.md` predates the ID scaffold).** A backlog from an older super-bootstrap version may carry `## Open` rows without `BUG/DEBT/GAP-###` IDs, or be missing the header's ID high-water-mark line. harness-bootstrap is the sole write owner for retroactive ID assignment — `/super-bootstrap:todo` flags it read-only, `/super-bootstrap:log` defers here. Detect: `docs/backlog.md` exists, has row content under `## Open`, and either no high-water line or un-IDed rows. When detected, surface:

```
docs/backlog.md predates the ID scaffold — {N} un-IDed rows / missing high-water line.
Re-plant assigns canonical BUG/DEBT/GAP IDs and rebuilds the high-water counter.

Re-plant? (y / n / dry-run)
```

On `y`: rebuild the high-water mark from `git log --grep` over consumed IDs — **never from current open rows** (resolved-but-deleted IDs stay consumed; re-deriving from open rows collides). Then mint IDs onto un-IDed rows by category, per the high-water-mark rule documented in the `docs/backlog.md` header (the rule's SSoT — don't restate the algorithm), classifying each row into BUG/DEBT/GAP by its content. Preserve row claims verbatim — re-plant adds the ID heading only, never rewrites the claim. Stage `docs/backlog.md` with the 2c commit.

**Special case — `docs/techstack.md` § Rejected Alternatives retirement (re-run).** Older skeletons grew a § Rejected Alternatives section inside `techstack.md` — state/history dimension pollution, and tech-scoped. It is retired in favor of `docs/decisions.md` (cross-domain history dimension). On re-run, if `techstack.md` carries a § Rejected Alternatives section with content, propose migrating it:

```
docs/techstack.md § Rejected Alternatives detected — retired section (dimension pollution).
Propose: move its entries to docs/decisions.md § Closed Forks (domain: tech), remove the section.

Migrate? (y / n / show entries)
```

On `y`: append each entry as a `tech`-domain row in `docs/decisions.md` (preserve the claim verbatim, add a commit-pointer Ref where one is obvious), then delete the section from `techstack.md`. On `n`: leave it, mark project-owned (no further drift attempts). Never destructive without confirmation.

**Special case — `bootstrap.md`** carries user state (checkbox progress from prior session). Don't auto-merge. Prompt: **Keep existing** (default) / **Reset from template** / **Merge** (rare, task-by-task).

**Special case — `bootstrap.md` missing on mature repo.** When the file is **missing** AND the repo has ≥5 commits past the most recent bootstrap-shaped commit (`chore: scaffold superpowers pipeline` / `chore: sync superpowers pipeline` / `chore: complete pipeline bootstrap`), don't silently re-template — the file was almost certainly Task-3-cleanup-deleted by a prior session, and re-templating resurfaces completed work as fresh tasks. Surface an advisory instead:

```
docs/superpowers/plans/bootstrap.md is missing.
Repo has {N} commits since last bootstrap-shaped commit ({sha} — {date}).
File was likely cleanup-deleted (Task 3 of prior bootstrap).

Options:
  (a) skip re-seed (bootstrap complete)        ← default
  (b) re-seed (Tasks 1/2 still applicable)
  (c) re-seed cleanup-only (Task 3 stub for next session)
```

Fresh repos (no bootstrap-shaped commit yet) keep current behavior — write from template, no advisory.

**Placeholders:**
- `{Project Name}` — repo name
- `{date}` — today's date
- Manifest detection facts (Runtime / Framework / Key Dependencies / Build & Distribution) → fill into CLAUDE.md Tech Stack one-liner AND `techstack.md` skeleton sections
- Problem / User / Current State (`overview.md` skeleton sections) → left empty at install; filled at GAP-card pickup, not by the runway
- Bracketed conditional lines `{- docs/specs/ — ...}` — keep only if the corresponding adaptive doc is scaffolded for this repo (specs per the 2a code-presence gate, backlog always); drop the whole line otherwise
- **Monorepo tier** (Phase 1 § Monorepo detection) — fill CLAUDE.md's conditional monorepo block (workspace tool + the workspace-aware filtered build command) and `techstack.md` § Packages table rows (package | path | role | build command) from the Phase 1 package enumeration. Single-package repo → drop the CLAUDE.md monorepo block and the § Packages section entirely
- CLAUDE.md § **Rules** summary bullets — fill from seeded `.claude/rules/*.md` files (one bullet per rule with glob + 2-4 one-line key points). If no rules seeded, drop the example placeholders and keep only the explanatory paragraph.
- Rule skeleton placeholders (`{component path glob}`, `{Framework}`, body bullets in `assets/rules-*-skeleton.md`) → fill from Phase 1 detection. Lines that don't apply get dropped during scaffold.

**Bootstrap-plan task adaptation:**

The slim plan is `Task 1: Seed feature specs` / `Task 2: Seed backlog` / `Task 3: Cleanup`. Adapt at write time:

- `docs/specs/` NOT scaffolded → drop Task 1
- No source-code features yet (greenfield / fresh scaffold, Module Index empty) → drop Task 1 — specs document built features; none exist to seed
- Re-run with `docs/specs/` already populated → drop Task 1
- Re-run with `docs/backlog.md` already populated → drop Task 2
- Add tasks for any project-specific needs surfaced during Phase 1 detection
- Task 3 (Cleanup) always retained — includes deleting `docs/superpowers/plans/bootstrap.md` and `docs/superpowers/plans/bootstrap-sync-report.md` if a prior session left it

If both Task 1 and Task 2 drop, the plan becomes Task 3 (cleanup) only — that's fine, signals bootstrap is essentially complete.

Tech curation (skill / MCP / hook picks) is gated tier-2 — orchestrated by `/super-bootstrap` after `overview.md` / `techstack.md` are substantive, not during this runway install.

### 2b-adopt: Superseded-fork adoption (migration, silent-skip)

Migration machinery for repos that **forked the harness before this plugin existed** — they carry their own copies of skills/agents the plugin now ships as root artifacts (a local `commit` / `merge` / `log` / `todo` / `drain` skill + agent that the installed plugin supersedes). On re-run, offer to delete the superseded forks so the single root copy takes over. Repos with no such collision see nothing — silent skip, like § 2a-scale.

**Superseded-artifact map — derived at runtime, never hardcoded.** Enumerate the plugin's own shipped skills and agents from the install: the plugin's `skills/<name>/` directory names + `agents/<name>.md` basenames, read at the plugin root two directory levels above this skill's base dir (same anchor as the Phase 1 version-stamp read). That listing IS the map — it tracks the plugin as its skill/agent set grows, so no static list drifts.

**Collision detection.** In the consumer repo, scan `.claude/skills/<name>/` directories and `.claude/agents/<name>.md` files. A consumer artifact whose **name** matches a shipped skill/agent name is a superseded-fork candidate — the installed root copy supersedes it. Name-non-colliding consumer skills/agents are **project delta** — never touched, never listed, never surfaced.

None collide → place nothing, surface nothing.

When candidates exist, surface the full list with a per-deletion confirm — each row maps the consumer path to the root artifact that supersedes it:

```
Superseded harness forks detected — the installed plugin now ships these:

  .claude/skills/commit/   → superseded by the plugin's `commit` skill (/super-bootstrap:commit)
  .claude/agents/todo.md   → superseded by the plugin's `todo` agent
  ... (one row per collision: consumer path → superseding root artifact)

Delete the forked copies? (y = all / n = none / per-item)
```

`per-item` walks one candidate at a time (`y` / `n` each). **Never auto-delete** — every deletion is an explicit confirm.

Per-candidate handling:
- **Approve** → remove the consumer copy (`git rm -r` the skill dir / `git rm` the agent file; plain delete + stage where the path is untracked). Stage the deletion with the Phase 2c commit.
- **Reject** → leave it in place; a later re-run re-offers.

### 2c: Sync report + commit

**Gate — the sync report must exist and cover every pipeline-owned section before commit.** Read `docs/superpowers/plans/bootstrap-sync-report.md` and cross-check its per-section rows against § Pipeline-owned: every pipeline-owned section that applies to a file in scope must have a row. Missing file, or any uncovered section → halt, return to 2b, produce the missing rows. This is a Read + set-difference check, not a self-attestation — a skipped drift check leaves no rows to find, so it cannot pass the gate.

**Sync report** — rendered from the artifact (the file is canonical; this table is its commit-time view). Always shown before commit. Fresh repos see "all new"; re-run repos see drift fixes and current items.

```
| Artifact                            | Status       | Action              |
|-------------------------------------|--------------|---------------------|
| CLAUDE.md: Doc Sync                 | ✓ current    | —                   |
| docs/techstack.md: Runtime          | ⚠ drifted    | updated (approved)  |
| .claude/rules/mv3.md                | ⊕ new        | seeded (signal: MV3 manifest) |
```

**Stamp write.** Once the sync completes, write `.claude/super-bootstrap-runway.json` = `{ "version": "{current plugin version}" }` — fresh install writes it new, re-run overwrites with the just-synced version. Present + value-checked, so a matching stamp is a no-op write. This runs even when every other row is `✓ current` — the stamp records "last synced at this version," independent of whether content changed.

If every row is `✓ current` and nothing changed on disk, report and skip the commit.

Otherwise use `/super-bootstrap:commit` to stage:
- `CLAUDE.md` (new, modified, or post-migration)
- `docs/techstack.md` (new, skeleton-section drift, or post-migration absorbed content)
- `docs/overview.md` (new or skeleton-section drift)
- `docs/decisions.md` (new, scope-header drift, or post-retirement migration from techstack)
- `.claude/settings.json` (core plugin pins seeded at 2a; harness hooks merged at 2a-hooks)
- `.claude/hooks/harness-grounding.sh`, `.claude/hooks/entry-nudge.sh`, `.claude/hooks/commit-channel.sh` (frozen hook scripts seeded at 2a-hooks — always, default-on)
- `.claude/rules/index.md` (always — at minimum machinery seed)
- `.claude/rules/<seeded>.md` (any rule files newly seeded or migrated to)
- `docs/superpowers/specs/.gitkeep`
- `docs/superpowers/plans/.gitkeep`
- `docs/superpowers/plans/bootstrap.md` (if newly written or regenerated)
- `docs/specs/.gitkeep` (if scaffolded)
- `docs/backlog.md` (if scaffolded, re-planted, or fact-fields block inserted this run at 2a-scale)
- `docs/parked.md`, `docs/test-queue.md`, `.claude/rules/venue-map.md` (scale-module targets — only if installed this run at 2a-scale)
- `.claude/super-bootstrap-runway.json` (runway version stamp — written/overwritten every sync)
- Superseded-fork deletions (adopt mode, § 2b-adopt) — staged removals of approved consumer `.claude/skills/<name>/` dirs / `.claude/agents/<name>.md` files that root artifacts now supersede
- Any other adaptive files / folders created

Commit message: `chore: scaffold superpowers pipeline` on fresh repos, `chore: sync superpowers pipeline` when only drift fixes shipped, `refactor: migrate CLAUDE.md to rules layer + sync pipeline` when re-run performed legacy migration.

**Clean the run artifact.** `bootstrap-sync-report.md` is a transient diagnostic — never staged. After the commit lands (or after reporting no-changes), delete it: its consumer is this phase, so this phase is its cleaner. (Task 3 cleanup removes it too, as a safety net if a session broke between 2b and here.)

---

## Phase 3: Handoff

After committing (or reporting no changes needed), present results based on repo state:

**First-run (just scaffolded):**

> **Generic runway installed.** CLAUDE.md drives workflow. Skeleton `docs/techstack.md` and `docs/overview.md` carry detected facts (empty on greenfield) — grown sections fill via doc-sync as features land. Core plugin pins (superpowers + karpathy) sit in `.claude/settings.json`; stack-matched skill / MCP / hook picks come when `/super-bootstrap` runs gated tier-2 curation.
>
> {If product skeletons are empty (greenfield): "`docs/overview.md` / `docs/techstack.md` are empty skeletons — `/super-bootstrap` seeds GAP cards for them and surfaces the resolve gate."}
>
> {If any rule files were seeded: "Path-scoped rules seeded in `.claude/rules/` ({list seeded rules}). They auto-load on file match — full ammo at the decision moment, summary mirrored in CLAUDE.md § Rules. Add more rule files when path-scoped patterns emerge."}
>
> {If bootstrap.md has Task 1 / Task 2 active: "Optional adaptive seeding queued in `docs/superpowers/plans/bootstrap.md` (specs / backlog). Next session: `/clear`, then `/super-bootstrap:todo`."}
> {If bootstrap.md is cleanup-only: "Bootstrap essentially complete — `/super-bootstrap:todo` will show the cleanup task."}

**Re-run / sync pass:**

> **Pipeline synced.** {N items updated, M already current.}{If migration performed: " Migrated {sections moved} from CLAUDE.md to {destinations} — `CLAUDE.md` now {old line count} → {new line count} lines."}{If rule files added: " Rules: +K seeded, summary updated in CLAUDE.md § Rules."}

## Principles

- **Layer by decision-moment** — every rule has a moment-of-need: ambient (CLAUDE.md, every turn) for workflow + always-true safety; path-scoped (`.claude/rules/`, fires on file match) for full-body precision when relevant; on-demand (`docs/techstack.md`, `docs/specs/`) for reference Claude reads when intent surfaces. Skills are for thinking modes / structured processes — **not** a rule-storage layer.
- **Precision per always-on byte** — every CLAUDE.md line answers "what decision does this sharpen, at what moment?" Length is downstream of that. The Anthropic / community ~120-line target is a smoke alarm on bloat, not a hard cap. Sweet-spot session quality (~80k context = 100% recall) requires the orchestrator brief stays lean enough that opening file reads + workflow + actual task fit.
- **Default-to-rules when ambiguous** — enforcement-shaped content (imperatives: must / never / always) goes to `.claude/rules/<scope>.md` even when the heading sounds like reference. Silent-miss in a cold file costs more than slight over-attach.
- **Subagent dispatch protects orchestrator focus** — verbose work (10+ file reads, noisy test runs, parallel-safe chunks, fresh-eye review) belongs in a subagent's clean window. Orchestrator's attention budget is too valuable to spend on tool churn.
- **Mandatory checks ride a forcing function, not prose** — a step the model is merely told to "always run" collapses into a confident assertion on re-runs where the surface looks done. Encode it produce-then-judge: enumerate to a file first, then gate the downstream phase on that file's coverage (a Read + set-difference, not a self-attestation). This skill applies it at the drift check (2b → 2c); new mandatory steps take the same shape.
