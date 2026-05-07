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
