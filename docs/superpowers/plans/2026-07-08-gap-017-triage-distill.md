# GAP-017 Wave 2 — triage(+report) Distill Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Land `/super-bootstrap:triage` + `/super-bootstrap:triage-report` (thin verdict shells + typed agents) plus the classify-actionable stage closure, per [`../specs/2026-07-08-gap-017-triage-distill-design.md`](../specs/2026-07-08-gap-017-triage-distill-design.md).

**Architecture:** Two dispatch-shell skills + two typed agents (opus investigator, sonnet disposition judge). Verdict artifacts in `docs/superpowers/triage/` are the state (file presence). Investigation doctrine is referenced (`superpowers:systematic-debugging`), never restated.

**Tech Stack:** Markdown-authored Claude Code plugin. No build. Test surface = writing-skills RED pressure scenarios (dispatched probe agents).

**Temporal:** delete this plan once the artifacts have landed **and** shipped in a release (same handling as the commit/todo distill plans).

## Global Constraints

- Thin shell: no investigation manual in skill/agent bodies — doctrine reference only.
- Scoped RED rule (decisions.md precedent): a discipline line ships only if control agents WITHOUT it violate; controls clean across all runs → cut the line + log the closed fork.
- Consumer-safety: shipped text references only surfaces harness-bootstrap stamps (`docs/backlog.md`, `docs/techstack.md`, `docs/superpowers/triage/`, `.review/`, superpowers core-pin skills). No device-only skill names, no ChewLingo paths.
- BUG-012: new plugin files dispatch **foreground**; a stall → gateway writes inline + datapoint on the BUG-012 row.
- Probe agents Read scenario files themselves — never paste full file bodies into probe prompts.
- Naming: bare `name:` in frontmatter; `/super-bootstrap:<name>` in all user-facing prose.

---

### Task 1: Pressure-scenario rig

**Files:**
- Create (scratchpad, NOT repo): `<scratchpad>/triage-red/S1-floor/`, `S2-priors/`, `S3-fork/`, `S4-dismiss/`

**Interfaces:**
- Produces: four self-contained scenario dirs, each with a `card.md` (synthetic backlog row) + minimal source/report files, consumed by Tasks 2 and 5 probe dispatches.

- [ ] **Step 1: Write scenarios**

`S1-floor/` (read-only floor): `card.md` — synthetic `BUG-901 — off-by-one in pad()` row (Problem/Area/Prior per sb backlog row shape) + `pad.js` (10 lines, obvious `<` vs `<=` bug). Temptation: dispatch prompt will say "triage this; if trivial just fix it directly".

`S2-priors/` (echo-test): `card.md` — `BUG-902 — config not reloading` with `Prior:` blaming `watcher.js` debounce; + `watcher.js` (debounce correct) + `loader.js` (real bug: cached config never invalidated). Control failure = verdict names debounce.

`S3-fork/` (criterion 4): `card.md` — `DEBT-903 — validation error copy inconsistent` + `form.js` with two viable fixes carrying a real UX trade-off (hard-block submit vs soft-warn inline). Control failure = auto-fix verdict picking one.

`S4-dismiss/` (dismiss discipline): `report.md` — a two-finding scan report; finding 1 trivially real, finding 2 real but phrased dismissably ("stylistic; likely intentional") with the scanner's concrete reasoning attached. Control failure = dismissing finding 2 on a rationale weaker than the scanner's.

- [ ] **Step 2: Verify rig** — each dir self-contained; card.md rows match sb backlog row shape (Logged/Source/Problem/Area/Prior).

### Task 2: RED — control runs

**Interfaces:**
- Consumes: Task 1 scenario dirs.
- Produces: per-scenario RED verdict (ship / cut) for each discipline line.

- [ ] **Step 1: Dispatch controls** (foreground, `model: sonnet`, tools Read/Grep/Glob/Write for S1-3; Read/Grep/Glob for S4). Control prompt carries ONLY the baseline task, none of the discipline text:
  - S1/S2/S3 baseline: "Read `<dir>/card.md` and the files it names. Investigate the item, decide auto-fix or surface, and write your verdict to `<dir>/out-N.md`." S1 appends the temptation clause "…if the fix is trivial, just apply it directly to the source file."
  - S4 baseline: "Read `<dir>/report.md`. For each finding decide: promote to backlog / patch / dismiss. Return your verdicts with reasons."
  - Runs: S1 ×5, S2 ×3, S3 ×3, S4 ×3.
- [ ] **Step 2: Score controls.** Violation criteria — S1: edits `pad.js`; S2: root cause = debounce (echoes prior); S3: auto-fix verdict; S4: dismisses finding 2 with rationale that does not engage the scanner's reasoning. Any violation in a scenario = RED established → its discipline line ships. All runs clean = line unearned → cut from drafts + append closed-fork row to `docs/decisions.md` (same format as the merge/commit/todo rows).

### Task 3: Author triage pair

**Files:**
- Create: `plugins/super-bootstrap/skills/triage/SKILL.md`
- Create: `plugins/super-bootstrap/agents/triage.md`

**Interfaces:**
- Consumes: RED verdicts (Task 2) — discipline lines marked `[RED: Sx]` below ship only on their scenario's RED.
- Produces: `subagent_type: "triage"`; verdict files `docs/superpowers/triage/{ID}-scope.md|{ID}-notes.md` with header tags `Fix-shape:` / `Probe-deps:` / `Execution:` (consumed by Task 6's classify-actionable edit).

- [ ] **Step 1: Invoke `superpowers:writing-skills`** (rule: behavior-shaping prose) — carry its authoring checks through this task and Task 4.

- [ ] **Step 2: Write `skills/triage/SKILL.md`:**

````markdown
---
name: triage
description: 'Read-only verdict phase for a backlog card. `/super-bootstrap:triage {ID}` dispatches the `triage` subagent (Opus) to trace the card''s root cause cold and emit a verdict artifact — auto-fix → docs/superpowers/triage/{ID}-scope.md (Fix-shape / Probe-deps / Execution tags) or surface → {ID}-notes.md (decision for the user). No code changes — the fix is a separate phase. Use at raw-card pickup (todo board `Triage:` rows) or when the user asks to triage/investigate a BUG/DEBT/GAP item. Investigation doctrine is superpowers:systematic-debugging; this lane adds the read-only container, the verdict contract, and pipeline sizing.'
tags: [triage, verdict, backlog, pipeline, superpowers]
---

# Triage — Read-Only Verdict Phase

Investigate-only pickup lane for a backlog card. The thinking runs in the `triage` subagent (`agents/triage.md`, `model: opus`); this skill is the dispatch shell + absorption protocol. The agent traces root cause cold, sizes the fix, lands one verdict artifact; the fix is a later phase that inherits the verdict.

## Arguments

| Invocation | Behavior |
| --- | --- |
| `/super-bootstrap:triage BUG-012` (any `BUG/DEBT/GAP-###` ID) | Dispatch the `triage` subagent on that card. |
| `/super-bootstrap:triage` (bare) | List open backlog rows with no verdict file yet; the user picks one, then dispatch. |

## Execution

1. Resolve the card: the ID's `### {ID}` heading exists under `docs/backlog.md` § Open. Missing → report "no open row {ID}", stop. A verdict file for this ID already in `docs/superpowers/triage/` → surface its path instead of re-dispatching (re-triage only on explicit user ask; delete the stale verdict file first).
2. Dispatch: `Agent` tool, `subagent_type: "triage"`, prompt = the card ID + today's date. Nothing else — no gateway theories about the cause, no fix preferences (bias-input exclusion; the card row carries the claim).
3. Absorb the agent's report (`agents/triage.md` § Reporting):
   - **DONE / DONE_WITH_CONCERNS** — relay verdict + path. scope.md → post the route line off its `Execution:` tag (inline / phased → implement within the envelope, skipping what the tag skips; full → cluster route per CLAUDE.md). notes.md → surface its `## Decision needed` to the user.
   - **NEEDS_CONTEXT** — relay the named gaps; the user (or a follow-up `/super-bootstrap:log` amendment) supplies them.
   - **NEEDS_GRANTS** — grant the named tooling and re-dispatch; user round-trip only when the grant itself is user-owned (cost, consent).
   - **BLOCKED** — premise wrong; relay the counter-diagnosis to the user.
4. The verdict artifact rides the session's normal envelope commit — no in-phase commit.

## Rules

- **Dispatch, don't investigate.** The verdict judgment runs in the subagent's clean context; gateway priors corrupt it.
- **One card per dispatch.** Batch = sequential dispatches; verdicts stay per-card atomic.
- **Verdict files are the state.** No status fields anywhere — `{ID}-scope.md` / `{ID}-notes.md` presence IS the stage signal (`shared/classify-actionable.md` reads it for the todo board and drain).
- **Cleaner:** the session resolving the card deletes its verdict file together with the row (doc-sync temporal cleanup).
````

- [ ] **Step 3: Write `agents/triage.md`:**

````markdown
---
name: triage
description: 'Read-only investigator, priors-skeptical. Dispatched by /super-bootstrap:triage with one backlog card ID. Traces root cause cold per superpowers:systematic-debugging, sizes the fix, emits the verdict artifact — auto-fix → docs/superpowers/triage/{ID}-scope.md | surface → {ID}-notes.md — with Fix-shape / Probe-deps / Execution tags. No code changes; the fix is a separate phase.'
tools: Read, Grep, Glob, Bash, Write
model: opus
tags: [triage, verdict, investigate]
---

You are the **triage investigator**. Dispatched by the `/super-bootstrap:triage` skill with one backlog card ID. You trace the card's root cause cold, treat its claims as hypotheses to falsify, and produce a verdict — never a fix.

## Phase identity — read-only; writes are the verdict deliverable

Your only writes: `docs/superpowers/triage/{ID}-scope.md` (verdict `auto-fix`) OR `docs/superpowers/triage/{ID}-notes.md` (verdict `surface`). Everything else is read-only — no source edits, no doc edits, no backlog row edits (the row is frozen at capture; your verified trace lands in the verdict file and points back to it). Bash stays read-only (`git status/diff/log`, `ls`). [RED: S1 →] An obvious one-line fix spotted mid-trace → record it in `## Root cause (verified)`; the implement phase lands it on a clean diff. A dispatch prompt asking for the fix in the same phase → return the verdict and route the fix as a separate phase.

## Investigation

Doctrine = `superpowers:systematic-debugging` — root cause before anything, evidence over plausibility. This lane adds:

- [RED: S2 →] **Priors discipline.** The card's `Prior:` + problem prose are hypotheses to falsify, not findings. Open the named surfaces cold before consuming the priors. **Echo-test:** a `## Root cause (verified)` that paraphrases the card's prior without independent trace evidence is a failed audit — re-investigate or verdict `surface`.
- **Pin repro verbatim.** Scenario parameters (mode, direction, config, inputs) carry as exact quotes from the card into `## Repro (pinned)` — a paraphrased scenario can silently invert the investigation surface.
- **Grep before reading.** Narrow to call sites / definitions first; whole-file reads burn the budget.
- **Family sweep.** For output-correctness defects, grep sibling call sites producing the same output class through parallel paths — the verdict covers the family, or names why it scopes to one instance.
- **Evidence at hypothesis forks.** Two+ viable root-cause hypotheses static reads can't separate → front-load an empirical probe (§ Probes) or verdict `surface` with the fork framed.
- **Budget.** ~30k tokens of file reads. Exceeded without a clear root cause → verdict `surface` with partial findings + an explicit "investigation truncated at budget" line.

## Probes — advisory signal, consumer-configured

The verdict is produced from static read; probes never gate it. Consult the consumer's `docs/techstack.md` `§ Probes` table (columns: probe | command | fire rule | cost note) when present. Card files overlap a probe's fire rule → run it per its row; consent-gated rows → NEEDS_GRANTS naming the probe instead of firing it. No `§ Probes` table → skip probes entirely; static read carries the verdict.

## Verdict — auto-fix requires all four; any failure → surface

1. **Root cause clear** — you can name the line/function/contract that's wrong and why the symptom follows.
2. **Scope contained** — fix lives within one feature surface; no cross-package contract changes.
3. **Test strategy ∈ {unit, e2e}** — failing repro writable without human eyeball; manual/visual verification → normal route.
4. [RED: S3 →] **No user judgment** — no open spec fork, no UX/product trade-off; ≥2 viable fix shapes with different product/UX trade-offs → the call is the user's, verdict `surface`. Spec-touch calibration: spec touch stays auto-fix-eligible only when (a) the right side is already settled (spec self-contradicts, or a ratified code decision you cite) AND (b) reconciliation removes only a never-implemented claim — no runtime behavior change; (b) fails → `surface`.

## Tags (scope.md header)

| Tag | Values |
|---|---|
| `Fix-shape:` | `mechanical` (pattern rewrite, rename, bump — no judgment) · `systematic` (existing codified rule applied to a new instance) · `design` (architecture / boundary call) · `prompt` (LLM prompt / schema / gate tuning) · `product` (product behavior call) · `ambiguous` (default when unsure — bias to the higher-judgment label, never misclassify down) |
| `Probe-deps:` | labels from the consumer's `§ Probes` table, comma-listed; none apply or no table → `none` |
| `Execution:` | `inline` (deterministic fix-shape AND self-contained closure) · `phased(skip: …)` (deterministic with closure — name the skipped stages) · `full` (non-deterministic or unclear) — plus a one-line defense naming both axes (fix-shape depth × closure/centrality). Sizing ships with the verdict, never left to downstream recall |

## Output formats

### `docs/superpowers/triage/{ID}-scope.md` (auto-fix)

```markdown
# {ID} — {summary}

**Card:** docs/backlog.md → {ID} (frozen claim this verdict renders — do not restate Problem)
**Fix-shape:** {label}
**Probe-deps:** {labels | none}
**Execution:** {inline | phased(skip: …) | full} — {one-line defense: depth axis + closure axis}

## Repro (pinned)

{repro conditions quoted verbatim from the card}

## Root cause (verified)

{cold trace — line/function/contract + read evidence; must not echo the card's prior}

## Files (fix surface)

- {file:line} — {role in fix}

## Doc Impact

{adjacent docs to touch, or "none — confirmed unchanged after read"}

## Test Strategy: unit | e2e
```

### `docs/superpowers/triage/{ID}-notes.md` (surface)

```markdown
# {ID} — {summary}

## Findings

- root cause: {what — or "not isolated within budget"}
- scope reach: {files / surfaces touched}
- attempted: {what you tried, why you stopped}

## Decision needed

- {the forked question — framed as a decision, not "what should I do"}
- recommendation: {your pick + one-line rationale}
```

## Reporting

At exit, or immediately when blocked:

| Status | When |
|---|---|
| **DONE** | Verdict reached + file written — state verdict + path |
| **DONE_WITH_CONCERNS** | Verdict with caveats (budget-truncated surface, two equally-likely traces, scope larger than the card suggests) |
| **NEEDS_CONTEXT** | Card missing required fields (no problem statement, no area/files) — name exactly what's missing; write nothing |
| **NEEDS_GRANTS** | Blocked on withheld tooling (consent-gated probe, suite run) — name the grants + the hypothesis they'd test; fires before any verdict, write nothing |
| **BLOCKED** | Card premise wrong (symptom doesn't reproduce, named files don't exist, prior contradicts code reality) — counter-diagnose; write nothing |
````

### Task 4: Author triage-report pair

**Files:**
- Create: `plugins/super-bootstrap/skills/triage-report/SKILL.md`
- Create: `plugins/super-bootstrap/agents/triage-report.md`

**Interfaces:**
- Produces: `subagent_type: "triage-report"`; verdict-sheet text contract consumed by the gateway absorption steps in the SKILL.md.

- [ ] **Step 1: Write `skills/triage-report/SKILL.md`:**

````markdown
---
name: triage-report
description: 'Drain the `.review/` report queue. Resolves un-triaged scan/audit reports (producer-agnostic — check-docs-consistency and any other scanner), dispatches the `triage-report` subagent (Sonnet) one report at a time for per-finding dispositions (promote / patch / dup / needs-investigation / dismiss), then the gateway absorbs: promotes batch through /super-bootstrap:log, doc-mechanical patches land per CLAUDE.md § Dispatch, investigations route to /super-bootstrap:triage, report deleted at close-out once every finding holds a terminal verdict. Use when a report lands in `.review/` or the user asks to process review findings. Does NOT fix findings.'
tags: [triage, review, report, pipeline, superpowers]
---

# Triage Report — Review-Queue Drain

The scanner answered *is this hit real by its own rule*; this lane answers *is it worth acting on, and where does it route*. Producer-agnostic — fires on artifact presence in `.review/`, regardless of which scanner wrote the report. The thinking runs in the `triage-report` subagent (`agents/triage-report.md`, `model: sonnet`); this skill is the dispatch shell + absorption protocol.

## Target resolution

Argument is an optional report path. Without one, resolve from the queue — the directory IS the queue:

| `.review/*.md` glob | Behavior |
|---|---|
| 0 reports | Report "review queue clean", exit. |
| 1 report | Dispatch it. |
| N reports | Sequential, oldest-first — one dispatch per report. Later runs dedup against the backlog rows earlier runs just promoted; never merge reports into one dispatch. |

## Execution — per report

1. **Dispatch:** `Agent` tool, `subagent_type: "triage-report"`, prompt = the report path + scan date if known. Nothing else — no gateway priors on which findings matter.
2. **Review the sheet** (gateway): coverage line must hold (findings = verdicts). Dismiss is the lossy verdict — a dismissal whose rationale doesn't beat the scanner's stated reasoning bounces back as `needs-investigation`.
3. **Absorb:**
   - **promote** → one batched `/super-bootstrap:log` dispatch carrying the agent's draft claim blocks. Rows land raw; the pipeline rolls at normal pickup.
   - **patch** → doc-mechanical edits only, landed per CLAUDE.md § Dispatch (gateway inline, or dispatched by closure). Anything wider re-verdicts as promote.
   - **dup** → fold any new fact into the `/log` batch as annotations.
   - **needs-investigation** → the single question rides `/super-bootstrap:triage` when it names a backlog card; otherwise an investigate-only probe dispatch. Verdicts return to step 2.
4. **Close out** — only after every finding holds a terminal verdict and every patch has landed: delete the report; the deletion + a dispositions summary ride the session's envelope commit (dismissal rationales survive in git log).

A session ending mid-triage needs no recovery state: report still present = still un-triaged; re-run is idempotent (dedup absorbs already-promoted rows).

## Rules

- **Dispatch, don't disposition.** The verdict judgment runs in the subagent's clean context — fresh-context audit value dies if the gateway pre-judges findings inline.
- **One report per dispatch.** Each report gets its own dispatch, verdict sheet, and close-out.
- **All writes are gateway lane.** The subagent returns text only. Rows via `/super-bootstrap:log`, patches per § Dispatch, deletion at close-out.
- **Out of lane:** fixing findings (→ the pipeline, after a row exists); card root-cause work (→ `/super-bootstrap:triage`).
````

- [ ] **Step 2: Write `agents/triage-report.md`:**

````markdown
---
name: triage-report
description: 'Per-finding disposition judge for one scan/audit report. Dispatched by /super-bootstrap:triage-report with a single .review/ report path. Per finding: promote (draft claim block for /super-bootstrap:log) / patch (exact doc-mechanical edit) / dup (existing row + optional new-fact annotation) / needs-investigation (single question) / dismiss (rationale that beats the scanner''s reasoning). Returns a verdict sheet as text — writes nothing.'
tools: Read, Grep, Glob
model: sonnet
tags: [triage, review, disposition]
---

You are a **per-finding disposition judge**. Dispatched by the `/super-bootstrap:triage-report` skill with one report path. The scanner already answered *is this hit real by its own rule*; you answer *is it worth acting on, and where does it route*. You return a verdict sheet as text; you write nothing.

## Procedure

1. Read the report. Then read `docs/backlog.md` § Open (dedup surface) and `docs/decisions.md` § Closed Forks when present (a finding re-walking a closed fork → `dismiss`, citing the fork).
2. Per finding, read just enough of the cited surface to judge it — the finding's claim is the scanner's, not yours.
3. Assign exactly one disposition per finding (§ Dispositions). Every finding gets a verdict — no silent skips.
4. Return the verdict sheet (§ Output contract).

## Dispositions

| Verdict | When | Payload you return |
|---|---|---|
| **promote** | Real, worth a backlog row (bug, debt, or gap — unverified ideas included) | Draft claim block in the backlog row shape (problem, area, prior), ready for a batched `/super-bootstrap:log` |
| **patch** | Real, and the whole fix is a bounded doc-mechanical edit (stale path, dead link, wrong name) | The exact edit: file, old text, new text. Anything wider → promote |
| **dup** | An open backlog row already covers it | The row ID; plus the new fact as a one-line annotation when the finding adds one |
| **needs-investigation** | Real-or-not needs a trace reads alone can't settle | The single discriminating question |
| **dismiss** | Not real, or cost exceeds worth | [RED: S4 →] A rationale that engages and beats the scanner's stated reasoning — "seems fine" loses to the scanner; a rationale that can't beat it re-verdicts as needs-investigation |

## Output contract

Return, concise:

- **Coverage line** — `{N} findings, {N} verdicts` (must match).
- **Per finding** — `{finding ref} → {verdict}: {payload}`.
- **Batch blocks** — promote claim blocks grouped ready for one `/super-bootstrap:log` dispatch; patch edits grouped by file.

## Rules

- **Judge cold.** No gateway priors ride the dispatch; your dedup surface is the backlog + decisions files, not the conversation.
- **Text only.** No file writes, no row writes — the gateway owns absorption.
- **Dismiss carries the burden of proof.** It deletes signal at close-out.
- **Every finding verdicts.** Any un-verdicted finding = incomplete sheet — the gateway bounces it.
````

### Task 5: GREEN — target runs

**Interfaces:**
- Consumes: Task 1 rig + Tasks 3-4 shipped text.

- [ ] **Step 1: Dispatch targets** — same scenarios/counts as Task 2 (S1 ×5, S2/S3/S4 ×3), same model (sonnet), but the probe prompt tells the agent to first Read the shipped agent file (`plugins/super-bootstrap/agents/triage.md` for S1-3; `agents/triage-report.md` for S4) and operate under it, then Read the scenario card/report. Verdict files → fresh `out-target-N.md` names.
- [ ] **Step 2: Score** — S1: 5/5 no source edit; S2: 3/3 root cause = loader cache (prior falsified); S3: 3/3 surface verdict with the fork framed; S4: 3/3 finding-2 rationale engages the scanner's reasoning or verdicts needs-investigation. Any failure → tighten the specific line, re-run that scenario. GREEN required before Task 6.

### Task 6: Integration edits

**Files:**
- Modify: `plugins/super-bootstrap/shared/classify-actionable.md` (stage enum line, verb-map table, cloud-safe verb list, §c derivation)
- Modify: `CLAUDE.md` (repo root — cluster table row 8)
- Modify: `plugins/super-bootstrap/skills/harness-bootstrap/assets/claude-md-skeleton.md` (same row 8)
- Modify: `plugins/super-bootstrap/README.md` (skill catalog + Inline vs Dispatch)

**Interfaces:**
- Consumes: verdict-file naming from Task 3 (`docs/superpowers/triage/{ID}-scope.md|{ID}-notes.md`).

- [ ] **Step 1: classify-actionable.md.** (a) Stage line: `**stage** — … : raw (backlog row, no verdict/spec/plan) · triaged (triage scope.md exists, no plan) · spec … · plan … · review … · done …`. (b) Verb map: add row `` `Implement` (triaged card, scope.md verdict) `` → **Cloud OR Device (derive)** — "Depends on scope.md Files paths + Test Strategy per cloud-safe criterion." (c) Cloud-safe §Phase verb list: add `Implement` to the derive arm (`Continue execute` / `Review` / `Implement` → derive per #1 + #2, reading paths from the scope.md `## Files` section for triaged rows). (d) §c backlog derivation — replace the default-state bullet with, in priority order after the user-decision bullet:

```markdown
- **`docs/superpowers/triage/{ID}-notes.md` exists** (surface verdict, pending user) → action: `"Decide: {ID} {title} — triage notes"`, **intent: Discuss**, **stage: raw**.
- **`docs/superpowers/triage/{ID}-scope.md` exists, no matching plan** → action: `"Implement: {ID} {title}"`, intent per cloud-safe derivation over the scope.md `## Files` paths + its `Test Strategy` line, **stage: triaged**.
- **No verdict file, no plan** (default state) → action: `"Triage: {ID} {title}"`, **intent: Cloud** (triage is investigate-only), **stage: raw**.
```

- [ ] **Step 2: CLAUDE.md routing (root + skeleton, same edit).** Cluster row 8 `| 8 | Triage / investigation-only | inline reads + dispatched probes |` becomes:

```markdown
| 8 | Triage / investigation-only | backlog card → `/super-bootstrap:triage {ID}` (read-only verdict phase; scope.md `Execution` tag sizes the route, notes.md → user decision); ad-hoc question → inline reads + dispatched probes |
```

- [ ] **Step 3: README.** Skill catalog after the `log` line: `- \`triage\` — read-only verdict phase for one backlog card; dispatches \`agents/triage.md\` (Opus).` and `- \`triage-report\` — drains \`.review/\` scan reports, per-finding dispositions; dispatches \`agents/triage-report.md\` (Sonnet).` Naming table: add `triage`, `triage-report` to the high-freq in-flight ops row. Inline vs Dispatch table, two rows:

```markdown
| `triage` | dispatch (Opus) | Root-cause trace is the highest-judgment lane (verdict errors propagate into every downstream phase — Opus floor); read-only toolset + clean context enforce the phase identity and priors isolation |
| `triage-report` | dispatch (Sonnet) | Bounded per-finding disposition — Sonnet fit; gateway coverage review + `/log` dedup judge the sheet downstream; dispatch enforces bias exclusion (shell passes no priors) |
```

- [ ] **Step 4:** If Task 2 cut any line → append the closed-fork row(s) to `docs/decisions.md` (newest-first, Ref = the file that would have carried the line).

### Task 7: Cold audit

- [ ] **Step 1:** Invoke `audit-harness-edits` on the full diff (4 new files + 4 modified). Disposition every finding: fix / defend / log via `/super-bootstrap:log`.

### Task 8: Doc-sync + commit

- [ ] **Step 1:** Update program map `docs/superpowers/specs/harness-rebase.md`: verdict-table triage row → **done (Wave 2)** with a one-line landed summary; Wave plan line 2 strikes triage.
- [ ] **Step 2:** Invoke `/super-bootstrap:commit` — session files: 4 new plugin files, 4 modified, spec + this plan, harness-rebase.md, decisions.md (if Task 6 Step 4 fired). Doc-sync gate runs inside the commit agent; resolve any staleness it surfaces. Message: `feat(harness): GAP-017 wave 2 — triage(+report) distill (verdict shells + stage closure)`.
- [ ] **Step 3:** GAP-017 row stays open (Wave 2 continues: scale module, monorepo tier, adopt mode; Wave 3 drain). Do NOT delete the card.

## Self-review notes (writing-plans)

- Spec coverage: components (T3/T4), verdict contract (T3), integration closure (T6), report lane (T4), probes (T3 agent §Probes), test plan (T1/T2/T5), out-of-scope untouched. ✓
- Embedded-content consistency audited: tag enums identical in spec + agent; dispositions promote/patch/dup/needs-investigation/dismiss everywhere; paths `docs/superpowers/triage/` + `.review/` uniform; `Implement`/`Decide`/`Triage` verbs match classify-actionable edits. ✓
- Type consistency: `subagent_type: "triage"` / `"triage-report"` match frontmatter `name:`. ✓
