# Harness Rebase — ChewLingo onto super-bootstrap Root

> Temporal work order (card: GAP-017). Grounded 2026-07-08 on three parallel read-only probes: ChewLingo spine map, sb root map, shared-artifact diff. Delete after the program merges.

## Goal

super-bootstrap is the one harness root. ChewLingo (mother repo the harness originally forked from) rebases onto it: its universal evolution upstreams into sb first, then ChewLingo swaps its forked base for the sb-served root and keeps only project delta. End of bidirectional contribution.

## Verdict (settled)

Unify is viable; never-merge is off the table. Evidence: every shared artifact shows common ancestry (same section skeletons; drain assets near line-for-line parallel pseudocode); divergence is complementary — ChewLingo evolved the judgment layer, sb evolved the mechanism-hardening layer; sb already owns the generalization machinery (harness-bootstrap drift-sync, FROZEN versioned assets, consumer-contract framing, stack facts sourced from consumer `docs/techstack.md`).

## Locked spine decisions (2026-07-08, user-confirmed)

1. **Work-SSOT** — root = `docs/backlog.md` core. ChewLingo's tracker constellation (state machine, fact fields, venue-map, test-queue, parked bucket) becomes an opt-in **scale module** installed by harness-bootstrap when a repo earns it. Convergence to exploit: ChewLingo `closed-forks.md` ≈ sb `docs/decisions.md` (same admission test) — one doc, sb's name wins.
2. **Envelope** — sb's superpowers-routed envelope is the spine. Upstream from ChewLingo as root capabilities: **pipeline sizing** (Fix-shape × centrality collapses PLAN/REVIEW), **Execution tag** (`inline|phased(skip:…)|full`), triage as read-only verdict phase. ALIGN folds into doc-sync; test-queue joins the scale module.
3. **Dispatch architecture** — artifacts that read/write doc state (log, todo, commit) ship as agent-dispatch (thin skill shell → subagent); pure-git merge stays inline. ChewLingo's `commit-channel-pretool.sh` (raw `git commit` confined by `agent_type`) upstreams into the root hook set — it presupposes agent-dispatch.
4. **Update channel** — no new engine. Extend the existing FROZEN-asset materialization pattern (today: hooks) to skills/agents: cloud-needing consumers get **committed copies** drift-rechecked on harness-bootstrap re-run; local-only repos stay plugin-runtime. Rationale: cloud sessions are clone-provisioned; marketplace install in cloud has three known failure modes (`~/.claude/guidelines/claude-shape/cloud-run-surface.md`).
5. **Monorepo tier** — harness-bootstrap Phase 1 detects workspace manifests (pnpm-workspace/turbo/nx/cargo) → monorepo tier: rule-signal globs fan out per package (`apps/*/src/components` etc.), cross-package build pre-flight lands in the CLAUDE.md skeleton, techstack.md gains a per-package table. **No nested-CLAUDE.md capability needed** — ChewLingo runs a mid-size monorepo with zero nested CLAUDE.md; path-scoped rules carry the whole boundary.

## Migration door (end state)

ChewLingo runs `/super-bootstrap` (plugin currently present-but-disabled in its settings — flip on at migration time) and the sync engine performs the swap. Constraints:

- **Not a blind overlay.** harness-bootstrap's per-artifact rule governs: missing→write; exists+matches→skip; exists+drifted→**diff+approve**+write; project-owned→never touch. First migration run is supervised section-by-section.
- **New capability required: adopt mode.** Deleting a consumer's superseded fork copies (its own `commit/merge/log/todo/drain` skills + agents replaced by root) is not a behavior harness-bootstrap has — build it as part of wave 2/3, with an explicit superseded-artifact map and per-deletion confirm.
- **Prerequisite:** waves 1–3 below complete. Running `/super-bootstrap` against ChewLingo before its judgment tech has landed in root would clobber the very evolution being upstreamed.

## Per-artifact verdicts

| Artifact | Verdict | Distill recipe |
|---|---|---|
| merge | **done (Wave 1)** | Landed: parameterized conflict-handoff agent name. Anti-pattern § NOT ported — closed fork (pressure-tested: sb wording already binds; see `docs/decisions.md`) |
| commit | **done (Wave 2)** | Landed: agent-dispatch shell + commit agent (doc-sync state machine, push facts, cycle facts returned; gateway lanes for resolution/push/handoff); commit-channel upstreamed as FROZEN A6. Rename sub-check NOT ported — closed fork (pressure-tested 5/5 control; see docs/decisions.md) |
| log | **done (Wave 1)** | Landed: row-shape gate (no standing-watch rows) + closed-fork bounce against decisions.md, both GREEN-tested 5/5. Claim-block write-once was already in the backlog header — no edit. Parked bucket stays deferred to the Wave 2 scale module |
| todo | **done (Wave 2)** | Landed: harness intent + Deliberate/Apply lane, RED-gated (control leak 5/5); pre-filter lives in shared classify-actionable.md — drain excludes Harness via its Cloud gate (harness-never-drains). Consumer-safe routing (git-log + rules grounding wording; no device-only skill names). Work-table NOT ported — closed fork (5/5 control); macro picker NOT ported — closed fork (footer legend + macro header already cover); both in docs/decisions.md |
| drain | **done (Wave 3)** | Landed: venue-keyed admission (`eligibility.md` file-presence branch, Cloud-gate fallback), inline/wave-of-one carve-out, eng/doc polymorphic lanes + pre-plan confirm gate (`phase-loop.md`), gateway merge-probe parameterized from consumer techstack (`merge-probe.md`, new). sb mechanism layer kept whole. Cold-audited (3 major/2 minor/3 nit, all applied) |
| check-docs-consistency | **done (Wave 1)** | Promoted into the plugin; the four work-discipline guideline references distilled into skill-local `assets/` (self-contained, grep-verified). Dogfood copy deleted — residual: claude-config-manager still serves its own copy; retire/redirect it upstream via `/contribute` |
| triage + triage-report (CL-only) | **done (Wave 2)** | Landed: thin verdict shells + typed agents (Opus investigator / Sonnet disposition judge), verdict home `docs/superpowers/triage/{ID}-scope\|notes.md`, classify-actionable `triaged` stage + `Implement` verb, drain/todo stage closure. RED-gated: read-only floor shipped (controls 2/5 violated; precedence line added after first GREEN 2/5 fail); echo-test, fork-spotting reinforcement, dismiss burden-of-proof NOT ported — closed forks (controls clean; docs/decisions.md). Probe specifics → consumer `docs/techstack.md § Probes` (absent → static read only) |
| spec/plan/implement/review (CL) | partial upstream | Surface-on-Gap refusal, design gate, evidence block salvage into superpowers route wrappers; bodies otherwise superseded by envelope decision — do not ship a parallel chain |
| journey-simulation (CL) | upstream as root | Portable mechanism, near-zero contamination |
| venue-map, capture-routing, pickup-grounding, findings-logging, triage-routing, worktree-boundary (CL rules) | **done (Wave 2)** | Landed as the scale module (harness-bootstrap §2a-scale, opt-in earn-gated): parked + test-queue containers, venue-map rule skeleton, backlog fact fields carrying the capture-routing pointer; log agent parked-aware; classify-actionable §d test-queue source. RED all-clean (S1 5/5, S2–S5 2/2): capture-routing + pickup-grounding NOT shipped as rule files (container header / root triage lane carry them); triage-routing, findings-logging, worktree-boundary closed as superseded — 5 closed forks in docs/decisions.md. CL's stored `State:` machine deliberately NOT ported (sb file-presence derivation won, per shipped triage doctrine) |
| model-tiering hooks (CL agent/workflow pre/posttool) | upstream as root hook assets | Doctrine lives in served work-discipline lore; hooks are enforcement |
| test-all, frontend-soc-scan, firestore-schema, ui-primitives, mobile/playwright-mcp, ai-layer, prompt-engineering, doc-terminology, web-expo-stub, lib-purity (CL) | consumer delta — stay | Product/stack knowledge |
| harness-bootstrap, resolve-plugins, release-init, help, super-bootstrap, entry-nudge/docsync/harness-grounding hooks (sb) | stay root | Bootstrap machinery |

## Wave plan

1. **Wave 1 — cheap wins**: merge distill; check-docs-consistency promote; log distill. — **COMPLETE** (per-artifact outcomes in the verdict table above). Live edge = Wave 2.
2. **Wave 2**: ~~commit~~ (done), ~~todo~~ (done), ~~triage(+report)~~ (done), ~~scale module~~ (done), ~~monorepo tier~~ (done), ~~adopt mode~~ (done). — **COMPLETE**
3. **Wave 3**: ~~drain distill~~ (done — venue admission w/ Cloud-gate fallback, inline/wave-of-one carve-out, eng/doc lanes, pre-plan confirm gate, merge-probe asset). — **COMPLETE**. Live edge = Wave 4 (migration run).

**Distill route sizing (binds remaining waves).** The distill shape is known (5 precedents: merge, log, commit, todo, triage) — remaining artifacts route **cluster 3** (`writing-plans` direct from this spec's verdict-table recipe + locked spine decisions; no brainstorming pass). Plans reference draft bodies by section, never embed full file text when the authoring session also executes (embed propagates typos and doubles the meta:ship ratio — two observed instances). Probe budget: 5/5 on the headline discipline line, 1–2 spot checks per secondary line. Audit scope: new files + directly-edited shared surfaces.
4. **Rebase run**: `/super-bootstrap` against ChewLingo (materialized mode), supervised diff+approve, adopt-mode deletions, CLAUDE.md rewritten from skeleton + delta sections.
5. **Δ audit + verify**: `audit-harness-edits` on both repos; every remaining ChewLingo artifact must name the project knowledge that keeps it out of root; wet run one full card cycle in each repo.

Each upstreamed artifact goes through the normal sb pipeline (card → route → superpowers phase triage) — this spec is the program map, not a bypass.

## Facts a pickup session needs

- ChewLingo repo lives at `V:\ChewLingo` (not under `D:\Git`). Schema-grain source (rule bodies, tracker fields, state names) is read fresh from there per wave — the verdict table carries routing, not schemas.
- sb plugin v2.21.0 released + installed locally (todo distill live; commit dispatch flow wet-verified). triage(+report) distill is committed on main but unreleased — consumers and this repo's runtime see the new skills only after the next `/release` + plugin update; that release also folds the plugin.json `description` update (doesn't yet list triage/triage-report) and deletes the triage-distill temporal spec+plan. First real `/super-bootstrap:triage` run post-release is the wet verify. sb's own dogfood runway stamp is stale (2.17.0) — its next `/super-bootstrap` run fires `version_stale`.
- `.served` markers = claude-config-manager work-discipline channel, orthogonal to this program — never conflate the two serve channels.
- sb backlog GAP-003 already cites ChewLingo as measured downstream adopter.
- Shipped skeleton self-containment rule: injected/planted text may reference only surfaces harness-bootstrap itself stamps — never device-only skills. Binds every upstreamed artifact.
- ChewLingo settings has `super-bootstrap` + `superpowers` plugins present but disabled.
- Full probe evidence (three reports: ChewLingo spine, sb root, shared-artifact diff) lives in the 2026-07-08 session transcript; the load-bearing conclusions are all restated here — do not block on transcript access.
