# DEBT-116 — rot scan has no frozen-provenance skip, so history docs re-hit every sync

**Logged:** 2026-09-20 · **Source:** observed during the runway 2.51.0 → 2.51.1 sync this session
**Problem:** `harness-bootstrap` § 2b's rot scan greps every pipeline-owned file in scope for each rename-map `old` literal. A `dimension: history` doc preserves old literals by construction — [`docs/decisions.md`](../decisions.md)'s own scope header binds "existing row text is never deleted or reworded" — so every hit there is structurally undeclinable-once: this sync produced 7 rot rows in that one file, each needing its own decline decision, and the next sync produces the same 7. One of them is worse than noise: the row at `docs/decisions.md:40` records the `sp-bootstrap` grep hazard itself, so migrating its literal would destroy the evidence the row exists to hold. The sibling door already solves this class — [the commit door's frozen-provenance exemption](../../plugins/super-bootstrap/skills/commit/SKILL.md) drops `dimension: history` docs from `terms` / `hits` / `refs` while keeping the link check over them — so the two doors in one plugin disagree on whether a history-dimension doc is scannable prose.
**Area:** `plugins/super-bootstrap/skills/harness-bootstrap/SKILL.md` § 2b Rot scan; `assets/rename-map.md` § Scan guidance
**Prior:** Suspected shape (not settled) — give the rot scan the commit door's frozen-provenance predicate: skip `dimension: history` docs and card threads, keep every other pipeline-owned file strict.
**Test-feel:** doc-only
**Blast:** pkg

## Verdict — auto-fix · 2026-09-21

**Fix-shape:** systematic
**Probe-deps:** none
**Execution:** phased(skip: design settling, written plan) — depth: the predicate is already ratified in the sibling door, so nothing is designed here, only transcribed to a second scope sentence; closure: self-contained in one skill file, the doc-narration sweep returned nothing to sync. Residual phases are RED micro-test → edit → `audit-harness-edits`.

### Repro (pinned)

> `harness-bootstrap` § 2b's rot scan greps every pipeline-owned file in scope for each rename-map `old` literal. A `dimension: history` doc preserves old literals by construction — [`docs/decisions.md`](../decisions.md)'s own scope header binds "existing row text is never deleted or reworded" — so every hit there is structurally undeclinable-once: this sync produced 7 rot rows in that one file, each needing its own decline decision, and the next sync produces the same 7. One of them is worse than noise: the row at `docs/decisions.md:40` records the `sp-bootstrap` grep hazard itself, so migrating its literal would destroy the evidence the row exists to hold.

Scenario: runway sync 2.51.0 → 2.51.1 (commit `9493622`).

### Root cause (verified)

Premise **confirmed**, and the mechanism sits one layer below the card's framing.

**Direct evidence.**

1. `SKILL.md:461` scopes the grep at **file** grain: "grep every pipeline-owned file in scope for each entry's `old` literal".
2. `SKILL.md:163-177` partitions those same files at **section** grain. `docs/decisions.md` enters § Pipeline-owned for its *scope header* alone (`:166`); § Project-owned (`:173`) lists "`docs/decisions.md` § Closed Forks table rows (consumer-filled history)" under the heading **"(never touched)"**. The file-grain grep therefore sweeps content the same section declares untouchable.
3. `docs/decisions.md:2` declares `dimension: history`; its scope header at `:8` binds "**existing row text is never deleted or reworded**". This is the load-bearing leg: the rows are unacceptable-by-construction regardless of who approves, so every hit's only lawful resolution is `decline`, every sync, forever.
4. Telemetry — commit `9493622` body: "Seven rot hits, all inside `docs/decisions.md` closed-fork rows: declined, since that doc's own scope header forbids rewording an existing row and one of the hits is the evidence for the rename hazard its row records." Independent of the card; corroborates both the count and the hazard.
5. Hazard row read at `docs/decisions.md:40` — it states that "a whole-token grep for `sp-bootstrap` also hits the pre-rename *command* form `/sp-bootstrap`, so the naive replace-all ships the namespace-less wrong replacement". A scan proposing to migrate that literal deletes the evidence for the rule the row exists to carry. Confirmed verbatim.
6. The sibling-door predicate exists and is ratified in three places: [`skills/commit/SKILL.md:19`](../../plugins/super-bootstrap/skills/commit/SKILL.md) ("A doc whose leading frontmatter declares `dimension: history` is frozen provenance the same way — a change to it yields no term (`terms` skips it), `hits` and `refs` leave it out of the scan scope, and the link check below still covers it"), [`agents/doc-sync-scan.md:23`](../../plugins/super-bootstrap/agents/doc-sync-scan.md), and mechanically in `skills/commit/assets/doc-links.sh:57,104`. The two-doors-disagree claim holds.

**Finding the card does not carry — the skill contradicts itself on rot-scan scope.** Phase 1 § Rot signals (`SKILL.md:81`) defines the same scan's trigger over an explicit five-entry enumeration — "any pipeline-owned file (`CLAUDE.md`, `docs/overview.md`, `docs/techstack.md`, `.claude/bootstrap.md`, `.claude/rules/*.md`)" — which **already excludes `docs/decisions.md`**, and `SKILL.md:96` declares "record `rot_hits[]` so Phase 2b can re-use the scan instead of grepping twice." Under that re-use contract the 7 rows could never have been produced; they exist because § 2b re-greps against a strictly wider scope than Phase 1 recorded. The fix surface is therefore **two** scope sentences, not one.

That Phase 1 list is not a latent frozen-provenance skip: it also omits `docs/work/README.md`, `AGENTS.md`, `CODING_STANDARDS.md`, `.claude/rules/index.md` and the scale-module docs, none of them history-dimension. `docs/decisions.md` joined § Pipeline-owned at `d6a941e` (2026-06-19); the parenthetical was last touched at `03b0f7c` (2026-09-05) for a path relocation, without reconciling. Stale partial enumeration.

**Reconciliation direction settled by measurement, not preference.** Narrowing § 2b down to Phase 1's five-file list would drop `docs/work/README.md` — a pipeline-owned whole-file skeleton whose shipped prose does reference plugin skills, i.e. a legitimate rot target. So Phase 1's parenthetical widens to § Pipeline-owned minus the skip; § 2b keeps its sweep and gains the skip. Cited: `SKILL.md:163-177` § Pipeline-owned.

**Card-Prior correction.** The Prior asks to skip "`dimension: history` docs **and card threads**". Card threads are already out of scope by construction — § Pipeline-owned names only `docs/work/README.md` and `docs/work/TEMPLATE.md`, never `docs/work/{BUG,DEBT,GAP}-###.md`. Encoding a card-thread clause would assert a scope that does not exist; the predicate is `dimension: history` only.

### Files (fix surface)

All paths are this repo's own plugin source — super-bootstrap is the serving repo, so the fix lands here. The installed copy under `C:/Users/User/.claude/plugins/cache/super-bootstrap/super-bootstrap/2.51.1/` is the published artifact: read-only, never edited.

- `plugins/super-bootstrap/skills/harness-bootstrap/SKILL.md:461` — § 2b **Rot scan**. Primary edit: add the frozen-provenance skip to the scope sentence. Mirror the sibling door's shape — the rot lane skips `dimension: history` docs while the per-section drift check still covers their pipeline-owned sections (`docs/decisions.md`'s scope header must stay drift-checked; this is a lane skip, not a file-out-of-scope).
- `plugins/super-bootstrap/skills/harness-bootstrap/SKILL.md:81` — Phase 1 § Rot signals trigger. Second edit: reconcile the five-file parenthetical to § Pipeline-owned minus the same skip, so `rot_hits[]` (`:96`) and § 2b agree on one scope.
- `plugins/super-bootstrap/skills/harness-bootstrap/SKILL.md:163-177` — § Pipeline-owned / § Project-owned. Read-only: the enumeration both sentences must name.
- `plugins/super-bootstrap/skills/commit/SKILL.md:19` — read-only: source wording for the predicate. Transcribe its shape, do not re-invent it.
- `plugins/super-bootstrap/skills/harness-bootstrap/assets/rename-map.md:69` — § Scan guidance. The card names it as a fix surface; the trace says **leave it**. Its three bullets own matching, referent-confirmation, and multiplicity — never scope. Restating the predicate there forks the SSOT; at most a pointer to § 2b.

### Doc Impact

none — confirmed unchanged after read. Narration sweep for `rot scan` / `rename-map` / `rot hit` across `docs/`, root `README.md`, `plugins/super-bootstrap/README.md`, `.claude/`, and both manifests returns two lines, neither restating the scan's scope: `docs/decisions.md:77` (closed-fork row naming the rot scan's existence — `dimension: history`, frozen, no sync) and `assets/rename-map.md:60` (a § Paths note). `CLAUDE.md:70` and `assets/claude-md-skeleton.md:70` carry the *commit door's* history-dimension skip, untouched by this fix.

### Test Strategy: unit

Behavior-shaping skill prose, so [`.claude/rules/skill-authoring.md`](../../.claude/rules/skill-authoring.md)'s RED floor binds: micro-test the new scope wording against a no-guidance control — a cold agent given the § 2b sentence plus a fixture `docs/decisions.md` carrying `dimension: history` and a `/sp-bootstrap` literal in a closed-fork row, asked which files it greps and which rot rows it emits. Control (current wording) emits the row; treatment must not, while still emitting a rot row for a `CLAUDE.md` literal. Dispatchable, no human eyeball.

### Residual — out of scope for this card

§ 2c's receipt sources `declined` from per-section drift rows and the missing-on-mature advisory only (`SKILL.md:575`); rot rows are never enumerated there, and the `previously declined:` line renders only when the prior receipt's `declined` carries the row's section. So a declined rot row leaves **no** trace the next sync reads — the `9493622` decline lives in the commit message, not the receipt. This fix removes the 7 recurring rows, so the symptom clears; the decline-memory gap survives for any non-frozen rot row a consumer legitimately declines (the § Scan guidance referent-ambiguity case — another plugin's `/triage`). Separate class, separate card — route via `/super-bootstrap:log`, not this fix.
