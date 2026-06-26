# Bootstrap Tier-Split + Dogfood Refactor — Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Restructure the super-bootstrap pipeline so it does zero product prework — scaffold the generic dogfood runway early and always, seed two GAP cards through `/super-bootstrap:log`, gate tech curation on `overview.md`/`techstack.md` being resolved, and route product discovery through the harness's own log → todo → brainstorm/distill loop.

**Architecture:** Two-axis detection replaces the single code-presence/greenfield gate. **Axis A** (harness artifacts present?) drives the generic runway — `/super-bootstrap:harness-bootstrap` installs (fresh) or syncs (idempotent drift) on every run, greenfield and updater alike. **Axis B** (seed docs substantive?) gates the GAP-card seeding and the tech-curation tier. The entry `/super-bootstrap` stays a thin orchestrator: git-init → dispatch generic runway → seed 2 GAP cards (greenfield) → gate → tech curation (resolve-plugins + tech rules + release-init) only when `overview.md`/`techstack.md` are substantive. Product Q&A in **both** skills dissolves; product content is filled at GAP-card pickup, not at install.

**Tech Stack:** Markdown-authored Claude Code plugin skills. No runtime, no build. The unit of change is prose structure across two `SKILL.md` files + a rename-map asset. Verification is ref-integrity grep + cold-read coherence per task, and a final `audit-harness-edits` pass.

## Global Constraints

- **Harness MD discipline** — every retained/added line passes the cut test ("what decision does this sharpen, at what moment?"); positive-over-negative phrasing; no precedent essays / dated chronicles in skill bodies. (`axiom-principles/harness-md-discipline.md`)
- **Thin gateway** — the entry skill orchestrates (detect, route, dispatch, integrate); it does not absorb the generic-install procedure. (`axiom-principles/agent-shapes.md`)
- **State = file presence** — the gate between generic runway and tech curation is a session-safe break point; greenfield resolution happens across sessions via the dogfood loop. (`axiom-principles/pipeline-design.md`)
- **Dogfood capture** — the 2 GAP cards are seeded **through `/super-bootstrap:log`**, never hand-written as backlog rows. (CLAUDE.md / backlog funnel rule)
- **No silent product Q&A** — bootstrap asks zero product questions; `overview.md`/`techstack.md` are scaffolded as empty skeletons and filled at pickup.
- **Idempotency + correctness moves** — git-init if absent; re-run detects existing GAP cards and does not re-seed; invoking the command IS consent (one post-hoc disclosure line, no consent gate).
- **Non-goals** — no roadmap tier; no clobber gate for hand-authored config (overwrite is the user's risk, surfaced by the disclosure line + git diff).

## Affected Files

| File | Change |
|---|---|
| `plugins/super-bootstrap/skills/super-bootstrap/SKILL.md` | Rewrite to thin orchestrator: drop Phase 1 ideation Q&A + Phase 2 seed-writing; add two-axis detect, git-init, GAP-card seeding via `/log`, gate, tier-2 orchestration, post-hoc disclosure |
| `plugins/super-bootstrap/skills/harness-bootstrap/SKILL.md` | Becomes generic runway installer: dissolve product Q&A (Phase 2 Q1-Q4); remove greenfield redirect (runs on greenfield now); write `overview.md`/`techstack.md` as empty skeletons; remove Phase 3c curation call (moves to entry's tier-2); keep all generic drift/sync/migration machinery |
| `plugins/super-bootstrap/skills/harness-bootstrap/assets/rename-map.md` | Add entries for any user-facing literal this refactor renames (rot-scan coverage for updaters) |
| `plugins/super-bootstrap/skills/harness-bootstrap/assets/backlog.md` | No structural change — confirm the GAP-card shape the entry seeds matches this template |
| `plugins/super-bootstrap/README.md` (+ `plugin.json` description if it narrates the flow) | Doc-sync: update the flow narration to the new tier-split |
| `docs/backlog.md` | Delete DEBT-001 row on completion (resolving session's job) |

---

### Task 1: harness-bootstrap — dissolve product Q&A, keep structural/drift

**Files:**
- Modify: `plugins/super-bootstrap/skills/harness-bootstrap/SKILL.md` (Phase 2 block, lines ~91-136; Phase 1 greenfield redirect, lines ~57-67)

**Interfaces:**
- Produces: a harness-bootstrap that runs with **zero product questions**. Phase 1 manifest detection still produces stack facts (Runtime/Framework/deps) for the `techstack.md` skeleton. The `bootstrap-qa.md` precondition forcing-function is removed (no Q&A to gate). External-tools signal (old Q4) is **not** asked here — it is a tier-2 curation input consumed later from `overview.md`'s `<!-- harness-meta -->` block.
- Consumes: nothing new.

- [ ] **Step 1: Cold-read the current Phase 2 to classify each question**

Read `plugins/super-bootstrap/skills/harness-bootstrap/SKILL.md` lines 91-136. Classify:
- Q1 "What does this project do?" / Q2 "Who uses it?" / Q3 "Current state?" → **product prework — dissolve.**
- Q4 "External tools?" → **curation input — relocate to tier-2 timing** (Task 4), remove from here.
- Q5 monorepo / Q6 existing CLAUDE.md / Q7 existing docs → **drift-handling — fold into Phase 3b per-section approval** (already exists there); remove the upfront questions.
- Q8 persistent specs → **keep as a code-presence check, not a question** (BUG-002 gate already enforced at 3a line ~196).
- Q9 backlog → **always scaffold now** (GAP cards need it); remove the question.

- [ ] **Step 2: Remove the Phase 2 Q&A section**

Delete the entire `## Phase 2: Q&A Alignment` block (lines ~91-137, from the heading through the `bootstrap-qa.md` write paragraph). Remove the `bootstrap-qa.md` hard-precondition paragraph (lines ~94-95) and its references. Replace with a short bridge paragraph stating the runway scaffolds with no product Q&A; manifest facts feed the techstack skeleton; drift on existing files is resolved inline at Phase 3b.

- [ ] **Step 3: Neutralize the greenfield redirect**

In `### Greenfield Redirect` (lines ~57-67), remove the abort/redirect-to-`/super-bootstrap` behavior. The generic runway now **runs on greenfield** — replace with: on no-seed-docs, scaffold the generic runway and write empty `overview.md`/`techstack.md` skeletons (the entry handles GAP-card seeding + gate). Keep the `force` token discussion only if still meaningful; otherwise drop it.

- [ ] **Step 4: Purge dangling references to removed Q&A**

Grep the file for `bootstrap-qa`, `Q1`, `Q2`, `Q3`, `Q4`, `Phase 2`, `Alignment Confirmation`:

Run: `grep -nE "bootstrap-qa|Phase 2|Alignment|Q[1-9]\b" plugins/super-bootstrap/skills/harness-bootstrap/SKILL.md`
Expected: only references that survive (e.g. Phase numbering renumbered, or none). Fix any orphan that points at deleted content. Renumber remaining phases if Phase 2 removal leaves a gap (Phase 1 → Phase 3 becomes Phase 1 → Phase 2).

- [ ] **Step 5: Cold-read coherence check**

Re-read the whole file top to bottom as a cold agent. Confirm: no question-asking remains; manifest detection still feeds skeletons; phase numbering is contiguous; no reference to `bootstrap-qa.md` survives anywhere.

- [ ] **Step 6: Commit**

```bash
git add plugins/super-bootstrap/skills/harness-bootstrap/SKILL.md
git commit -m "refactor(harness-bootstrap): dissolve product Q&A; runway runs on greenfield"
```

---

### Task 2: harness-bootstrap — empty seed-doc skeletons + remove curation call

**Files:**
- Modify: `plugins/super-bootstrap/skills/harness-bootstrap/SKILL.md` (Phase 3b asset table ~249-258; Phase 3c ~414-427; Phase 3d staging list ~445-458; Phase 4 handoff ~466-481)

**Interfaces:**
- Produces: harness-bootstrap that writes `overview.md`/`techstack.md` as **empty skeletons** (placeholders unfilled on greenfield; manifest-derived facts filled only when source code exists) and **does not invoke `/super-bootstrap:resolve-plugins`** — curation moves to the entry's gated tier-2 (Task 4). harness-bootstrap's deliverable ends at "generic runway installed/synced + committed."
- Consumes: Task 1's Q&A-free Phase 1/2.

- [ ] **Step 1: Make seed-doc skeleton writes product-free**

In Phase 3b (asset table + per-doc handling), confirm `overview.md`/`techstack.md` skeletons write from `assets/overview-skeleton.md` / `assets/techstack-skeleton.md` with **only manifest-derived facts** filled (Runtime/Framework/deps when code present). On greenfield (no manifest, no source), they write as **unfilled skeletons** — the Problem/User/Current State and Runtime/Framework placeholders stay empty for the dogfood to fill. Add one line stating empty-skeleton-on-greenfield is intentional (it is the "unsolved" state Axis B detects).

- [ ] **Step 2: Remove Phase 3c (curation) from harness-bootstrap**

Delete `### 3c: Curate skill / MCP / hook` (lines ~414-427). Curation is now the entry's tier-2 step (Task 4), gated on seed docs. Leave a one-line pointer if a reader expects it here: "Tech curation is gated tier-2 — orchestrated by `/super-bootstrap` after `overview.md`/`techstack.md` are substantive." Renumber 3d → 3c.

- [ ] **Step 3: Update Phase 3d staging + commit messages**

In the (renumbered) sync-report/commit phase, remove `.claude/settings.json` plugin-pin staging that belonged to curation (the core pins at 3a stay — superpowers + karpathy are runway deps, not curation). Confirm the commit-message set still fits a runway-only scaffold.

- [ ] **Step 4: Trim Phase 4 handoff**

Phase 4 first-run message currently promises "Skill / MCP / hook picks pinned" — that is now tier-2. Reword to: runway installed; if greenfield, the entry seeds GAP cards + surfaces the gate; tech picks come when curation runs. Keep the rules-seeded and bootstrap.md-task lines.

- [ ] **Step 5: Ref-integrity check**

Run: `grep -nE "resolve-plugins|Phase 3c|3c:" plugins/super-bootstrap/skills/harness-bootstrap/SKILL.md`
Expected: no live invocation of `resolve-plugins` remains (only the one-line gated-tier-2 pointer, if kept). Confirm phase numbering contiguous (3a → 3b → 3c).

- [ ] **Step 6: Commit**

```bash
git add plugins/super-bootstrap/skills/harness-bootstrap/SKILL.md
git commit -m "refactor(harness-bootstrap): empty seed skeletons; move curation to gated tier-2"
```

---

### Task 3: Entry `/super-bootstrap` — rewrite to thin orchestrator (detect + dispatch + git-init)

**Files:**
- Modify: `plugins/super-bootstrap/skills/super-bootstrap/SKILL.md` (full rewrite — currently 154 lines of Phase 0 detect + Phase 1 ideation Q&A + Phase 2 seed-write + Phase 3 dispatch)

**Interfaces:**
- Produces: an orchestrator that (1) git-inits if absent, (2) runs two-axis detection, (3) dispatches `/super-bootstrap:harness-bootstrap` (generic runway, always). GAP-card seeding (Task 5), gate + tier-2 (Task 4), and disclosure (Task 6) layer on in later tasks — this task lays the skeleton with those as named placeholders pointing at their task.
- Consumes: harness-bootstrap's new runway-only contract (Tasks 1-2).

- [ ] **Step 1: Delete Phase 1 ideation Q&A and Phase 2 seed-writing**

Remove `## Phase 1: Greenfield ideation Q&A` (lines ~25-89) and `## Phase 2: Write seed files` (lines ~91-123) in full. The entry writes **no** product content and asks **no** product questions. `overview.md`/`techstack.md`/`backlog.md` are written by the generic runway (harness-bootstrap), not here.

- [ ] **Step 2: Rewrite Phase 0 → two-axis detection**

Replace `## Phase 0: Detect greenfield` with `## Detect — two axes`:
- **Axis A — harness artifacts present?** Check `CLAUDE.md` + `.claude/rules/` + `docs/superpowers/` skeleton. Absent → runway installs fresh. Present → runway syncs (idempotent drift). Either way, **the runway always runs.**
- **Axis B — seed docs substantive?** Check `docs/overview.md` + `docs/techstack.md` exist **and are filled beyond skeleton placeholders** (substantive-content check, not mere file-exists — mirror the README "≥3 substantive lines" notion already used). Drives GAP-card seeding + the tier-2 gate.

State explicitly: Axis B is the **product-content** axis; it never decides whether the harness syncs (that is Axis A). This is the fix for the updater path — a documented-but-stale repo still gets runway sync.

> **BINDING (audit seam 1, Finding 1):** Axis B MUST test *substantive content*, not file-existence. The runway writes `overview.md`/`techstack.md` as **empty skeletons** on greenfield — a mere file-exists check would misread them as "documented," skip GAP-card seeding, and dispatch to harness-bootstrap in a loop (the old Phase 0 bug). The harness-bootstrap handoff already promises "`/super-bootstrap` seeds GAP cards + surfaces the gate" — Tasks 4-5 are the contract that makes that pointer true. The old "files exist → non-greenfield" line MUST be deleted, not adapted.

- [ ] **Step 3: Add git-init correctness move**

At the top of the flow: if the repo is not a git repo (`git rev-parse --git-dir` fails), run `git init`. Silent correctness move — so the promised post-hoc `git diff` exists. One log line, no gate.

- [ ] **Step 4: Write the orchestration spine with named placeholders**

Body becomes:
```
1. git-init if absent
2. Detect (Axis A + Axis B)
3. Dispatch /super-bootstrap:harness-bootstrap   (generic runway — always)
4. [GAP-card seeding — Task 5]                    (Axis B = not substantive)
5. [Gate + tier-2 curation — Task 4]
6. [Post-hoc disclosure — Task 6]
```
Leave steps 4-6 as one-line stubs naming their task — Tasks 4-6 fill them. This task delivers a runnable detect-and-dispatch orchestrator.

- [ ] **Step 5: Fix description frontmatter + cross-refs**

Update the `description:` frontmatter — it currently says "Detects greenfield repos and runs lean ideation Q&A — produces overview.md, techstack.md." Rewrite to the new behavior (orchestrates runway + GAP-card seeding + gated curation; zero product prework). Grep for stale self-references:

Run: `grep -nE "ideation|Phase 0|Phase 1|Phase 2|seed file" plugins/super-bootstrap/skills/super-bootstrap/SKILL.md`
Expected: no orphan references to deleted sections.

- [ ] **Step 6: Cold-read + commit**

Re-read as a cold agent — confirm the orchestrator is coherent with stubs clearly marked. Then:
```bash
git add plugins/super-bootstrap/skills/super-bootstrap/SKILL.md
git commit -m "refactor(super-bootstrap): thin orchestrator — two-axis detect, drop ideation Q&A"
```

---

### Task 4: Entry — gate + tier-2 tech curation

**Files:**
- Modify: `plugins/super-bootstrap/skills/super-bootstrap/SKILL.md` (the Task-3 step-5 gate stub)

**Interfaces:**
- Consumes: Axis B result (seed docs substantive?) from Task 3; harness-bootstrap's runway-complete return.
- Produces: the gate + tier-2 sequence. Tier-2 = `Skill(resolve-plugins)` + tech-specific rules seeding + release-init offer, run **only** when Axis B is substantive.

- [ ] **Step 1: Write the gate**

After the runway dispatch returns, branch on Axis B:
- **Not substantive (greenfield / undocumented)** → **STOP** before tier-2. Surface the dogfood handoff (Task 5 seeds the cards; this step writes the "resolve via `/super-bootstrap:todo` then re-run" guidance). Nothing to curate yet.
- **Substantive (just-resolved or already-documented updater)** → proceed to tier-2.

- [ ] **Step 2: Write tier-2 orchestration**

On the substantive branch, in order:
1. `Skill(resolve-plugins)` — curation reads stack signal from `techstack.md` + external-tools from `overview.md`'s `<!-- harness-meta -->` block (the relocated old-Q4 signal). No Q&A — the signal is already in the docs.
2. Tech-specific rules seeding — the rule-signal detection that lived in harness-bootstrap Phase 1 (frontend/MV3/etc.) fires here against now-substantive docs, if not already seeded. (Cross-check: if harness-bootstrap still seeds these at runway time, keep it there and drop this — avoid double-seed. Decide by where the signal is reliably available; prefer runway-time if manifest-derivable, tier-2 if it needs `techstack.md` content.)
3. release-init offer — `/super-bootstrap:release-init` as an optional offer.

- [ ] **Step 3: Resolve the rules-seeding ownership (SoC check)**

Confirm exactly one home for each rule-signal seed (frontend, MV3, migrations, tests). Manifest-derivable signals (framework manifest present) → runway-time (harness-bootstrap Phase 1, already there). Signals needing resolved `techstack.md` → tier-2. Document the split in one line so a future reader knows the boundary. No signal seeded in both.

- [ ] **Step 4: Ref-integrity check**

Run: `grep -nE "resolve-plugins|release-init|harness-meta" plugins/super-bootstrap/skills/super-bootstrap/SKILL.md`
Expected: resolve-plugins invoked once on the substantive branch; harness-meta cited as the external-tools source; release-init offered once.

- [ ] **Step 5: Commit**

```bash
git add plugins/super-bootstrap/skills/super-bootstrap/SKILL.md
git commit -m "feat(super-bootstrap): gate tech curation on substantive seed docs"
```

---

### Task 5: Entry — seed 2 GAP cards via `/log` (dogfood capture, idempotent)

**Files:**
- Modify: `plugins/super-bootstrap/skills/super-bootstrap/SKILL.md` (the Task-3 step-4 GAP-seeding stub)
- Reference: `plugins/super-bootstrap/skills/harness-bootstrap/assets/backlog.md` (card shape) + `plugins/super-bootstrap/skills/log/SKILL.md` (invocation)

**Interfaces:**
- Consumes: Axis B = not substantive (greenfield/undocumented); the runway has scaffolded `docs/backlog.md` (empty).
- Produces: exactly 2 GAP cards in `docs/backlog.md`, seeded **through `/super-bootstrap:log`**, idempotent on re-run.

- [ ] **Step 1: Write the seeding step**

When Axis B is not substantive, after the runway scaffolds the empty backlog, invoke `/super-bootstrap:log` with two observations (batched, one invocation):
- `"pin down product overview — docs/overview.md is an unfilled skeleton"` → classifies GAP.
- `"decide techstack — docs/techstack.md is an unfilled skeleton; blocked on the overview card"` → classifies GAP.

Cards carry `Prior:` as a **HINT, not a locked route**: `Prior: no source code → brainstorm; source present + undocumented → distill-repo-essence`. This honors backlog's "no phase prescription" — triage decides the method at pickup.

- [ ] **Step 2: Idempotency guard**

Before seeding, read `docs/backlog.md` and check for existing overview/techstack GAP cards (match on the card summary text, since IDs are minted by `/log`). If present → skip seeding, log "GAP cards already seeded." This makes re-run safe (the two correctness moves: git-init + re-run idempotency).

- [ ] **Step 3: Confirm card shape matches the template**

Cross-check the seeded card against `assets/backlog.md`'s row shape (`### {BUG|DEBT|GAP}-### — {summary}` + Logged/Source/Problem/Area/Prior). `/log` writes the canonical shape — confirm the observations carry enough for its classifier to fill Source (`/super-bootstrap bootstrap`) and Area (`docs/overview.md` / `docs/techstack.md`).

- [ ] **Step 4: Write the dogfood handoff line (pairs with Task 4 gate STOP)**

On the not-substantive branch, the STOP surfaces:
```
Generic harness installed. Two GAP cards seeded (overview, techstack).
Resolve them via /super-bootstrap:todo → brainstorm (no code) / distill-repo-essence (code present).
Once overview.md + techstack.md are filled, re-run /super-bootstrap for tech curation.
```

- [ ] **Step 5: Ref-integrity check**

Run: `grep -nE "log|GAP|Prior" plugins/super-bootstrap/skills/super-bootstrap/SKILL.md`
Expected: `/super-bootstrap:log` invoked once with batched observations; idempotency guard present; Prior:HINT phrasing present.

- [ ] **Step 6: Commit**

```bash
git add plugins/super-bootstrap/skills/super-bootstrap/SKILL.md
git commit -m "feat(super-bootstrap): seed 2 GAP cards via /log, idempotent (dogfood capture)"
```

---

### Task 6: Entry — post-hoc disclosure (autonomous tier-1, no consent gate)

**Files:**
- Modify: `plugins/super-bootstrap/skills/super-bootstrap/SKILL.md` (the Task-3 step-6 disclosure stub)

**Interfaces:**
- Consumes: the set of files the runway wrote/changed (CLAUDE.md, settings.json core pins, docs skeletons, rules).
- Produces: one post-hoc heads-up line in the done-summary — disclosure + reconciliation-enabler.

- [ ] **Step 1: Write the disclosure line**

Invoking the command IS consent — no upfront gate. After the runway (and tier-2 if it ran), the done-summary carries one line:
```
Wrote/changed: CLAUDE.md, .claude/settings.json, docs/ skeletons{, rules}. Review with `git diff` (or `git diff HEAD~N`).
```
Phrased as forward navigation (positive-over-negative): tells the user where to look, not "this might have clobbered your config." Covers users with existing harness taste.

- [ ] **Step 2: Confirm no consent gate crept in**

Re-read the entry flow — confirm there is **no** "proceed? (y/n)" before scaffolding. The closed fork at `docs/decisions.md:21` (rejected a PreToolUse entry-gate hook, "probe ambient first") backs the no-hard-gate direction. The disclosure is post-hoc only.

- [ ] **Step 3: Cold-read the full entry skill**

Read `super-bootstrap/SKILL.md` end to end. Confirm the whole orchestrator is coherent: git-init → detect → runway → (greenfield: GAP cards + STOP + handoff) / (substantive: tier-2 curation) → disclosure. No stubs remain.

- [ ] **Step 4: Commit**

```bash
git add plugins/super-bootstrap/skills/super-bootstrap/SKILL.md
git commit -m "feat(super-bootstrap): post-hoc disclosure line (consent-by-invocation)"
```

---

### Task 7: rename-map coverage for renamed literals (updater rot-scan)

**Files:**
- Modify: `plugins/super-bootstrap/skills/harness-bootstrap/assets/rename-map.md`

**Interfaces:**
- Consumes: the full set of changes from Tasks 1-6.
- Produces: rename-map entries so an updater's rot scan (harness-bootstrap Phase 1 + 3b) catches any user-facing literal this refactor renamed in already-bootstrapped repos.

- [ ] **Step 1: Enumerate user-facing literal changes**

Diff the branch against `main` and list every literal that appears in **scaffolded/pipeline-owned files** (CLAUDE.md skeleton, docs skeletons, rules) that this refactor renamed or retired. The refactor is mostly skill-internal flow — expect few or none. Candidates to check: any slash-command rename, any CLAUDE.md skeleton section whose name/wording an old repo would carry.

Run: `git diff main --stat` then inspect `claude-md-skeleton.md` / skeleton assets for renamed tokens.

- [ ] **Step 2: Add rename-map rows (if any)**

For each renamed literal, add a row to `rename-map.md` per its existing format (`old` → `new` + reason). If the refactor renamed **nothing** user-facing, write a one-line note in the commit body stating "no rename-map entries needed — changes are skill-internal" and skip the file edit.

- [ ] **Step 3: Verify rot-scan would fire**

Confirm each new `old` literal is a whole-token match that the Phase 1 rot scan greps for. Cross-check against `harness-bootstrap` Phase 1 rot-signal logic (lines ~70-87).

- [ ] **Step 4: Commit (only if rows added)**

```bash
git add plugins/super-bootstrap/skills/harness-bootstrap/assets/rename-map.md
git commit -m "chore(harness-bootstrap): rename-map entries for tier-split rot scan"
```

---

### Task 8: Doc-sync + audit-harness-edits + resolve DEBT-001

**Files:**
- Modify: `plugins/super-bootstrap/README.md`, `plugins/super-bootstrap/.claude-plugin/plugin.json` (description, if it narrates the old flow)
- Modify: `docs/backlog.md` (delete DEBT-001 row)
- Audit: both `SKILL.md` files

- [ ] **Step 1: Doc-sync the full propagation closure**

The phase renumber (3x→2x) + Q&A/curation removal rippled wider than the original README+plugin.json scope. Both the unit-1 implementer and the cold auditor (seam 1, Finding 2) flagged the same stale-cross-ref set. Fix every one against the *final* state of both skills:

- `plugins/super-bootstrap/README.md` — "harness-bootstrap Phase 3c delegates" (→ tier-2/entry), "redirects empty repos here" (greenfield no longer redirects).
- `plugins/super-bootstrap/.claude-plugin/plugin.json` — description narrating old flow.
- `plugins/super-bootstrap/skills/resolve-plugins/SKILL.md` — frontmatter "delegated from harness-bootstrap Phase 3c"; Phase 1 "harness delegation (Phase 3c)"; Phase 1 "same MCQ as harness-bootstrap Phase 2 Q4" (Q&A gone — repoint to tier-2's own prompt); Phase 4 "Phase 3a pins" (→ 2a).
- `plugins/super-bootstrap/agents/help.md` — "called from harness Phase 3c."
- `plugins/super-bootstrap/skills/drain/assets/ensure-infra.md` — cross-ref "§Phase 3a (drain infra opt-in)" (→ 2a-drain).
- `plugins/super-bootstrap/skills/harness-bootstrap/assets/rename-map.md` — prose "Phase 3b can spot literals" (→ 2b).
- **Orphaned asset:** `plugins/super-bootstrap/skills/harness-bootstrap/assets/phase2-qa-protocol.md` — its only consumer (Phase 2 Q&A rendering) is deleted. Delete it; grep first to confirm no surviving reference.

Run the sweep: `grep -rnE "Phase 3[abcd]|Phase 2 Q|ideation|greenfield Q&A|phase2-qa-protocol|redirects? .*(here|empty repo)" plugins/super-bootstrap/`
Expected after fixes: zero stale phase numbers / Q&A references outside the audited skills' own current bodies.

- [ ] **Step 2: Run audit-harness-edits**

Invoke the `audit-harness-edits` skill on the branch diff (both SKILL.md files are harness files — this is the verify artifact per CLAUDE.md Entry Gate step 5). Disposition each finding: fix real ones, justify-skip false positives.

- [ ] **Step 3: Cross-skill integration check**

Walk the live flow cold: `/super-bootstrap` on a fresh repo → runway installs → 2 GAP cards seeded → STOP + handoff. Then simulate "docs filled" → re-run → tier-2 curates. Confirm every Skill invocation and asset path resolves (no dangling `../harness-bootstrap/assets/...` after the entry stopped loading skeletons directly).

Run: `grep -rnE "Skill\(|/super-bootstrap:|\.\./harness-bootstrap/assets" plugins/super-bootstrap/skills/super-bootstrap/SKILL.md plugins/super-bootstrap/skills/harness-bootstrap/SKILL.md`
Expected: every invocation/path points at something that exists.

- [ ] **Step 4: Resolve DEBT-001**

Delete the DEBT-001 row from `docs/backlog.md` (resolving session's job per backlog cleanup rule). The ID stays consumed (history = `git log --grep="DEBT-001"`); do not touch the high-water-mark line.

- [ ] **Step 5: Final commit**

```bash
git add plugins/super-bootstrap/README.md plugins/super-bootstrap/.claude-plugin/plugin.json docs/backlog.md
git commit -m "docs: sync bootstrap flow narration; resolve DEBT-001"
```

- [ ] **Step 6: Finish the branch**

Use `superpowers:finishing-a-development-branch` to decide merge/PR. On merge: delete this plan + any temporal spec from `docs/superpowers/plans|specs/` (temporal cleanup per CLAUDE.md § Doc Sync).

---

## Self-Review

**Spec coverage (card's 6 points + 2 moves):**
1. Unified detection → **refined to two-axis** (Task 3 step 2) — Axis B keeps the seed-doc-presence spirit; Axis A fixes the updater hole. ✓
2. Two-tier install + CLAUDE.md relocation → runway (Tasks 1-2) writes CLAUDE.md + generic artifacts always; tech curation gated (Task 4). ✓
3. Bootstrap writes zero product content → Phase 1 ideation + Phase 2 product Q&A dissolved (Tasks 1, 3); 2 GAP cards via /log (Task 5). ✓
4. Method routed at pickup → Prior:HINT, not locked route (Task 5 step 1). ✓
5. Autonomous tier-1, no consent gate → post-hoc disclosure (Task 6). ✓
6. Two correctness moves → git-init (Task 3 step 3) + re-run idempotency (Task 5 step 2). ✓
- Non-goals (no roadmap tier, no clobber gate) → honored; disclosure + git diff is the reconciliation path, not a gate. ✓
- **Updater path** (the smoothness concern) → Axis A always-sync (Task 3 step 2) + Q&A dissolution removes forced re-confirm + external-tools persists in overview.md (Task 4 step 2) + rot-scan coverage (Task 7). ✓

**Open judgment for the executor:** Task 4 step 3 (rules-seeding ownership — runway-time vs tier-2). Resolve by signal availability; the rule is "one home per signal, no double-seed." If ambiguous at execution, surface rather than guess.

**Placeholder scan:** the new prose snippets (gate, GAP-card observations, disclosure line, handoff) are given verbatim; structural surgery (delete/relocate/renumber) is specified by section + line range. No "TBD"/"handle edge cases" left.

**Type/name consistency:** Axis A / Axis B used consistently; `/super-bootstrap:log`, `/super-bootstrap:resolve-plugins`, `/super-bootstrap:release-init`, `/super-bootstrap:todo` named exactly; `<!-- harness-meta -->` external-tools block is the single external-tools source across Tasks 2/4.
