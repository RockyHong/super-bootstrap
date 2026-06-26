---
name: super-bootstrap
description: "Public entry for the super-bootstrap pipeline — thin orchestrator. Git-inits if absent, then dispatches /super-bootstrap:harness-bootstrap to install or sync the generic runway (always; the runway self-detects fresh-vs-sync). Checks whether seed docs are substantive: greenfield seeds two GAP cards via /super-bootstrap:log and stops at the resolve gate; substantive seed docs run gated tier-2 tech curation (resolve-plugins + release-init). Zero product prework. Solo dev workflow."
tags: [bootstrap, orchestrator, detect, gate, curation, meta]
---

# Super Bootstrap — Public Entry, Thin Orchestrator

The single command users invoke. Orchestrates — detect, route, dispatch, integrate — and owns no install procedure itself: scaffolding lives in the generic runway, [`/super-bootstrap:harness-bootstrap`](../harness-bootstrap/SKILL.md). The entry writes no product content and asks no product questions. `overview.md` / `techstack.md` / `backlog.md` are scaffolded by the runway; their product content fills later at GAP-card pickup.

## Orchestration spine

1. **Git-init** if absent (correctness move).
2. **Dispatch the runway** — `/super-bootstrap:harness-bootstrap` (generic, always; it self-detects fresh-vs-sync).
3. **Detect** — are the seed docs substantive?
4. **Greenfield branch** (not substantive) — seed 2 GAP cards via `/super-bootstrap:log`, stop at the resolve gate.
5. **Substantive branch** — gated tier-2 tech curation.
6. **Disclose** — one post-hoc heads-up line (substantive branch; the greenfield branch's resolve gate is its disclosure).

## Git-init (correctness move)

If the repo is not a git repo (`git rev-parse --git-dir` fails), run `git init` first. One log line, no gate.

## Dispatch the runway (always)

Invoke `/super-bootstrap:harness-bootstrap` via the Skill tool. The runway installs fresh or syncs drift — its own detection — scaffolding CLAUDE.md, skeleton docs, path-scoped rules, core plugin pins, and returns "runway installed/synced + committed." The entry dispatches it unconditionally, so a documented-but-stale repo still gets runway sync. Then check whether the seed docs are substantive.

## Detect — seed docs substantive?

Check whether `docs/overview.md` + `docs/techstack.md` carry content **filled beyond the skeleton placeholders** — substantive product content, not mere file presence (the runway writes these as empty skeletons on greenfield; a file-exists test misreads an empty skeleton as documented). Substantive = the product sections (`overview.md` Problem / User / Current State, `techstack.md` Runtime / Framework) carry real content past the placeholder text — mirror the "≥3 substantive lines" notion (lines that aren't headings, blank, or placeholder).

This is the only branch the entry makes: not-substantive → greenfield (seed GAP cards + gate); substantive → tier-2 curation.

## Greenfield branch — seed GAP cards + gate (not substantive)

The runway returned with empty product skeletons. Seed two GAP cards through the capture funnel, then stop at the resolve gate — there is nothing to curate until the product is resolved.

**Idempotency guard (run first).** Read `docs/backlog.md`. If GAP cards for the overview and techstack skeletons are already present (match on the card summary text — IDs are minted by `/log`), skip seeding and log "GAP cards already seeded." Re-run stays safe.

**Seed via [`/super-bootstrap:log`](../log/SKILL.md)** — one invocation, both observations batched, passing Source context `/super-bootstrap bootstrap` in the dispatch:

- `pin down product overview — docs/overview.md is an unfilled skeleton; resolve at pickup via brainstorm (no source code) or distill-repo-essence (code present, undocumented)`
- `decide techstack — docs/techstack.md lacks product + architecture context (manifest facts auto-filled where a manifest exists); blocked on the overview card`

Each classifies GAP; the funnel mints IDs, dedups, and fills Area (`docs/overview.md` / `docs/techstack.md`). The pickup-routing hint rides in the observation text, not a `Prior:` route — triage owns the method.

**Resolve gate — stop here.** After seeding, surface the dogfood handoff and stop. Nothing to curate yet:

```
Generic harness installed. Two GAP cards seeded (overview, techstack).
Resolve them via /super-bootstrap:todo → brainstorm (no code) / distill-repo-essence (code present).
Once overview.md + techstack.md are filled, re-run /super-bootstrap for tech curation.
```

## Substantive branch — gated tier-2 tech curation (substantive)

The runway returned and the seed docs are substantive (a just-resolved greenfield, or an already-documented updater). Seed docs carry real stack signal, so tier-2 curation can read it. Run in order:

1. **`Skill(resolve-plugins)`** — [`/super-bootstrap:resolve-plugins`](../resolve-plugins/SKILL.md) curates stack-matched skill / MCP / hook picks. It reads stack from `docs/techstack.md` and external-tools from `docs/overview.md`'s `<!-- harness-meta -->` block (the relocated external-tools signal). No Q&A — the signal is already in the docs.
2. **`/super-bootstrap:release-init`** — offer once as an optional step to generate a project-level `/release` skill.

**Rules-seeding stays runway-owned.** Path-scoped rule seeding (frontend / MV3 / migrations / tests) fires at runway-time in [`/super-bootstrap:harness-bootstrap`](../harness-bootstrap/SKILL.md) Phase 1. Tier-2 adds no rule seeding — one home per signal, no double-seed.

The gate between the runway and tier-2 is the substantive check: substantive proceeds here; not-substantive stops at the greenfield branch above. Tier-2 runs only when there is a resolved stack to curate against.

## Disclosure (post-hoc)

Invoking the command is consent — there is no upfront proceed gate. After the runway (and tier-2 if it ran), the done-summary carries one heads-up line pointing the user at the diff:

```
{Initialized git repo. }Wrote/changed: CLAUDE.md, .claude/settings.json, docs/ skeletons{, rules}. Review with `git diff` (or `git diff HEAD~N`).
```

Reconciliation is `git diff`, not a gate.
