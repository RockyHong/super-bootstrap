# Doc-Sync Gate Redesign Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Dissolve the ceremonial doc-sync token mechanism — make `/super-bootstrap:commit` the SSOT commit path with doc-sync in-process, delete the token hooks, leaving `commit-channel` as the sole commit hook and `/check-docs-consistency` as the async accuracy layer.

**Architecture:** The commit agent's existing in-process semantic staleness scan (`commit.md` §3 layer 1) becomes the whole doc-sync mechanism; the token/gate hooks (layer 2) are deleted. See the design spec `docs/superpowers/specs/2026-07-10-docsync-gate-redesign-design.md` for full rationale — this plan sequences its § Migration surface into shippable tasks.

**Tech Stack:** Markdown-authored Claude Code plugin. No language runtime, no build. Verification is static (grep assertions) except the one live bash test for `commit-channel.sh`. Every task touches harness files → each ends with `/audit-harness-edits` + user ship-confirm per the session cadence.

## Global Constraints

- **No-runtime repo:** red/runtime phases are structurally empty; verification = static grep/consistency assertions + the `tests/` bash suite for the surviving hook. Copied verbatim from the envelope (CLAUDE.md § The envelope).
- **FROZEN-hook edits:** the deleted files carry `# FROZEN` markers; deletion (not mutation) is the operation. The surviving `commit-channel.sh` stays FROZEN — its matcher change bumps its version marker.
- **Dogfood + source parity:** every plugin-asset hook has a git-tracked dogfood copy under `.claude/hooks/`; source and dogfood copy change in the same task (propagation closure, one commit).
- **Migration safety net:** the commit agent's gate-absent branch (`commit.md:44`) keeps commits working the instant a hook disappears — so deletions are safe before the agent is simplified. Order below still deletes hooks before simplifying the agent to lean on this.
- **Downstream adopters:** existing bootstrapped repos carry the old hooks; removal reaches them via the harness-bootstrap re-run's retirement step (same mechanism that retired `docsync-stamp.sh`).
- **Card cleanup:** on completion, resolved rows (GAP-024, GAP-022, DEBT-010, DEBT-011, DEBT-014) + `docs/superpowers/triage/GAP-022-notes.md` + this spec/plan pair are deleted (git is the archive). DEBT-013 is edited down to its residual (routing-only), not deleted.

---

### Task 1: commit-channel matcher — adopt command-position anchor (DEBT-010)

Resolves the over-match class (a `git commit`-shaped substring inside a quoted arg / heredoc trips the deny). With `docsync-gate.sh` being deleted this task, the "deliberate divergence" note vanishes — `commit-channel` simply adopts the good anchor.

**Files:**
- Modify: `plugins/super-bootstrap/skills/harness-bootstrap/assets/hooks/commit-channel.sh:20-24` (matcher) + `:1` FROZEN version marker (v1 → v2)
- Modify: `.claude/hooks/commit-channel.sh` (dogfood copy — same edit)
- Test: `tests/docsync-hooks.test.sh` (retarget the commit-channel matcher assertions; add a heredoc/quoted-arg negative case)

**Interfaces:**
- Produces: `commit-channel.sh` v2 with a bash `[[ =~ ]]` command-position matcher mirroring `docsync-gate.sh` v4's `_re` (command-start or after `;`/`&`/`|`, `[:blank:]` gaps, trailing boundary skipping `commit-tree`/`-graph`). Note: `commit-channel`'s existing safe-fail bias (over-match denies a non-commit worker, never lets a commit through) is preserved — the anchor tightens the match, it does not flip the bias.

- [x] **Step 1: Write the failing test** — add to `tests/docsync-hooks.test.sh`: a case feeding `commit-channel.sh` stdin whose command contains a quoted `"git commit"` substring (not a real invocation) under a non-commit `agent_type`; assert it PASSES through (exit 0, no deny). Under current v1 grep matcher this fails (denies).
- [x] **Step 2: Run to verify it fails** — `bash tests/docsync-hooks.test.sh`; expect the new assertion RED.
- [x] **Step 3: Port the v4 anchor** — replace `commit-channel.sh`'s `grep -Eq '...'` matcher with the bash `[[ "$cmd" =~ $_re ]]` form from `docsync-gate.sh:47` (read it as the reference), keeping commit-channel's `command -v jq` guard and `agent_type` case. Apply to both source + dogfood copy. Bump `# FROZEN commit-channel v1` → `v2`.
- [x] **Step 4: Run to verify pass** — `bash tests/docsync-hooks.test.sh`; all assertions GREEN.
- [x] **Step 5: audit + ship** — `/audit-harness-edits` on the diff; ship-confirm; commit (`fix(hooks): commit-channel v2 — command-position matcher (DEBT-010)`).

---

### Task 2: Delete the token hooks (source assets + dogfood copies + settings)

**Files:**
- Delete: `plugins/super-bootstrap/skills/harness-bootstrap/assets/hooks/docsync-gate.sh`
- Delete: `plugins/super-bootstrap/skills/harness-bootstrap/assets/hooks/docsync-scan.sh`
- Delete: their `.hook.json` merged-settings entries (locate under the same assets dir / hooks-ensure-infra references)
- Delete: `.claude/hooks/docsync-gate.sh`, `.claude/hooks/docsync-scan.sh` (dogfood copies) + this repo's `.claude/settings*.json` entries registering them

**Interfaces:**
- Produces: a repo with no `docsync-gate`/`docsync-scan` hook files and no settings referencing them. The commit path now relies on the commit agent's gate-absent branch (already live).

- [ ] **Step 1: Enumerate settings references** — grep `.claude/settings*.json` + the assets `*.hook.json` for `docsync-gate` / `docsync-scan`; list every registration.
- [ ] **Step 2: Delete the four hook files** (2 source assets + 2 dogfood copies) and their settings/`.hook.json` entries.
- [ ] **Step 3: Verify no dangling reference** — `grep -rn "docsync-gate\|docsync-scan\|docsync-token" .claude plugins` returns only intentional narration slated for later tasks (commit.md, SKILL.md, hooks-ensure-infra, README, tests) — no live settings/hook wiring.
- [ ] **Step 4: Behavioral check** — dispatch a trivial commit through `/super-bootstrap:commit`; confirm it lands with no token file created (`test ! -f .git/docsync-token`) and no deny.
- [ ] **Step 5: audit + ship** — `/audit-harness-edits`; ship-confirm; commit (`refactor(hooks): delete docsync-token gate — SSOT commit path (GAP-024)`).

---

### Task 3: Simplify the commit agent (`commit.md` §3)

**Files:**
- Modify: `plugins/super-bootstrap/agents/commit.md` — §3 (delete lines 42–47 hook-branch state machine; keep 34–40 semantic scan); frontmatter description (drop "docsync-gate hook state machine"); § Rules (drop "Scan and commit are separate Bash calls")

**Interfaces:**
- Consumes: nothing new.
- Produces: a commit agent whose only doc-sync is the §3 semantic staleness scan → `stale-docs` return; commits directly once clean. No hook probes, no scan invocation, no token.

- [ ] **Step 1: Rewrite §3** — keep the staleness-scan paragraph (34–40); replace the four hook-branch bullets (42–47) with a one-line close: once the scan is clean, stage and commit directly (no token, no scan script). Judgment-grade edit — draft against the spec's § Data flow, don't transcribe blindly.
- [ ] **Step 2: Fix frontmatter + rules** — description: "…runs the doc-sync staleness scan (consumer CLAUDE.md § Doc Sync owns the surface), drafts a conventional message…" (drop the hook-state-machine clause). Remove the "Scan and commit are separate Bash calls" rule bullet.
- [ ] **Step 3: Consistency check** — grep `commit.md` for `docsync-gate`/`docsync-scan`/`docsync-token`/`gate-absent` → zero hits.
- [ ] **Step 4: audit + ship** — `/audit-harness-edits`; ship-confirm; commit (`refactor(commit): fold doc-sync into in-process scan, drop token dance (GAP-024)`).

---

### Task 4: harness-bootstrap install set + adopter retirement

**Files:**
- Modify: `plugins/super-bootstrap/skills/harness-bootstrap/SKILL.md` (hook-set narration: was 5 FROZEN assets → harness-grounding + commit-channel; add retirement of `docsync-gate.sh`/`docsync-scan.sh` for already-bootstrapped repos, mirroring the existing `docsync-stamp.sh` retirement step)
- Modify: `plugins/super-bootstrap/skills/harness-bootstrap/assets/hooks-ensure-infra.md` (drop the two hooks from the ensure-infra asset set + `scriptCurrent()` version table)

**Interfaces:**
- Produces: harness-bootstrap installs only harness-grounding + commit-channel; a re-run on an old adopter removes the retired token hooks.

- [ ] **Step 1: Edit SKILL.md** — hook count/names; add the retirement bullet (find the `docsync-stamp.sh` retirement precedent and extend the retired-set to the two token hooks). Judgment-grade — draft against spec § Migration surface item 4.
- [ ] **Step 2: Edit hooks-ensure-infra.md** — remove the two assets from the copy-on-drift set + version markers.
- [ ] **Step 3: Consistency check** — grep both files for `docsync-gate`/`docsync-scan` → only appear in the retirement/retired-set context, never the install/ensure set.
- [ ] **Step 4: audit + ship** — `/audit-harness-edits`; ship-confirm; commit (`refactor(harness-bootstrap): drop token hooks from install, retire on adopter re-run (GAP-024)`).

---

### Task 5: release-init template + this repo's /release

**Files:**
- Modify: `plugins/super-bootstrap/skills/release-init/**` (template that generates `/release` — drop the "run docsync-scan.sh first" step, BUG-009's now-moot fix)
- Modify: this repo's own `/release` skill (drop the same scan-first step)

**Interfaces:**
- Produces: /release commits from the main session (commit-channel allows main); no scan-first step.

- [ ] **Step 1: Locate the scan-first step** — grep `release-init` + this repo's `/release` for `docsync-scan`; identify the step introduced by BUG-009's fix (`7e8f7b1`).
- [ ] **Step 2: Delete the step** in both the template and this repo's `/release`.
- [ ] **Step 3: Verify** — grep both → zero `docsync-scan` references; /release's own marketplace-mirror doc-sync logic untouched.
- [ ] **Step 4: audit + ship** — `/audit-harness-edits`; ship-confirm; commit (`refactor(release): drop docsync-scan step, commit via trusted main channel (GAP-024)`).

---

### Task 6: CLAUDE.md doc-sync doctrine + envelope

**Files:**
- Modify: `CLAUDE.md` — § Doc Sync (the doc-sync step is the commit agent's in-process scan + gateway/user resolution; drop token/scan-call ceremony) + § The envelope (verify-on-harness / commit-step prose) + the GAP-022 SDD carve-out doctrine (implementer reports; gateway commits via `/super-bootstrap:commit`)

**Interfaces:**
- Produces: doctrine matching the redesigned mechanism + the GAP-022 carve-out as default.

- [ ] **Step 1: Rewrite § Doc Sync** — the gate is the commit door's in-process semantic scan surfaced to gateway+user; accuracy backstop is `/check-docs-consistency`; no token. Judgment-grade — draft against spec § Design + § GAP-022 resolution. Load `/load-harness-principles` first (rewriting what a doctrine section means).
- [ ] **Step 2: Add the SDD carve-out** — one clause in the SDD-consumption routing: under sb, SDD's implementer-commits step is overridden — implementer reports built + file list, gateway commits via `/super-bootstrap:commit`; drain worktree is the opt-in path for free implementer commits.
- [ ] **Step 3: Envelope prose** — reconcile any § envelope reference to the token/scan.
- [ ] **Step 4: Consistency check** — grep `CLAUDE.md` for `docsync-token`/`docsync-scan`/`docsync-gate` → zero (or only in a deliberate "removed" note, preferably none).
- [ ] **Step 5: audit + ship** — `/audit-harness-edits`; ship-confirm; commit (`docs(claude): doc-sync doctrine to in-process door + SDD carve-out (GAP-024/GAP-022)`).

---

### Task 7: README + plugin.json + marketplace mirror

**Files:**
- Modify: root `README.md` + `plugins/super-bootstrap/README.md` (default-on-hooks narration: hook count + names)
- Modify: `plugins/super-bootstrap/.claude-plugin/plugin.json` description (default-on hooks list) + `.claude-plugin/marketplace.json` mirror

**Interfaces:**
- Produces: user-facing narration matching the 2-hook reality (harness-grounding + commit-channel).

- [ ] **Step 1: Edit the four narration sites** — replace the doc-sync-gate hook mentions; state the doc-sync mechanism as the commit door's in-process scan.
- [ ] **Step 2: Verify mirror parity** — plugin.json description == marketplace.json description (sb's mirror invariant).
- [ ] **Step 3: Consistency check** — grep all four for `docsync-gate`/`docsync-scan` → zero.
- [ ] **Step 4: audit + ship** — `/audit-harness-edits` (narration is doc-sync-narrating prose); ship-confirm; commit (`docs: hook narration to 2-hook set post token removal (GAP-024)`).

---

### Task 8: Card cleanup + temporal artifact deletion

**Files:**
- Modify: `docs/backlog.md` — delete resolved rows GAP-024, GAP-022, DEBT-010, DEBT-011, DEBT-014; edit DEBT-013 down to its routing residual (the doc-sync-scan-subagent portion is resolved; the dispatch-per-phase routing portion remains — restate the row to that residual only)
- Delete: `docs/superpowers/triage/GAP-022-notes.md`
- Delete: `docs/superpowers/specs/2026-07-10-docsync-gate-redesign-design.md` + `docs/superpowers/plans/2026-07-10-docsync-gate-redesign.md` (this pair — temporal, deleted on merge)

**Interfaces:**
- Produces: a backlog with the five facet rows gone, DEBT-013 narrowed, and no orphan temporal artifacts.

- [ ] **Step 1: Delete the five rows** — GAP-024, GAP-022, DEBT-010, DEBT-011, DEBT-014. Leave the ID high-water-mark line untouched (consumed IDs stay consumed).
- [ ] **Step 2: Narrow DEBT-013** — rewrite its Problem to the residual: dispatch-per-phase routing overhead on tiny diffs (the doc-sync-scan subagent portion is gone with the token). Keep its ID.
- [ ] **Step 3: Delete the triage notes + this spec/plan pair.**
- [ ] **Step 4: Final sweep** — `grep -rn "docsync-token" .` returns nothing in shipped/dogfood/test trees (backlog/decisions history mentions acceptable only as closed-context); `/check-docs-consistency` optionally run to confirm no dangling doc references.
- [ ] **Step 5: ship** — no audit (docs-only backlog/temporal); ship-confirm; commit (`chore(backlog): close GAP-024 cluster — token dissolved (GAP-024/022, DEBT-010/011/014)`).

---

## Self-Review

**Spec coverage:** every § Migration surface item (1–9) maps to a task — hooks delete (T2), commit.md (T3), harness-bootstrap+ensure-infra (T4), release-init/release (T5), CLAUDE.md (T6), README/plugin.json/mirror (T7), tests (T1 retargets the suite), commit-channel matcher (T1). Success criteria: no-token-on-commit (T2 step 4), stale-docs still returns (T3 — semantic scan kept), docs-only no ceremony (T2 step 4), check-docs-consistency untouched (not modified anywhere — verified by omission), no docsync-token references (T8 step 4), commit-channel matcher (T1). Facet dispositions (spec table): GAP-022 carve-out (T6 step 2), DEBT-010 (T1), DEBT-011/014 dissolved (T2/T3 remove the mechanism), DEBT-013 narrowed (T8 step 2).

**Placeholder scan:** judgment-grade prose edits (T3/T4/T6) intentionally specify intent + location + spec-section rather than embedded final text — this is the same-session transcription carve-out (CLAUDE.md § Agent Discipline; GAP-019), not a placeholder. Mechanical edits (T1 matcher, T2 deletions, T8 row deletions) carry exact targets.

**Type consistency:** n/a (no code types); the one interface — `commit-channel.sh` v2 matcher mirroring `docsync-gate.sh` v4 `_re` — is named consistently in T1.

**Ordering:** T1 (isolated matcher) and T2 (delete, safe via gate-absent branch) are independent; T3 leans on T2's deletion; T4–T7 are narration/doctrine reconciling the deletion; T8 closes. Each task is independently shippable and reviewer-gateable.
