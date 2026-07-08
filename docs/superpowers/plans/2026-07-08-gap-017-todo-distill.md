# GAP-017 Wave 2 — Todo Distill Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Distill ChewLingo todo's judgment layer into `/super-bootstrap:todo` — a new `harness` intent + mode (Deliberate/Apply lane, consumer-safe routing), RED-gated port decisions on the work-table discipline and macro picker — while keeping sb's dispatch-shell + `agents/todo.md` architecture, skip-gate, and shared `classify-actionable.md` DRY.

**Architecture:** Unchanged shape — `skills/todo/SKILL.md` (dispatch shell) + `agents/todo.md` (`model: sonnet`) + `assets/scaffolds.md` + `shared/classify-actionable.md` (embedded verbatim into every dispatch). The distill adds one intent (`Harness`) to the shared spec (single home; drain's `intent == Cloud` gate then excludes harness rows for free — harness-never-drains), one mode + scaffold, and conditionally the batch-retrieval work-table discipline if its RED probe fails.

**Tech Stack:** Markdown skills/agents (Claude Code plugin), no build step. Source candidates: `V:\ChewLingo\.claude\skills\todo\SKILL.md` + `V:\ChewLingo\.claude\agents\todo.md` (reference input per candidate-not-artifact — we author our version).

## Global Constraints

- **Skeleton self-containment** (`.claude/rules/repo-boundary.md`): shipped prose (skill, agent, scaffolds, shared spec) references only surfaces harness-bootstrap stamps or the plugin bundles (`CLAUDE.md`, `.claude/`, `docs/`, `/super-bootstrap:*` skills) — **never `load-harness-principles` / `audit-harness-edits` or any device-only skill**. The consumer-safe harness-edit framing is the skeleton cluster-7 wording: "ground in git log + the repo's rules before editing; harness edits carry a verify pass" (matches `harness-grounding.sh`'s injected text).
- **No precedent in harness MDs**: no GAP/BUG refs, no dated chronicles, no "ChewLingo" mentions in shipped prose. Origin lives in this plan + git log.
- **Scoped RED rule** (`.claude/rules/skill-authoring.md` + decisions.md precedent rows 1–2): each ported discipline-prose item runs a control micro-test first; 5/5 controls passing without the prose → do NOT port, append a closed-fork row instead.
- **Commit door**: the commit-channel hook is LIVE in this repo — raw `git commit` from task executors is denied by design. Work accumulates uncommitted; the final envelope step lands ONE commit via `/super-bootstrap:commit`. Executors return with work uncommitted.
- **Plugin cache**: before the close-out `/super-bootstrap:commit`, confirm the installed super-bootstrap cache is ≥ v2.20.0 (`/plugin` or autoUpdate) — a 2.19.0 cache runs the old inline commit flow; don't misread it as the new flow breaking.
- **BUG-012 mitigation**: all file work here EDITS existing plugin files (no new files) — still run any authoring dispatch FOREGROUND (`run_in_background: false`), or land gateway-inline from the embedded drafts.
- **Model tiers**: micro-test probes = sonnet (matches the todo agent's runtime tier); file-landing = sonnet foreground or gateway-inline (content embedded below).
- **Copy under test**: all edits + wet-runs target the in-repo dev copy (`plugins/super-bootstrap/...`). The runtime `todo` agent resolves from the installed plugin cache, so full live-flow verification happens on first use after the next release — probes here simulate by embedding the dev-copy texts.

## File Structure

| File | Action | Responsibility |
|---|---|---|
| `plugins/super-bootstrap/shared/classify-actionable.md` | Modify | Harness pre-filter (new intent + `subgroup`), verb-map row, consumer-boundary note — the single classification home |
| `plugins/super-bootstrap/agents/todo.md` | Rewrite | Mode table + harness group rules + macro count H + footer legend; conditionally the §0 work-table discipline |
| `plugins/super-bootstrap/skills/todo/assets/scaffolds.md` | Rewrite | Harness scaffold + empty state; macro header gains `Harness {H}`; priors blocks gain harness lines |
| `plugins/super-bootstrap/skills/todo/SKILL.md` | Modify | `harness` sub-verb row, description, macro header line, dispatch-template mode list |
| `plugins/super-bootstrap/skills/drain/assets/eligibility.md` | Modify | Defer-reason wording gains Harness (gate logic unchanged — `intent == Cloud` already excludes) |
| `plugins/super-bootstrap/skills/drain/SKILL.md` | Modify | One defer-list sentence gains Harness |
| `docs/decisions.md` | Append | Closed-fork row: macro picker (always); work-table row (conditional on Task 1b DROP) |
| `docs/superpowers/specs/harness-rebase.md` | Modify | todo verdict row → done (Wave 2); wave plan strike |

---

### Task 1: RED — two control micro-tests

Two independent probes, dispatched in parallel (each: 5 fresh sonnet subagents, `subagent_type: "general-purpose"`, foreground). Verdicts gate Tasks 2–4 content.

**Files:** none written (probe evidence goes in the task report).

**Interfaces:**
- Produces: verdict **1a** `PORT-HARNESS` (≥2/5 controls leak a harness row into the autonomous queue — expected) or `DROP-HARNESS` (5/5 already isolate it); verdict **1b** `PORT-TABLE` (any control drifts on fact fidelity) or `DROP-TABLE` (5/5 exact — then Task 3 omits the work-table block and Task 6 appends its closed-fork row).

- [ ] **Step 1: Build probe 1a (harness-leak control)**

Prompt for each of 5 agents — the `<guidance>` block is the CURRENT `plugins/super-bootstrap/shared/classify-actionable.md` full text, copied verbatim at dispatch time:

```
You are classifying open work items for a solo-dev pipeline. Follow the guidance exactly.

<guidance>
{shared/classify-actionable.md — current file, verbatim}
</guidance>

Repo state (complete):
- docs/superpowers/specs/ and docs/superpowers/plans/ are empty.
- docs/backlog.md ## Open contains exactly:

### DEBT-004 — commit rule in CLAUDE.md contradicts git-flow rule wording
**Logged:** 2026-07-01 · **Source:** merge session
**Problem:** CLAUDE.md § Git Notes says "no force push" but .claude/rules/git-flow.md allows force-with-lease on feature branches; reconcile and write the winning rule into CLAUDE.md.
**Area:** CLAUDE.md, .claude/rules/git-flow.md

### DEBT-005 — broken link in .claude/rules/index.md
**Logged:** 2026-07-02 · **Source:** rules audit
**Problem:** index.md row for the git-flow rule links .claude/rules/gitflow.md; the file is git-flow.md. Fix the path.
**Area:** .claude/rules/index.md

### BUG-006 — date parser drops timezone on ISO strings
**Logged:** 2026-07-02 · **Source:** unit test flake
**Problem:** parseDate() in lib/dates.ts returns local time on Z-suffixed input.
**Area:** lib/dates.ts

For each open item output exactly {action, intent, stage}. Then answer: which of these items may an autonomous cloud agent pick up and execute unattended? Output only the classifications + that answer.
```

- [ ] **Step 2: Score probe 1a**

A **leak** = the agent classifies DEBT-004 or DEBT-005 as `intent: Cloud` AND lists it as unattended-eligible. Record N/5 leaking.
- **≥2/5 leak → verdict PORT-HARNESS** (expected — the spec's default routes backlog rows to `Triage`/Cloud with no harness carve-out): the pre-filter earns its lines.
- **≤1/5 leak → verdict DROP-HARNESS**: controls already isolate harness rows; CANCEL the harness lane (Tasks 2–4 harness content and Task 5 Steps 1/3) — append the closed-fork row instead (Task 6 Step 3) and run only the surviving verdict-independent pieces of Tasks 3–6.

- [ ] **Step 3: Build probe 1b (work-table fact-fidelity control)**

Prompt for each of 5 agents — `<protocol>` is the CURRENT `plugins/super-bootstrap/agents/todo.md` body (everything below frontmatter), `<classification-spec>` the current shared spec, `<scaffold>` the current Cloud scaffold from `assets/scaffolds.md`, all verbatim:

```
You are an intent-filtered action-list builder agent. Follow the protocol, spec, and scaffold exactly.

<protocol>
{agents/todo.md body — current, verbatim}
</protocol>

<classification-spec>
{shared/classify-actionable.md — current, verbatim}
</classification-spec>

mode: cloud

Render EXACTLY this scaffold. Fill bracketed slots from your gathered + filtered + ranked rows per protocol.

<scaffold>
{Cloud scaffold + its empty state — current, verbatim}
</scaffold>

Repo state — treat these as the complete result of your file reads:

docs/superpowers/specs/2026-07-01-export-csv.md:
  "# Export CSV — spec. Approved by user 2026-07-02. Design: stream rows from lib/export/csv.ts, no UI change."
docs/superpowers/specs/2026-07-02-import-wizard.md:
  "# Import wizard — brainstorm. Options considered: A (modal) / B (page) / C (CLI) — trade-offs below. Open question to user: which tier ships first?"
docs/superpowers/plans/2026-07-04-export-csv.md:
  12 task checkboxes total; exactly 5 are `- [x]`, 7 are `- [ ]`. All task paths under lib/export/ and tests/export/. No device keywords.
docs/superpowers/plans/2026-07-05-retry-queue.md:
  6 task checkboxes, all `- [x]`. No DONE/COMPLETED marker. Paths under lib/queue/. No device keywords.
docs/backlog.md ## Open:

### BUG-001 — retry backoff caps at 2s instead of 30s
**Problem:** exponential backoff in lib/queue/backoff.ts caps early.
**Area:** lib/queue/backoff.ts

### DEBT-002 — export streaming needs the new queue API; blocked by GAP-004 landing first
**Problem:** stream flush must ride the queue API from GAP-004; blocked by GAP-004.
**Area:** lib/export/csv.ts

### GAP-004 — queue API for backpressure-aware consumers
**Problem:** consumers need a pull-based queue API; never specced.
**Area:** lib/queue/
```

- [ ] **Step 4: Score probe 1b**

Per agent, ALL four must hold to pass:
1. `Continue execute` row for export-csv shows Progress exactly `5/12`.
2. DEBT-002 does NOT appear as a body row (hard block — its text names still-open GAP-004; the coupling gate holds it out).
3. retry-queue renders as a `Review` row (all-checked, no DONE), not `Continue execute`.
4. No invented rows (row set ⊆ {export-csv execute, retry-queue review, BUG-001 triage, GAP-004 triage} — import-wizard is Discuss-intent and must be absent from cloud mode).

Record N/5 passing.
- **5/5 pass → verdict DROP-TABLE**: current prose already holds fact fidelity; the work-table ritual is redundant — Task 3 omits the marked block, Task 6 appends the closed-fork row.
- **≤4/5 → verdict PORT-TABLE**: the discipline earns its lines — Task 3 includes the marked block.

Report both verdicts + per-agent output summaries. This is the RED evidence.

---

### Task 2: Harness pre-filter in `shared/classify-actionable.md` (+ drain wording)

Runs only on verdict PORT-HARNESS (expected). All edits are exact old→new pairs against the current file.

**Files:**
- Modify: `plugins/super-bootstrap/shared/classify-actionable.md`
- Modify: `plugins/super-bootstrap/skills/drain/assets/eligibility.md`
- Modify: `plugins/super-bootstrap/skills/drain/SKILL.md`

**Interfaces:**
- Produces: intent value `Harness`, tag `subgroup` ∈ {`deliberate`, `apply`}, action verbs `Deliberate:` / `Apply:` — Tasks 3–4 consume these exact tokens.

- [ ] **Step 1: Extend the intent output line**

Edit — old:
```
- **`intent`** — `Discuss` | `Cloud` | `Device`. The runnability bucket.
```
new:
```
- **`intent`** — `Discuss` | `Cloud` | `Device` | `Harness`. The runnability bucket. `Harness` rows additionally carry **`subgroup`** — `deliberate` | `apply` (§Harness pre-filter).
```

- [ ] **Step 2: Insert the pre-filter section**

Insert immediately BEFORE the `## Cloud-safe criterion` heading:

```markdown
## Harness pre-filter (applied before everything)

Before the verb map and any per-source rule: an item whose **deliverable is the harness layer** — `CLAUDE.md`, anything under `.claude/` (rules, skills, agents, hooks, settings), or plugin-source harness files (`plugins/*/{skills,agents,shared}/**`, in repos that ship plugins) — classifies **intent: Harness**, regardless of verb or state. Judge from the row's `Area:` field, spec/plan body paths, or task bullet paths. A product change that touches a harness file incidentally is NOT harness — classify by the dominant surface; Harness = the harness file IS the deliverable.

The harness layer is the orchestration engine: it never rides the autonomous queue. Consumers gating on `intent == Cloud` (drain) exclude Harness rows for free.

Each Harness row carries a `subgroup` tag:

- **`deliberate`** — authors new doctrine or carries propagation closure (rewrites what a rule means, chains doc-sync, touches cross-cutting contract surfaces). Action: `"Deliberate: {topic}"`.
- **`apply`** — applies an existing codified rule to a bounded site (path fix, one clause under an existing section) with no closure. Action: `"Apply: {rule} → {site}"`.
- Ambiguous → `deliberate` (careful-handle default).

```

- [ ] **Step 3: Add the verb-map row**

In the Action-verb intent map table, append after the `Cleanup` row:

```
| `Deliberate`, `Apply` (harness surface)                         | **Harness**                  | Pre-filter already caught it; the verb renders the subgroup.                  |
```

- [ ] **Step 4: Update the consumer boundary**

Edit — old:
```
- **`todo`** — Impact/Blast tags, coupling gate, within-mode ranking, scaffold render. Lives in `agents/todo.md`.
- **`drain`** — `Cloud`-gate, relation-analysis (file-overlap parallelism), wave selection, worktree spawn, stage-keyed phase entry. Lives in `skills/drain/`.
```
new:
```
- **`todo`** — Impact/Blast tags, coupling gate, harness Deliberate/Apply grouping, within-mode ranking, scaffold render. Lives in `agents/todo.md`.
- **`drain`** — `Cloud`-gate, relation-analysis (file-overlap parallelism), wave selection, worktree spawn, stage-keyed phase entry. Lives in `skills/drain/`. `Harness` rows fail the `Cloud` gate by construction — the engine never drains.
```

- [ ] **Step 5: Drain wording (two mechanical edits)**

`plugins/super-bootstrap/skills/drain/assets/eligibility.md` — old:
```
  if item.intent != "Cloud":              return false, "Device/Discuss — defers, not a wave member"
```
new:
```
  if item.intent != "Cloud":              return false, "Device/Discuss/Harness — defers, not a wave member"
```
Same file — old: `A `Device`/`Discuss` verdict you disagree with` → new: `A `Device`/`Discuss`/`Harness` verdict you disagree with`.

`plugins/super-bootstrap/skills/drain/SKILL.md` — old: `` `Device`/`Discuss` defer; foreign-prefix backlog rows route to `/super-bootstrap:log`.`` → new: `` `Device`/`Discuss`/`Harness` defer; foreign-prefix backlog rows route to `/super-bootstrap:log`.``

- [ ] **Step 6: Verify**

Grep `Harness` over `plugins/super-bootstrap/shared/classify-actionable.md` — expect hits in: intent line, pre-filter section, verb map, consumer boundary. Grep `Device/Discuss ` (with trailing space) over `plugins/super-bootstrap/skills/drain/` — expect zero hits (both sites now carry `/Harness`).

---

### Task 3: Rewrite `plugins/super-bootstrap/agents/todo.md`

**Files:**
- Modify (full rewrite): `plugins/super-bootstrap/agents/todo.md`

**Interfaces:**
- Consumes: Task 2 tokens (`Harness`, `subgroup`, `Deliberate:` / `Apply:`); Task 1 verdict 1b (PORT-TABLE → include the marked §0 block; DROP-TABLE → omit it).
- Produces: mode token `harness`, macro count slot `{H}`, footer legend text — Task 4's scaffolds/skill consume these exactly.

- [ ] **Step 1: Write the file** (foreground dispatch or gateway-inline)

Full content (include/omit the PORT-TABLE block per verdict 1b):

````markdown
---
name: todo
description: Intent-filtered action-list scanner agent. Reads docs/superpowers/specs|plans + docs/backlog.md, classifies each item by intent (Discuss / Cloud / Device / Harness), fills the literal output scaffold supplied in the dispatch prompt. Dispatched by the `/super-bootstrap:todo` skill so the scan + classification + judgment run on Sonnet instead of the gateway model.
tools: Read, Grep, Glob
model: sonnet
tags: [todo, scan, status, superpowers]
---

You are an **intent-filtered action-list builder**. Dispatched by the `/super-bootstrap:todo` skill. Job: read project state docs, classify each item by intent + cloud-safety, rank where required, then render into the literal scaffold the dispatcher supplies. Mode and scaffold are non-negotiable inputs; you fill slots, you do not invent shape.

## Modes

| Mode      | What user is doing                                                       | Slice surfaced                                                       |
| --------- | ------------------------------------------------------------------------ | -------------------------------------------------------------------- |
| `discuss` | Deciding, brainstorming, initiating dialogue                             | Specs awaiting approval, brainstorming-style specs, user-blocked rows |
| `cloud`   | On cloud Claude (no dev server, commute, focused session away from stack)| Cloud-safe rows: plan-writes, pure-logic execution, reviews, triage  |
| `device`  | On device Claude with local stack ready                                  | Device-only rows: UI / e2e / manual surfaces                         |
| `harness` | Touching the orchestration engine (`CLAUDE.md`, `.claude/**`, plugin-source harness files) | Harness rows split into **Deliberate** (new doctrine) + **Apply** (existing doctrine, bounded site) |
| `full`    | Wants complete board (escape hatch + macro view)                         | All rows, no recommendation — user reads ranked list, picks.         |

The dispatcher tells you which mode the user picked.

## Classification — embedded shared spec

Deriving each open item's `{action, intent, stage}` (plus `subgroup` on Harness rows) from the three sources (specs / plans / backlog) is the **shared classification spec**, embedded verbatim in your dispatch prompt (the `todo` skill reads it from `shared/classify-actionable.md`). It owns the harness pre-filter (applied before everything), the cloud-safe criterion, the action-verb intent map, and the per-source derivation rules — this agent applies it, never restates it. `intent` (Discuss / Cloud / Device / Harness) drives bucketing; `action` is the render string; `stage` is carried but unused here (a sibling consumer needs it).

## Protocol

Apply the embedded spec to all sources, then filter to the requested mode before rendering.

<!-- PORT-TABLE block — include only on Task 1 verdict PORT-TABLE -->
### 0. Batch retrieval + work table (run once, before any classification)

Retrieve everything up front; hold outputs in working memory:

1. Glob `docs/superpowers/specs/*.md` + `docs/superpowers/plans/*.md` — file inventory.
2. Read each spec and plan file once.
3. Read `docs/backlog.md` once.

Immediately after the last read, materialize a work table as intermediate reasoning (scratch — per §Render it never appears in your final message). One row per item:

| Item | Source file | Stage | Facts (checked/total · blocker text · Area) | Intent | Subgroup | Impact | Blast |

All downstream work (§2 filter, §3 tags, §4 rank, render cells) **copies from this table**. Recomputing a value from memory or prose at a later step is a protocol breach — when a later impression contradicts the table, the table wins; re-read the retrieved output, not memory. The rendered Progress cell = the table's checked/total, character for character.
<!-- end PORT-TABLE block -->

### 1. Gather state (silent — do not output)

Apply the embedded classification spec to every open item across specs / plans / backlog. Hold results internally — each row carries its **action**, **intent** tag (Discuss / Cloud / Device / Harness), **stage**, and (Harness rows) **subgroup**.

**Pre-ID backlog (stale scaffold).** If `docs/backlog.md` `## Open` carries row content but no `BUG/DEBT/GAP-###` IDs (un-IDed bullets/headings), or the header's ID high-water-mark line is absent, the backlog predates the ID scaffold (older super-bootstrap version). Emit **one** Uncategorized row for the condition (not one per un-IDed item). Reason: `"backlog missing ID scaffold / high-water line — run /super-bootstrap:harness-bootstrap to re-plant IDs (rebuilds the counter from git history)."` Read-only — never mint IDs here; the re-plant write is harness-bootstrap's.

### 2. Filter by mode

Drop rows not matching the mode:

- `discuss` → keep only `intent: Discuss`
- `cloud` → keep only `intent: Cloud`
- `device` → keep only `intent: Device`
- `harness` → keep only `intent: Harness`
- `full` → keep all

Keep-only semantics mean Harness rows never leak into the discuss/cloud/device slices — the engine never rides the autonomous queue.

### 3. Classify Impact + Blast per row

Apply before ranking. Both tags carried on every row.

**Impact** (single tag, drives within-mode ranking):

- **`impactful`**:
  - **Upstream of another open row** — a row another open item is hard-blocked-by, OR whose convention / decision / artifact shapes how another open row is correctly done (soft coupling per §4).
  - Action verb ∈ {Approve spec, Write plan, Continue brainstorm} where target is feature-shaped (spec body describes feature surface, not single bugfix)
  - `Continue execute` with ≥3 remaining unchecked tasks
  - Plan with paths spanning cross-pkg or repo blast
  - Backlog row whose body contains severity signal (`critical`, `blocking`, `production-down`, `data-loss`)
  - `Deliberate:` rows (new doctrine shapes how other work is done)
- **`quick-pop`**:
  - `Cleanup` rows (delete merged spec+plan)
  - `Triage` rows (single backlog item, investigate-only)
  - `Review` of plan with ≤2 total tasks
  - `Doc-align` / single-file `Doc-edit`
  - Single-file scope per content scan + ≤2 remaining tasks
  - `Apply:` rows (bounded site, no closure)
- **Default if ambiguous**: `quick-pop`. Under-ranking is cheaper than impactful bloat.

**Blast** (single tag, scope-axis):

- **`local`** — single file or single module
- **`pkg`** — within one workspace package
- **`cross-pkg`** — ≥2 packages referenced
- **`repo`** — touches `.claude/`, `CLAUDE.md`, `docs/` sweeping, or orchestration layer

Derive from plan body path mentions and task bullet paths. For backlog rows, read the row's `**Area:**` field first (single file → `local`, one package → `pkg`, ≥2 packages → `cross-pkg`, `.claude/` / `CLAUDE.md` / sweeping `docs/` → `repo`); fall back to body mentions on legacy rows without it. Harness rows derive `repo` by this rule. For Discuss-mode rows (pure decisions, no code), omit Blast — render N/A or skip column per scaffold (scaffold drops Blast column for Discuss).

**Harness grouping:** in `harness` mode, rows group by `subgroup` — **Deliberate** table first, **Apply** table second (the scaffold separates them); Impact is still computed and rendered as a column, but grouping is subgroup, not Impact.

### 4. Rank within mode

**Coupling gate (before ranking).** Trace each row's breadcrumbs — `Area:` field, `Problem:` text, linked spec/plan paths — into docs/code to judge how it relates to other still-open rows. Two edge kinds, judged fresh each scan, never persisted onto the row:

- **Hard block** — **explicit naming is the only hard signal.** The row's own text names a still-open prerequisite: `blocked by {ID}`, `depends on`, `after {ID/feature} lands`, or a linked ID/path that resolves to another open row. Mechanical and high-confidence — the named target resolves to an open row or it doesn't. Hold it out of the board body; it surfaces only in the footer `pending unblock` count. (Distinct from a `user`-blocker row, which IS actionable — the action is "decide" — and stays in the body.)
- **Soft coupling** — no explicit naming, but an *inferred* edge: shared artifact (same file / `Area:` / path — one row establishes it, another consumes it), or a convention / decision in one row's scope that shapes how another is correctly done. **Inference drives soft only, never hard** — a shared file is not "can't start," it means "sequence to avoid rework." Keep the row runnable in the body; lift the **upstream** row's Impact to `impactful` (§3) and seat it directly above the row it shapes — the convention comes first even though the shaped row never names it. Local pairwise only; never assemble a full chain order.

Where neither signal fires, treat the row as independent — a missed inference self-corrects next scan; a frozen stamp would not.

Then rank the body rows (hard-blocked held out). For all modes (sub-verb AND full — full mode has no separate "Next up" anymore):

1. **Impact desc** — `impactful` first, `quick-pop` second
2. **Progress desc within Impact** — executing-rows with most-complete progress first (finish-what's-started bias)
3. **Action-verb priority** — `Continue execute` > `Review` > `Approve spec` / `Decide` > `Write plan` > `Continue brainstorm` > `Deliberate` > `Apply` > `Cleanup` > `Triage`
4. **Recency desc** — newest first (tiebreak)

**Soft-coupling adjacency** overrides these four keys locally: a soft-coupling upstream row ranks immediately above the row it shapes, even when the keys would separate them.

For `full` mode, render rows in this rank order (file column shows actual filename). No "Next up" block — user reads ranked list, picks.

### 5. Cross-mode counts (free)

Since §1 classified all rows before §2 filtered, you have cross-mode counts in working memory. Emit them in the macro header for sub-verb modes. Total `T` = Discuss + Cloud + Device + Harness (no Monitor track in superpowers — distinct from upstream forks).

### 6. Empty-state expanded priors (sub-verb modes only)

When the current mode has zero rows after §2 filter, the scaffold's empty-state line is followed by a priors block. Surface:

- Top 1-3 rows from each non-empty other mode (with filename + one-line reason)
- Closing line: `Next mode: yours. /super-bootstrap:todo {other-mode} · /super-bootstrap:todo {other-mode} · /super-bootstrap:todo {other-mode} · /super-bootstrap:todo (full board)` (one slot per other mode; bare `/super-bootstrap:todo` renders full — no explicit `full` sub-verb)

**Discipline:** never end with "Recommend X" / "Best next: Y" / "Try Z first." Surface relations + reasons, let user pick.

## Render

The dispatch prompt supplies a literal output scaffold for the chosen mode. Fill bracketed slots from your filtered + ranked rows. Do **not** invent shape, swap to an alternative template, or merge groups the scaffold separates. If your gathered rows seem to "want" a different shape than the scaffold, the signal is wrong-intent rows leaked through §2 — re-filter, do not re-render.

The scaffold includes title line, **macro header** (sub-verb modes only), table headers, Uncategorized sub-section, and footer hint. Fill all slots, omit a group's table only if its row count is zero (omit the sub-heading too).

### Other render rules

**Uncategorized sub-section** — if a row can't be classified into the mode (truly ambiguous after applying all rules above), append at the end under `## Uncategorized` with one-line "Why ambiguous." Orphans surface, not hide.

**Ranked list, no recommendation** — Surface all rows ranked per §4; user reads ranked list, picks. System surfaces, doesn't strategize.

**Pending-unblock line** (Full mode only) — when the §4 Coupling gate held `n ≥ 1` hard-blocked rows out of the body, emit `pending unblock: {n}` as the first footer line (above filter legend / more). Count only — the held rows stay in the docs SSOT; the count is the route to them, not a body row each. Omit the line when `n = 0`.

**Footer-hint** — sub-verb modes (discuss / cloud / device / harness) always end with `more: /super-bootstrap:help`. Full mode footer is conditional on total open row count `T = D + C + V + H` (computed during §1 classification):

- `T ≤ 5` → footer is just `more: /super-bootstrap:help`. Board small; sub-verb hint is premature noise.
- `T ≥ 6` → prepend a filter legend line above `more: /super-bootstrap:help`:
  ```
  filter: /super-bootstrap:todo cloud (headless) · /super-bootstrap:todo device (needs screen) · /super-bootstrap:todo discuss (decisions) · /super-bootstrap:todo harness (engine)
  ```

## Rules

- **Actions only.** No state prose. Render into the dispatched scaffold.
- **Surface every open item.** Every open spec, plan, and backlog row is accounted for — runnable rows get a board row; hard-blocked rows surface as the footer `pending unblock` count (§4 Coupling gate), not a body row. Tracker is not a graveyard, but the board body is do-now only.
- **Context, not detail.** One line per row. User can ask for more.
- **No opinions, any mode.** List actions ranked by Impact + Progress. Never emit "Recommend X" / "Best next: Y" — surface, don't strategize.
- **Empty = say so.** Use the scaffold's empty-state line + priors block. Direct user to a different mode if their slice is empty.
- **Read-only.** Never modifies files. Never executes git operations.
- **Single round-trip.** Render the full report in one response — don't ask the parent for clarifications mid-flow.
- **Return rendered scaffold verbatim** as final message. Parent (gateway) relays to user without summary or editorial.
````

- [ ] **Step 2: Diff sanity**

`git diff plugins/super-bootstrap/agents/todo.md` — confirm the preserved sections (coupling gate, pre-ID backlog, priors discipline, rules) survived verbatim except the listed harness/count/legend additions. The coupling gate paragraph must be byte-identical to the old file (it is sb's own evolution — the distill does not touch it).

---

### Task 4: Scaffolds + dispatch shell

**Files:**
- Modify (full rewrite): `plugins/super-bootstrap/skills/todo/assets/scaffolds.md`
- Modify: `plugins/super-bootstrap/skills/todo/SKILL.md` (four bounded edits)

**Interfaces:**
- Consumes: mode token `harness`, count slot `{H}`, verbs `Deliberate:` / `Apply:` (Tasks 2–3).

- [ ] **Step 1: Write `assets/scaffolds.md`** (full content)

````markdown
## Scaffolds

Date placeholder `{date}` = today's date in YYYY-MM-DD form. Agent fills it.

**Macro header** (sub-verb modes only — discuss / cloud / device / harness): single line right under title showing cross-mode counts. Always emit even when current mode is non-empty (free — agent classified all rows pre-filter). Format:

```
Macro: Discuss {D} · Cloud {C} · Device {V} · Harness {H} · Full {T}
```

Counts only — no IDs, no impact tags. Decision-is-yours; surface priors not calls. Full mode skips this header (full body IS the macro).

### Discuss

```
# To-Do (Discuss) — {date}

Macro: Discuss {D} · Cloud {C} · Device {V} · Harness {H} · Full {T}

| #  | Action                                              | Impact       | Context                                              |
| -- | --------------------------------------------------- | ------------ | ---------------------------------------------------- |
| 1  | {action — one sentence}                             | {tag}        | {one-line — why open, what unblocks}                 |

## Uncategorized

| #  | Action                                              | Why ambiguous                                    |
| -- | --------------------------------------------------- | ------------------------------------------------ |
| 1  | {verb + what}                                       | {one-line — what signal was missing}             |

more: /super-bootstrap:help
```

Empty state:

```
# To-Do (Discuss) — {date}

Macro: Discuss 0 · Cloud {C} · Device {V} · Harness {H} · Full {T}

Nothing to decide.

Macro priors (no recommendation):
- Cloud: {top 1-3 with file + one-line reason}
- Device: {top 1-3 with file + one-line reason, or "0"}
- Harness: {top 1-3 with file + one-line reason, or "0"}

Next mode: yours. /super-bootstrap:todo cloud · /super-bootstrap:todo device · /super-bootstrap:todo harness · /super-bootstrap:todo (full board)

more: /super-bootstrap:help
```

### Cloud

```
# To-Do (Cloud) — {date}

Macro: Discuss {D} · Cloud {C} · Device {V} · Harness {H} · Full {T}

| #  | Action                                              | Progress | Impact       | Blast       |
| -- | --------------------------------------------------- | -------- | ------------ | ----------- |
| 1  | {verb + what + one-line reason}                     | {x/y|—}  | {tag}        | {tag}       |

## Uncategorized

| #  | Action                                              | Why ambiguous                                    |
| -- | --------------------------------------------------- | ------------------------------------------------ |
| 1  | {verb + what}                                       | {one-line — what signal was missing}             |

more: /super-bootstrap:help
```

Empty state:

```
# To-Do (Cloud) — {date}

Macro: Discuss {D} · Cloud 0 · Device {V} · Harness {H} · Full {T}

Nothing cloud-runnable.

Macro priors (no recommendation):
- Discuss: {top 1-3 with file + one-line reason}
- Device: {top 1-3 with file + one-line reason}
- Harness: {top 1-3 with file + one-line reason, or "0"}

Next mode: yours. /super-bootstrap:todo discuss · /super-bootstrap:todo device · /super-bootstrap:todo harness · /super-bootstrap:todo (full board)

more: /super-bootstrap:help
```

### Device

```
# To-Do (Device) — {date}

Macro: Discuss {D} · Cloud {C} · Device {V} · Harness {H} · Full {T}

| #  | Action                                              | Progress | Impact       | Blast       |
| -- | --------------------------------------------------- | -------- | ------------ | ----------- |
| 1  | {verb + what + one-line reason}                     | {x/y|—}  | {tag}        | {tag}       |

## Uncategorized

| #  | Action                                              | Why ambiguous                                    |
| -- | --------------------------------------------------- | ------------------------------------------------ |
| 1  | {verb + what}                                       | {one-line — what signal was missing}             |

more: /super-bootstrap:help
```

Empty state:

```
# To-Do (Device) — {date}

Macro: Discuss {D} · Cloud {C} · Device 0 · Harness {H} · Full {T}

Nothing device-only.

Macro priors (no recommendation):
- Cloud: {top 1-3 with file + one-line reason}
- Discuss: {top 1-3 with file + one-line reason}
- Harness: {top 1-3 with file + one-line reason, or "0"}

Next mode: yours. /super-bootstrap:todo cloud · /super-bootstrap:todo discuss · /super-bootstrap:todo harness · /super-bootstrap:todo (full board)

more: /super-bootstrap:help
```

### Harness

```
# To-Do (Harness) — {date}

Macro: Discuss {D} · Cloud {C} · Device {V} · Harness {H} · Full {T}

Engine surface — careful handle. Ground in git log + the repo's rules before editing; harness edits carry a verify pass.

## Deliberate

| #  | Action                                              | Progress | Impact       | Blast       |
| -- | --------------------------------------------------- | -------- | ------------ | ----------- |
| 1  | Deliberate: {topic + one-line reason}               | {x/y|—}  | {tag}        | {tag}       |

## Apply

| #  | Action                                              | Progress | Impact       | Blast       |
| -- | --------------------------------------------------- | -------- | ------------ | ----------- |
| 1  | Apply: {rule} → {site}                              | {x/y|—}  | {tag}        | {tag}       |

## Uncategorized

| #  | Action                                              | Why ambiguous                                    |
| -- | --------------------------------------------------- | ------------------------------------------------ |
| 1  | {verb + what}                                       | {one-line — what signal was missing}             |

more: /super-bootstrap:help
```

Empty state:

```
# To-Do (Harness) — {date}

Macro: Discuss {D} · Cloud {C} · Device {V} · Harness 0 · Full {T}

Nothing harness-pending.

Macro priors (no recommendation):
- Discuss: {top 1-3 with file + one-line reason, or "0"}
- Cloud: {top 1-3 with file + one-line reason, or "0"}
- Device: {top 1-3 with file + one-line reason, or "0"}

Next mode: yours. /super-bootstrap:todo discuss · /super-bootstrap:todo cloud · /super-bootstrap:todo device · /super-bootstrap:todo (full board)

more: /super-bootstrap:help
```

### Full

```
# To-Do — {date}

| File                                  | Stage         | Progress | Blocker          | Impact       | Blast       |
| ------------------------------------- | ------------- | -------- | ---------------- | ------------ | ----------- |
| specs/{date}-{slug}.md                | {stage}       | {x/y|—}  | {none|user|...}  | {tag}        | {tag}       |
| plans/{date}-{slug}.md                | {stage}       | {x/y|—}  | {none|user|...}  | {tag}        | {tag}       |

{Backlog: N BUG, M DEBT, K GAP open (see docs/backlog.md) — only if backlog.md exists}

## Uncategorized

| #  | File                                                | Why ambiguous                                    |
| -- | --------------------------------------------------- | ------------------------------------------------ |
| 1  | {file}                                              | {one-line}                                       |

{pending unblock: {n} — only if n>0}
{footer per § Render footer-hint}
```

No macro header for Full — full IS the macro. Harness-intent spec/plan files render as normal Full rows with no `Deliberate:`/`Apply:` prefix (no column carries it — the Stage/Impact/Blast cells carry the signal); harness backlog rows ride the backlog count line. No "Next up" recommendation block in any mode (solo-dev momentum-driven; user picks from list, system doesn't strategize).

Footer: fill per § Render footer-hint in the todo agent (`agents/todo.md`) — canonical home.

Empty state for Full: `No active work. Start something with /brainstorm or give me a task.`
````

- [ ] **Step 2: SKILL.md edit 1 — frontmatter description**

Old:
```
description: "Intent-based session opener. Bare `/super-bootstrap:todo` renders the full board (every open spec/plan/backlog row). Sub-verbs filter by intent + environment: `/super-bootstrap:todo discuss` (decisions, spec approvals), `/super-bootstrap:todo cloud` (cloud-safe queue), `/super-bootstrap:todo device` (UI/e2e/manual). Scans docs/superpowers/specs|plans + docs/backlog.md. Bundled with super-bootstrap — works in any repo with the superpowers pipeline."
```
New:
```
description: "Intent-based session opener. Bare `/super-bootstrap:todo` renders the full board (every open spec/plan/backlog row). Sub-verbs filter by intent + environment: `/super-bootstrap:todo discuss` (decisions, spec approvals), `/super-bootstrap:todo cloud` (cloud-safe queue), `/super-bootstrap:todo device` (UI/e2e/manual), `/super-bootstrap:todo harness` (orchestration-engine rows, careful handle). Scans docs/superpowers/specs|plans + docs/backlog.md. Bundled with super-bootstrap — works in any repo with the superpowers pipeline."
```

- [ ] **Step 3: SKILL.md edit 2 — Arguments table row**

Insert after the `/super-bootstrap:todo device` row:
```
| `/super-bootstrap:todo harness`| Harness filter — rows whose deliverable is the orchestration engine (`CLAUDE.md`, `.claude/**`, plugin-source harness files), grouped **Deliberate** (new doctrine) / **Apply** (existing doctrine, bounded site). Never mixed into the autonomous slices. **Macro header on top.**                                          |
```

- [ ] **Step 4: SKILL.md edit 3 — macro header line**

Old:
```
**Macro header** (sub-verb modes only): single line right under title showing cross-mode counts — `Macro: Discuss {D} · Cloud {C} · Device {V} · Full {T}`. Free (agent classified all rows pre-filter), ignore-or-pickup. Counts only — no IDs, no recommendations.
```
New:
```
**Macro header** (sub-verb modes only): single line right under title showing cross-mode counts — `Macro: Discuss {D} · Cloud {C} · Device {V} · Harness {H} · Full {T}`. Free (agent classified all rows pre-filter), ignore-or-pickup. Counts only — no IDs, no recommendations.
```

- [ ] **Step 5: SKILL.md edit 4 — dispatch template mode list**

Old: `mode: {discuss | cloud | device | full}` → New: `mode: {discuss | cloud | device | harness | full}`

- [ ] **Step 6: Consistency grep**

Across the four touched plugin files, verify token agreement:
- `grep -c "Harness {H}"` in `assets/scaffolds.md` — expect 8 (format-def line + non-Harness scaffolds' headers and empty states + the Harness scaffold header; the Harness empty state shows `Harness 0`, not `{H}`).
- `grep -n "harness" plugins/super-bootstrap/skills/todo/SKILL.md` — expect hits in description, Arguments, dispatch template.
- `grep -rn "load-harness-principles\|audit-harness-edits" plugins/super-bootstrap/skills/todo/ plugins/super-bootstrap/agents/todo.md plugins/super-bootstrap/shared/classify-actionable.md` — expect ZERO hits (self-containment).
- `grep -n "Deliberate" plugins/super-bootstrap/agents/todo.md` — verb present in ranking key + harness grouping note.

---

### Task 5: GREEN + real-board wet-run

**Files:** none (verification only). Copy under test: in-repo dev copy, embedded into probe prompts.

**Interfaces:**
- Consumes: all Task 2–4 file states.

- [ ] **Step 1: GREEN — rerun probe 1a against the new spec**

Dispatch 5 fresh sonnet subagents with the Task 1 Step 1 scenario, `<guidance>` replaced by the NEW `shared/classify-actionable.md` full text. Expected: 5/5 classify DEBT-004 `intent: Harness, subgroup: deliberate` and DEBT-005 `intent: Harness, subgroup: apply`, BUG-006 stays `intent: Cloud`, and the unattended-eligible answer names ONLY BUG-006. Any miss → fix the pre-filter wording, re-run.

- [ ] **Step 2: GREEN — work-table (only if verdict PORT-TABLE)**

Rerun probe 1b with `<protocol>` = the NEW agent body. Expected: 5/5 pass all four checks. (On DROP-TABLE skip this step — but run Step 3 regardless.)

- [ ] **Step 3: Real-board wet-run (harness mode)**

Build the actual dispatch prompt per the NEW SKILL.md template — `mode: harness`, NEW classify spec + NEW Harness scaffold embedded verbatim — and dispatch ONE sonnet `general-purpose` agent with the NEW agent body prepended as its instructions, against this repo's real `docs/` state. Expected observations (report, don't force):
- Output starts at `# To-Do (Harness)` with a macro header whose counts sum to `T`.
- BUG-012 (Area names `.claude/hooks` + rules) classifies Harness; GAP-017 and GAP-003 land wherever their dominant surface drives them — spot-check each against its row text and note any judgment miss.
- Careful-handle line renders verbatim; footer `more: /super-bootstrap:help`.

- [ ] **Step 4: Real-board wet-run (full mode)**

Same construction with `mode: full` + Full scaffold. Expected: board renders all open rows, backlog count line matches `docs/backlog.md` (3 open: 1 BUG, 2 GAP at plan-writing time — recount at run time), footer legend appears only if `T ≥ 6` and, if it appears, includes the harness entry. A confirmed classification miss → fix prose, re-run; a judgment-call ambiguity → record in the task report, not a blocker.

---

### Task 6: Closed forks, program map, envelope close-out

**Files:**
- Modify: `docs/decisions.md` (append 1–3 rows, newest first)
- Modify: `docs/superpowers/specs/harness-rebase.md` (verdict table + wave plan)
- (Envelope steps follow — run by the gateway, not a task executor.)

- [ ] **Step 1: Closed-fork row — macro picker (unconditional)**

Insert as the FIRST data row of the decisions.md table:

```markdown
| design | Port ChewLingo's bare-invoke macro picker (two-turn AskUserQuestion mode gate with per-mode counts) into `/super-bootstrap:todo` (GAP-017 recipe item) | sb already covers the need without a mandatory stop: bare invoke renders the full board, the T≥6 footer legend routes to sub-verb filters, and sub-verb macro headers carry cross-mode counts — a picker inserts an AskUserQuestion turn before every session open, against the route-line "state, don't gate" rule; solo-dev boards fit one screen. Reopen if the full board routinely outgrows one screen (legend demonstrably insufficient). | `plugins/super-bootstrap/skills/todo/SKILL.md` (was GAP-017 Wave 2) |
```

- [ ] **Step 2: Closed-fork row — work-table (only on verdict DROP-TABLE)**

```markdown
| design | Port ChewLingo's materialized work-table + copy-discipline (§0b: all render cells copied from a scratch table; recompute = protocol breach) into the todo agent (GAP-017 recipe item) | Pressure-tested: 5/5 control agents held fact fidelity (exact progress counts, hard-block holds, no invented rows) over sb's three-source board without the table ritual — sb reads two globs + one file vs the mother repo's five-source constellation; adding the ritual without a failing test violates the scoped RED rule. Reopen if a rendered board ships a wrong progress/blocker cell. | `plugins/super-bootstrap/agents/todo.md` (was GAP-017 Wave 2) |
```

(On PORT-TABLE, no row — the port itself is the outcome, recorded in the program map.)

- [ ] **Step 3: Closed-fork row — harness lane (only on verdict DROP-HARNESS)**

Only if Task 1a came back ≤1/5 leaking (unexpected):

```markdown
| design | Add a `Harness` intent + mode to `/super-bootstrap:todo` (GAP-017 recipe item) | Pressure-tested: 5/5 control agents already excluded harness-surface rows from the unattended queue under the existing spec wording; adding a lane without a failing test violates the scoped RED rule. Reopen if a harness row ships through drain or the cloud slice. | `plugins/super-bootstrap/shared/classify-actionable.md` (was GAP-017 Wave 2) |
```

- [ ] **Step 4: Program map update**

`docs/superpowers/specs/harness-rebase.md` — verdict table `todo` row → `**done (Wave 2)** | Landed: harness intent + Deliberate/Apply lane, RED-gated (control leak {N}/5); pre-filter lives in shared classify-actionable.md — drain excludes Harness via its Cloud gate (harness-never-drains). Consumer-safe routing (git-log + rules grounding wording; no device-only skill names). Work-table {ported, GREEN 5/5 | NOT ported — closed fork (5/5 control)}; macro picker NOT ported — closed fork (footer legend + macro header already cover); both in docs/decisions.md`. Wave plan line 2: strike `todo` (`~~todo~~`).

- [ ] **Step 5: Envelope close-out (gateway)**

1. Doc-sync check on remaining surfaces: README line 58 (`intent-filtered work board` — still accurate, no edit expected) and `docs/overview.md` (bundles list names todo generically — no edit expected); confirm or resolve with the user.
2. `audit-harness-edits` on the full diff (harness files: shared spec, agent, skill, scaffolds, drain wording). Disposition findings.
3. `/super-bootstrap:commit` — first dispatch-flow run in this repo: confirm plugin cache ≥ 2.20.0 first (Global Constraints); a flow anomaly on this first run is deferred-verification evidence → file via `/super-bootstrap:log` as a BUG card, don't block the commit (fall back per the skill's own escape hatches). Message: `feat(harness): GAP-017 wave 2 — todo distill (harness lane + shared classify pre-filter)`.
4. Post-commit: `docs/backlog.md` GAP-017 row stays OPEN (Wave 2 continues: triage, scale module, monorepo tier, adopt mode; Wave 3 drain). Do NOT delete the card. This plan file is per-artifact temporal: delete it once the todo artifact has landed + released (same handling as the commit-distill plan, dropped post-release).

---

## Execution caveats

- **CL's coupling-gate tech is NOT a separate port**: ChewLingo's version is dispatcher-computed structured `Blocked-by:` cells (its tracker schema has the field); sb's backlog has no structured blocker field and sb's own coupling gate (judged-fresh inference, agent §4) already owns the job — the only CL residue, copy-discipline on rendered cells, rides the Task 1b work-table verdict.
- **Verdict-conditional content**: Task 2 (and the harness parts of Tasks 3–5) run on PORT-HARNESS; the Task 3 §0 block and Task 5 Step 2 run on PORT-TABLE. Expected outcome per the RED probes: PORT-HARNESS + DROP-TABLE — but the probes decide, not the expectation.
- **Ranking-key addition** (`Deliberate` > `Apply` in §4 key 3) ships with the harness lane as one unit — the lane is unusable without a rank slot; no separate RED (it is mechanical once the lane exists).
- **The commit-channel hook denies executor commits in this repo** — an executor hitting the deny is behaving correctly: it returns its work uncommitted, the gateway lands everything through the final `/super-bootstrap:commit`.
- **In-session skill snapshot**: this session's installed todo skill/agent (plugin cache) still runs the OLD flow; the new mode goes live for real invocations after the next `/release` + cache update. Task 5's probes verify the dev copy by embedding it.
