# Pipeline Bootstrap Plan

> **For agentic workers:** Use `/todo` to see current progress. Each task is independent and session-sized.

**Goal:** Complete the superpowers pipeline setup for {project name}

**Context:** Pipeline scaffolded on {date}. Skeleton CLAUDE.md is live with workflow rules. These tasks complete the deep analysis and finalize the setup.

**Parallelism:** Tasks 1 and 2 are independent — can run in parallel sessions. Tasks 3, 4, 5, 6 all gate on 1 and/or 2. Each task's `Depends on:` line states its prerequisites.

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

Auto-curate Claude Code tooling matched to detected stack AND product context. Harness-internal — user sees one batch, replies. No manual search, no plugin install gate.

**Depends on:** Task 1 (stack-matched picks — language/framework skills, runtime MCPs) and Task 2 (product/project-level picks — Notion / Linear / Jira / Slack / GitHub MCPs based on workflow context)

**Process — automated:**

1. **Take detected stack from Task 1** — runtime, framework, key tools, project size, monorepo state. Drives stack-matched picks (e.g. `react-expert` for React, `postgres-pro` for Postgres).
2. **Take product context from Task 2** — user type, workflow style, external systems mentioned (issue tracker, docs platform, comms). Drives project-management / docs / comms MCP picks (e.g. Notion MCP for docs-heavy, Linear / Jira MCP for active dev, Slack MCP for team comm, GitHub MCP for PR-heavy workflow).
3. **Curate recommendations** across:
   - Anthropic plugin marketplace (`claude-plugins-official`)
   - [awesome-skills.com](https://awesome-skills.com) / [skills.sh](https://skills.sh)
   - [tonsofskills.com](https://tonsofskills.com) / `ccpi` CLI
   - [mcpmarket.com](https://mcpmarket.com) (MCP servers)
   - Fast-path: if `claude-code-setup` plugin installed, invoke `/setup` and merge its picks
4. **Filter to matched picks only** — drop generic / spray suggestions. Match against stack signals (Step 1) AND product/workflow signals (Step 2). A Notion MCP isn't "off-stack" if Task 2 surfaced docs-heavy workflow.
5. **Trust signal lookup per pick** — for any plugin NOT from `claude-plugins-official`, fetch (via WebFetch or `gh api`):
   - Repo URL + GitHub stars
   - Last-commit recency (e.g. "3d ago", "14mo ago")
   - License (or "no license" — flag as ⚠)
   - Permissions exercised (read-only? shell? network? auto-exec hook?)

   Hooks are elevated risk: they auto-exec on every tool call (PreToolUse / PostToolUse / UserPromptSubmit). Always tag hooks with `⚠ HOOK = auto-executes. Audit source before accept.`

6. **Present batch to user with full trust signal per pick:**
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
7. **Apply approved — write `.claude/settings.json` always.** This is the source of truth: project-scope intent, committed, travels with repo, cloud-friendly. Device install (`claude plugin install`) is optional convenience layered on top — not a substitute.
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
8. **Commit if anything added.**

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

### Task 6: Seed Backlog *(only if `docs/backlog.md` was scaffolded)*

Walk the project once and seed any obvious deferred items already visible in code or recent history.

**Depends on:** Task 1 and Task 2 (needs stack + overview to spot gaps)

- [ ] **Scan for `TODO` / `FIXME` / `XXX` / `HACK` markers** in source — each is a candidate `DEBT-###` or `BUG-###`
- [ ] **Review test output** — failing or skipped tests with no recent fix attempt → `BUG-###` or `DEBT-###`
- [ ] **Note design gaps surfaced during Q&A or overview drafting** — areas where behavior was hand-waved → `GAP-###`
- [ ] **Cap at ~5 items** — backlog is a queue, not a dump. If more candidates exist, list them but seed only the highest-signal ones
- [ ] **Present to user for review** — user prunes/approves
- [ ] **Commit**: `docs: seed backlog`

If no obvious items exist, leave the file with just its header — that's fine. The tracker grows organically as reviews surface things.

### Task 7: Cleanup

- [ ] **Delete this file** (`docs/superpowers/plans/bootstrap.md`) — bootstrap is complete
- [ ] **Verify `/todo` shows no active work** (unless the user has started real project work)
- [ ] **Commit**: `chore: complete pipeline bootstrap`
