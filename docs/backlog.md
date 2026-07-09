# Backlog

New rows route through `/super-bootstrap:log` — one funnel for classification, dedup, and ID assignment. Bugs, debt, design gaps, and unverified feature ideas all land here as rows; whether each is real or worth doing is decided at `/super-bootstrap:todo` triage on pickup, not at capture.

**Row deletion:** the resolving session — via `/super-bootstrap:commit` doc-sync, or manually on resolve. Direct `git commit` skips the sweep; clean up stale rows when noticed.

**Three categories** distinguished by ID prefix:

- **`BUG-###`** — broken behavior. Surface symptom may hide deeper cause.
- **`DEBT-###`** — working but rotting (test fixture rot, stale dep, cleanup owed).
- **`GAP-###`** — design gap or unverified capability idea, never properly specced. Forward feature ideas land here; triage decides drop / spec.

No phase prescription per category — when an item rolls into a session, the harness phase triage decides which superpowers phases run. Surface "clear fix" can become design work after evidence; pre-routing biases that judgment.

**ID high-water mark:** `BUG-014` · `DEBT-014` · `GAP-023` — last consumed ID per category. Next ID = max+1 from this line, bumped in the same write. Resolved rows are deleted but their IDs stay consumed (history = `git log --grep="<id>"`); never re-derive IDs from open rows.

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

### DEBT-014 — docs-only diffs still pay the full docsync-gate token dance

**Logged:** 2026-07-08 · **Source:** token-cost retrospective on the BUG-014 session; observed committing the DEBT-010 backlog row (pure docs, zero behavior/runtime surface)
**Problem:** committing a pure-docs diff (e.g. a backlog row) still requires the full `docsync-scan.sh` token-mint-then-commit dance — a docs-only diff has nothing behavioral to sync, so the doc-sync-scan gate is pure ceremony there.
**Area:** `plugins/super-bootstrap/skills/harness-bootstrap/assets/hooks/docsync-gate.sh` + `docsync-scan.sh` + commit door
**Prior:** exempt docs-only diffs (only `docs/**` / prose, no code/harness/behavior files) from the doc-sync-scan token requirement; nuance — the exemption must not let a behavior-narrating doc (README, manifest descriptions) drift silently, so scope tightly (e.g. `docs/backlog.md`/`docs/decisions.md` tracking-only prose) rather than blanket `docs/**`.

### DEBT-013 — no small-change lane: dispatch-per-phase overhead disproportionate on tiny diffs

**Logged:** 2026-07-08 · **Source:** token-cost retrospective on the BUG-014 session (~10-line hook-regex fix; gateway ≥200k + subagents ~460k tokens)
**Problem:** for a ~10-line fix, the pipeline still spun up a full doc-sync-scan subagent (74k tokens) plus per-commit agent dispatches, each re-reading context and reporting back. Dispatch-per-phase (CLAUDE.md § Dispatch, § Doc Sync's "dispatch the scan to a clean subagent" default) is proportionate for large work but heavy for a bounded small change with no propagation closure of its own.
**Area:** `CLAUDE.md` § Dispatch + § Doc Sync + the envelope
**Prior:** a "small-change lane" — diff under N lines touching ≤1 behavior surface inlines the doc-sync staleness check as a bounded gateway grep instead of a full-agent dispatch, and commits directly, rather than dispatching build/doc-sync/commit as separate agents; triage sizes N and the surface bound.

### DEBT-012 — commit batching: propagation closure split across session-isolation into N commits

**Logged:** 2026-07-08 · **Source:** token-cost retrospective on the BUG-014 session (~10-line hook-regex fix; gateway ≥200k + subagents ~460k tokens)
**Problem:** BUG-014's fix (asset matcher fix + verbatim propagation to this repo's git-tracked dogfood copy `.claude/hooks/docsync-gate.sh`) was one logical propagation-closure change, but session-isolation on the commit door forced it into 2 separate commits via 2 separate commit-agent dispatches (`b9f3e36` asset, `3a646fc` dogfood re-sync). The envelope/commit discipline has no "propagation-closure commit" concept bundling a source-harness edit with its verbatim installed/dogfood copy into one commit.
**Area:** super-bootstrap commit door (`plugins/super-bootstrap/skills/commit`, `plugins/super-bootstrap/agents/commit.md`) + `CLAUDE.md` § Dispatch session-isolation rule
**Prior:** when a diff includes a source harness file AND its verbatim installed/dogfood copy, consider allowing one commit instead of forcing session-isolated per-file dispatches; triage decides whether this is a defect or accepted-by-design (isolation is itself a safety property).

### GAP-023 — CLAUDE.md § Dispatch doctrine has no transcription/prose-exact exception; SDD over-dispatches implementer subagents for plan-supplied exact-content edits

**Logged:** 2026-07-08 · **Source:** token-cost retrospective after executing the todo need-me board via subagent-driven-development this session
**Problem:** when a plan pre-specifies the exact edit text and the target is markdown / no-runtime, § Dispatch's "dispatch build per phase" composed with `subagent-driven-development` still routes the edit through a full implementer-subagent round trip — the dispatch prompt re-states the content, the subagent transcribes it, and returns a report, all resident in gateway context. Measured this session: the plan wrote every edit's exact text; 6 implementer subagents acted as pure transcribers. Cost exceeds an inline edit for ~zero added safety, since the plan already carries the content verbatim.
**Area:** `CLAUDE.md` § Dispatch / § Development Workflow, composing with `superpowers:subagent-driven-development`
**Prior:** add a transcription-grade carve-out parallel to GAP-019/GAP-020's — exact old/new text pre-specified + no-runtime target → inline edit, skip subagent dispatch; judgment-grade edits (shape left to implementer) keep full dispatch.

### GAP-022 — commit-channel.sh's single-channel gate blocks SDD implementer subagents from committing; gateway must re-commit every dispatch, erasing the delegation benefit

**Logged:** 2026-07-08 · **Source:** token-cost retrospective after executing the todo need-me board via subagent-driven-development this session
**Problem:** `commit-channel.sh` (`plugins/super-bootstrap/skills/harness-bootstrap/assets/hooks/commit-channel.sh`) confines raw `git commit` to the commit agent + the main session/orchestrator — every other `agent_type` is denied with "Finish your task, report the work as built with the file list, and let the orchestrator fire /super-bootstrap:commit." This conflicts with `superpowers:subagent-driven-development`'s implementer-commits-its-own-work contract: this session, all 6 SDD implementer subagents were blocked at their commit step, and the gateway re-committed each one — so the token cost of dispatching them (edit + round-trip + report) was pure overhead over an inline edit, since the commit-delegation half of the benefit never lands. For exact-content/prose tasks this makes dispatch strictly more expensive than inline.
**Area:** `plugins/super-bootstrap/skills/harness-bootstrap/assets/hooks/commit-channel.sh` (single-channel commit gate) vs superpowers `subagent-driven-development`'s implementer-commits model — two harness layers never reconciled
**Prior:** either extend commit-channel's allowed-agent list to admit SDD implementers, or design a batch/hand-back commit path so dispatch keeps its delegation benefit; triage decides which composition is correct.

### DEBT-011 — docsync-gate.sh forces the doc-sync scan and git commit into two separate mandatory Bash calls; adds a per-commit round-trip tax plus chain-retry cost

**Logged:** 2026-07-08 · **Source:** token-cost retrospective after executing the todo need-me board via subagent-driven-development this session
**Problem:** `docsync-gate.sh`'s deny `$REMEDY` requires `docsync-scan.sh` to run "as its own Bash call, separate from the commit" — chaining scan `&&` commit in one call fails the gate. This session: ~10 commits × 2 calls, plus several retries where scan+commit were chained wrongly and got bounced.
**Area:** `plugins/super-bootstrap/skills/harness-bootstrap/assets/hooks/docsync-gate.sh` / `docsync-scan.sh` handshake
**Prior:** the split may be a hard PreToolUse constraint (the hook fires pre-execution, so a chained `scan && commit` in one Bash call has no token written yet when the gate checks) rather than an arbitrary tax — triage to confirm whether it's addressable or accepted-by-design before proposing an atomic scan+commit path.

### DEBT-010 — commit-channel.sh's word-boundary `git commit` re-check shares BUG-014's over-match class; may be acceptable-by-design (opposite safe-fail bias)

**Logged:** 2026-07-08 · **Source:** surfaced by the audit-harness-edits probe during the BUG-014 fix, flagged out-of-diff-scope
**Problem:** `commit-channel.sh:24` (`plugins/super-bootstrap/skills/harness-bootstrap/assets/hooks/commit-channel.sh`) uses a word-boundary per-line grep matcher for its in-script `git commit` re-check: `grep -Eq '(^|[^[:alnum:]_-])git[[:space:]]+([^[:space:]]+[[:space:]]+)*commit([[:space:]]|$|;|&)'` — the same over-match class BUG-014 just fixed in sibling `docsync-gate.sh` (resolved to a command-position-anchored bash `[[ =~ ]]` matcher with `[:blank:]` gaps, marker v4, commit `b9f3e36`). commit-channel over-matches: a Bash command whose text merely contains a `git commit`-shaped substring (e.g. a heredoc/quoted line writing a script that embeds "git commit") trips its single-channel deny, blocking a legitimate non-commit worker call. Triage nuance: commit-channel has the OPPOSITE risk profile from docsync-gate — its stated safe-fail design deliberately accepts over-match ("a rare over-match denies a non-commit worker call, never lets a commit through"), so this MAY be acceptable-by-design rather than a defect. docsync-gate v4's own comment documents the divergence as deliberate ("Sibling commit-channel.sh matches the same verb with the opposite bias — the divergence is deliberate, don't align them") — any fix must reconcile with that, not blindly port v4's matcher over.
**Area:** `plugins/super-bootstrap/skills/harness-bootstrap/assets/hooks/commit-channel.sh:24`
**Prior:** open triage question is whether the safe-fail bias truly makes the false-deny acceptable as-is, or whether commit-channel should adopt docsync-gate v4's command-position anchor despite the documented-deliberate divergence — triage decides, don't assume alignment is the fix.

### BUG-013 — harness-grounding.sh PreToolUse additionalContext lacks permissionDecision; may be dead or expose subagent Write-corruption

**Logged:** 2026-07-08 · **Source:** surfaced during BUG-012 4-cell live probe investigation
**Problem:** `harness-grounding.sh` (FROZEN v1, `.claude/hooks/harness-grounding.sh`) emits PreToolUse additionalContext with no `permissionDecision` field. Per Tier-1 lore `claude-shape/hook-feedback-channels.md`, PreToolUse additionalContext is valid only paired with `permissionDecision: "allow"` or `"defer"` — unpaired, the injection may be silently dropped (the harness-edit grounding nudge never reaches Claude at all), OR if it does inject, it exposes background-dispatched subagents that create new `.claude/{rules,skills,agents}/` or `CLAUDE.md` files to the same platform Write-corruption BUG-012 fixed for the plugins path (background subagent + PreToolUse additionalContext injection → Write returns "[Tool result missing due to internal error]"). Not directly probed: the BUG-012 4-cell live probe confirmed the device-global "New harness file" hook as injector for `plugins/*/skills/**` new-file creation (cell A failed, cell D on a plain path succeeded); this repo-owned analog (case arms at `harness-grounding.sh:20-30`, firing on `.claude/` + `CLAUDE.md` paths) is inferred exposure, not observed.
**Area:** `.claude/hooks/harness-grounding.sh` (PreToolUse Edit|Write), FROZEN v1
**Prior:** verify whether additionalContext-without-permissionDecision reaches Claude at all (if not, the grounding nudge is dead — a separate latent bug); if it does inject, gate on `agent_type` to skip subagent context (per `claude-shape/hook-agent-type.md`) or align with BUG-012's foreground-dispatch rule. FROZEN v1 hook — any change needs deliberate handling.

### GAP-021 — ChewLingo delta artifacts verdicted "upstream as root" never assigned a wave; remain consumer-only

**Logged:** 2026-07-08 · **Source:** GAP-017 program close-out — verdict rows with no wave assignment, carried here before the program map's deletion
**Problem:** Three GAP-017 verdicts marked ChewLingo artifacts as portable root capability but no wave shipped them: `journey-simulation` (portable mechanism, near-zero contamination — upstream whole); spec/plan/implement/review partial salvage (Surface-on-Gap refusal, design gate, evidence block → fold into superpowers route wrappers, not a parallel chain); model-tiering pre/posttool hooks (doctrine lives in served work-discipline lore; hooks are enforcement — upstream as root hook assets). They are not dups (root has no counterpart), so adopt mode correctly left them as ChewLingo delta — but the portable value stays single-consumer until upstreamed.
**Area:** `plugins/super-bootstrap/skills/` (+ `harness-bootstrap` hook assets for model-tiering); source bodies live in `V:\ChewLingo` `.claude/skills/{journey-simulation,spec,plan,implement,review}` + its `.claude/hooks`
**Prior:** same distill recipe as GAP-017 waves (direct port of production-proven text, consumer-safe rewrite, one cold audit per batch); triage decides ship-order or drop per artifact.

### GAP-020 — SDD's mandatory fix→re-review loop runs regardless of fix grade; transcription-grade fixes earn no new findings

**Logged:** 2026-07-08 · **Source:** GAP-017 scale-module session, user challenged re-review ceremony mid-wave
**Problem:** `superpowers:subagent-driven-development`'s fix→re-review loop dispatches a full re-review after every fix, independent of fix grade. Measured across the GAP-017 todo-distill and scale-module waves: 5 re-review dispatches, 0 new findings — every one a clean confirmation. When the fix dispatch already carries exact old/new text (transcription-grade fix), a re-review by the same reviewer is near-deterministic approval; the step earns itself only for judgment-grade fixes (fix shape left to the implementer).
**Area:** CLAUDE.md § Development Workflow / SDD consumption (upstream skill is superpowers-owned; sb-side fix is a documented carve-out in sb's own routing prose)
**Prior:** same pattern as GAP-019's writing-plans carve-out — transcription-grade fixes (exact old/new text supplied) → dispatcher verifies by reading the diff, no re-review dispatch; judgment-grade fixes (shape left to implementer) → full re-review stays.

### GAP-019 — writing-plans no-placeholder contract duplicates full file bodies even when the authoring session also executes

**Logged:** 2026-07-08 · **Source:** GAP-017 triage-distill session, meta-harness pain surfaced mid-session
**Problem:** writing-plans' no-placeholder contract (full file bodies embedded in the plan) assumes a cold executor. When the authoring session also executes, the embed is pure duplication and propagates typos — two observed instances (todo distill: 4 typos propagated; triage distill: ~350 lines duplicated).
**Area:** CLAUDE.md § Development Workflow / writing-plans consumption (upstream skill is superpowers-owned; sb-side fix is a documented carve-out in sb's own routing prose)
**Prior:** same-session carve-out — plans reference draft bodies by section instead of embedding full text when the authoring session also executes; already applied ad hoc in `docs/superpowers/specs/harness-rebase.md` § Distill route sizing for GAP-017's remaining waves (temporal, deleted on merge) — this generalizes the fix into the permanent routing prose.

### GAP-018 — cluster routing sizes by work type only; no shape-knowledge valve for spec-driven repeat work

**Logged:** 2026-07-08 · **Source:** GAP-017 triage-distill session, meta-harness pain surfaced mid-session
**Problem:** Envelope's cluster routing (CLAUDE.md § Cluster routing) sizes depth by work TYPE only — new capability → cluster 2 whole (full brainstorming + full plan), regardless of how many same-shape artifacts already preceded it. The 5th same-shape distill artifact in GAP-017 was still forced through full ceremony; meta:ship ratio ran ~2:1 by lines. Shipped Execution tag (`inline|phased|full`) sizes backlog-card pickups but nothing sizes spec-driven repeat work at the route line.
**Area:** CLAUDE.md § Cluster routing / envelope
**Prior:** generalize pipeline sizing to the route line itself (a known-shape route may skip discovery phases) — beyond the per-program patch already in `docs/superpowers/specs/harness-rebase.md` § Distill route sizing (temporal, GAP-017-scoped, deleted on merge).

### GAP-003 — harness-collab-optimization effect unmeasured; criteria reshaped by entry-discipline

**Logged:** 2026-07-06 (criteria reshaped 2026-07-08, entry-discipline session) · **Source:** harness-collab spec § 6 C1 (full text @ c1e2820) + entry-discipline spec W4
**Problem:** next harvest window measures: (a) off-card / off-lane leakage — change-work entered without a backlog card (entry-discipline E1/E2 regression); (b) cluster-1/3 omission shapes — bug fixed without root-cause entry, multi-step work without plan artifact — unharvestable under current ccm harvest taxonomy, companion `[ccm]` taxonomy item routes via `/contribute`; (c) route-line theater — E3 regression: confirm-stops firing where SSOT already resolved (07-04 baseline: "MCQ 給自由假象，實質只是確認"); (d) zero regressions on preserved wins (todo skip-dispatch fast path, four zero-retry dispatch lanes, audit gate); (e) principles-load user re-assertions →0 (baseline ~15/session worst case); (f) premature-commitment top-pain exit (still top pain 3 consecutive windows as of 07-08 — unmeasured post-entry-discipline). RETIRED: dispatch-majority ratio target — dispatch value is two-sided (context-hygiene + model-strength routing); a ratio target manufactures reflexive routing. Raw inline:dispatch ratio stays descriptive-only (mining baseline ~13:1, 35 sessions — not a harvested figure).
**Area:** next harness-pain harvest window
**Prior:** pure measurement pass, no code change. docsync-gate v3 value + one-shot-token cost (token consumed by a failing commit → forced re-scan) ride this window — v1-era defect evidence closed at GAP-014 triage 2026-07-08 (facets 1+3 verified fixed in v3 in-file; facet 2 structurally present, zero v3 firings measured, adopters pending re-sync).
**Measured (2026-07-08, ccm three-probe downstream timing audit — evidence: claude-config-manager `docs/harness-pain/reports/2026-07-08.md` + GAP-063 closing commits `d05742e`/`067fac4`):** (1) model-guard deny hits: only 2 real runtime pin-denials corpus-wide post-enforcement, both complied+succeeded next call — EXCLUDE the 4 spotify-radio denies on `super-bootstrap:todo` dispatches (`0696f836`/`15a02eb4`/`df6637d0`/`58108cd9`): stale-copy artifacts of a 06-26 agent-model hook predating ccm's BUG-007 namespaced-pin fix (07-01; copy refreshed 07-07 23:47), NOT guard noise and NOT a todo-template defect (todo's `model: sonnet` pin correct in every released version). (2) docsync-gate value since v3: zero organic catches AND zero v3 firings downstream — all 4 adopters still carry byte-identical v1 hooks (every sync predates the first fix; v3 deny text zero corpus hits); measurement blocked on adopter re-sync, which commit-skill's FROZEN drift check triggers on each adopter's next `/super-bootstrap:commit`. (3) unmeasured by this audit: premature-commitment top-pain, principles-load re-assertions, inline:dispatch ratio — DEBT-028 family did recur in-window (ChewLingo ×2 facets).
