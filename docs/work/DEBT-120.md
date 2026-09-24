# DEBT-120 — drain re-classifies every card in-model though render-board.py already encodes the spec (prompt-audit M8)

**Logged:** 2026-09-24 · **Source:** `/claude-api prompt-audit` over `plugins/super-bootstrap/**`; unverified at capture
**Problem:** `skills/drain/SKILL.md:36` (Shape 2) has the gateway Read `shared/classify-actionable.md` and derive `{action, intent, stage}` per card in-model. The plugin README (`:66`) calls that spec a total function, and `skills/todo/assets/render-board.py` already computes it mechanically — a model call doing deterministic work, with fork risk between the two lanes. The in-model judgment that genuinely remains is relation analysis + wave selection (`drain/assets/relations.md`) and the confirm gate.
**Area:** `plugins/super-bootstrap/skills/drain/SKILL.md`, `plugins/super-bootstrap/skills/todo/assets/render-board.py`, `bench/todo-board/`
**Prior:** A rows-emitting mode on `render-board.py` (e.g. `render-board.py <root> rows` → `id\taction\tintent\tstage`) behind the golden bench; drain consumes it and keeps its model call for relations/waves.

## Verdict — auto-fix · 2026-09-24

**Fix-shape:** systematic
**Probe-deps:** none
**Execution:** phased(skip: design) — depth: the codified todo script-lane pattern (mechanical encoding primary, in-model read as script-failure fallback — `skills/todo/SKILL.md` §Render behavior) applied to a second consumer; design settled below, so no design stage. Closure: spans script + golden bench + drain skill prose + shared-spec consumer text + plugin README, and the drain prose is behavior-shaping (RED micro-test per `.claude/rules/skill-authoring.md`), so a written step order earns its place; not inline.

### Repro (pinned)

"`skills/drain/SKILL.md:36` (Shape 2) has the gateway Read `shared/classify-actionable.md` and derive `{action, intent, stage}` per card in-model." "`skills/todo/assets/render-board.py` already computes it mechanically"

### Root cause (verified)

- `plugins/super-bootstrap/skills/drain/SKILL.md:36` (Shape step 2) instructs the gateway to Read `shared/classify-actionable.md` and "Classify EXACTLY per it" for every open card + test-queue entry. `drain/assets/eligibility.md:3` and `shared/classify-actionable.md:3,5,135` restate the same: drain's gateway reads the spec inline.
- `plugins/super-bootstrap/skills/todo/assets/render-board.py` already encodes that spec: `classify_card` (:361), `classify_queue` (:438), outward walls (`wall_owned_cards` :600), even the venue + lane partition (`venue` :717, `wired_lane` :754, `unwired_lane` :772). Its CLI (:908-914) exposes only board-render modes (`needme | full | discuss | cloud | device | harness`) — no machine-readable row output, so drain has nothing to consume and re-derives in-model.
- Fork risk is real, not hypothetical: the script's documented mechanical readings (header :12-40) deliberately diverge from a free in-model read — e.g. the fuzzy "unresolved ? directed at the user" Wait arm is not encoded (:21-24). Today todo's board and drain's admission can therefore classify the same card differently. Converging drain onto the script removes that fork; the non-encoded fuzzy arm is already covered by the mislabel doctrine (`eligibility.md` § Mislabel is fixed upstream, cited by the script header) and the runtime-wall backstop.
- Premise holds; aim valid. No overlapping open card (`grep render-board|classify-actionable docs/work/` → only this card + README). `docs/decisions.md:63` (intent axis retained as drain's gate) is compatible — the fix keeps the intent axis, only moves who computes it.

**Settled implementation calls (harness-internal, not user judgment):**
1. **Row columns follow the card's Prior** — `id`, `action`, `intent`, `stage`, plus what drain's guards already need from classification: a `source` column (card / test-queue / outward — test-queue rows carry no card ID) and a `held` flag (hard-blocked / outward-walled, so `eligibility.md` `outwardWalled` reads it instead of re-deriving). Outward rows may be omitted from rows mode instead of tagged — implementer's pick, stated in the script header.
2. **Venue stays out of rows mode.** The script's venue reads a built-in skeleton encoding and ignores placed `venue-map.md` edits (header :38-42, main :918-922), whereas `eligibility.md` § Admission gate has drain read the placed map. Emitting venue would silently change drain's admission for consumers with an edited map — a runtime behavior change the card did not ask for. Drain keeps `nextPhaseVenue` as-is; the bulk classification is what moves.
3. **Fallback = today's behavior.** Script failure (python absent, non-zero exit, empty stdout — same predicate as `todo/SKILL.md:61`) → drain falls back to the current in-model Read of `classify-actionable.md`. Invocation path mirrors todo: `python3 "${CLAUDE_PLUGIN_ROOT}/skills/todo/assets/render-board.py" "$(pwd)" rows`.

### Files (fix surface)

All native to this repo (plugin source; no imported copies in the surface).

- `plugins/super-bootstrap/skills/todo/assets/render-board.py:1-5,908-914` — add `rows` to mode choices + usage docstring; emit tab-separated rows after classify/couple/blast (before `render`), header documenting columns; stdout = rows only, stderr notes unchanged.
- `bench/todo-board/run.sh`, `bench/todo-board/expected/` (new `rows*.md` goldens over `fixture` + at least `fixture-outward` / `fixture-allblocked` for the `held` column), `bench/todo-board/README.md` (mode list :72) — golden-first: RED goldens before the mode lands.
- `plugins/super-bootstrap/skills/drain/SKILL.md:36` — Shape step 2: script lane primary, in-model Read as fallback; venue gate unchanged. Behavior-shaping → RED micro-test first.
- `plugins/super-bootstrap/skills/drain/assets/eligibility.md:3` (+ `outwardWalled` bullet :31 if the `held` column is consumed) — input now arrives from the rows lane.
- `plugins/super-bootstrap/shared/classify-actionable.md:3,5,135` — drain's consumption line ("gateway Reads it inline") becomes script-primary / read-on-fallback; the "script is the one consumer that encodes" line gains drain as a consumer of the encoding.

### Doc Impact

- `plugins/super-bootstrap/README.md:63` (drain row — mode rationale may note the script lane) and `:83` ("Both `todo` … and `drain` … embed it verbatim at dispatch" — stale once drain consumes the script).
- `docs/overview.md:41` (shared/ index — "classification SSOT for `todo` + `drain`") — read, still accurate; confirm at doc-sync. `docs/overview.md:64` drain flow — unchanged.
- `docs/specs/harness-architecture.md:338` — todo-only cost row; unchanged unless a drain cost row is added (optional, needs a measurement).

### Test Strategy: unit

Golden bench (`bench/todo-board/run.sh`) for the `rows` mode — failing goldens first. Drain SKILL.md prose change additionally takes the skill-authoring RED micro-test floor (no-guidance control) and `audit-harness-edits`.
