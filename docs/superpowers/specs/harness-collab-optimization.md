# Spec: Harness Collaboration Optimization — user / opus / sonnet / haiku

**Status:** approved direction, ready for implementation orchestration
**Date locked:** 2026-07-06 · **Decisioner:** user (direction MCQ, same date)
**Owner repos:** super-bootstrap (SSOT — changes ship to consumers via plugin update) · claude-config-manager (device-layer items, tagged `[ccm]`)
**Temporal:** delete after merge per [`CLAUDE.md`](../../../CLAUDE.md) § Doc Sync.

---

## 1. Evidence base (already gathered — do not re-derive)

Three independent sources, triangulated 2026-07-06:

1. **Harvest reports** — `claude-config-manager/docs/harness-pain/reports/2026-07-04.md` + `2026-07-06.md` (17+6 transcripts).
2. **super-bootstrap transcript mining** — 35 sessions (`~/.claude/projects/D--Git-super-bootstrap/`, 2026-06-06 → 07-05), deep-read on 5 most recent.
3. **Official docs research** — code.claude.com/docs (memory, hooks, sub-agents, skills, tools-reference, best-practices, settings), verified live 2026-07-06. Plus a haiku-competency probe over the claude-config-manager corpus.

**Root shape (all three sources agree):** prose-enforced discipline does not stick; hard-gated discipline does.

- Principles-load convention re-asserted by user ~15× within a single session (`5a95f9c0`), ~8× in another (`707fa50f:74-285`).
- Dispatch-by-default prose rule silently outvoted by Entry Gate step 4's concrete wording for weeks; root-caused and patched v2.15.0 (`da309ecc:8`), post-fix effect unmeasured.
- Phase 3b per-section diff — user-filed bug, verbatim: "prose-enforced, model-skippable — silently passes real drift" (`9d6b51b2:19`).
- Official position: CLAUDE.md is advisory, injected as user message, "no guarantee of strict compliance"; "if an instruction must run at a specific point, write it as a hook."

**Closed-fork clearance:** [`docs/decisions.md`](../../decisions.md) row "PreToolUse(Edit|Write) hook to enforce the entry gate" was rejected with an explicit re-open condition — *"Build the hook only if the gate prose demonstrably fails downstream."* The evidence above is that demonstration. This spec re-opens that fork legitimately; cite this section when routing. The dimension-routing hook rejection (same doc) stays closed — nothing here touches it.

**Wins to preserve (regression guardrails — do not break while implementing):**
- todo skip-dispatch fast path (2 Globs + backlog Read → empty-state, no spawn) — verified working twice.
- audit-harness-edits catching real propagation drift + gateway dispositioning with judgment (rejected a bad finding, applied two).
- The four fixed dispatch lanes (audit-probe / log / todo / tldr) — zero failed or re-sent dispatches in the whole corpus. Dispatch *machinery* is reliable; every fix below targets *whether/at-what-tier* to dispatch, never the mechanics.
- Verify-before-act (e.g. "remove /discuss if ours" → globs proved not-ours → no-op).

**Explicitly out of scope:** Edit-before-Read (built-in tool-level hard check per official docs; cost is one retry turn; hooks would only add overhead).

---

## 2. Locked direction decisions

| Fork | Decision | Rationale anchor |
|---|---|---|
| Improvement scope | All four axes (A–D) + mechanical floor | user MCQ 2026-07-06 |
| model-designation guard | **Declarative-first, deny kept for edge cases only** — agent frontmatter `model:` + `CLAUDE_CODE_SUBAGENT_MODEL` env resolve *before* dispatch (zero re-send tax); deny hook survives only where declarative can't reach (e.g. workflow name-launch, ad-hoc dispatch missing `model`) | Supersedes the earlier "deny tax worth it" ruling — that ruling predated knowledge of the declarative layer (official sub-agents.md precedence chain) |
| Haiku tier | **Keep, scoped: readers inside existing readers→judge fan-outs only; sonnet floor everywhere else** | Probe verdict: haiku extraction quality held (zero hallucination in the auditable 9-collector run); every haiku output was sonnet-re-verified *by pattern design*, and escaped misses were sonnet/opus misses, not haiku's. Token savings real but confined to the extraction slice — so never build a verification stage *just for* haiku; only use it where a judge already exists |
| Landing | Single spec here; super-bootstrap is SSOT; consumer-visible changes must land in **shipped plugin surfaces** (skills / agents / templates / hook assets) so consumers receive them on plugin update. Device-only items tagged `[ccm]` are claude-config-manager's to pick up | user MCQ 2026-07-06 |

---

## 3. Work items

### Axis A — prose → hard gate

**A1. Harness-edit grounding hook (shipped).**
`PreToolUse` on `Edit|Write` matched to harness paths (`CLAUDE.md`, `.claude/rules/**`, `.claude/skills/**`, `.claude/agents/**`) → `hookSpecificOutput.additionalContext` injecting the grounding checklist (read the repo's rules index + relevant docs before harness edits). **Nudge first, not deny** — escalate to `permissionDecision: "ask"` only if a later harvest shows the nudge under-fires.
*Self-containment constraint (hard):* the shipped hook must work blind downstream — reference only surfaces harness-bootstrap itself stamps (`.claude/rules/index.md`, `docs/`). It must NOT name device-only skills (`/load-harness-principles` does not exist on consumers). Precedent for shipping hooks: drain's read-hook assets.
`[ccm]` companion: device layer may *additionally* inject the principles-load pointer via its own served hook — layered, not merged.
*Ships via:* harness-bootstrap assets (new hook asset + settings wiring, same pattern as drain's).

**A2. Pre-commit doc-sync gate (shipped).**
`PreToolUse` with `if: "Bash(git commit *)"` → runs a check script that verifies the doc-sync artifact exists for the session (produce-then-judge: scan report file present and newer than the staged diff) before the commit executes; on miss, `permissionDecision: "deny"` with a one-line reason (this deny is *correct* — it fires at most once per commit and prevents the audit-after-commit inversion, the measured gate-timing gap).
*Ships via:* harness-bootstrap assets + `/super-bootstrap:commit` skill update (the skill produces the artifact; the hook only checks its existence — cheap, deterministic).
`[ccm]` companion: retime `audit-harness-edits` from Stop-context to the same pre-commit interception.

**A3. Phase 3b forcing function — ALREADY SATISFIED, no work.**
Investigation (2026-07-06) found the fix shipped in commit `7959a15` (2026-06-13, "gate drift check on sync-report artifact") and survived the phase renumbering (old 3b/3d → current 2b/2c). Current SKILL.md §2b (enumerate-first sync report) + §2c (Read + set-difference commit gate) carry the full produce-then-judge mechanism. The § 1 bug quote predates that commit. Kept as a record that the evidence-to-fix pipeline must check git log before prescribing — the exact under-read shape this spec targets.

### Axis B — tiering declarative

**B1. `[ccm]` model-guard demotion.**
Primary enforcement becomes declarative: every typed agent carries frontmatter `model:` (already true for todo/log/help); set `CLAUDE_CODE_SUBAGENT_MODEL` in device settings `env` as the fallback floor for ad-hoc dispatches. The PreToolUse deny survives *only* for surfaces the declarative chain can't inspect (workflow name-launch). Expected effect: the measured 35-deny re-send tax → ~0.
Official precedence chain (sub-agents.md): env var → per-call `model` → agent frontmatter → inherit.

**B2. drain tier + flags hardening (shipped).**
- Add explicit `--model` per phase to drain's `claude -p` dispatch line (highest-fan-out surface in the system, currently tier-unspecified — direct contradiction of the repo's own model-tiering doctrine). Default proposal: `sonnet` for triage/execute/review phases; keep the wave-level relation analysis on the gateway. If phase-level splits prove noisy, a single `--model sonnet` on the whole subprocess is the acceptable floor.
- Codify `--allowedTools "Skill"` (and any other required flags) into drain's dispatch spec + a one-line constraint note in the asset docs — this constraint was independently re-derived in ~7 sessions; make it cold-readable once.
*Ships via:* drain SKILL.md + assets.

**B3. Shell+agent split — from convention to checked rule (shipped).**
SKILL.md frontmatter cannot pin a model; the dispatch-shell + typed-agent pair is the only tiering escape hatch, currently convention-only. Add: (a) a skill-authoring note in the rules index skeleton, (b) a `/release` pre-flight check that flags any shipped skill whose SKILL.md contains bounded-judgment protocol (classify/rank/scan verbs) but no agent dispatch — warn, not block.
First applications: `resolve-plugins` (self-admitted "dispatch candidate" in its own catalog entry) — split Phase 2.5 README-parse→digest into a reader agent; harness-bootstrap's Phase 1 quick-scan is the second candidate. Do resolve-plugins first; measure before touching harness-bootstrap.
*Ships via:* rules-index skeleton, release-init template, resolve-plugins SKILL.md + new agent file.

### Axis C — dispatch-as-hands 實化

**C1. Measure v2.15.0's effect (no code).**
The dispatch-by-default fix landed 2026-07-04; the corpus ends 07-05 — post-fix data is essentially empty. Next harvest window over super-bootstrap + consumer repos: count inline-authoring vs dispatched-authoring (baseline: ~369 inline tool calls vs 27 dispatches ≈ 13:1 in a 10-file sample). Target: authoring work (Write/Edit of skills, rules, specs) predominantly dispatched; ratio is the tracked number, not a hard threshold.

**C2. Spot-check feedback loop (shipped, small).**
scan-workflow-fanout doctrine mandates the invoker spot-check reader output between runs ("pin a lossy reader to sonnet on the next run") — implemented nowhere. Add one line to todo/log dispatch shells: on consuming agent output, gateway spot-checks one sampled item against source; a confirmed miss gets logged via `/super-bootstrap:log` (which then feeds tier re-pinning). Keep it one sampled item — the loop must stay cheaper than the work it audits.
*Ships via:* todo + log SKILL.md dispatch shells.

**C3. `[ccm]` doctrine/reality sync.**
`scan-workflow-fanout.md` says "readers on haiku"; the actual harness-pain-probe is pinned `model: sonnet`. Update the doctrine to the locked Haiku policy (§ 2): haiku readers only where a judge stage already exists; sonnet floor otherwise. One doc edit; prevents the next author from cargo-culting either side.

### Axis D — ask-threshold mechanization

**D1. `[ccm]` climb-SSOT nudge on AskUserQuestion.**
`PreToolUse` matcher `AskUserQuestion` → `additionalContext`: "Before asking: locked decisions → project docs → own capability check. Delegation signal present → pick + state, don't ask." **Never deny** — the pipeline's designed gates (route-confirm, merge gate, drain halts) are deliberate asks and must not be suppressed; the nudge reminds, the model decides. Measured motivation: 9–18 asks/session in five sessions, often outnumbering dispatches; ask-over-fire is a 3-window recurring harvest shape.
Device-layer because the Ask Threshold policy is user-global — but evaluate whether a consumer-generic version ("check docs/decisions.md + backlog before asking") earns a shipped variant later. Not now.

**D2. `[ccm]` session-close single-option AskUserQuestion bug.**
Schema requires ≥2 options; session-close's single-option push-confirm can never render (`InputValidationError`, `67717a29:270`). Fix: two options (push now / hold) or fold into /release as the recovery already did. Small, mechanical.

### Mechanical floor (no design decisions — batch these first)

- **M1 (shipped).** todo dispatch-prep ordering: run the skip-gate globs *before* reading dispatch-prep files (~5-6K tokens read then discarded on empty board, `0a42ac59:32-38`). Reorder in SKILL.md.
- **M2.** Run `/doctor` — one unresolved plugin load error from `da309ecc:471`, never diagnosed.
- **M3 (shipped).** Repo-boundary rule: new path-scoped rule (or CLAUDE.md § addition) in super-bootstrap codifying (a) in-repo dev version vs installed/published version — test against published unless explicitly working the dev copy; (b) findings about *this repo's own artifacts* route `/super-bootstrap:log`; findings about *device/global config* route `/contribute`. Both confusions user-corrected repeatedly (`5fc3e7e3:53,582`; `9d94c333:129`).
- **M4.** `[ccm]` `_hook_apply.sh` exit-1-on-success (both fresh wire and idempotent re-run) — cost 3 extra confirm calls; return 0 on success paths.

---

## 4. Propagation map

| Surface | Items | Consumer receives via |
|---|---|---|
| harness-bootstrap assets (hooks, skeletons, rules index) | A1, A2, A3, B3(a), M3 | plugin update → next `/super-bootstrap` re-run (drift-diff sync) |
| Skill/agent files (todo, log, commit, drain, resolve-plugins, release-init) | A2, B2, B3, C2, M1 | plugin update |
| claude-config-manager (device layer) | B1, C3, D1, D2, M4, A1/A2 companions | serve.sh / setup.sh — file as backlog rows there, own sessions pick up |
| Measurement only | C1, M2 | n/a |

## 5. Sequencing for the orchestrating gateway

1. **Phase 1 — mechanical floor** (no design risk, immediate): M1, M2, D2, M4, B2. Independent; fan out as parallel dispatches per § Dispatch.
2. **Phase 2 — gates**: A3 → A2 → A1 (A3 is pure SKILL.md, lowest risk; A2 introduces the hook-asset pattern A1 then reuses). Each is a harness edit → runs the repo's own Entry Gate + audit pass.
3. **Phase 3 — tiering + dispatch**: B1 `[ccm]`, B3 (resolve-plugins split first), C2, C3 `[ccm]`, M3, D1 `[ccm]`.
4. **Phase 4 — measure**: C1 at next harvest window; compare against § 6.

`[ccm]` items: log into claude-config-manager's backlog via its own funnel; do not edit that repo from a super-bootstrap session.

## 6. Acceptance — what "worked" looks like at the next harvest window

- Premature-commitment-before-grounding **not** the top shape for the first time in 4 windows.
- model-guard deny hits ≈ 0 (baseline 35/window) with tier correctness unchanged (spot-check dispatched agents' resolved models).
- Principles-load user re-assertion count → 0 (baseline ~15/session worst case).
- Authoring inline:dispatch ratio moving from ~13:1 toward dispatch-majority (C1 tracks the number).
- Zero regressions on the § 1 wins list (skip-dispatch fast paths still short-circuit; four lanes still zero-retry).
- audit-harness-edits findings fire pre-commit, not post-commit.
