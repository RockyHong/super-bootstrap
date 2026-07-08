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

- **Waves 1–3 COMPLETE, RELEASED (plugin v2.22.0, pushed, device cache updated):** merge, log,
  check-docs-consistency (W1); commit, todo, triage(+report), scale module, monorepo tier, adopt
  mode (W2); drain distill (W3). Final three shipped under the trimmed process (direct port, one
  cold audit per batch, no synthetic RED / per-task review / plan docs): ~0.35M subagent tokens
  total — vs 2.3M for the scale module alone under the old stack. Release debt cleared: plugin.json
  description updated, temporal plans+spec deleted, all pushed.
- **Wave-4 prerequisites DONE:** ChewLingo `.claude/settings.json` now has `superpowers` +
  `super-bootstrap` flipped ON (uncommitted — the migration run's scaffold commit absorbs it).
- **Remaining:** Wave 4 — supervised `/super-bootstrap` run **in a V:\ChewLingo session** (plugin
  loads there on session start; materialized mode, diff+approve section-by-section, adopt-mode
  deletions per-confirm). Wave 5 — `audit-harness-edits` on both repos + one wet card cycle each;
  the first real `/super-bootstrap:triage {ID}` and first scale-module `/super-bootstrap:log`
  (parked lane) double as wet verifies — anomaly → BUG card.
- **Deferred (log as a GAP card if not absorbed by Wave 4/5):** journey-simulation upstream,
  spec/plan/implement/review salvage (Surface-on-Gap refusal, design gate, evidence block),
  model-tiering hooks — verdict rows exist in `harness-rebase.md`, no wave assigned; they are
  NOT dups (root has no counterpart), so adopt mode leaves them as ChewLingo delta untouched.

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
