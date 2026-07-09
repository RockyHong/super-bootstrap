# Doc-Sync Gate Redesign — Dissolve the Ceremonial Token (GAP-024)

**Card:** GAP-024 — doc-sync gate conflates scan-ran proof with docs-resolved judgment; shared token safe only because commit channel serializes. Root upstream of GAP-022, DEBT-010, DEBT-011, DEBT-014.

**Date:** 2026-07-10 · **Route:** brainstorming → this spec → writing-plans

---

## Problem

The current doc-sync-before-commit gate is a two-hook mechanism (`docsync-scan.sh` + `docsync-gate.sh`) coordinating through a single shared mutable token file (`.git/docsync-token`, written at the main repo's git-common-dir, one-shot consumed). It carries two structural smells and a heavy accumulated cost, while not addressing the failure mode it appears to guard.

### Smell 1 — semantic gap (partly irreducible)

The token proves only *"a scan ran in this session within 30 min"*. It does **not** verify docs were actually resolved/synced — the staleness judgment is externalized to the scanning agent and unenforced. This contradicts CLAUDE.md's own doc-sync doctrine ("gateway + user resolve, never silently fix/skip").

**Irreducibility (grounded in `decisions.md` row 39):** a `PreToolUse(Write)` hook to enforce doc routing was already closed as a fork because *"the routing includes an omission decision a hook can't deny, only nudge."* Resolving doc-sync often means *deciding no doc needs changing* — an omission. No hook can verify an omission. So no mechanism can mechanically guarantee "docs are synced." The achievable targets are only: (a) get the scan surface in front of the deciding actor, and (b) place the judgment with the right actor by construction.

### Smell 2 — shared mutable state (Axiom VII), collision-safe only by serialization

The single token is collision-safe **only because** `commit-channel.sh` serializes all commits to one channel (commit agent / main). Multiple non-worktree dispatched agents in the same workspace would all write/consume the same token → overwrite + one-shot-consume race. This co-dependence is precisely why widening the commit channel (GAP-022) reads as invariant-breaking: removing the serialization exposes the token collision `commit-channel.sh` currently prevents.

### The real root — flow-agnostic enforcement via string-matching

Git history names the root directly. The v3 redesign commit (`7e8f7b1`) states its own root cause: **"enforcing a semantic invariant via command-string matching."** The entire v1→v4 evolution — BUG-007 (token-write flagged as bypass), BUG-009 (gate blocks /release), GAP-010/GAP-011 (session-key), BUG-014 (substring over-match), the v4 matcher — is accumulated fixes to one fragile idea.

That idea is a **deliberate design choice**, also stated in `7e8f7b1`: *"any flow that scans earns its commit; /super-bootstrap:commit no longer the only lawful path."* The gate was made **flow-agnostic** on purpose — so /release, or any scan-first flow, could commit without going through the commit skill. A token/stamp is the *only* mechanism that can enforce "a scan ran" when there is no single lawful path. The flow-agnostic choice **necessitates** the token, and the token's fragility (string-matching a `git commit` invocation at PreToolUse) is the small-change-cost cluster's engine.

### What the token does NOT fix

Empirically (user's lived experience across the pre-token pipeline): the well-disciplined pipeline did doc-sync anyway; the residual failure was ~20% chronic omission in the heal step — an **accuracy/coverage** problem. A per-commit stamp is structurally incapable of catching coverage misses (it proves a scan *ran*, not that it *caught everything*). That accuracy layer is already owned by `/check-docs-consistency` — an async, whole-repo, cross-reference scan producing a `.review/` report + a `doc-hygiene.json` current-state stamp. The token guards a narrow case (a commit that skipped doc-sync) at broad cost, while the genuine failure mode is owned elsewhere.

---

## Root-cause reframe

Reverse the flow-agnostic choice. Make **`/super-bootstrap:commit` (the commit agent) the SSOT commit path for subagents**; `commit-channel.sh` already enforces exactly this (subagents denied, main + `*:commit` trusted). With one lawful subagent path, the token becomes unnecessary: doc-sync lives *in-process in the one door*, and the ceremonial flow-agnostic stamp dissolves.

The commit agent **already supports this** — `commit.md` §3 has a two-layer doc-sync gate:

1. **Semantic staleness scan** (lines 34–40): grep the doc surface for prose describing behavior the diff touched, return `stale-docs` to the gateway if any, else proceed. This is the *real* doc-sync judgment, runs in-process, **always**, regardless of hooks.
2. **Hook dance** (lines 42–47): the token/gate branch, only when the gate hook is live. The "Gate absent" branch (line 44) states plainly: *"the staleness judgment above still gates; once clear, commit directly."*

So the redesign **keeps layer 1, deletes layer 2** — the commit agent runs in permanent "gate-absent" mode. This is a *simplification*, not a rewrite.

---

## Design — A-strict

### Principle

- **One lawful subagent commit path**: `/super-bootstrap:commit`. Doc-sync (the semantic staleness scan + gateway/user resolution) lives in-process there. No external stamp.
- **Judgment actor by construction**: the commit agent returns `stale-docs`; the gateway + user resolve. The right actor holds the judgment because there is one door and the door routes to the gateway.
- **Accuracy backstop**: `/check-docs-consistency` (async, whole-repo) owns coverage — the ~20% heal-omission class. Its `doc-hygiene.json` is the *legitimate* stamp (current-state, overwrite-in-place verification metadata — not a per-commit ceremonial token).
- **Trust model for off-door commits**: main-session direct `git commit` is off-doctrine (CLAUDE.md: "Commit = /super-bootstrap:commit") and is trusted + async-backstopped, not hook-blocked. The user accepts this trade (the pipeline did doc-sync without the token anyway; the async scanner catches drift).

### Components

**Deleted:**
- `docsync-gate.sh` (both plugin asset + `.claude/hooks/` dogfood copy)
- `docsync-scan.sh` (both copies) — its surface-print is redundant with the commit agent's own §3 grep; its token side-effect is the thing being removed
- The token mechanism (`.git/docsync-token`) entirely
- `docsync-gate.hook.json` / `docsync-scan.hook.json` merged-settings entries

**Kept, unchanged in role:**
- `commit-channel.sh` — the single-channel door enforcement (subagent → door, main + `*:commit` trusted). This is now the *sole* commit hook. (DEBT-010: its matcher is the over-match class BUG-014 fixed in docsync-gate; with docsync-gate gone, the "deliberate divergence" note disappears — commit-channel can adopt the command-position anchor cleanly. Folded here.)
- `/check-docs-consistency` — async accuracy layer, unchanged.
- The commit agent's §3 semantic staleness scan (layer 1).

**Changed:**
- `commit.md` agent — delete §3 lines 42–47 (the hook-branch state machine); keep §3 lines 34–40 (semantic scan). Update frontmatter description (drop "docsync-gate hook state machine"). Drop the "scan and commit are separate Bash calls" rule (no scan call anymore).
- `harness-bootstrap` SKILL.md + `hooks-ensure-infra.md` — remove docsync-gate/scan from the installed hook set (was 5 FROZEN assets → now harness-grounding + commit-channel). Add a retirement step: an adopter re-run removes the now-retired `docsync-gate.sh` / `docsync-scan.sh` (same pattern as the already-retired `docsync-stamp.sh`).
- `release-init` template + this repo's `/release` — drop the "run docsync-scan.sh first" step (BUG-009's fix, now moot). /release commits from main; commit-channel allows main.
- CLAUDE.md doc-sync doctrine + envelope — the doc-sync step is the commit agent's in-process scan + gateway resolution; drop token/scan-call ceremony references.
- README / plugin.json / marketplace description — update the default-on-hooks narration (hook count + names).
- `tests/docsync-hooks.test.sh` — retire the token/gate assertions; keep/retarget commit-channel matcher assertions.

### Data flow — commit path after redesign

```
gateway (session done) → /super-bootstrap:commit
  → dispatch commit agent (agent_type: super-bootstrap:commit)
    → §1 gather state · §2 classify session vs prior
    → §3 semantic staleness scan (grep doc surface for diff-touched prose)
        → stale candidates? → return stale-docs → gateway + user resolve → re-dispatch
        → clean? → §4 draft message → §5 stage by path + git commit
    → commit-channel.sh PreToolUse: agent_type = super-bootstrap:commit → *:commit → pass
    → §6 return hash + push + cycle facts
```

No token write, no scan.sh call, no PreToolUse token check. `commit-channel.sh` is the only PreToolUse hook on the commit, and it passes the commit agent by `agent_type`.

### /release exception (documented, not a hole)

/release is a version commit (bump plugin.json, sync marketplace description mirror) that runs in the main session. `commit-channel.sh` allows main. /release owns its own narrow doc-sync concern (the marketplace description mirror) in its own logic. It is a documented second lawful path, not an ungated bypass — consistent with the SSOT-path model (subagents → commit door; main-session flows are trusted named exceptions).

### GAP-022 resolution (reframed, now unblocked)

**What GAP-022 is:** `commit-channel.sh` forbids dispatched worker subagents from running `git commit` — only the commit agent (via `/super-bootstrap:commit`) or the main session may. But superpowers' *subagent-driven-development* (SDD) working style designs each dispatched "implementer" subagent to implement **and commit its own work**. sb's channel blocks those implementer commits, so the gateway must re-commit each one — the delegation benefit is lost.

Deleting the token removes the *invariant risk* that made widening `commit-channel` dangerous (multiple committers no longer race on a shared doc-sync token). But `commit-channel` still denies subagents by design — so GAP-022 is now a pure doctrine choice, not an architecture risk:

- **Default (recommended): keep the carve-out.** A "carve-out" here = a documented override in CLAUDE.md stating that under sb, SDD's "implementer commits its own work" step is replaced: the implementer subagent finishes, reports *done + the file list*, and the **gateway** commits via `/super-bootstrap:commit`. The commit agent owns doc-sync in-process — clean, simplest, no hook change.
- **When free implementer commits are genuinely wanted: drain worktree.** sb's drain feature already lets worker subagents commit freely inside an isolated git worktree (under `.claude/worktrees/`), with doc-sync deferred to the merge boundary instead of per-commit. SDD implementers can run there when end-to-end delegation is truly wanted.

Either way, the redesign closes GAP-022's invariant concern. Its *separate* cost concern — that dispatching a subagent to make an edit whose exact text is already known costs more than just making the edit inline — is a routing problem (don't dispatch transcription-grade work at all), not a commit-gate problem, and is handled by the transcription-inline rule in CLAUDE.md § Agent Discipline plus the related routing cards (GAP-020, GAP-023, DEBT-013).

### Facet card disposition

| Card | Disposition after this redesign |
|---|---|
| **DEBT-011** (scan + commit two mandatory Bash calls) | **Dissolved** — no scan call, no token; the two-call handshake is gone. |
| **DEBT-014** (docs-only diffs pay the token dance) | **Dissolved** — no token dance; a docs-only diff runs the in-process scan (cheap) and commits. |
| **DEBT-010** (commit-channel over-match) | **Folded here** — with docsync-gate gone, commit-channel adopts the command-position anchor with no divergence note to reconcile. |
| **DEBT-013** (small-change lane) | **Partly dissolved** — the doc-sync-scan-subagent portion of the overhead is gone. The dispatch-per-phase routing portion remains a separate CLAUDE.md § Dispatch concern. |
| **GAP-022** (channel blocks SDD implementer) | **Reframed + unblocked** — invariant risk removed; doctrine carve-out (recommended) or drain worktree. |

On merge of the implementing work, these facet rows are deleted (git is the archive); GAP-024 is deleted; any GAP-022 residual doctrine decision is captured in CLAUDE.md, not left as a card.

---

## Migration surface (for writing-plans to sequence)

FROZEN-hook deletions + dogfood + downstream-seed touch-points:

1. Delete plugin assets: `assets/hooks/docsync-gate.sh`, `assets/hooks/docsync-scan.sh` + their `.hook.json`.
2. Delete dogfood copies: `.claude/hooks/docsync-gate.sh`, `.claude/hooks/docsync-scan.sh` + settings entries.
3. `commit.md` agent — simplify §3, frontmatter, rules.
4. `harness-bootstrap` SKILL.md + `hooks-ensure-infra.md` — hook-set narration + adopter retirement step for the two retired hooks.
5. `release-init` template + this repo's `/release` — drop the scan-first step.
6. CLAUDE.md — doc-sync doctrine + envelope prose.
7. README + plugin.json + marketplace mirror — hook narration.
8. `tests/docsync-hooks.test.sh` — retire token/gate assertions, keep commit-channel.
9. `commit-channel.sh` — adopt command-position matcher (DEBT-010).

**Adopter migration:** existing bootstrapped repos carry the old hooks; the harness-bootstrap re-run's drift/retirement step removes them (same mechanism that retired `docsync-stamp.sh`). Note: this repo's installed hooks are v4 (ahead of the last plugin release) — the deletion supersedes the v3-vs-v4 divergence entirely.

---

## Success criteria

- A subagent commit through `/super-bootstrap:commit` lands with no token file created, no scan.sh invocation, commit-channel passing by agent_type.
- The commit agent still returns `stale-docs` on a diff with stale doc prose (layer-1 semantic scan intact) — verified by a diff that touches behavior narrated in `docs/`.
- A docs-only diff commits without any token ceremony.
- `/check-docs-consistency` still runs and produces its report + hygiene stamp (accuracy layer untouched).
- No `.git/docsync-token` path referenced anywhere in the shipped plugin or dogfood tree after migration.
- `commit-channel.sh` matcher no longer substring-matches a `git commit` mention inside a quoted arg / heredoc (DEBT-010 class), verified by the retargeted test.

## Non-goals / accepted limits

- **Not** mechanically guaranteeing "docs are synced" — irreducible (decisions.md row 39); the judgment stays a gateway+user act, backstopped async.
- **Not** blocking off-door (main-session ad-hoc) commits — trusted by doctrine + async scanner, not hook-enforced.
- **Not** re-deciding GAP-022's doctrine here beyond the recommendation — the plan/CLAUDE.md edit lands the chosen carve-out.

## Risks

- **Off-door commit skips doc-sync.** Mitigated: pipeline discipline (commit agent is the door) + `/check-docs-consistency` async catch. Accepted by the user.
- **Downstream adopters mid-migration** carry stale hooks until their next harness-bootstrap re-run; the retirement step is idempotent and the deleted hooks fail safe (their absence = the commit agent's gate-absent branch, which already does the real scan).
