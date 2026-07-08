# PICKUP — Harness Rebase (GAP-017), Cold Entry for an Unbound Agent

> Written 2026-07-08 at a deliberate stop. The user halted the program mid-wave over process cost
> and suspects the sessions running it were **bound by this repo's own harness** (dispatch-everything,
> synthetic pressure-testing, layered review). You are expected to read this, form your own judgment
> about which of those bindings to keep, and finish the program efficiently. This doc is temporal —
> delete when the program closes.

## Mission in one paragraph

`super-bootstrap` (this repo) is a Claude Code plugin — the single harness root. `ChewLingo`
(**`V:\ChewLingo`** — mother repo the harness forked from) evolved a judgment layer in parallel.
The program: upstream ChewLingo's universal evolution into this plugin, then rebase ChewLingo onto
the plugin so it keeps only project delta. Program map + locked decisions + per-artifact verdicts:
[`harness-rebase.md`](harness-rebase.md) (same dir). Backlog card: `docs/backlog.md` § GAP-017.

## Where it stands (verified, not aspirational)

- **Done, committed, RELEASED (plugin v2.21.0, installed):** merge, log, check-docs-consistency
  (Wave 1); commit, todo (Wave 2).
- **Done, committed, UNRELEASED:** triage(+report) distill (`ef62c87`) and the scale module
  (`e9fecd9`, today — opt-in earn-gated module in harness-bootstrap §2a-scale: `docs/parked.md` +
  `docs/test-queue.md` container skeletons, `venue-map` rule (T/S/U/P phase→venue map — Wave 3
  drain's interface), backlog fact-fields insert; classify-actionable §d; log agent parked-aware).
  `main` is **3 commits ahead of origin, unpushed** — convention: push rides the next `/release`.
- **Done, committed, UNRELEASED (2026-07-08 pickup session):** monorepo tier + adopt mode +
  drain distill — Waves 2 and 3 COMPLETE. Trimmed process used (direct port, one cold audit per
  batch, no synthetic RED / per-task review / plan docs): ~0.35M subagent tokens for all three.
- **Remaining:** `/release` v2.22.0 (clears release debt below, pushes). Wave 4 — supervised
  `/super-bootstrap` run against ChewLingo (materialized mode, diff+approve, adopt-mode deletions).
  Wave 5 — `audit-harness-edits` on both repos + one wet card cycle each.
- **Release debt (next `/release`, v2.22.0):** plugin.json `description` must be hand-updated to
  mention triage/triage-report AND the scale module (release skill only syncs the marketplace
  mirror); delete the two landed temporal plans (`2026-07-08-gap-017-triage-distill.md`,
  `2026-07-08-gap-017-scale-module.md`) + their spec (`2026-07-08-gap-017-triage-distill-design.md`)
  — deletion condition is "landed AND released", which the release satisfies; push. First real
  `/super-bootstrap:triage {ID}` and first module-installed `/super-bootstrap:log` (parked lane)
  post-release are wet verifies — anomaly → BUG card.

## The cost pathology you are being asked to fix (measured, this repo's own sessions)

The scale-module wave (one artifact, ~250 shipped markdown lines) consumed **~2.3M subagent tokens**:
40% synthetic RED/GREEN pressure probes, 30% implementation, 26% per-task review + re-review, 14%
grounding/commit. Meta:ship ≈ 8:1. Diagnosis, with the evidence:

1. **Synthetic RED treats production-proven source text as unproven hypothesis.** ChewLingo's rules
   have months of live mileage — that is the real GREEN. Re-proving ports with synthetic probes is
   re-deriving known truth. RED earns its cost only for discipline lines **new to both repos**.
   (It did pay once: 20 probes killed 3 planned rule files — see `docs/decisions.md` top rows.)
2. **Double verification nets.** SDD per-task review (610k) + end-of-plan cold `audit-harness-edits`
   (246k) overlap, and the cold audit is the stronger net — it caught a CRITICAL (log-agent/parked
   contradiction) plus 4 MAJOR that every per-task review missed. For markdown harness work, keep
   ONE net: the cold audit.
3. **Re-review after fixes: 0 new findings in 5 measured dispatches** across two waves (GAP-020,
   already carded). Transcription-grade fixes need a dispatcher diff-read, nothing more.
4. Route sizing by work TYPE not shape (GAP-018), plan-embed waste (GAP-019) — both carded.

**Recommended process for everything remaining** (was proposed to the user immediately before the
stop; not yet ratified — confirm or override): port production-proven CL text directly → one cold
`audit-harness-edits` per batch → wet verify → commit. No synthetic RED for ports, no per-task
review layer, no re-review, no plan documents for the two small Wave-2 items (inline implement).
Estimated remaining cost under this: **~1.5M tokens, ~4 sessions** for the whole program.

## Bindings the previous sessions ran under — choose consciously

This repo's `CLAUDE.md` + installed skills impose: card-grounded entry, cluster routing into
superpowers skills run whole, dispatch-per-phase (gateway never builds), writing-skills RED for
behavior-shaping prose, SDD per-task review loops, doc-sync scan before every commit, cold audit on
harness diffs, `/super-bootstrap:commit` as sole commit channel (raw `git commit` is hook-denied
without a fresh docsync token). The user suspects — with the numbers above largely agreeing — that
the full stack is miscalibrated for THIS program's work shape. What demonstrably earned its cost
here: **the cold audit** (caught the only CRITICAL), **doc-sync** (cheap, kept docs true), the
**decisions.md closed-fork ledger** (7 rows prevented re-walks). What didn't: synthetic RED on
proven text, the per-task review layer, re-reviews. User instructions override the harness defaults
— the user has explicitly authorized questioning them.

## Facts a cold agent needs

- ChewLingo lives at **`V:\ChewLingo`** (not `D:\Git`). Schema-grain source (rule bodies, tracker
  fields) is read fresh from there; the verdict table carries routing, not schemas.
- Plugin dev copy = `plugins/super-bootstrap/**` in this repo; installed copy = v2.21.0 cache.
  Runtime doesn't see unreleased skills until `/release` + update.
- ChewLingo's settings have `super-bootstrap` + `superpowers` present but **disabled** — flip on
  only at Wave 4 migration time; running it earlier clobbers the evolution being upstreamed.
- Open meta-cards: GAP-018 (route sizing valve), GAP-019 (plan embeds), GAP-020 (re-review),
  BUG-012 (background-opus new-plugin-file stall — new `plugins/**` files dispatch foreground).
- Session scratch ledger (git-ignored): `.superpowers/sdd/progress.md` — per-task history of the
  scale-module wave, superseded by this doc for pickup purposes.
- The scale module is installed in **no repo yet** — this repo doesn't qualify (docs-only, small
  board); first real consumer install is a wet-verify moment.

## Suggested first moves for the next session

1. Ratify (or override) the trimmed process above with the user — one question, then lock it into
   [`harness-rebase.md`](harness-rebase.md) § Distill route sizing.
2. `/release` v2.22.0 (ships triage + scale module, clears the release-debt list above, pushes the
   3 commits) — unblocks both wet verifies and the temporal-file cleanup.
3. Then monorepo tier + adopt mode in one session under the trimmed process; drain next.
