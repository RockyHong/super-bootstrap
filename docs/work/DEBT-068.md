# DEBT-068 — shipped skeletons carry the retired `sp-bootstrap` name in placeholder lines

**Logged:** 2026-08-12 · **Source:** runway sync 2.29.7 → 2.34.2 (Phase 2b § Rules per-section compare)
**Problem:** Six bracketed placeholder lines across two shipped assets still name the plugin `sp-bootstrap` — the pre-rename spelling (`sp` = superpowers). `claude-md-skeleton.md:116` (`{seeded by sp-bootstrap based on Phase 1 stack signals — examples:}`) and `rules-frontend-skeleton.md:11,20,28,35,42` (`{filled by sp-bootstrap or doc-sync …}`). Consumer impact is nil today because every hit sits inside a `{}` placeholder line that the scaffold drops at fill time — but a consumer who scaffolds with no rule signal and keeps the explanatory block, or anyone reading the asset, meets a plugin name that does not exist. The rot scan cannot catch this class: `assets/rename-map.md` § Skeleton headings / structure is empty (`none yet`), and the § Slash commands table covers only `/sb-*` and bare command forms, not the bare plugin name in prose.
**Area:** `plugins/super-bootstrap/skills/harness-bootstrap/assets/claude-md-skeleton.md`; `plugins/super-bootstrap/skills/harness-bootstrap/assets/rules-frontend-skeleton.md`; `plugins/super-bootstrap/skills/harness-bootstrap/assets/rename-map.md`
**Prior:** Replace the six literals with `super-bootstrap`, and add a rename-map row (`sp-bootstrap` → `super-bootstrap`) so the rot scan covers prose plugin names, not just slash-command literals. Leave the `superpowers/` path exclusions in `assets/hooks/consult-check-sessionstart.sh` alone — those are the documented legacy-home exclusions, not stale naming.

## Verdict — auto-fix · 2026-08-13

**Fix-shape:** systematic — six literal rewrites are mechanical; the rename-map rows apply the map's own codified rule (`rename-map.md:12-14`: "When a literal renames, add a row here and update the relevant skeleton in the same commit"). Labelled up, not down.
**Probe-deps:** none — `docs/techstack.md` carries no § Probes table.
**Execution:** inline — deterministic fix-shape (codified rule, replacement name settled by sibling-asset convention) × self-contained closure (4 files, one skill dir, no doc-sync writes, no consumer contract change). Harness surface, so `audit-harness-edits` on the diff still binds per cluster 7.

### Repro (pinned)

> Six bracketed placeholder lines across two shipped assets still name the plugin `sp-bootstrap` — the pre-rename spelling (`sp` = superpowers). `claude-md-skeleton.md:116` (`{seeded by sp-bootstrap based on Phase 1 stack signals — examples:}`) and `rules-frontend-skeleton.md:11,20,28,35,42` (`{filled by sp-bootstrap or doc-sync …}`).

> The rot scan cannot catch this class: `assets/rename-map.md` § Skeleton headings / structure is empty (`none yet`), and the § Slash commands table covers only `/sb-*` and bare command forms, not the bare plugin name in prose.

### Root cause (verified)

Repo-wide `grep -rn "sp-bootstrap"` returns **seven** live hits, not six. The card's six are exact — verbatim text and line numbers confirmed at `claude-md-skeleton.md:116` and `rules-frontend-skeleton.md:11,20,28,35,42`. The seventh is `harness-bootstrap/SKILL.md:324`, same rot class, missing from the card's inventory:

> Older sp-bootstrap skeletons baked content into CLAUDE.md that now belongs in `.claude/rules/` …

Mechanism — all seven are post-rename authoring slips from one commit, not deliberate legacy referents. The plugin renamed `sp-bootstrap` → `super-bootstrap` on 2026-05-02 (`16ac4b0`, marketplace-layout restructure; the pre-rename name survives only in the 2026-05-01 initial extract `486e861`). All seven lines were **added** two days later by `8334a05` (2026-05-04), authored under the already-renamed `skills/super-bootstrap/` path. So SKILL.md:324's "Older sp-bootstrap skeletons" names an era no downstream consumer ever installed — it reads as the same slip, and folds into this card's fix rather than standing as history.

Replacement name is settled, no judgment: sibling shipped assets already use bare `super-bootstrap` for the plugin (`bootstrap-plan.md:5` — "The core plugin pin (super-bootstrap)") and the namespaced slash form for a skill (`/super-bootstrap:harness-bootstrap`). Bare `super-bootstrap` is the in-convention replacement for all seven.

Rot-scan gap confirmed as described. `rename-map.md:48-50` § Skeleton headings / structure is literally `(none yet …)`; § Slash commands is scoped by its own coverage rule (line 20) to bare/`sb-`-prefixed **skill invocation** forms. No entry matches a bare plugin name in prose, so the Phase 2b rot scan (`SKILL.md:414` — "grep every pipeline-owned file in scope for each entry's `old` literal") cannot surface a consumer's surviving `{seeded by sp-bootstrap …}` line. The scan loop is section-agnostic ("each entry's old literal"), so a row is picked up wherever it is placed — section choice is organizational, not behavioral.

Family sweep — the seven hits are the whole family. No other asset carries a named-filler attribution (`grep "filled by\|seeded by"` across `assets/` returns only these lines plus `rules-frontend-skeleton.md:49`, which names no plugin). One coverage-rule extension the card missed: a whole-token grep for `sp-bootstrap` also hits the pre-rename **command** form `/sp-bootstrap` (real — `486e861:README.md:9`), and would propose the wrong replacement (`super-bootstrap`, missing the slash namespace). A paired `/sp-bootstrap` → `/super-bootstrap` row under § Slash commands is corrective, not scope creep — the map's own coverage rule (line 20) reaches it, mirroring the existing `/sb-super-bootstrap` → `/super-bootstrap` row.

Aim valid. No overlapping open card (DEBT-068 is the only card in `docs/work/`). No closed fork re-walked — `docs/decisions.md:58` rejects a version-driven migration *engine* while explicitly keeping the rename-map rot scan as the shipped residual; adding rows to that map lands inside the kept mechanism. That row is history-dimension and additive-only — do not reword it.

### Files (fix surface)

- `plugins/super-bootstrap/skills/harness-bootstrap/assets/claude-md-skeleton.md:116` — `sp-bootstrap` → `super-bootstrap`
- `plugins/super-bootstrap/skills/harness-bootstrap/assets/rules-frontend-skeleton.md:11,20,28,35,42` — same, five lines
- `plugins/super-bootstrap/skills/harness-bootstrap/SKILL.md:324` — seventh hit; "Older sp-bootstrap skeletons" → "Older super-bootstrap skeletons". Descriptive prose in § Legacy CLAUDE.md migration — no gate, no trigger, no behavior change
- `plugins/super-bootstrap/skills/harness-bootstrap/assets/rename-map.md` — add the bare-name row (`sp-bootstrap` → `super-bootstrap`, reason: pre-rename plugin name) plus the paired `/sp-bootstrap` → `/super-bootstrap` row under § Slash commands. Keep any new section's prose to placement only — a new *scan directive* would be behavior-shaping and pull the `skill-authoring.md` RED floor in; a data row under the existing procedure does not

### Doc Impact

none — confirmed unchanged after read. `docs/decisions.md:58` is the only doc mentioning the rot scan; it is an additive-only history row whose verdict is untouched by this fix. No spec narrates skeleton placeholder attributions (`grep "placeholder" docs/specs/ README.md` → no hits). No dogfood-harness counterpart: root `CLAUDE.md` § Rules lists real rules, carrying no `{seeded by …}` placeholder line, so the `repo-boundary.md` sync direction has nothing to mirror.

### Test Strategy: e2e

