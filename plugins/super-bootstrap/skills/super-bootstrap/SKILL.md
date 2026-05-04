---
name: super-bootstrap
description: "Public entry for the super-bootstrap pipeline. Detects greenfield repos and runs lean ideation Q&A — produces overview.md, techstack.md, and a backlog.md with one BIG roadmap item — then dispatches to /harness-bootstrap to install the harness. For repos with code, dispatches immediately. Solo dev workflow."
tags: [bootstrap, scaffold, ideation, greenfield, gate, meta]
---

# Super Bootstrap — Public Entry, Greenfield-Aware

The single command users invoke. Inspects the repo, decides whether ideation is needed, and dispatches to `/harness-bootstrap`. Greenfield repos get lean ideation first — `overview.md` + `techstack.md` + `backlog.md` (with one big "plan v1 roadmap" item to fuel the pipeline once harness is live) — then harness-bootstrap proceeds.

## Why a separate gate

`/harness-bootstrap` installs workflow + skeleton docs + curated picks. It assumes the repo already encodes intent (manifest, source files, README, OR seed docs). Greenfield repos have none of that — running harness-bootstrap on emptiness produces an empty harness. This skill seeds the missing intent (what / why / who / how at a high level) so harness-bootstrap has something to scaffold around.

For repos with code, this skill is a thin pass-through to `/harness-bootstrap`. The user could invoke `/harness-bootstrap` directly; `/super-bootstrap` is the safer default because it auto-routes.

## Phase 0: Detect greenfield

Mirror Phase 1 detection from `/harness-bootstrap` (manifest scan, source-file scan, README assessment) but invert the conclusion.

**Greenfield = ALL of:**
- No manifest at repo root (no `package.json` / `pyproject.toml` / `requirements.txt` / `Cargo.toml` / `go.mod` / `Gemfile` / `pom.xml` / `build.gradle` / `composer.json` / `pubspec.yaml` / `CMakeLists.txt` / `Makefile` / `*.csproj` / `*.sln` — illustrative).
- No source files of any extension (excluding `.md`, `.txt`, `.gitignore`, `LICENSE`).
- No `README.md` OR `README.md` has fewer than 3 substantive lines (lines that aren't headings, blank, or boilerplate badges).
- No `docs/overview.md` AND no `docs/techstack.md` (if these exist from a prior `/super-bootstrap` greenfield run, treat as non-greenfield — pick up where left off, dispatch to harness).

Any of these absent → **non-greenfield**, skip to Phase 3 (dispatch).

## Phase 1: Greenfield ideation Q&A

Lean — match the harness skeleton sections only. Don't pre-fill grown sections (Architecture Rules / Coding Patterns / Module Index / Data Flow / Key Boundaries) — those grow from real code via doc-sync, not from speculation.

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

4. **External tools in your workflow?** — Multi-select. GitHub-only / Notion / Linear / Jira / Slack / Trello / ClickUp / other. Default GitHub-only. (Same as `/harness-bootstrap` Phase 2 Q4 — feeds Phase 3c MCP curation when harness runs.)

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

Use the template from `assets/overview-skeleton.md` in `/harness-bootstrap` (the harness skeleton is the source of truth — copy from there). Fill placeholders:

- `## Problem` body ← Q1 answer.
- `## User` body ← Q2 answer (+ Q6 if asked).
- `## Current State` body ← `greenfield` (literal — this is a fresh repo).
- `## Module Index`, `## Data Flow`, `## Key Boundaries` → keep as empty grown sections per skeleton — they fill via doc-sync once code lands.

If `docs/` doesn't exist, create it. If `docs/overview.md` already exists (re-run during ideation), present diff and ask before overwriting.

### `docs/techstack.md`

Use the template from `assets/techstack-skeleton.md` in `/harness-bootstrap`. Fill placeholders:

- `## Runtime` ← stack pick's runtime line (e.g. "Node.js 20+ (ESM)").
- `## Framework` ← stack pick's framework (e.g. "Next.js 14"). Drop the section if the user picked a no-framework option.
- `## Key Dependencies` ← top-level deps implied by the stack pick. Brief grouping (runtime / dev / test / build) with placeholder names if specifics aren't yet decided ("Tailwind for styling, TypeScript for types" rather than exhaustive list — this is a seed, not a manifest).
- `## Build & Distribution` ← commands implied by the stack pick (e.g. "`pnpm dev` / `pnpm build` / `vercel deploy`"). Mark as "to be confirmed when scaffolded" if commands aren't standard.
- `## Architecture Rules`, `## Coding Patterns`, `## Rejected Alternatives` → keep as empty grown sections per skeleton.

### `docs/backlog.md`

One BIG item — the roadmap-planning task. This is what makes greenfield bootstrap actually finish the loop: harness lives, but `/sb-todo` has fuel.

Write exactly this content (substitute `{Q1 summary}` from confirmed answer):

```markdown
# Backlog

Single tracker for deferred items — things found but not fixing now. Solo-dev queue. Scanned by doc sync at commit. When picking up new work, scan related items here to bundle.

**Three categories** distinguished by ID prefix:

- **`BUG-###`** — broken behavior with a clear fix. Routes direct to implementation.
- **`DEBT-###`** — working but rotting (test fixture rot, stale dep, cleanup owed). Routes direct to implementation.
- **`GAP-###`** — design gap, never properly specced. Routes through `superpowers:brainstorming` first, then spec → plan → execute.

Format per item: stable ID, short title, affected area, why it matters, proposed fix (BUG/DEBT) or what's missing (GAP). Newest at top. When resolved, **delete the item** — git history is the archive.

---

## Open

### GAP-001: Plan v1 roadmap

**Affected area:** whole product

**Why it matters:** bootstrap delivered overview + techstack but no feature breakdown / order / first-step. Without this, `/sb-todo` will report empty and the pipeline has no fuel.

**What's missing:** ordered feature list with rationale, first-feature spec, and first-feature plan.

**Route:** `superpowers:brainstorming` (this is a GAP — design exploration before implementation). Brainstorming should ground itself in `docs/overview.md` and `docs/techstack.md`. Output deliverables:

- This backlog file populated with feature breakdown (one item per feature, ordered, w/ rationale).
- First-feature spec at `docs/specs/{first-feature-slug}.md` (or `docs/superpowers/specs/` if the project doesn't scaffold persistent specs — the `/harness-bootstrap` Q&A decides).
- First-feature plan at `docs/superpowers/plans/{date}-{first-feature-slug}.md`.

After deliverables exist, delete this `GAP-001` item — `/sb-todo` will pick up the actual work from the populated backlog and first-feature spec/plan.
```

If `docs/backlog.md` already exists with content (re-run case), do NOT overwrite. Skip writing this file and warn the user that the existing backlog stays.

## Phase 3: Dispatch to `/harness-bootstrap`

Invoke `/harness-bootstrap` directly. It will detect the seed docs (`overview.md` + `techstack.md` exist), pre-fill its Phase 2 Q&A defaults from them, and proceed through scaffold → curate → sync → commit.

The handoff is **file-based**: this skill writes the seed docs and exits. `/harness-bootstrap` reads them on next invocation. No in-memory state, no tight coupling. User can pause between (ideate today, harness tomorrow) — the seed files persist.

For pre-existing repos (Phase 0 said non-greenfield), this whole skill collapses to a one-line announcement and immediate dispatch:

```
Detected non-greenfield repo (manifest + source files present).
Dispatching to /harness-bootstrap.
```

Then run `/harness-bootstrap`. Done.

## Principles

- **Lean Q&A, not PRD-mining.** Six questions max, four required. Skeleton-section depth only. Grown sections live for doc-sync, not pre-code speculation.
- **One BIG backlog item, not five candidates.** Bootstrap doesn't know the roadmap. Pretending it does (LLM-guessed feature list) is noise. Single deterministic next-action via `/sb-todo` → `/sp:brainstorming` is the route.
- **Files-as-contract handoff.** Write seed docs, exit. `/harness-bootstrap` consumes them. User can pause between phases.
- **Pre-exist repos: thin pass-through.** Non-greenfield → immediate dispatch. Don't add ceremony.
- **Never force harness on emptiness.** If user invokes `/harness-bootstrap` directly on truly empty repo, it redirects here. The redirect is one-way: this skill seeds, then dispatches. No infinite ping-pong.
- **Greenfield product ideation is in scope; greenfield product discovery is not.** Q&A produces enough seed for harness to live. Roadmap, market research, PRD generation belong elsewhere — this skill stops at "harness has fuel."
