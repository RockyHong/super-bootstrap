---
name: setup
description: "Public entry for the super-bootstrap pipeline — thin orchestrator. Git-inits if absent, then dispatches /super-bootstrap:harness-bootstrap to install or sync the generic runway (always; the runway self-detects fresh-vs-sync). Checks whether seed docs are substantive: greenfield seeds three GAP cards (overview, techstack, tech-curation) from a pinned asset and stops at the resolve gate; substantive seed docs run gated tier-2 tech curation (resolve-plugins + release-init). Zero product prework. Solo dev workflow."
tags: [bootstrap, orchestrator, detect, gate, curation, meta]
---

# Super Bootstrap — Public Entry, Thin Orchestrator

The single command users invoke. Orchestrates — detect, route, dispatch, integrate — and owns no install procedure itself: scaffolding lives in the generic runway, [`/super-bootstrap:harness-bootstrap`](../harness-bootstrap/SKILL.md). The entry writes no product content and asks no product questions. `overview.md` / `techstack.md` are scaffolded by the runway; their product content fills later at GAP-card pickup.

## Orchestration spine

1. **Git-init** if absent (correctness move).
2. **Dispatch the runway** — `/super-bootstrap:harness-bootstrap` (generic, always; it self-detects fresh-vs-sync).
3. **Detect** — are the seed docs substantive?
4. **Greenfield branch** (not substantive) — seed 3 GAP cards from the pinned seed-card asset, stop at the resolve gate.
5. **Substantive branch** — gated tier-2 tech curation.
6. **Disclose** — one post-hoc heads-up line (substantive branch; the greenfield branch's resolve gate is its disclosure).

## Git-init (correctness move)

If the repo is not a git repo (`git rev-parse --git-dir` fails), run `git init` first. One log line, no gate.

## Dispatch the runway (always)

Invoke `/super-bootstrap:harness-bootstrap` via the Skill tool. The runway installs fresh or syncs drift — its own detection — scaffolding CLAUDE.md, AGENTS.md, CODING_STANDARDS.md, skeleton docs, path-scoped rules, the core plugin pin, and returns "runway installed/synced + committed." The entry dispatches it unconditionally, so a documented-but-stale repo still gets runway sync. Then check whether the seed docs are substantive.

## Detect — seed docs substantive?

Check whether `docs/overview.md` + `docs/techstack.md` carry content **filled beyond the skeleton placeholders** — substantive product content, not mere file presence (the runway writes these as empty skeletons on greenfield; a file-exists test misreads an empty skeleton as documented). Substantive = the product sections (`overview.md` Problem / User / Current State, `techstack.md` Runtime / Framework) carry real content past the placeholder text — mirror the "≥3 substantive lines" notion (lines that aren't headings, blank, or placeholder).

This is the only branch the entry makes: not-substantive → greenfield (seed GAP cards + gate); substantive → tier-2 curation.

## Greenfield branch — seed GAP cards + gate (not substantive)

The runway returned with empty product skeletons. Seed three GAP cards from the pinned bodies in [`assets/seed-cards.md`](assets/seed-cards.md), then stop at the resolve gate — there is nothing to curate until the product is resolved.

**Idempotency guard (run first).** Check `docs/work/` for card files (`GAP-###.md`) whose H1 summary (the text after `{ID} — `) matches one of the asset's three fixed summaries. A card seeded before the asset existed carries a model-written H1 — it counts as a match when its `**Source:**` names a `/super-bootstrap… bootstrap` seed run and its `**Area:**` names the same doc set as an asset card (`docs/overview.md` alone → overview; `docs/techstack.md` alone → techstack; both → tech-curation). Card present → skip that card; all three present → log "GAP cards already seeded." Re-run stays safe.

**Seed by hand-copy** — the sanctioned transcription path of [`/super-bootstrap:log`](../log/SKILL.md) (hand-copying `docs/work/TEMPLATE.md` with the high-water bump is the same door): write each missing fenced body verbatim as `docs/work/{ID}.md`, filling only `{ID}` and `{date}`. IDs = the next GAP IDs from `docs/work/README.md`'s high-water line, in the asset's order, with the line bumped in the same write. No re-phrasing, no Mover / dedup gates — the bodies are fixed; the pickup-routing hint rides in each `Problem:` line, not a `Prior:` route — triage owns the method.

**Resolve gate — stop here.** After seeding, surface the dogfood handoff and stop. Nothing to curate yet:

```
Generic harness installed. Three GAP cards seeded (overview, techstack, tech-curation).
Resolve overview + techstack via /super-bootstrap:todo — settle the framing with the user (no code), or reverse-engineer it from the code (code present).
Once both are filled, re-run /super-bootstrap:setup for tech curation — the tech-curation card tracks that step.
```

## Substantive branch — gated tier-2 tech curation (substantive)

The runway returned and the seed docs are substantive (a just-resolved greenfield, or an already-documented updater). Seed docs carry real stack signal, so tier-2 curation can read it. Run in order:

1. **`Skill(resolve-plugins)`** — [`/super-bootstrap:resolve-plugins`](../resolve-plugins/SKILL.md) curates stack-matched skill / MCP / hook picks. It reads stack from `docs/techstack.md` and external-tools from `docs/overview.md`'s `<!-- harness-meta -->` block (the relocated external-tools signal). No Q&A — the signal is already in the docs.
2. **`/super-bootstrap:release-init`** — offer once as an optional step to generate a project-level `/release` skill.
3. **Clear the `tech-curation` seed card** — if a card file in `docs/work/` carries the greenfield `tech-curation` GAP card (match using the greenfield idempotency guard's criteria above — the fixed H1 summary from [`assets/seed-cards.md`](assets/seed-cards.md), or its pre-asset Source + Area fallback), delete the card file and land the deletion through `/super-bootstrap:commit` (card-lifecycle — no doc-sync gate) — this branch running *is* its resolution, so the card never lingers once curation has run, and the tree is clean when § Disclosure renders.

**Rules-seeding stays runway-owned.** Path-scoped rule seeding (frontend / MV3 / migrations / tests) fires at runway-time in [`/super-bootstrap:harness-bootstrap`](../harness-bootstrap/SKILL.md) Phase 1. Tier-2 adds no rule seeding — one home per signal, no double-seed.

The gate between the runway and tier-2 is the substantive check: substantive proceeds here; not-substantive stops at the greenfield branch above. Tier-2 runs only when there is a resolved stack to curate against.

## Disclosure (post-hoc)

Invoking the command is consent — there is no upfront proceed gate. Each dispatched step that writes commits its own work (runway §2c, resolve-plugins, release-init, the seed-card clear above), so when the done-summary renders the working tree is clean and the commits are the inventory. The summary carries one heads-up line. `{N}` is derived, never left as a placeholder: record `git rev-parse HEAD` before the runway dispatch (empty on a fresh init), then at disclosure `git rev-list --count {that}..HEAD` — `git rev-list --count HEAD` when there was no prior commit:

```
{Initialized git repo. }Wrote/changed: {N} commit{s} this run — review with `git log --stat -{N}`.
```

Zero commits (harness already current, no curation delta): `Nothing written — harness already current.`

Reconciliation is `git log`, not a gate.
