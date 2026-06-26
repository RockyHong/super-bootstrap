---
name: super-bootstrap
description: "Public entry for the super-bootstrap pipeline — thin orchestrator. Git-inits if absent, runs two-axis detection, then dispatches /super-bootstrap:harness-bootstrap to install or sync the generic runway (always). On greenfield it seeds two GAP cards via /super-bootstrap:log and stops at the resolve gate; on substantive seed docs it runs gated tier-2 tech curation (resolve-plugins + tech rules + release-init). Zero product prework. Solo dev workflow."
tags: [bootstrap, orchestrator, detect, gate, curation, meta]
---

# Super Bootstrap — Public Entry, Thin Orchestrator

The single command users invoke. Orchestrates — detect, route, dispatch, integrate — and owns no install procedure itself: scaffolding lives in the generic runway, [`/super-bootstrap:harness-bootstrap`](../harness-bootstrap/SKILL.md). The entry writes no product content and asks no product questions. `overview.md` / `techstack.md` / `backlog.md` are scaffolded by the runway; their product content fills later at GAP-card pickup.

## Orchestration spine

1. **Git-init** if absent (correctness move).
2. **Detect** — Axis A (harness present?) + Axis B (seed docs substantive?).
3. **Dispatch the runway** — `/super-bootstrap:harness-bootstrap` (generic, always).
4. **Greenfield branch** (Axis B not substantive) — seed 2 GAP cards via `/super-bootstrap:log`, stop at the resolve gate.
5. **Substantive branch** (Axis B substantive) — gated tier-2 tech curation.
6. **Disclose** — one post-hoc heads-up line.

## Git-init (correctness move)

If the repo is not a git repo (`git rev-parse --git-dir` fails), run `git init` first — so the runway's writes land on a tracked tree and the promised post-hoc `git diff` exists. Silent move: one log line, no gate.

## Detect — two axes

Two independent axes answering different questions, driving different branches.

**Axis A — harness artifacts present?** Check `CLAUDE.md` + `.claude/rules/` + `docs/superpowers/`. Absent → the runway installs fresh. Present → the runway syncs (idempotent drift). Either way **the runway always runs** — Axis A only colors install-vs-sync, it never gates the dispatch.

**Axis B — seed docs substantive?** Check whether `docs/overview.md` + `docs/techstack.md` carry content **filled beyond the skeleton placeholders** — substantive product content, not mere file presence. The runway writes these as empty skeletons on greenfield, so a file-exists test would misread an empty skeleton as "documented," skip GAP-card seeding, and loop. Substantive = the product sections (`overview.md` Problem / User / Current State, `techstack.md` Runtime / Framework) carry real content past the placeholder text — mirror the "≥3 substantive lines" notion (lines that aren't headings, blank, or placeholder).

Axis B is the **product-content** axis: it drives GAP-card seeding + the tier-2 gate, and never decides whether the harness syncs — that is Axis A. A documented-but-stale repo still gets runway sync.

## Dispatch the runway (always)

After git-init + detect, invoke `/super-bootstrap:harness-bootstrap` via the Skill tool. The runway installs (fresh, Axis A absent) or syncs (drift, Axis A present) the generic harness — CLAUDE.md, skeleton docs, path-scoped rules, core plugin pins — and returns "runway installed/synced + committed." Then branch on Axis B.

## Greenfield branch — seed GAP cards + gate (Axis B not substantive)

The runway returned with empty product skeletons. Seed two GAP cards through the capture funnel, then stop at the resolve gate — there is nothing to curate until the product is resolved.

**Idempotency guard (run first).** Read `docs/backlog.md`. If GAP cards for the overview and techstack skeletons are already present (match on the card summary text — IDs are minted by `/log`), skip seeding and log "GAP cards already seeded." Re-run stays safe.

**Seed via [`/super-bootstrap:log`](../log/SKILL.md)** — one invocation, both observations batched (never hand-write backlog rows):

- `pin down product overview — docs/overview.md is an unfilled skeleton`
- `decide techstack — docs/techstack.md is an unfilled skeleton; blocked on the overview card`

Each classifies GAP. The funnel mints IDs, dedups, and fills Source (`/super-bootstrap bootstrap`) and Area (`docs/overview.md` / `docs/techstack.md`) from the observation text. Carry `Prior:` as a **hint, not a locked route**:

```
Prior: no source code → brainstorm; source present + undocumented → distill-repo-essence
```

This honors the backlog's no-phase-prescription rule — triage decides the method at pickup.

**Resolve gate — stop here.** After seeding, surface the dogfood handoff and stop. Nothing to curate yet:

```
Generic harness installed. Two GAP cards seeded (overview, techstack).
Resolve them via /super-bootstrap:todo → brainstorm (no code) / distill-repo-essence (code present).
Once overview.md + techstack.md are filled, re-run /super-bootstrap for tech curation.
```

## Substantive branch — gated tier-2 tech curation (Axis B substantive)

The runway returned and Axis B is substantive (a just-resolved greenfield, or an already-documented updater). Seed docs carry real stack signal, so tier-2 curation can read it. Run in order:

1. **`Skill(resolve-plugins)`** — [`/super-bootstrap:resolve-plugins`](../resolve-plugins/SKILL.md) curates stack-matched skill / MCP / hook picks. It reads stack from `docs/techstack.md` and external-tools from `docs/overview.md`'s `<!-- harness-meta -->` block (the relocated external-tools signal). No Q&A — the signal is already in the docs.
2. **`/super-bootstrap:release-init`** — offer once as an optional step to generate a project-level `/release` skill.

**Rules-seeding stays runway-owned.** Path-scoped rule seeding (frontend / MV3 / migrations / tests) fires at runway-time in [`/super-bootstrap:harness-bootstrap`](../harness-bootstrap/SKILL.md) Phase 1 — every current signal is manifest- or filesystem-derivable, so one home, no double-seed. Tier-2 adds no rule seeding. A future signal derivable only from substantive `techstack.md` prose (not the manifest) would seed here instead.

The gate between the runway and tier-2 is Axis B: substantive proceeds here; not-substantive stops at the greenfield branch above. Tier-2 runs only when there is a resolved stack to curate against.

## Disclosure (post-hoc)

Invoking the command is consent — there is no upfront proceed gate. After the runway (and tier-2 if it ran), the done-summary carries one heads-up line pointing the user at the diff:

```
Wrote/changed: CLAUDE.md, .claude/settings.json, docs/ skeletons{, rules}. Review with `git diff` (or `git diff HEAD~N`).
```

Forward navigation: tells the user where to look. Covers users who carry their own harness taste — reconciliation is `git diff`, not a gate.
