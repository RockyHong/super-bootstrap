# Classify Actionable — shared spec

Single source of truth for deriving, from the three pipeline sources, **each open item's `{action, intent, stage}`**. Embedded verbatim into a dispatch prompt by every caller that needs the classification — `todo` (then ranks + renders a board) and `drain` (then gates on `Cloud` + spawns per stage). One criterion, many callers: neither caller re-derives it.

> **Callers embed, never paraphrase.** Read this file and inject it verbatim into the dispatch prompt (same move `todo` uses for `assets/scaffolds.md`). Paraphrasing forks the taxonomy — the drift this shared home exists to prevent.

Three outputs per item:

- **`action`** — the one-line actionable verb-phrase (`"Triage: BUG-12 …"`, `"Continue execute: plan.md (3/7)"`). The render string.
- **`intent`** — `Discuss` | `Cloud` | `Device`. The runnability bucket.
- **`stage`** — where the item sits in the pipeline, by file presence: `raw` (backlog row, no spec/plan) · `spec` (spec exists, no plan) · `plan` (plan executing) · `review` (plan all-checked, no DONE) · `done` (DONE/COMPLETED marker). The entry point for stage-resuming consumers.

`intent` is the gate; `stage` is the entry point; `action` is for human render.

---

## Cloud-safe criterion

Single positive rule applied to every row before bucketing:

> **Cloud-safe = phase produces a verifiable artifact via tooling alone. No human visual judgment, no real browser/device interaction, no "looks right" call.**

### Derivation inputs (read per row when classifying)

1. **Plan content** — grep the plan file body for device signals:
   - Keywords: `manual test`, `e2e`, `playwright`, `cypress`, `visual`, `device`, `mobile`, `browser`, `screenshot`
   - Paths in task bullets: `**/components/**`, `**/app/**`, `**/pages/**`, `**/views/**`, `apps/web/**`, `apps/mobile/**` → device-suspicion
   - If only pure-logic paths (`lib/`, `utils/`, `core/`, `packages/{logic-name}/`) and no device keywords → cloud-safe
2. **Spec §Success Criteria** (if linked spec exists) — explicit `manual verification`, `visual check`, `e2e pass` → device-only for the executing/review row
3. **Phase verb** in derived action:
   - `Write plan` / `Approve spec` / `Triage` / `Extract` / `Doc-edit` / `Cleanup` → cloud-safe regardless of paths
   - `Continue execute` / `Review` → derive per #1 + #2
   - `Manually verify` / `E2E run` / `Smoke test` → device-only

### Default

If no signal is conclusive, default cloud-safe for spec/plan-write/triage/cleanup rows; default device for executing rows touching UI surfaces; default cloud for executing rows on pure-logic surfaces.

## Action-verb intent map (applied FIRST in classification)

Intent is determined by action verb before path/state rules.

| Action verb prefix                                              | Intent (locked)              | Why                                                                          |
| --------------------------------------------------------------- | ---------------------------- | ---------------------------------------------------------------------------- |
| `Approve spec`, `Decide`, `Continue brainstorm`, `Confirm`      | **Discuss**                  | User-decision shape — only user can resolve.                                 |
| `Write plan`                                                    | **Cloud**                    | Plan author write is doc artifact, headless.                                 |
| `Refine spec`, `Doc-edit`                                       | **Cloud**                    | Doc artifact, headless.                                                      |
| `Continue execute`, `Resume`                                    | **Cloud OR Device** (derive) | Depends on paths + content per cloud-safe criterion.                         |
| `Review` (read diff of completed plan)                          | **Cloud**                    | Reading diff is headless.                                                    |
| `Manually verify`, `E2E run`, `Smoke test`                      | **Device**                   | Real browser / device required.                                             |
| `Triage` (backlog item, investigate-only)                       | **Cloud**                    | Investigate-only artifact, headless.                                         |
| `Cleanup` (delete merged spec+plan files)                       | **Cloud**                    | File delete on completed work, no judgment.                                  |

## Per-source derivation

Read all three sources, derive each item's `{action, intent, stage}`. Apply the Action-verb intent map FIRST, then the content rules.

### a. Specs (`docs/superpowers/specs/*.md`)

For each:

- **Brainstorming-style** (no checkboxes, "options" / "approaches" / "trade-offs" present, open question to user not resolved) → action: `"Continue brainstorm: {filename}"`, **intent: Discuss**, **stage: spec**.
- **Spec-ready but no matching plan file** (matched by date prefix or slug) AND content contains user-approval signal (`awaiting approval`, `needs sign-off`, `decision pending` from user) → action: `"Approve spec: {filename}"`, **intent: Discuss**, **stage: spec**.
- **Spec-ready, approved, no matching plan** → action: `"Write plan: {filename}"`, **intent: Cloud**, **stage: spec**.
- **Spec exists with matching plan** → spec is reference now; don't emit a spec row, emit the plan row instead (see §b).
- **Orphaned spec** (>7 days old, no plan, no approval signal) → action: `"Decide: stale spec {filename} — approve / refine / delete"`, **intent: Discuss**, **stage: spec**.

### b. Plans (`docs/superpowers/plans/*.md`)

For each, count checkboxes:

- **Plan with all `- [ ]` unchecked** (planning stage) → action: `"Start execute: {filename}"`, **stage: plan**. Intent per cloud-safe derivation.
- **Plan with mix of `- [ ]` and `- [x]`** (executing) → action: `"Continue execute: {filename} ({checked}/{total})"`, **stage: plan**. Intent per cloud-safe derivation.
- **Plan with all `- [x]` checked AND no DONE marker** (review-ready) → action: `"Review: {filename}"`, **stage: review**. Intent per cloud-safe derivation (manual verification → Device; diff-read → Cloud).
- **Plan with "DONE" or "COMPLETED" marker** → action: `"Cleanup: delete {spec+plan files} for {feature}"`, **intent: Cloud**, **stage: done**.
- **Plan with explicit user-blocker** (`waiting on user`, `needs user decision`, unresolved `?` directed at user) → action: `"Decide: {what's open on {filename}}"`, **intent: Discuss**, **stage: plan**.

### c. Backlog (`docs/backlog.md`)

Backlog owns BUG/DEBT/GAP — bugs, debt, and design gaps / unverified feature ideas (GAP). A GAP that is a feature idea is classified like any other row — no separate lane.

Open items are `### {BUG|DEBT|GAP}-###` row headings under `## Open`. The header's **ID high-water mark** line carries the same ID literals but is a counter, not an item — exclude it from rows and counts.

For each open `BUG-### / DEBT-### / GAP-###` item:

- **Item flagged for user decision** (line contains `needs user`, `decision required`, `route?`) → action: `"Decide: {ID} {title}"`, **intent: Discuss**, **stage: raw**.
- **Item with no scope.md / no plan yet** (default state) → action: `"Triage: {ID} {title}"`, **intent: Cloud** (triage is investigate-only), **stage: raw**.
- **Item with active plan reference** → don't double-emit; the plan row already covers it (see §b).

For any row with a **foreign prefix** (anything outside `BUG-### / DEBT-### / GAP-###` — e.g. `F-`, `FEAT-`, `ROAD-`, bare bullet): emit as `Uncategorized` with reason `"non-canonical backlog prefix; backlog owns BUG/DEBT/GAP (feature ideas log as GAP). New rows route through /super-bootstrap:log."` — never invent classification.

If `docs/backlog.md` doesn't exist, skip §c.

---

## Consumer boundary

This spec stops at `{action, intent, stage}`. What each caller does next is **its own** concern, not shared here:

- **`todo`** — Impact/Blast tags, coupling gate, within-mode ranking, scaffold render. Lives in `agents/todo.md`.
- **`drain`** — `Cloud`-gate, relation-analysis (file-overlap parallelism), wave selection, worktree spawn, stage-keyed phase entry. Lives in `skills/drain/`.

Edit the classification here; edit each caller's downstream in its own home.
