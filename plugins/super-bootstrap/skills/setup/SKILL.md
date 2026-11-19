---
name: setup
description: "Public entry for the super-bootstrap pipeline — thin orchestrator. Git-inits if absent, then dispatches /super-bootstrap:harness-bootstrap to install or sync the generic runway (always; the runway self-detects fresh-vs-sync). Code present → also seeds and works two GAP cards (spec-seeding, marker-sweep). Then checks whether seed docs are substantive: greenfield seeds two GAP cards (overview, techstack) from a pinned asset, commits them, and stops at the resolve gate; substantive seed docs take the release-init offer. Zero product prework. Solo dev workflow."
tags: [bootstrap, orchestrator, detect, gate, meta]
---

# Super Bootstrap — Public Entry, Thin Orchestrator

The single command users invoke. Orchestrates — detect, route, dispatch, integrate — and owns no install procedure itself: scaffolding lives in the generic runway, [`/super-bootstrap:harness-bootstrap`](../harness-bootstrap/SKILL.md). The entry writes no product content and asks no product questions itself — product work runs through card pickup. `overview.md` / `techstack.md` are scaffolded by the runway; their product content fills later at GAP card pickup.

## Orchestration spine

1. **Git-init** if absent (correctness move).
2. **Dispatch the runway** — `/super-bootstrap:harness-bootstrap` (generic, always; it self-detects fresh-vs-sync).
3. **Code-present seed** (code present) — seed 2 GAP cards from the pinned seed-card asset, commit, pick up each whose precondition holds now.
4. **Detect** — are the seed docs substantive?
5. **Greenfield branch** (not substantive) — seed 2 GAP cards from the pinned seed-card asset, stop at the resolve gate.
6. **Substantive branch** — the `release-init` offer.
7. **Disclose** — one post-hoc heads-up line (substantive branch; the greenfield branch's resolve gate is its disclosure).

## Git-init (correctness move)

If the repo is not a git repo (`git rev-parse --git-dir` fails), run `git init` first. One log line, no gate.

## Dispatch the runway (always)

Invoke `/super-bootstrap:harness-bootstrap` via the Skill tool. The runway installs fresh or syncs drift — its own detection — scaffolding CLAUDE.md, CODING_STANDARDS.md, skeleton docs, path-scoped rules, the core plugin pin, the language-server pins the techstack names, and returns "runway installed/synced + committed." The entry dispatches it unconditionally, so a documented-but-stale repo still gets runway sync. Then run the code-present seed.

## Code-present seed — seed first, work now (code present)

Pending pipeline work is carried by cards: seed it before working it, so a run interrupted mid-work leaves committed cards for cold pickup. Runs on both branches below, before the substantive check. Code presence is the runway's own test — [Phase 1 § Code presence](../harness-bootstrap/SKILL.md#manifest-detection) (a manifest or any source file); docs-only repo → skip this step.

**Seeded-once guard (run first, per card).** For each of the two code-present cards in [`assets/seed-cards.md`](assets/seed-cards.md) (`spec-seeding`, `marker-sweep`), skip it when any of these mechanical checks hits:

1. a card file in `docs/work/` carries its H1 summary (the text after `{ID} — `) — open now;
2. `git log -S"— <H1 summary>" --oneline -- docs/work/` returns a commit — seeded before, resolved since;
3. `spec-seeding` only: `docs/specs/` already holds a spec file (any `*.md`) — specs exist;
4. `marker-sweep` only: `docs/work/` already holds a `{BUG,DEBT,GAP}-*.md` card whose `**Source:**` names no `/super-bootstrap… bootstrap` seed run (the greenfield guard's tolerant match) — the repo already captures work as cards;
5. `git log --oneline -- .claude/bootstrap.md docs/work/bootstrap.md` returns a commit — the repo carried a legacy bootstrap plan, whose own checkboxes decided this work (the runway's § 2b legacy plan migration converts what was still open), so the check skips both cards.

Both skipped → log "Code-present cards already seeded." A re-run seeds nothing twice, so an interrupted run re-enters safely.

**Seed and commit** — write each card the guard passed by the greenfield branch's hand-copy (below: the fenced body verbatim, `{ID}` + `{date}` only, GAP IDs from one generator call in the asset's order), then land the new card files through `/super-bootstrap:commit` (card-lifecycle — no doc-sync gate). Nothing written → nothing to commit.

**Work now** — after the seed commit, pick up each open code-present card — a `docs/work/` card whose H1 summary matches `spec-seeding` or `marker-sweep` in the asset, seeded by this step or by the runway's legacy plan migration — whose `Problem:` precondition holds now, by its ID: the ordinary card pickup (framing + route; the routed phase resolves and deletes the card in its own commit) — no bootstrap-private path. A card whose precondition fails now (`spec-seeding` on an empty Module Index) stays open. Each pickup runs as its own phase, dispatched per the repo's `CLAUDE.md` like any card; one that stops at a user gate the user does not clear now leaves its card open, and the run moves on. An interrupted pickup leaves its card open too; `/super-bootstrap:needs-me`, triage, and autorun see it like any other card. Then continue to Detect — the greenfield branch still stops at its resolve gate.

## Detect — seed docs substantive?

Check whether `docs/overview.md` + `docs/techstack.md` carry content **filled beyond the skeleton placeholders** — substantive product content, not mere file presence (the runway writes these as empty skeletons on greenfield; a file-exists test misreads an empty skeleton as documented). Substantive = the product sections (`overview.md` Problem / User / Current State, `techstack.md` Runtime / Framework) carry real content past the placeholder text — mirror the "≥3 substantive lines" notion (lines that aren't headings, blank, or placeholder).

This is the only branch the entry makes: not-substantive → greenfield (seed GAP cards + gate); substantive → the release-init offer.

## Greenfield branch — seed GAP cards + gate (not substantive)

The runway returned with empty product skeletons. Seed two GAP cards from the pinned bodies in [`assets/seed-cards.md`](assets/seed-cards.md), then stop at the resolve gate — the product is not resolved yet.

**Idempotency guard (run first).** Check `docs/work/` for card files (`GAP-*.md`) whose H1 summary (the text after `{ID} — `) matches one of the asset's two greenfield summaries. A card seeded before the asset existed carries a model-written H1 — it counts as a match when its `**Source:**` names a `/super-bootstrap… bootstrap` seed run and its `**Area:**` names the same doc set as an asset card (`docs/overview.md` alone → overview; `docs/techstack.md` alone → techstack). Card present → skip that card; both present → log "GAP cards already seeded." Re-run stays safe.

**Seed by hand-copy** — the sanctioned transcription path of [`/super-bootstrap:log`](../log/SKILL.md) (hand-copying `docs/work/TEMPLATE.md` with an ID from its generator is the same door): write each missing fenced body verbatim as `docs/work/{ID}.md`, filling only `{ID}` and `{date}`. IDs = one call to the log skill's generator, `bash ${CLAUDE_PLUGIN_ROOT}/skills/log/assets/new-id.sh GAP …` from the repo root, issued as its own tool call with one `GAP` argument per missing card; assign the printed IDs verbatim, in the asset's order — never compose one by hand. No re-phrasing, no Mover / dedup gates — the bodies are fixed; the pickup-routing hint rides in each `Problem:` line, not a `Prior:` route — triage owns the method.

**Commit the seed** — a card written → land the new `docs/work/{ID}.md` files through `/super-bootstrap:commit` (card-lifecycle — no doc-sync gate) before the gate renders; both already present → nothing written, nothing to commit. The tree is clean when the resolve gate renders.

**Resolve gate — stop here.** After seeding, surface the dogfood handoff and stop. Render the block verbatim, no additions; the two command literals stay untranslated:

```
Generic harness installed. Two GAP cards seeded (overview, techstack).
Resolve overview + techstack via /super-bootstrap:needs-me — settle the framing with the user (no code), or reverse-engineer it from the code (code present).
Once both are filled, re-run /super-bootstrap:setup — the run pins the language server for the stack and offers release setup.
```

## Substantive branch — release setup (substantive)

The runway returned, pinned the language server the techstack names, and the seed docs are substantive (a just-resolved greenfield, or an already-documented updater). Run in order:

1. **`/super-bootstrap:release-init`** — offer once as an optional step to generate a project-level `/release` skill.
2. **Clear an open "Run tech curation" card** — a `docs/work/GAP-*.md` card whose H1 summary is `Run tech curation`, or whose `**Source:**` names a `/super-bootstrap… bootstrap` seed run and whose `**Area:**` names both `docs/overview.md` and `docs/techstack.md`. Delete the card file and land the deletion through `/super-bootstrap:commit` (card-lifecycle — no doc-sync gate); this run is that card's resolution, so the tree is clean when § Disclosure renders.

**Rules-seeding stays runway-owned.** Path-scoped rule seeding (frontend / MV3 / migrations / tests) fires at runway-time in [`/super-bootstrap:harness-bootstrap`](../harness-bootstrap/SKILL.md) Phase 1 — one home per signal, no double-seed.

This branch runs only when the substantive check passes; not-substantive stops at the greenfield branch above.

## Disclosure (post-hoc)

Invoking the command is consent — there is no upfront proceed gate. Each dispatched step that writes commits its own work (runway §2c, the code-present seed commit and each card pickup worked in the same run, the greenfield seed commit, release-init, the seed-card clear above), so when the done-summary renders the working tree is clean and the commits are the inventory. The summary carries one heads-up line. `{N}` is derived, never left as a placeholder: record `git rev-parse HEAD` before the runway dispatch (empty on a fresh init), then at disclosure `git rev-list --count {that}..HEAD` — `git rev-list --count HEAD` when there was no prior commit:

```
{Initialized git repo. }Wrote/changed: {N} commit{s} this run — review with `git log --stat -{N}`.
```

Zero commits (harness already current, nothing to pin or seed): `Nothing written — harness already current.`

Reconciliation is `git log`, not a gate.
