# resolve-plugins Extraction Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Extract `/harness-bootstrap` Phase 3c (curate skill/MCP/hook) into a standalone `resolve-plugins` skill so users can refresh picks without doc-sync ceremony, with single source of truth for plugin curation logic.

**Architecture:** Move Phase 3c verbatim into a new SKILL.md at `plugins/super-bootstrap/skills/resolve-plugins/`. Shrink harness 3c to a one-paragraph delegation pointer that invokes the new skill. Add naming-rule convention to a new plugin-level `plugins/super-bootstrap/README.md`. Verification: grep harness for source-pool URLs / trust-tier strings — must return zero matches.

**Tech Stack:** Markdown-only — Claude Code skill files. No code, no tests in the runtime sense. Verification via `grep`.

**Source spec:** `docs/superpowers/specs/resolve-plugins.md`

---

## File Structure

- **Create:** `plugins/super-bootstrap/skills/resolve-plugins/SKILL.md` — full Phase 3c logic, expanded preamble for standalone use (input contract from techstack.md, fail-loud redirect, output contract).
- **Modify:** `plugins/super-bootstrap/skills/harness-bootstrap/SKILL.md` — replace Phase 3c body (~80 lines) with one-paragraph delegation; keep the `### 3c:` heading so the phase order narrative stays intact.
- **Create:** `plugins/super-bootstrap/README.md` — plugin-level contributor doc with § Naming convention. (Repo-root `README.md` stays user-facing only.)

No other files touched. No assets moved (Phase 3c references no asset templates — pure live-query logic).

---

## Open Questions Resolved

Spec left two open questions for plan review. Resolutions:

- **Auto-commit at end?** YES — mirror harness 3d for picks-only case. Skill ends by invoking `/sb-commit` if delta non-empty. User reviews staged diff at commit-time. Captured in Task 1 Step 3 (Phase 5 body).
- **Workflow-tools signal source on standalone runs?** Read in priority order: (1) existing `.claude/settings.json` pinned MCPs (Notion MCP pinned → docs-heavy inferred), (2) keyword scan of `docs/overview.md`, (3) prompt user once with the original Q4 MCQ if neither yields signal. Captured in Task 1 Step 3 (Phase 1 body).

If user disagrees with either resolution at plan-review checkpoint, adjust before execution.

---

## Task 1: Write `resolve-plugins` SKILL.md

**Files:**
- Create: `plugins/super-bootstrap/skills/resolve-plugins/SKILL.md`

**Source content:** Lines 394-494 of `plugins/super-bootstrap/skills/harness-bootstrap/SKILL.md` (Phase 3c body — Process steps 1-7 + "Why settings.json is non-negotiable" paragraph). Move verbatim where possible; add standalone preamble (Phase 1 input read + fail-loud) + standalone closer (commit handoff).

- [ ] **Step 1: Verify source content range**

Run:
```bash
grep -n "^### 3c:\|^### 3d:" plugins/super-bootstrap/skills/harness-bootstrap/SKILL.md
```
Expected output: two line numbers matching `### 3c:` and `### 3d:` — confirms the boundary range to extract. Note both numbers; they bound the source content.

- [ ] **Step 2: Create skill folder**

Run:
```bash
mkdir -p plugins/super-bootstrap/skills/resolve-plugins
```

- [ ] **Step 3: Write `SKILL.md`**

Write the file with this content:

````markdown
---
name: resolve-plugins
description: "Curate Claude Code skill / MCP / hook picks against live upstream sources and pin them in .claude/settings.json. Reads stack from docs/techstack.md, workflow signal from docs/overview.md + existing pins, then live-queries six source pools, dedupes, scores trust tier, presents diff vs pinned, writes settings.json. Standalone refresh path; also delegated from /harness-bootstrap Phase 3c. Solo dev workflow."
tags: [plugins, curation, mcp, skills, settings, meta]
---

# Resolve Plugins — Curate & Pin

Curate Claude Code skill / MCP / hook picks against live upstream sources and write them to `.claude/settings.json`. Designed for two callers: standalone refresh (`/resolve-plugins`) and harness delegation (`/harness-bootstrap` Phase 3c).

## When to Use

- **Standalone refresh:** upstream marketplaces drift independent of code (new picks land, deprecations happen, licenses change). Run when nothing in your repo changed but you want fresh picks.
- **From `/harness-bootstrap` Phase 3c:** harness delegates here so curation logic has one home.

## Why a separate skill

Phase 3c does work that has nothing to do with doc scaffolding — different inputs (live upstream sources), different output (`.claude/settings.json`), different cadence (refresh-on-demand). Coupling it inside `/harness-bootstrap` forces users through Phase 1 quick-scan + Phase 2 Q&A + Phase 3a-b drift just to refresh picks. Extracted here, harness becomes a thin caller; standalone refresh is one command.

**Single source of truth.** Source pool list, trust tiers, dedupe rules, batch format live ONLY here. Harness 3c is one paragraph delegating to this skill.

---

## Phase 1: Read inputs (or fail loud)

Files-as-contract — no in-memory handoff from caller.

### Required input

`docs/techstack.md` — drives stack-matched picks. Read § Runtime, § Framework, § Key Dependencies.

If missing → fail loud:

> No `docs/techstack.md` found. `/resolve-plugins` reads stack signal from harness-seeded docs. Run `/harness-bootstrap` first to seed the harness, then re-run `/resolve-plugins` if you want a standalone refresh.

Don't silently scan manifests — manifest detection is harness's job. Doing it here would duplicate logic.

### Workflow-tools signal (priority order)

1. **Existing `.claude/settings.json` pinned MCPs** — Notion MCP pinned → docs-heavy workflow. Linear MCP pinned → ticket-driven. Slack MCP pinned → team comm. Etc. Strong signal — user already explicitly enabled the tool.
2. **Keyword scan of `docs/overview.md`** — phrases like "Notion docs", "Linear tickets", "Slack standup". Weak signal but cheap.
3. **Prompt user once** with the same MCQ as `/harness-bootstrap` Phase 2 Q4 if neither (1) nor (2) yields signal:

   > External tools in your workflow? GitHub-only / Notion / Linear / Jira / Slack / Trello / ClickUp / other (multi-select).

### Optional input

`docs/overview.md` — § User, § Current State for additional workflow signal. Skip silently if missing (rare on a harness-bootstrapped repo).

---

## Phase 2: Live-query source pool

**Non-skippable, runs every invocation.** Stable project ≠ stable upstream. Marketplaces add picks, deprecate picks, change licenses, between any two runs. The only way to detect that drift is to actually query.

Issue WebFetch / Bash queries against each source. **GitHub-only pool — sites without backing repos can't surface trust signals (stars / recency / license).** Run queries in parallel where the harness allows.

- **Anthropic plugin marketplace** — `gh api repos/anthropics/claude-plugins-official/contents/plugins` — Anthropic-vetted picks (🛡 tier).
- **MCP official registry** — `gh api repos/modelcontextprotocol/registry/contents` (or query the registry API directly) — official MCP discovery service. Indexes both steering-group reference impls AND community-published servers. Primary source for MCP picks. Picks authored under `modelcontextprotocol/*` org auto-tier as 🛡 vetted.
- **everything-claude-code (affaan-m / ECC)** — `gh api repos/affaan-m/everything-claude-code/contents` — 172k-star MIT-licensed harness component bundle (skills + agents + rules + hooks + MCP configs). Strongest source for **language-specific rules** (TS / Python / Go / etc.).
- **awesome-claude-skills (ComposioHQ)** — `gh api repos/ComposioHQ/awesome-claude-skills/contents/README.md` (or WebFetch) — actively-curated category index (~200 entries, "production ready" bar). Strongest source for **workflow / external-tools** picks (78 Composio SaaS workflow skills covering Notion / Slack / Jira / Linear / CRM).
- **VoltAgent/awesome-agent-skills** — `gh api repos/VoltAgent/awesome-agent-skills/contents` — 1000+ skills from official dev teams (Anthropic, Vercel, Stripe, Cloudflare, Sentry, Hugging Face, Figma) + community. MIT-licensed, ~20k stars. Cross-reference for cross-team picks the Claude-only catalogs miss.
- **jeffallan/claude-skills** — `gh api repos/Jeffallan/claude-skills/contents` — broad fullstack-skills marketplace (~65 skills covering fullstack workflows, project-mgmt integration). Direct query > aggregator listing for freshness.
- **Fast-path** — if `claude-code-setup` plugin is installed locally, invoke `/setup` and merge its picks.

**Partial failure handling.** Single source unreachable (404 / rate limit / network) → note inline, continue with the others. Never skip the whole step.

**Total failure handling.** All sources unreachable → fail loud, don't write a stale-pin diff. Report and let user retry.

---

## Phase 3: Dedupe + trust signals + filter

### Filter to matched picks only

Drop generic / spray suggestions. Match against stack signals (Phase 1 § Required input) AND product/workflow signals (Phase 1 § Workflow-tools signal). A Notion MCP isn't "off-stack" if Phase 1 surfaced docs-heavy workflow.

### Dedupe by canonical name across sources

Same skill / MCP often appears in multiple sources (e.g. `react-expert` in Anthropic + ECC + jeffallan with different versions / licenses / recency). Sources are peers, not ranked — never silently default to one. Process:

- Group hits by canonical plugin name (case-insensitive, ignore source suffix)
- Pick the **primary row** by highest composite signal: stars × recency × license-clean. Tie-break by Anthropic-vetted if present.
- Collapse other variants into a single `also in: <source-A> · <source-B>` line under the primary row, with provenance: stars / last-commit / license per alternate.
- User can expand alternates at present-batch step if the primary's trust signal looks weaker than an alternate's.

### Trust signal lookup per pick

For any plugin NOT from `claude-plugins-official` or `modelcontextprotocol/*`, fetch (via WebFetch or `gh api`):

- Repo URL + GitHub stars
- Last-commit recency (e.g. "3d ago", "14mo ago")
- License (or "no license" — flag as ⚠)
- Permissions exercised (read-only? shell? network? auto-exec hook?)

Hooks are elevated risk: auto-exec on every tool call (PreToolUse / PostToolUse / UserPromptSubmit). Always tag hooks: `⚠ HOOK = auto-executes. Audit source before accept.`

### Trust tiers

- `🛡 vetted` — authored under `anthropics/*` or `modelcontextprotocol/*` org (Anthropic-audited or MCP steering-group authored, license-clean, slower to land sharp picks).
- `★ popular` — outside the vetted orgs above, ≥1k stars + commit ≤90d ago + license clean
- `🆕 fresh` — recent activity (≤30d) but lower stars / smaller pool
- `⚠ unaudited` — no license, archived, last-commit >12mo, or stars <100

---

## Phase 4: Diff vs pinned, present batch

If `.claude/settings.json` already has pinned picks, diff the new curation against the pinned set. **Re-fetch trust signals on every pinned pick** (not just new ones) — license can change, last-commit can age, repo can be archived.

- **Pinned + still recommended + trust block unchanged** → keep silently, mark `✓ pinned`
- **Pinned + still recommended + trust block moved** (license / last-commit / archive status changed) → re-show that pick's trust block, ask user to re-confirm
- **New pick recommended** (upstream added it; or stack signal changed) → propose as **add**
- **Pinned but no longer recommended** (deprecated upstream; license changed; stack changed) → propose as **drop** with reason
- **Pinned but source missing** — `enabledPlugins` entry exists with no resolvable source (not in `extraKnownMarketplaces`, not Anthropic-vetted). **Live-query source pool first** to find the plugin's real marketplace; if found, propose **resolve** (add marketplace to `extraKnownMarketplaces`) with trust block; if not found in any source, propose **drop** (orphan, can't reproduce on cloud / fresh machine).

### Batch presentation format

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

`also in:` line collapses dedupe alternates from Phase 3. User can ask to expand if primary's signal looks weaker than an alternate.

**Catalog stays chat — never popup.** Per-row trust blocks + per-pick toggles + alternate expand don't fit popup option/description shape. Final approve gesture stays chat too — splitting from catalog adds friction.

---

## Phase 5: Apply approved → write `settings.json` + commit

Source of truth: project-scope intent, committed, travels with repo, cloud-friendly. Device install (`claude plugin install`) is optional convenience layered on top.

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

### Why settings.json is non-negotiable

`enabledPlugins` declares intent. Resolution happens at session start — Claude reads settings.json, finds device-installed plugins or auto-resolves via marketplaces. Without settings.json, project intent is lost (cloud and fresh machines can't reproduce). Device install alone doesn't travel.

### Commit handoff

If delta non-empty → invoke `/sb-commit` to stage `.claude/settings.json` and commit with message `chore: refresh plugin picks` (or `chore: pin plugin picks` on first run with empty `enabledPlugins`).

If delta empty (every row `✓ pinned` and trust blocks unchanged) → report `✓ all pinned picks current` and skip commit.

---

## Principles

- **Single source of truth.** Source pool list, trust tiers, dedupe rules, batch format live ONLY here. Harness 3c delegates — never duplicates.
- **Live-query non-skippable.** Stable project ≠ stable upstream. Skipping = stale picks = silent failure mode.
- **Files-as-contract input.** Reads `docs/techstack.md` + `docs/overview.md` + `.claude/settings.json`. No in-memory handoff from caller.
- **Fail loud on missing input.** No `docs/techstack.md` → redirect to `/harness-bootstrap`. Don't silently scan manifests.
- **Trust tier before source rank.** Sources are peers; tier (🛡 / ★ / 🆕 / ⚠) tells the user what to judge.
- **Auto-exec hooks always tagged.** Hooks fire on every tool call — surface the risk every time.
````

- [ ] **Step 4: Verify file written**

Run:
```bash
ls plugins/super-bootstrap/skills/resolve-plugins/
```
Expected: `SKILL.md` listed.

Run:
```bash
grep -c "^## Phase" plugins/super-bootstrap/skills/resolve-plugins/SKILL.md
```
Expected: `5` (five phases).

- [ ] **Step 5: Commit**

```bash
git add plugins/super-bootstrap/skills/resolve-plugins/SKILL.md
git commit -m "feat(resolve-plugins): extract plugin curation skill from harness-bootstrap"
```

---

## Task 2: Shrink harness-bootstrap Phase 3c

**Files:**
- Modify: `plugins/super-bootstrap/skills/harness-bootstrap/SKILL.md` (current Phase 3c body lines ~394-494)

Replace the Phase 3c body with a one-paragraph delegation. Keep the `### 3c: Curate skill / MCP / hook` heading so phase order narrative stays intact.

- [ ] **Step 1: Read current Phase 3c boundaries**

Run:
```bash
grep -n "^### 3c:\|^### 3d:" plugins/super-bootstrap/skills/harness-bootstrap/SKILL.md
```
Expected: two line numbers. The Phase 3c body is everything between them (exclusive of the `### 3d:` line).

- [ ] **Step 2: Replace Phase 3c body**

Use Edit tool. Old string is the entire current Phase 3c body (Process steps 1-7 + "Why settings.json is non-negotiable" paragraph — roughly the content from `### 3c: Curate skill / MCP / hook` heading through the line before `### 3d: Sync report + commit`).

New body (replacement):

```markdown
### 3c: Curate skill / MCP / hook

**Delegated to `/resolve-plugins`.** Phase 3c is one Skill invocation — `Skill(resolve-plugins)`. The full curation logic (live-query of six source pools, dedupe, trust tiers, batch presentation, `.claude/settings.json` write) lives in `plugins/super-bootstrap/skills/resolve-plugins/SKILL.md`. Single source of truth.

`/resolve-plugins` is also runnable standalone — useful when upstream marketplaces drift but nothing in the repo changed (no need to walk Phase 1-3b just to refresh picks).

**Inputs the harness has already prepared by Phase 3c:**
- `docs/techstack.md` — written in Phase 3b. `/resolve-plugins` reads § Runtime / Framework / Key Dependencies for stack-matched picks.
- `docs/overview.md` — written in Phase 3b. `/resolve-plugins` reads § User / Current State for additional workflow signal.
- Phase 2 Q4 (external tools) answer — flows via `docs/overview.md` content (the harness embeds the answer when seeding the doc) or via `.claude/settings.json` pinned MCPs on re-run.

**Output:** `.claude/settings.json` updated with `enabledPlugins` + `extraKnownMarketplaces`. Commit handled by `/resolve-plugins` itself if delta non-empty.

**Why files-as-contract handoff:** harness doesn't pass in-memory state to the delegated skill. Same pattern as `/super-bootstrap` → `/harness-bootstrap` (seed docs). Lets `/resolve-plugins` run standalone without re-implementing Phase 1 quick-scan.

```

- [ ] **Step 3: Verify drift contract**

Run:
```bash
grep -n "claude-plugins-official\|modelcontextprotocol/registry\|affaan-m/everything-claude-code\|ComposioHQ/awesome-claude-skills\|VoltAgent/awesome-agent-skills\|Jeffallan/claude-skills" plugins/super-bootstrap/skills/harness-bootstrap/SKILL.md
```
Expected: zero matches. (Source-pool URLs now live ONLY in `resolve-plugins/SKILL.md`.)

If non-zero → residual logic in harness. Re-edit to remove and re-run.

Run:
```bash
grep -nc "🛡 vetted\|★ popular\|🆕 fresh\|⚠ unaudited" plugins/super-bootstrap/skills/harness-bootstrap/SKILL.md
```
Expected: `0`. Trust tier definitions live ONLY in `resolve-plugins/SKILL.md`.

Run:
```bash
grep -nc "^### 3c:\|^### 3d:\|^### 3a:\|^### 3b:" plugins/super-bootstrap/skills/harness-bootstrap/SKILL.md
```
Expected: `4`. All four sub-phase headings still present — narrative intact.

- [ ] **Step 4: Verify line-count shrink**

Run:
```bash
wc -l plugins/super-bootstrap/skills/harness-bootstrap/SKILL.md
```
Expected: ~470-490 lines (was 571 — Phase 3c shrunk from ~100 lines to ~15).

- [ ] **Step 5: Commit**

```bash
git add plugins/super-bootstrap/skills/harness-bootstrap/SKILL.md
git commit -m "refactor(harness-bootstrap): delegate Phase 3c curation to /resolve-plugins"
```

---

## Task 3: Document naming rule in plugin-level README

**Files:**
- Create: `plugins/super-bootstrap/README.md`

Repo-root `README.md` is user-facing. Naming convention is contributor concern. New plugin-level README owns it.

- [ ] **Step 1: Write README**

Write file with this content:

```markdown
# super-bootstrap (plugin)

Plugin-level contributor doc for the `super-bootstrap` plugin. End-user docs live in the repo-root `README.md`.

## Skill catalog

- `super-bootstrap` — public entry, greenfield gate, dispatches to `harness-bootstrap`.
- `harness-bootstrap` — installs/syncs the harness (CLAUDE.md, skeleton docs, rules, picks).
- `resolve-plugins` — curates skill/MCP/hook picks against live sources, writes `.claude/settings.json`. Standalone or delegated from `harness-bootstrap` Phase 3c.
- `sb-todo` — scans active specs/plans, reports cycle stage + blockers.
- `sb-commit` — session-isolated commit, doc-sync gated, conventional message, no push.

## Naming convention

| Prefix shape | Tier | Frequency | Examples |
|---|---|---|---|
| `sb-*` | In-flight ops | High (per-session, per-commit) | `sb-commit`, `sb-todo` |
| Self-explanatory verb-noun | Bootstrap / system / lifecycle | Low (rare invocations) | `super-bootstrap`, `harness-bootstrap`, `resolve-plugins` |

**Why:** `sb-*` shorthand is amortized by repetition. Lifecycle-tier skills fire rarely — name must read clearly cold without prefix knowledge.

**When adding a new skill:** decide tier first. High-freq in-flight (will user invoke this multiple times per session?) → `sb-*`. Lifecycle / one-shot setup → self-explanatory verb-noun. Don't `sb-*`-prefix a rarely-invoked skill — wrong frequency signal.

## Source of truth boundaries

When skills overlap in concern, one is canonical and others delegate:

- **Plugin curation logic** (source pool list, trust tiers, dedupe, settings.json write) — lives ONLY in `resolve-plugins/SKILL.md`. `harness-bootstrap` Phase 3c delegates.
- **Greenfield ideation Q&A** — lives ONLY in `super-bootstrap/SKILL.md`. `harness-bootstrap` redirects empty repos here.
- **Files-as-contract handoff** — skills communicate via committed docs (`docs/overview.md`, `docs/techstack.md`, `.claude/settings.json`), not in-memory state. Lets each skill run standalone.

If extracting a new shared concern: pick the canonical home, delete duplicated content elsewhere, replace with one-paragraph delegation. Verify via grep that source-of-truth strings appear in exactly one file.
```

- [ ] **Step 2: Verify**

Run:
```bash
ls plugins/super-bootstrap/README.md
```
Expected: file listed.

Run:
```bash
grep -c "^## " plugins/super-bootstrap/README.md
```
Expected: `3` (Skill catalog, Naming convention, Source of truth boundaries).

- [ ] **Step 3: Commit**

```bash
git add plugins/super-bootstrap/README.md
git commit -m "docs(plugin): add plugin-level README with naming + source-of-truth conventions"
```

---

## Task 4: Final verification pass

**Files:** none modified — verification only.

- [ ] **Step 1: Drift contract holds**

Run:
```bash
grep -rn "claude-plugins-official\|modelcontextprotocol/registry\|affaan-m/everything-claude-code\|ComposioHQ/awesome-claude-skills\|VoltAgent/awesome-agent-skills\|Jeffallan/claude-skills" plugins/super-bootstrap/skills/
```
Expected: matches ONLY in `plugins/super-bootstrap/skills/resolve-plugins/SKILL.md`. Zero matches in `harness-bootstrap/SKILL.md`, `super-bootstrap/SKILL.md`, `sb-commit/SKILL.md`, `sb-todo/SKILL.md`.

- [ ] **Step 2: Trust tiers single-home**

Run:
```bash
grep -rn "🛡 vetted\|★ popular\|🆕 fresh\|⚠ unaudited" plugins/super-bootstrap/skills/
```
Expected: matches ONLY in `resolve-plugins/SKILL.md`.

- [ ] **Step 3: Harness narrative intact**

Run:
```bash
grep -n "^### 3a:\|^### 3b:\|^### 3c:\|^### 3d:" plugins/super-bootstrap/skills/harness-bootstrap/SKILL.md
```
Expected: four matches in order 3a → 3b → 3c → 3d. Phase narrative preserved.

- [ ] **Step 4: New skill discoverable**

Run:
```bash
ls plugins/super-bootstrap/skills/
```
Expected output (alphabetical): `harness-bootstrap`, `resolve-plugins`, `sb-commit`, `sb-todo`, `super-bootstrap`.

- [ ] **Step 5: Plugin README references new skill**

Run:
```bash
grep -c "resolve-plugins" plugins/super-bootstrap/README.md
```
Expected: `≥2` (one in skill catalog, one in source-of-truth boundaries).

- [ ] **Step 6: Final commit (if any verification needed fix-up commits)**

If Steps 1-5 all pass on first run → no commit needed for Task 4. If any step required fix-up, commit those fixes per task they belonged to.

---

## Self-Review Notes

Verified before handing plan over for execution:

1. **Spec coverage:** every spec section maps to a task — Motivation/Goal → Tasks 1+2; Naming Rule → Task 3; Interface (inputs / output / phases) → Task 1 Step 3; Drift-Prevention Contract → Task 2 Step 3 verification; Edge Cases (handled inside SKILL.md content of Task 1 Step 3); Open Questions resolved before Task 1.

2. **Placeholder scan:** no TBD / TODO / "implement later". Each step has exact commands or exact content.

3. **Type/path consistency:** `resolve-plugins` named consistently throughout; file paths consistent (`plugins/super-bootstrap/skills/resolve-plugins/SKILL.md`); harness file path consistent (`plugins/super-bootstrap/skills/harness-bootstrap/SKILL.md`); README path consistent (`plugins/super-bootstrap/README.md` — plugin-level, NOT repo-root).

4. **Verification commands match expected outputs:** every grep/ls/wc step states what passes.

5. **Risks called out:** drift contract enforced by Task 2 Step 3 + Task 4 Step 1 (grep verification).
