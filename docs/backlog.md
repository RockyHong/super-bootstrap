# Backlog

New rows route through `/super-bootstrap:log` — one funnel for classification, dedup, and ID assignment. Bugs, debt, design gaps, and unverified feature ideas all land here as rows; whether each is real or worth doing is decided at `/super-bootstrap:todo` triage on pickup, not at capture.

**When a card is owed:** only for work that exits the current flow **incomplete** — deferred or dropped. Work completed in-flow, whoever directed it, carries no card debt. The trigger is completion-state (observable), not worth (triage's call).

**Row deletion:** the resolving session — via `/super-bootstrap:commit` doc-sync, or manually on resolve. Direct `git commit` skips the sweep; clean up stale rows when noticed.

**Three categories** distinguished by ID prefix:

- **`BUG-###`** — broken behavior. Surface symptom may hide deeper cause.
- **`DEBT-###`** — working but rotting (test fixture rot, stale dep, cleanup owed).
- **`GAP-###`** — design gap or unverified capability idea, never properly specced. Forward feature ideas land here; triage decides drop / spec.

No phase prescription per category — when an item rolls into a session, the harness phase triage decides which superpowers phases run. Surface "clear fix" can become design work after evidence; pre-routing biases that judgment.

**ID high-water mark:** `BUG-019` · `DEBT-029` · `GAP-041` — last consumed ID per category. Next ID = max+1 from this line, bumped in the same write. Resolved rows are deleted but their IDs stay consumed (history = `git log --grep="<id>"`); never re-derive IDs from open rows.

**Row shape** — stable ID + frozen claim, newest at top. When resolved, **delete the row** — git history is the archive.

```
### {BUG|DEBT|GAP}-### — {one-line summary}

**Logged:** {date} · **Source:** {where this surfaced}
**Problem:** {what's broken / rotting / missing}
**Area:** {files or module}
**Prior:** {one-line suspected cause or proposed fix — optional}
```

The claim is write-once — captured at the richest-context moment, read cold by later sessions. Sessions that pick a row up work from it; working history lives in specs/plans, not on the row.

---

## Open

### GAP-041 — Read mattpocock/skills for its real dispatch posture before trusting our tier-pinned-agent pattern

**Logged:** 2026-07-25 · **Source:** de-routing architecture review (`docs/specs/harness-architecture.md` §7 q3)
**Problem:** Our pattern pins a model tier on every agent and dispatches for attention offload. mattpocock's set reads differently — `code-review` runs two axes as parallel `general-purpose` sub-agents with no tier pinned, and the stated reason is isolation ("reports remain separate to prevent one axis masking the other"), not offload. Whether that generalizes to a "session as atomic runner" stance, or is one isolation-specific exception inside an otherwise orchestrating session, is unknown — every claim about his dispatch posture so far is grade B, derived from summaries rather than his source. The answer bears on whether our own tier-pinning is sound or cargo.
**Area:** `plugins/super-bootstrap/agents/*.md` (tier pins); read surface = `mattpocock/skills` repo, esp. `skills/engineering/{code-review,implement,research,wayfinder}/` + `skills/productivity/writing-great-skills/`
**Prior:** Read his repo properly — grade-A text, not fetch summaries. `writing-great-skills` is the likeliest home for a stated dispatch doctrine.

### GAP-039 — Add a path-scoped rule for verification-before-completion to the shipped skeleton's rules layer

**Logged:** 2026-07-25 · **Source:** de-routing architecture review (`docs/specs/harness-architecture.md`)
**Problem:** Verification-before-completion (evidence before claiming done, across all surfaces — not only tests) is a discipline superpowers holds with no independent equivalent in mattpocock's set. It is a behavioral rule, not a pipeline stage — it belongs in the path-scoped rules layer, where it fires at the decision moment with zero ambient cost when irrelevant. No shipped-skeleton rule currently covers it.
**Area:** `plugins/super-bootstrap/skills/harness-bootstrap/assets/` (skeleton rules section)
**Prior:** spec §5 identifies this gap and argues behavioral rule → rules layer over pipeline stage.

### GAP-038 — Ship an "Other" issue-tracker seed for mattpocock/skills' `/setup-matt-pocock-skills`, declaring docs/backlog.md + /super-bootstrap:log as the tracker

**Logged:** 2026-07-25 · **Source:** de-routing architecture review (`docs/specs/harness-architecture.md`)
**Problem:** `/setup-matt-pocock-skills` ships seed templates for GitHub / GitLab / Local but none for "Other" — that branch is authored fresh, yielding free-form prose his skills interpret ad hoc. Without a seed, his `to-spec` and `triage` have no declared path to write into our backlog. Accepted known weakness: the socket is prose, not schema; documented seams drift.
**Area:** `plugins/super-bootstrap/skills/harness-bootstrap/` (seed asset location); new seed file for mattpocock "Other" branch
**Prior:** spec §4; mattpocock "Other" option + absence of seed template confirmed grade A (2026-07-25).

### DEBT-029 — Replace mandatory karpathy-guidelines skill invocation in CLAUDE.md with CODING_STANDARDS.md in the shipped skeleton

**Logged:** 2026-07-25 · **Source:** de-routing architecture review (`docs/specs/harness-architecture.md`)
**Problem:** Root `CLAUDE.md` § Coding Principles hardcodes a mandatory `karpathy-guidelines` invocation, binding coding standards to one skill and making them invisible to reviewers not running that skill. mattpocock's `code-review` reads `CODING_STANDARDS.md` / `CONTRIBUTING.md` and a documented repo standard overrides its built-in Fowler baseline — the standard should live in the skeleton where any reviewer can read it.
**Area:** Root `CLAUDE.md` § Coding Principles; `plugins/super-bootstrap/skills/harness-bootstrap/assets/claude-md-skeleton.md`; new `CODING_STANDARDS.md` in skeleton
**Prior:** spec §4 second socket; grade B — `code-review` reads `CODING_STANDARDS.md`, documented standard overrides Fowler baseline.

### DEBT-028 — Convert drain's stage machine from hardcoded superpowers phases to interface-driven dispatch

**Logged:** 2026-07-25 · **Source:** de-routing architecture review (`docs/specs/harness-architecture.md`)
**Problem:** `skills/drain/SKILL.md` § Invariants hardcodes the stage-resume chain `raw→triage, triaged→plan, spec→plan, plan→execute, review→review`; `assets/phase-loop.md` hardcodes phase prompts naming superpowers skills. Stage names are superpowers' phases — half-dead once de-routing lands. drain should dispatch whatever discipline entry the repo declares, without naming specific skills.
**Area:** `plugins/super-bootstrap/skills/drain/SKILL.md` § Invariants; `plugins/super-bootstrap/skills/drain/assets/phase-loop.md`
**Prior:** spec §3 (drain listed half-dead) + §4 (seam mechanism — dispatch to declared entry, not named skills).

### DEBT-027 — Remove venue intent classification (Discuss / Cloud / Device / Harness) from classify-actionable and todo render path

**Logged:** 2026-07-25 · **Source:** de-routing architecture review (`docs/specs/harness-architecture.md`)
**Problem:** Venue categories exist to route rows to pipeline entries; with routing gone the backlog's job narrows to `/log` landing home plus declared tracker. The classification phase is the primary cost driver behind DEBT-022 (~34.3k tokens / ~226 s for 4 rows). Removing classification may reshape or subsume DEBT-022 (right-size the classify pass) and BUG-019 (full-mode scaffold shape changes when venue grouping disappears) — verify against both before closing.
**Area:** `plugins/super-bootstrap/shared/classify-actionable.md`; `agents/todo.md`; `plugins/super-bootstrap/skills/todo/**`
**Prior:** spec §2 + §6; elimination of the classify pass makes DEBT-022's right-sizing moot; board shape change may subsume BUG-019.

### DEBT-026 — Retire or rename `docs/superpowers/specs|plans/` path shape and update all consumers

**Logged:** 2026-07-25 · **Source:** de-routing architecture review (`docs/specs/harness-architecture.md`)
**Problem:** The `docs/superpowers/` directory layout is superpowers' artifact shape (temporal specs/plans from brainstorming and writing-plans); it carries a foreign namespace once routing is cut. Decision needed: drop the slot entirely (per-feature work orders delegate to whatever process harness the repo installs) or rename to a harness-neutral path. Consumers: `agents/todo.md`, `agents/triage.md`, `skills/drain/SKILL.md`, `shared/classify-actionable.md`, `skills/harness-bootstrap` (creates the dirs), root `CLAUDE.md` § Planning.
**Area:** `docs/superpowers/` dir; `agents/todo.md`; `agents/triage.md`; `plugins/super-bootstrap/skills/drain/SKILL.md`; `plugins/super-bootstrap/shared/classify-actionable.md`; `plugins/super-bootstrap/skills/harness-bootstrap/`; root `CLAUDE.md` § Planning
**Prior:** spec §2; mattpocock's `to-tickets` occupies the per-feature work order slot at `.scratch/<feature>/issues/NN-slug.md`. Carries its own downstream migration: adopt mode has no folder-removal path (spec §8), so retiring these dirs orphans them in every bootstrapped repo — unlike the other cut sites, which adopt mode migrates.

### DEBT-025 — Delete `docs/specs/superpowers-topology.md` and all references to it

**Logged:** 2026-07-25 · **Source:** de-routing architecture review (`docs/specs/harness-architecture.md`)
**Problem:** The topology doc maps superpowers entry points for routing purposes; with routing gone it has no consumer. References live in root `CLAUDE.md` § Cluster routing and possibly the shipped skeleton.
**Area:** `docs/specs/superpowers-topology.md`; root `CLAUDE.md` § Cluster routing; `plugins/super-bootstrap/skills/harness-bootstrap/assets/claude-md-skeleton.md`
**Prior:** spec §3 dissolve test.

### DEBT-024 — Remove cluster routing table, "inside a route" rule, and SDD carve-out from root CLAUDE.md and shipped skeleton

**Logged:** 2026-07-25 · **Source:** de-routing architecture review (`docs/specs/harness-architecture.md`)
**Problem:** Both surfaces hardcode superpowers entry points that lose their referent once de-routing lands. Root `CLAUDE.md` contains the 7-cluster routing table (6 entries naming superpowers skills), the "Inside a route — run it whole" rule, and the Dispatch § SDD carve-out. The shipped skeleton mirrors these into every repo bootstrapped by this plugin (skeleton holds 15 of 85 foreign-name occurrences across 19 files).
**Area:** Root `CLAUDE.md` § Cluster routing, § Inside a route, § Dispatch (SDD carve-out); `plugins/super-bootstrap/skills/harness-bootstrap/assets/claude-md-skeleton.md`
**Prior:** spec §3 dissolve test; `.claude/rules/repo-boundary.md` pulls the skeleton mirror into the dogfood edit's closure.

### BUG-019 — `todo full` scaffold renders empty table in spec-free repos, contradicting "every row, flat" contract

**Logged:** 2026-07-25 · **Source:** live session running `/super-bootstrap:todo all` on super-bootstrap source repo (2026-07-25, 3 open DEBT rows)
**Problem:** `SKILL.md` Arguments table documents `full` as "every row (need-me + drainable), ungrouped, ranked"; plugin.json description says "flat everything". But `assets/scaffolds.md` § Full table only accepts `specs/{date}-{slug}.md` and `plans/{date}-{slug}.md` rows — backlog rows are collapsed to a single count line ("Backlog: N BUG, M DEBT, K GAP open"). In a repo with no spec/plan files the rendered output is an empty table plus the count line — less informative than the default need-me board, which surfaces individual backlog rows as `Triage: {ID}` lines. Observed render on 2026-07-25: table header only, no data rows, then "Backlog: 0 BUG, 3 DEBT, 0 GAP open".
**Area:** `plugins/super-bootstrap/skills/todo/SKILL.md` Arguments table · `plugins/super-bootstrap/skills/todo/assets/scaffolds.md` § Full · `plugins/super-bootstrap/.claude-plugin/plugin.json` todo description
**Prior:** Either (a) make the Full scaffold render each backlog row as a table row (one row per open ID, same table or separate), or (b) align SKILL.md / plugin.json wording to match the scaffold's actual output shape.

### GAP-037 — `todo` sub-verb has no fallback contract for unlisted argument values

**Logged:** 2026-07-25 · **Source:** incidental observation alongside BUG-019 (same live session)
**Problem:** `all` is not listed in SKILL.md's Arguments table; the gateway inferred a mapping to `full` by semantic proximity. No fallback behavior is documented — the contract is silent on what happens when an unrecognized sub-verb is passed (fail / default to need-me / map to nearest match). Any unlisted value silently falls through to model-discretion resolution.
**Area:** `plugins/super-bootstrap/skills/todo/SKILL.md` Arguments table
**Prior:** Add a fallback contract to the Arguments table: unrecognized sub-verb → default to need-me board (or explicit error), so behavior is specified rather than inferred.

### DEBT-023 — doc-sync-scan per-commit Sonnet dispatch burns ~8-12k tokens for a read-only advisory

**Logged:** 2026-07-25 · **Source:** GitHub issue #24 (claude-config-manager 2026-07-23 harness-pain harvest, absorbed via /pull-issue)
**Problem:** `doc-sync-scan` fires per-commit after the grep-gate pre-filter hits and returns a text advisory with 0 writes by design. Observed burning ~8-12k output tokens per run; across a 5-day window: spotify-radio ×2 (~21.5k combined), stock (~11.5k), super-bootstrap (~19.7k). The grep-gate's false-positive rate or the scan's output scope may be too wide relative to its advisory-only yield.
**Area:** `agents/doc-sync-scan.md`; `/super-bootstrap:commit` commit door; grep-gate pre-filter
**Prior:** Raise grep-gate precision (reduce how often the Sonnet scan fires) or cap/trim the scan's output scope. Dropping doc-sync is not a direction (CLAUDE.md marks it non-negotiable).

### DEBT-022 — todo subagent classify+render pass not right-sized to working-set size

**Logged:** 2026-07-25 · **Source:** GitHub issue #25 (downstream adopter claude-config-manager, absorbed via /pull-issue)
**Problem:** `/super-bootstrap:todo` dispatches a subagent that re-classifies every open row from scratch on every invocation, regardless of working-set size. Observed on sb 2.24.1 with 4 open rows / 3-row need-me board (one venue group): ~34.3k subagent tokens / ~226s per bare dispatch. The full classify pass ran over every row; no computation reuse between invokes. The board is intended as a frequent, low-stakes glance; per-glance cost is disproportionate to a small working set.
**Area:** `agents/todo.md`; `plugins/super-bootstrap/skills/todo/**`
**Prior:** Right-size the classify+render work to actual working-set size — skip or shorten classify phases when row count is small.

### DEBT-021 — log agent ID allocation has no recovery contract for concurrent session collision

**Logged:** 2026-07-25 · **Source:** GitHub issue #26 (repo owner, absorbed via /pull-issue)
**Problem:** `agents/log.md` step 4 requires bumping the ID high-water mark in the same write, but specifies no recovery when two concurrent sessions both read the header before either writes — both compute the same `max+1` and allocate the same ID. The Edit tool's `old_string` mismatch catches the collision (stale-state detection), but what the subagent does after that failure is model discretion, not a spec contract. Same exposure on `PARK-000` high-water in `docs/parked.md`. Cost of a slip is higher than volatile state — the backlog is a durable queue, not something a fresh session regenerates.
**Area:** `agents/log.md` step 4; `docs/backlog.md` ID high-water mark line; `docs/parked.md` `PARK-000` line
**Prior:** Add explicit recovery to step 4: on Edit failure (HWM mismatch), re-read the header and recompute the ID before retrying.
