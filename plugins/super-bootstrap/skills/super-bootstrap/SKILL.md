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

> [GAP-card seeding via `/super-bootstrap:log` — Task 5]
> [Resolve gate + dogfood handoff — Task 4/5]

## Substantive branch — gated tier-2 tech curation (Axis B substantive)

> [Gate + tier-2 curation (resolve-plugins + tech rules + release-init) — Task 4]

## Disclosure (post-hoc)

> [Post-hoc disclosure line — Task 6]
