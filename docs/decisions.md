# Decisions

> **History-dimension doc.** Owns *closed forks / rejected directions* across every domain — tech, product, business, design. Append-only: entries are added, never edited to "now".
>
> **Lands here** — a direction genuinely evaluated and **closed** that (a) left **no diff** (road-not-taken, wall foreseen — git can't hold what was never committed) AND (b) would otherwise be re-proposed.
>
> **Does NOT land here:**
> - Committed change history (what changed / when / why-of-a-change) → **git log + commit messages**.
> - A past decision that still **binds** current work → present-tense constraint in the state doc it governs (`docs/techstack.md`, `docs/overview.md`), stripped of when/why-decided.
> - A closure obvious from current state → no entry.
>
> **Checked at triage** (`CLAUDE.md` § Development Workflow) before any route or design is proposed — a closed fork surfaces *before* it is re-walked. Routing rule in `CLAUDE.md` § Doc Sync.

## Closed Forks

<!-- Newest first. One fork per row. Keep terse — the closing reason, not a narrative. Domain ∈ tech | product | business | design. -->

| Domain | Rejected direction | Because | Ref |
|---|---|---|---|
| design | A version-driven update/merge engine for the bootstrapped runway (version-keyed migrations beyond the rename-map rot scan) | `harness-bootstrap` re-run already re-syncs — the Phase 2b per-section drift check preserves user edits — so a heavier engine is redundant with it *and* unearned at solo-dev scale (Leverage), the same reasoning as the release-init update-channel fork below. Shipped the earned residual instead: a version stamp (`.claude/super-bootstrap-runway.json`) + a stale-stamp guard that forces the existing drift check to run in full. | `skills/harness-bootstrap/SKILL.md` §§ Version-staleness signal · 2b · 2c |
| design | An update/sync channel (C: runtime-delegate · A: extract-config + re-render · B: version + 3-way merge) for release-init's generated `/release` skill | The generated skill is a pure derivative — config is re-detected on every re-run, no durable customization to preserve. Overwrite-after-confirm (SKILL.md §1 already gates `y/n`) **is** the update channel by design (SSoT *never hand-edit derivative*). The "blind overwrite / no update path" premise was refuted by current state; sync machinery unearned at solo-dev scale (Leverage). Behavior-divergent consumers (e.g. this repo's own marketplace-aware `/release`) are not release-init output and fall outside the model. | `plugins/super-bootstrap/skills/release-init/SKILL.md` §1 |
| design | drain strips its status file at the merge gate (`git rm` on the branch tip before handoff) — the intuitive fix, hand-done once on the leaking run | Status filename (`tasks.md`) can collide with a real product file; a blind `git rm` at merge would delete the user's file (post-action delete, ignores downstream). Root-fixed instead: status is an uncommitted, gitignored `.drain-status` — never tracked, never merges, no strip needed. Merge lane stays generic (rejected coupling it to drain's artifact name — SoC). | `skills/drain/assets/phase-loop.md` §Status contract |
| design | A user-invoked `/decision` skill (or new `/log` class) to capture history | Capture is doc-sync's job, not a human act — the AI running doc-sync knows what pivoted; the user doesn't. User self-log is dumb. | doc-sync § Dimension routing |
| design | Per-domain history docs (techstack-history, overview-history, …) | The anti-drift push wants **one** triage target to scan. Closed forks are admission-gated → rare → one cross-domain doc stays small. | CLAUDE.md § Development Workflow |
| design | `PreToolUse(Write)` hook to enforce the dimension routing | Probe ambient first (trust-upstream). The triage pointer + doc-sync rule *are* the ambient push; the routing also includes an omission decision a hook can't deny, only nudge. Build the hook only if ambient demonstrably fails. | `claude-shape/layer-placement.md` § action-vs-omission |
| design | `docs/techstack.md` § Rejected Alternatives as the closed-fork home | State doc carrying a history section = dimension pollution; also tech-scoped, so product/business/design forks stay homeless. Retired → this doc. | `axiom-principles/doc-dimension-ssot.md` |
| design | A standalone append-only **chronicle** doc (full decision timeline) | Duplicates git — git log + commit messages **are** the committed-history SSOT (free, drift-proof). Only the no-diff residual git can't hold earns a hand-doc. | `axiom-principles/doc-dimension-ssot.md` |
