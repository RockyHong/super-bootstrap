---
name: super-bootstrap
description: "Public entry for the super-bootstrap pipeline. Detects greenfield repos and runs lean ideation Q&A — produces overview.md (with empty § Roadmap), techstack.md, and an empty backlog.md — then dispatches to /super-bootstrap:harness-bootstrap to install the harness. For repos with code, dispatches immediately. Solo dev workflow."
tags: [bootstrap, scaffold, ideation, greenfield, gate, meta]
---

# Super Bootstrap — Public Entry, Greenfield-Aware

The single command users invoke. Inspects the repo, decides whether ideation is needed, and dispatches to `/super-bootstrap:harness-bootstrap`. Greenfield repos get lean ideation first — `overview.md` (with empty `## Roadmap` section) + `techstack.md` + empty `backlog.md` — then harness-bootstrap proceeds. Roadmap lives in overview (single pillar for "what product will become"); backlog stays scoped to BUG/DEBT/GAP and ships empty until shipped code surfaces deferrable items.

## Why a separate gate

`/super-bootstrap:harness-bootstrap` installs workflow + skeleton docs + curated picks. It assumes the repo already encodes intent (manifest, source files, README, OR seed docs). Greenfield repos have none of that — running harness-bootstrap on emptiness produces an empty harness. This skill seeds the missing intent (what / why / who / how at a high level) so harness-bootstrap has something to scaffold around.

For repos with code, this skill is a thin pass-through to `/super-bootstrap:harness-bootstrap`. The user could invoke `/super-bootstrap:harness-bootstrap` directly; `/super-bootstrap` is the safer default because it auto-routes.

## Phase 0: Detect greenfield

Mirror Phase 1 detection from `/super-bootstrap:harness-bootstrap` (manifest scan, source-file scan, README assessment) but invert the conclusion.

**Greenfield = ALL of:**
- No manifest at repo root (no `package.json` / `pyproject.toml` / `requirements.txt` / `Cargo.toml` / `go.mod` / `Gemfile` / `pom.xml` / `build.gradle` / `composer.json` / `pubspec.yaml` / `CMakeLists.txt` / `Makefile` / `*.csproj` / `*.sln` — illustrative).
- No source files of any extension (excluding `.md`, `.txt`, `.gitignore`, `LICENSE`).
- No `README.md` OR `README.md` has fewer than 3 substantive lines (lines that aren't headings, blank, or boilerplate badges).
- No `docs/overview.md` AND no `docs/techstack.md` (if these exist from a prior `/super-bootstrap` greenfield run, treat as non-greenfield — pick up where left off, dispatch to harness).

If ANY condition fails (a manifest exists, OR a source file exists, OR README has 3+ substantive lines, OR seed docs exist) → **non-greenfield**, skip to Phase 3 (dispatch).

## Phase 1: Greenfield ideation Q&A

Lean — match the harness skeleton sections only. Don't pre-fill grown sections (Architecture Rules / Coding Patterns / Module Index / Data Flow / Key Boundaries) — those grow from real code via doc-sync, not from speculation.

### Render surface

MCQ-shape (≤4 discrete options, no free text) → AskUserQuestion popup, one Q or small batch per call. Free text (Q1, Q6) + synthesis confirm → chat. Popup tool unavailable → fall back to chat-rendered MCQ, shape rules unchanged.

### Required questions

1. **What is this project? What problem does it solve?** — One paragraph in user's words. Feeds `overview.md` § Problem.

2. **Who uses it?** — End users / developers / internal team / library consumers / other. Feeds `overview.md` § User.

3. **Stack framing — pick a direction.** Based on Q1 + Q2, propose 2-3 stack options with one-line trade-offs each. LLM-driven proposal — judge the project category (web app / CLI / library / mobile / data pipeline / extension / desktop / other) and propose stacks fit for that category.

   Example shape (illustrative — adapt the actual options to the project):

   ```
   Detected category: web app, single-user, docs-heavy.

   Stack options:

     (a) Next.js 14 + Postgres + Vercel
         + Fast to prototype, good DX, strong ecosystem
         − SSR complexity if pivoting to static / SPA later

     (b) SvelteKit + SQLite + Cloudflare Pages
         + Lighter runtime, edge-friendly, simpler mental model
         − Smaller ecosystem, fewer hires-ready devs (irrelevant solo)

     (c) Astro + MD content + GitHub Pages
         + Cheapest to host, content-first, zero backend
         − Locked out of dynamic features without rework

   Pick (a/b/c), or describe alternative.
   ```

   User picks → feeds `techstack.md` § Runtime + § Framework + § Build & Distribution.

4. **External tools in your workflow?** — Multi-select. GitHub-only / Notion / Linear / Jira / Slack / Trello / ClickUp / other. Default GitHub-only. (Same as `/super-bootstrap:harness-bootstrap` Phase 2 Q4 — feeds Phase 3c MCP curation when harness runs.)

### Optional follow-up

5. **Distribution channel?** — Where does this ship? npm / PyPI / cargo / web / app store / private / other. Feeds `techstack.md` § Build & Distribution.

6. **ICP one-liner?** — Ideal customer / user one-liner if Q2 didn't capture it. Optional. Feeds `overview.md` § User as an addendum.

Stop here. Do **not** ask about features, architecture, file structure, error handling, naming conventions — those grow from code, not pre-code Q&A.

### Confirmation

After Q&A, surface a one-line synthesis and one yes/no:

```
Project: {Q1 summary}
User: {Q2 summary}
Stack: {Q3 pick}
Tools: {Q4 list}
Distribution: {Q5 if asked}

Sound right? (y / push back to fix specific item)
```

Wait for confirmation before writing files.

## Phase 2: Write seed files

Three files. Each writes to its target path with placeholders filled from Q&A.

### `docs/overview.md`

Use the template from `assets/overview-skeleton.md` in `/super-bootstrap:harness-bootstrap` (the harness skeleton is the source of truth — copy from there). Fill placeholders:

- `<!-- harness-meta -->` block `external-tools:` ← Q4 multi-select answer as YAML list (e.g. `[github, notion]`; default `[github]`). Keep comment block at top; `/super-bootstrap:resolve-plugins` Phase 1 reads it as Tier-2 fallback when no pinned MCPs encode workflow signal.
- `## Problem` body ← Q1 answer.
- `## User` body ← Q2 answer (+ Q6 if asked).
- `## Current State` body ← `greenfield` (literal — this is a fresh repo).
- `## Roadmap` → keep empty (skeleton blurb only). User fills via `/brainstorm` (spec presence drives todo pickup) or hand-edits names; `/super-bootstrap:todo` surfaces first unstarted entry as `Brainstorm:` row.
- `## Module Index`, `## Data Flow`, `## Key Boundaries` → keep as empty grown sections per skeleton — they fill via doc-sync once code lands.

If `docs/` doesn't exist, create it. If `docs/overview.md` already exists (re-run during ideation), present diff and ask before overwriting.

### `docs/techstack.md`

Use the template from `assets/techstack-skeleton.md` in `/super-bootstrap:harness-bootstrap`. Fill placeholders:

- `## Runtime` ← stack pick's runtime line (e.g. "Node.js 20+ (ESM)").
- `## Framework` ← stack pick's framework (e.g. "Next.js 14"). Drop the section if the user picked a no-framework option.
- `## Key Dependencies` ← top-level deps implied by the stack pick. Brief grouping (runtime / dev / test / build) with placeholder names if specifics aren't yet decided ("Tailwind for styling, TypeScript for types" rather than exhaustive list — this is a seed, not a manifest).
- `## Build & Distribution` ← commands implied by the stack pick (e.g. "`pnpm dev` / `pnpm build` / `vercel deploy`"). Mark as "to be confirmed when scaffolded" if commands aren't standard.
- `## Architecture Rules`, `## Coding Patterns`, `## Rejected Alternatives` → keep as empty grown sections per skeleton.

### `docs/backlog.md`

Copy `assets/backlog.md` from `/super-bootstrap:harness-bootstrap` unchanged — empty `## Open` section, no seed item.

Backlog owns BUG/DEBT/GAP only ("found-but-deferred in existing system"). Forward features → `docs/overview.md` § Roadmap (single pillar, SSoT). Greenfield ships an empty backlog because there's no shipped system yet to defer items from.

If `docs/backlog.md` already exists with content (re-run case), do NOT overwrite. Skip writing this file and warn the user that the existing backlog stays.

### Roadmap section in `docs/overview.md`

Phase 1 Q&A does NOT ask for feature breakdown — lean Q&A rule, not PRD-mining. The `## Roadmap` section ships **empty** in the seed (skeleton blurb only). Next action after bootstrap = user runs `/brainstorm` for first feature. Brainstorm produces a spec under `docs/superpowers/specs/`; `/super-bootstrap:todo` picks it up from file presence.

User can also hand-fill `## Roadmap` with feature names ahead of brainstorming — `/super-bootstrap:todo` surfaces the first unstarted entry as the next `Brainstorm:` row.

## Phase 3: Dispatch to `/super-bootstrap:harness-bootstrap`

After seed files are written (greenfield path) or immediately after Phase 0 returns non-greenfield, present a one-line summary and invoke `/super-bootstrap:harness-bootstrap` via the Skill tool. The harness will detect the seed docs (or existing manifest/source), pre-fill its Phase 2 Q&A defaults, and proceed through scaffold → curate → sync → commit.

The handoff is **file-based**: this skill writes the seed docs and exits. `/super-bootstrap:harness-bootstrap` reads them on next invocation. No in-memory state, no tight coupling. User can pause between (ideate today, harness tomorrow) — the seed files persist.

**Greenfield path — after writing seeds:**

```
Seed files written:
  - docs/overview.md
  - docs/techstack.md
  - docs/backlog.md

Dispatching to /super-bootstrap:harness-bootstrap to install the harness.
```

Then invoke `/super-bootstrap:harness-bootstrap` via the Skill tool.

**Non-greenfield path — Phase 0 returned non-greenfield:**

```
Detected non-greenfield repo (manifest + source files present).
Dispatching to /super-bootstrap:harness-bootstrap.
```

Then invoke `/super-bootstrap:harness-bootstrap` via the Skill tool.

If the user prefers to invoke harness manually later (e.g. wants to review seed files first), present the option: "Seeds written; ready when you are. Run `/super-bootstrap:harness-bootstrap` to continue, or pause and resume later." The seed files persist; nothing is lost by waiting.

## Principles

- **Lean Q&A, not PRD-mining.** Six questions max, four required. Skeleton-section depth only. Grown sections live for doc-sync, not pre-code speculation.
- **Backlog ships empty; roadmap is overview § Roadmap.** Backlog owns BUG/DEBT/GAP (existing-system deferrals); empty in greenfield. Forward feature list → `docs/overview.md` § Roadmap (single pillar). Roadmap fills via `/brainstorm` — brainstorm produces the first spec, file presence drives the next pickup; bootstrap exits with the skeleton blurb only.
- **Files-as-contract handoff.** Write seed docs, exit. `/super-bootstrap:harness-bootstrap` consumes them. User can pause between phases.
- **Pre-exist repos: thin pass-through.** Non-greenfield → immediate dispatch. Don't add ceremony.
- **Never force harness on emptiness.** If user invokes `/super-bootstrap:harness-bootstrap` directly on truly empty repo, it redirects here. The redirect is one-way: this skill seeds, then dispatches. No infinite ping-pong.
- **Greenfield product ideation is in scope; greenfield product discovery is not.** Q&A produces enough seed for harness to live. Roadmap, market research, PRD generation belong elsewhere — this skill stops at "harness has fuel."
