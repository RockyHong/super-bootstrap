---
name: resolve-plugins
description: "Curate Claude Code skill / MCP / hook picks against live upstream sources and pin them in .claude/settings.json. Reads stack from docs/techstack.md, workflow signal from docs/overview.md + existing pins, then live-queries six source pools, dedupes, scores trust tier, presents diff vs pinned, writes settings.json. Standalone refresh path; also delegated from /super-bootstrap:harness-bootstrap Phase 3c. Solo dev workflow."
tags: [plugins, curation, mcp, skills, settings, meta]
---

# Resolve Plugins — Curate & Pin

Curate Claude Code skill / MCP / hook picks against live upstream sources and write them to `.claude/settings.json`. Designed for two callers: standalone refresh (`/super-bootstrap:resolve-plugins`) and harness delegation (`/super-bootstrap:harness-bootstrap` Phase 3c).

## When to Use

- **Standalone refresh:** upstream marketplaces drift independent of code (new picks land, deprecations happen, licenses change). Run when nothing in your repo changed but you want fresh picks.
- **From `/super-bootstrap:harness-bootstrap` Phase 3c:** harness delegates here so curation logic has one home.

---

## Phase 1: Read inputs (or fail loud)

Files-as-contract — no in-memory handoff from caller.

### Required input

`docs/techstack.md` — drives stack-matched picks. Read § Runtime, § Framework, § Key Dependencies.

If missing → fail loud:

> No `docs/techstack.md` found. `/super-bootstrap:resolve-plugins` reads stack signal from harness-seeded docs. Run `/super-bootstrap:harness-bootstrap` first to seed the harness, then re-run `/super-bootstrap:resolve-plugins` if you want a standalone refresh.

Don't silently scan manifests — manifest detection is harness's job. Doing it here would duplicate logic.

### Workflow-tools signal (priority order)

1. **Existing `.claude/settings.json` pinned MCPs** — Notion MCP pinned → docs-heavy workflow. Linear MCP pinned → ticket-driven. Slack MCP pinned → team comm. Etc. Strong signal — user already explicitly enabled the tool.
2. **`<!-- harness-meta -->` block in `docs/overview.md`** — structured record of Q4 (external tools) answer from harness Q&A. Parse the YAML `external-tools:` list. Strong signal — grounded in user-confirmed Q&A, not inference. Robust to prose drift.
3. **Keyword scan of `docs/overview.md` prose** — phrases like "Notion docs", "Linear tickets", "Slack standup". Weak signal, brittle, but cheap. Fallback only when (1) and (2) absent (e.g. legacy harness-bootstrapped repos predating the meta block).
4. **Prompt user once** with the same MCQ as `/super-bootstrap:harness-bootstrap` Phase 2 Q4 if none of (1)–(3) yields signal:

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
- **Fast-path** — if `claude-code-setup` plugin is installed locally, invoke `/setup` and merge its picks.

**Partial failure handling.** Single source unreachable (404 / rate limit / network) → note inline, continue with the others. Never skip the whole step.

**Total failure handling.** All sources unreachable → fail loud, don't write a stale-pin diff. Report and let user retry.

### Language-LSP pre-filter

`claude-plugins-official` ships per-language LSP plugins (`python-lsp`, `rust-lsp`, `go-lsp`, `ruby-lsp`, `swift-lsp`, `php-lsp`, `kotlin-lsp`, `lua-lsp`, `java-lsp`, `csharp-lsp`, `typescript-lsp`, etc.). For a single-language project, all but one are guaranteed stack-mismatches — running Phase 2.5 README parse on each is wasted cycles (10+ fetches per run on Node/TS repos).

Pre-filter rule: after Phase 2 returns the source pool, partition `*-lsp` plugins by name → language mapping. Drop any whose language ≠ techstack.md § Runtime / § Framework / § Key Dependencies match. Surface dropped count inline so user sees they exist:

```
Pre-filtered: 10 language-LSP plugins (stack-mismatch w/ {detected-language}) — type `expand prefilter` to list.
```

Default collapsed. Multi-language repos (monorepos w/ Python + TS, etc.) keep both matching LSPs.

Skipped plugins do **not** enter Phase 2.5 README parse, Phase 3 dedupe/trust/gate, or Phase 4 rejection collapse — they're filtered above all of those. Distinct from Phase 3 earn-right rejections (collapsed under `Rejected (earn-right)`); the pre-filter line surfaces separately so the source-rejection accounting stays accurate.

Pre-filter applies **only** to the `*-lsp` name pattern from `claude-plugins-official`. Don't generalize this to other plugin patterns without an equally precise name → stack-attribute mapping — false-positive skip is silent harm.

---

## Phase 2.5: README parse → cached digest

For each candidate Phase 2 emitted, fetch the upstream README once and reduce it to a structured digest. Phase 3 (gate) and Phase 5 (install plan) consume the same digest — single parse, two callers.

Digest fields:

- `hard_paths_shipped` — hooks declared (which event + file glob), slash commands shipped, frontmatter `agents:` / `related-skills:` delegations, MCP server config presence.
- `manual_install_steps` — ordered imperative steps lifted from `## Installation` / `## Setup` / `## Quick Start` headings (e.g. `brew install graphify`, `pnpm add -D <pkg>`, `chmod +x .claude/hooks/<name>.sh`).
- `user_invoke_trigger` — one-sentence "user types /name when ___" hypothesis for any slash command shipped (empty if none).
- `multi_component` — boolean. Flags Phase 5 to plan an atomic multi-step install (e.g. binary + MCP + hook + skill in one bundle).

If README absent or fetch fails for one candidate: warn inline, accept best-effort interpretation from SKILL.md only — do not auto-decide. Don't halt the whole batch on a single missing README.

Cache lifetime: per `/super-bootstrap:resolve-plugins` invocation. Discarded at end. Re-runs re-fetch (README content drifts between runs).

---

## Phase 3: Dedupe + trust signals + filter

### Filter to matched picks only

Drop generic / spray suggestions. Match against stack signals (Phase 1 § Required input) AND product/workflow signals (Phase 1 § Workflow-tools signal). A Notion MCP isn't "off-stack" if Phase 1 surfaced docs-heavy workflow.

### Dedupe by canonical name across sources

Same skill / MCP often appears in multiple sources (e.g. `react-expert` in Anthropic + ECC + VoltAgent with different versions / licenses / recency). Sources are peers, not ranked — never silently default to one. Process:

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

### Earn-right gate

For each candidate that survived dedupe + trust scoring, name one hard invocation path that exists in **this project** (use Phase 2.5 digest's `hard_paths_shipped` as primary signal):

- [ ] hook (which event? which file glob?)
- [ ] slash command (concrete user-trigger context — "user types /name when ___")
- [ ] pipeline delegation (which existing skill calls it by name?)
- [ ] frontmatter `agents:` / `related-skills:` bundle (which orchestrator pulls it?)
- [ ] committed-stack — plugin name or primary keyword matches an entry committed in `docs/techstack.md` § Runtime / § Framework / § Key Dependencies. Covers passive runtime integrations (LSPs, type checkers, debuggers, formatters) that ship no hook/slash/bundle but earn their slot because Claude Code uses them when reading matched files.
- [ ] none — only CLAUDE.md prescription / description match

#### Decision rules

- **≥1 of hook / slash / delegation / bundle** → admit. Tag the path: `[hook]`, `[slash]`, `[delegation]`, `[bundle]`.
- **Only committed-stack** → admit when trust tier is `🛡 vetted` (Anthropic-vetted or MCP steering-group). Tag `[committed-stack: <matched-term>]`. For community tiers (`★ / 🆕 / ⚠`), surface for user confirm before admit — keyword-spoof risk on unvetted sources. Tag becomes `[committed-stack: <matched-term> · user-confirmed]` on accept.
- **Only the last box** → reject by default. Description-match autopilot orphan.
- **User override** → admit on single-line justification; tag becomes `[override: <reason>]`. Surfaces in Phase 7 report only (no persistent tracking in v1).

**Why committed-stack is distinct from description match.** `techstack.md` is project-committed user intent, written via harness Q&A or super-bootstrap ideation. Treating it identically to "plugin description happens to mention React" undersells the signal — it's the strongest declaration of stack in the repo, stronger than manifest scan (a manifest may include build-only deps the user wouldn't want plugins for). Gate against keyword-match is what `[description-match-only]` rejects exist for; committed-stack is the orthogonal admit.

#### Mass-rejection collapsing

If many candidates from the same source reject for the same reason, collapse to one batch line — e.g. `Rejected 42 candidates from VoltAgent/awesome-agent-skills (description-match-only)`. Default collapsed; user types `expand rejected` to expand.

---

## Phase 4: Diff vs pinned, present batch

### Core pins (locked when harness-active)

Two harness core deps — seeded CLAUDE.md names both by slash-route or skill-trigger rule:

- `superpowers@claude-plugins-official` — routes `/brainstorm`, `/write-plan`, `/execute-plan`.
- `andrej-karpathy-skills@karpathy-skills` — CLAUDE.md § Coding Principles invokes `karpathy-guidelines` skill before every code edit. Requires `karpathy-skills` entry in `extraKnownMarketplaces` (source: `github` / `forrestchang/andrej-karpathy-skills`).

`/super-bootstrap:harness-bootstrap` Phase 3a pins both pre-resolve.

**Harness-active marker:** `docs/superpowers/` directory exists in the repo. Detect with one Glob.

- **Harness-active + pinned + present** → keep silently, do not surface in batch.
- **Harness-active + pin absent** (user manually removed; or fresh harness call hadn't reached Phase 3a yet) → **propose re-pin** as a locked core dep, short message: "core dep missing, re-pinning so CLAUDE.md routes / triggers resolve." User can decline only with explicit override; flag what breaks (superpowers → `/brainstorm` etc; karpathy-skills → § Coding Principles trigger rule misfires silently).
- **Not harness-active** (no `docs/superpowers/` folder — standalone curation on a non-harness repo) → no core lock applies. Both core deps, if present, are treated as regular adaptive picks the user may drop.
- Locked picks: never propose drop, never re-fetch trust signals (superpowers Anthropic-vetted; karpathy-skills locked by harness contract — `~150-line MIT skill, single-author repo, license + behavior pinned by harness contract`).

### Adaptive picks

If `.claude/settings.json` already has pinned picks, diff the new curation against the pinned set. **Re-fetch trust signals on every pinned pick** (not just new ones) — license can change, last-commit can age, repo can be archived.

- **Pinned + still recommended + trust block unchanged** → keep silently, mark `✓ pinned`
- **Pinned + still recommended + trust block moved** (license / last-commit / archive status changed) → re-show that pick's trust block, ask user to re-confirm
- **New pick recommended** (upstream added it; or stack signal changed) → propose as **add**
- **Pinned but no longer recommended** (deprecated upstream; license changed; stack changed) → propose as **drop** with reason
- **Pinned but source missing** — `enabledPlugins` entry exists with no resolvable source (not in `extraKnownMarketplaces`, not Anthropic-vetted). **Live-query source pool first** to find the plugin's real marketplace; if found, propose **resolve** (add marketplace to `extraKnownMarketplaces`) with trust block; if not found in any source, propose **drop** (orphan, can't reproduce on cloud / fresh machine).

### Batch presentation format

```
Skill / MCP / hook curation for {project} ({stack}):

  Rejected (earn-right): {R} candidates collapsed — type `expand rejected` to list.

  [SKILL]   🛡 {name}@{source}        [bundle]   [+ add | ✓ keep | − drop]
             Why: {matched signal, one-line value}
             (vetted picks: trust block omitted)

  [SKILL]   ★ {name}@{source}         [slash]    [+ add | ✓ keep | − drop]
             ★ {stars} · last commit {recency} · {license}
             Permissions: {read-only / shell / network / etc.}
             Why: {matched signal, one-line value}
             also in: {alt-source-A} (★{stars} · {recency} · {license}) · {alt-source-B} (...)

  [HOOK]    ⚠ {name}@{source}         [hook]     [+ add]
             ★ {stars} · last commit {recency} · {license}
             Permissions: ⚠ {what triggers + what it runs}
             Why: {matched signal}
             ⚠ HOOK = auto-executes. Audit source before accept.

  [MCP]     🆕 {name}@{source}        [delegation] [+ add]
             ★ {stars} · last commit {recency} · {license}
             Permissions: {network / shell / file-system / etc.}
             Why: {matched signal}

Accept all / reject specific / discuss thoughts / expand alternates?
```

Path tag column (`[hook]` / `[slash]` / `[delegation]` / `[bundle]` / `[committed-stack: <term>]` / `[override: <reason>]`) shows the hard invocation path Phase 3 admitted the pick on — surfaces "why this one earned its slot" at a glance.

`Rejected (earn-right): {R} candidates collapsed` line renders only when Phase 3 produced rejections. Default collapsed; user types `expand rejected` to expand into per-source breakdown.

`also in:` line collapses dedupe alternates from Phase 3. User can ask to expand if primary's signal looks weaker than an alternate.

**Catalog stays chat — never popup.** Per-row trust blocks + per-pick toggles + alternate expand don't fit popup option/description shape. Final approve gesture stays chat too — splitting from catalog adds friction.

---

## Phase 5: Apply approved → settings.json + atomic install + verify + commit

Source of truth: project-scope intent, committed, travels with repo, cloud-friendly. Device install (`claude plugin install`) is optional convenience layered on top.

Each accepted candidate executes as an **atomic unit** — settings write + per-component install + per-component verify. Atomic boundary is per-candidate: one candidate failing verify halts only its own steps; sibling candidates continue independently.

### Phase 5.1: Install plan

For each accepted candidate, expand the Phase 2.5 digest into ordered install steps and render the plan before execution.

```text
candidate: graphify
  [skill]   graphify@market           -> .claude/skills/graphify/
  [mcp]     graphify-mcp              -> .mcp.json
  [hook]    post-commit-graphify      -> .claude/hooks/ + settings.json wiring
  [bin]     graphify (manual: brew install graphify per README)

candidate: superpowers
  [plugin]  superpowers@claude-plugins-official  -> enabledPlugins
```

Steps execute sequentially within a candidate. Multiple candidates may install in parallel.

### Phase 5.2: Settings.json write

- Add accepted picks to `enabledPlugins`. Drop rejected picks. **When harness-active (`docs/superpowers/` exists), never drop core pins** (`superpowers@claude-plugins-official`, `andrej-karpathy-skills@karpathy-skills`) — see Phase 4 § Core pins.
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

`enabledPlugins` declares intent. Resolution happens at session start — Claude reads settings.json, finds device-installed plugins or auto-resolves via marketplaces. Without settings.json, project intent is lost (cloud and fresh machines can't reproduce). Device install alone doesn't travel.

### Phase 5.3: Verify per component

For each install step: log to user → execute → run mechanical verify command. Never claim "done ✓" without an observable check.

| Component | Verify | Pass |
|---|---|---|
| Plugin install | `claude plugin install <pick>` exits 0 AND `jq -e '.enabledPlugins["<pick>"]' .claude/settings.json` | both 0 |
| Binary (manual install) | `command -v <bin>` | exit 0 |
| Hook script | `[ -x .claude/hooks/<name>.sh ]` AND `bash -n .claude/hooks/<name>.sh` AND `jq -e '.hooks.<event>[]? \| select(.command \| contains("<name>"))' .claude/settings.json` | all 0 |
| Local file copy (rare) | `[ -f <dest> ]` | exit 0 |

`bash -n` catches syntax pre-runtime. `jq -e` is structural — exits non-zero on missing keys, not substring match. `command -v` is POSIX-portable.

### Phase 5.4: Halt-or-rollback on verify fail

If any step fails verify:

1. Halt remaining steps for **this candidate only**. Sibling candidates continue.
2. Surface failure: which step (component type + name), the verify command + observed output, candidate's progress so far.
3. Offer three resolutions:
   - **Rollback** — best-effort undo of already-applied steps. Some manual installs (e.g. `brew install`) aren't rollback-able — surface that.
   - **Pause** — leave partial state, surface summary, user fixes manually then re-runs `/super-bootstrap:resolve-plugins`.
   - **Drop** — accept candidate didn't install, drop from accepted set, revert its settings.json edit.

Never silently skip. Never claim "done" with half-installed state.

### Phase 5.5: Commit only fully-installed candidates

`/super-bootstrap:commit` handoff. Restrict commit to candidates where every Phase 5.3 verify exited 0. Half-installed candidates excluded; user resolves before re-running.

If delta non-empty → invoke `/super-bootstrap:commit` to stage `.claude/settings.json` (and `.mcp.json` / `.claude/hooks/` / `.claude/skills/` if written by atomic install) with message `chore: refresh plugin picks` (or `chore: pin plugin picks` on first run with empty `enabledPlugins`).

If delta empty (every row `✓ pinned` and trust blocks unchanged) → report `✓ all pinned picks current` and skip commit.

---

## Phase 7: Report

After Phase 5 completes, render a single summary block.

```text
✓ Resolve complete.

Pins applied: {N} ({list-of-names})
Pins unchanged: {M}
Pins dropped: {K} ({reasons})

Earn-right rejections: {R}
  {if R > 0: list collapsed sources or `expand rejected` hint}

Verify failures: {V}
  {if V > 0: list candidates that halted, with chosen resolution per candidate}
```

If `R == 0` and `V == 0`, omit those rows entirely.

---

## Principles

- **Single source of truth.** Source pool list, trust tiers, dedupe rules, batch format live ONLY here. Harness 3c delegates — never duplicates.
- **Live-query non-skippable.** Stable project ≠ stable upstream. Skipping = stale picks = silent failure mode.
- **Files-as-contract input.** Reads `docs/techstack.md` + `docs/overview.md` + `.claude/settings.json`. No in-memory handoff from caller.
- **Fail loud on missing input.** No `docs/techstack.md` → redirect to `/super-bootstrap:harness-bootstrap`. Don't silently scan manifests.
- **Trust tier before source rank.** Sources are peers; tier (🛡 / ★ / 🆕 / ⚠) tells the user what to judge.
- **Auto-exec hooks always tagged.** Hooks fire on every tool call — surface the risk every time.
