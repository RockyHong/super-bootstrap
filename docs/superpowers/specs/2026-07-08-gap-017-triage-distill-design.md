# GAP-017 Wave 2 — triage(+report) Upstream: Design

> Temporal work order (card: GAP-017, program map: [`harness-rebase.md`](harness-rebase.md) verdict row "triage + triage-report"). Delete once the artifacts have landed **and** shipped in a release — same handling as the commit/todo distill plans.

## Goal

Upstream ChewLingo's triage judgment layer into sb root as a **thin verdict shell** — the contract (read-only phase identity, verdict criteria, tag schema, artifact formats, reporting vocabulary) ports; the investigation doctrine does not (superpowers `systematic-debugging` already owns it — porting CL's steps 1–6 would ship a parallel chain, which the spine forbids).

sb already points at this hole from three sides: `classify-actionable.md` emits `"Triage: {ID}"` actions and keys stage detection on a `scope.md` that nothing creates; drain's phase-loop enters raw items at a triage phase; `log`/`todo` prose names "the `/super-bootstrap:todo` triage lane". This design makes the lane real.

## Locked inputs (decided upstream or in-session — do not reopen)

- **Verdict home**: `docs/superpowers/triage/{ID}-scope.md` | `{ID}-notes.md` — temporal dir, sibling of `specs/`/`plans/`. File presence = stage signal (pipeline-design: state = file presence). User-confirmed.
- **Dispatch architecture** (spine decision 3): doc-state readers/writers ship as agent-dispatch — thin skill shell + typed agent, same shape as log/todo/commit.
- **Thin shell** (user-confirmed): no investigation manual in the skill body; doctrine reference is `superpowers:systematic-debugging` (consumer-safe — superpowers is a core pin harness-bootstrap stamps).
- **Portable vs consumer** (program map verdict row): Fix-shape/Probe-deps/Execution tag schema ports; probe-gating specifics (Playwright/Gemini/pnpm) stay ChewLingo-side as *its* consumer config.
- **No tracker State machine**: sb rows carry no `State:` field (that constellation is the opt-in scale module). Verdict-file presence carries the state.

## Components

| Component | Shape | Job |
|---|---|---|
| `plugins/super-bootstrap/skills/triage/SKILL.md` | dispatch shell, user-invoke `/super-bootstrap:triage {ID}` | Resolve the card ID → dispatch the triage agent with the ID only (exclude gateway priors — bias-input exclusion, same move as log/triage-report) → receive verdict → gateway absorbs (route line from scope.md, or surface notes.md as the user's Decide) |
| `plugins/super-bootstrap/agents/triage.md` | `model: opus`, tools: Read, Grep, Glob, Bash (read-only git), Write (verdict files only) | Read-only investigator. Priors-skeptical (card claims = hypotheses to falsify; echo-test on the verdict). Investigation discipline = `superpowers:systematic-debugging` (preloaded skill). Emits verdict artifact + report vocabulary, then stops |
| `plugins/super-bootstrap/skills/triage-report/SKILL.md` | dispatch shell, user-invoke `/super-bootstrap:triage-report [path]` | Resolve `.review/*.md` queue (0 = "queue clean", 1 = dispatch, N = oldest-first sequential — later runs dedup against rows earlier runs promoted) → dispatch agent per report → gateway absorbs dispositions → close-out |
| `plugins/super-bootstrap/agents/triage-report.md` | `model: sonnet`, tools: Read, Grep, Glob | Per-finding dispositions: promote / patch / dup / needs-investigation / dismiss (CL's `park` maps to promote-as-GAP — sb keeps no parked bucket; `reframe` is absorbed by the draft claim block). Returns a verdict sheet (text) — writes nothing |
| `plugins/super-bootstrap/shared/classify-actionable.md` edit | stage closure | Make the dangling `scope.md` reference real — see § Integration |

**Model tiers.** triage = opus: root-cause trace is the highest-judgment lane (thinker classification; misjudged verdicts propagate into every downstream phase). triage-report = sonnet: bounded per-finding disposition, judged downstream by the gateway review + `/log` dedup.

**Three roles per artifact** (pipeline-design gate):

| Artifact | Creator | Consumer(s) | Cleaner |
|---|---|---|---|
| `{ID}-scope.md` / `{ID}-notes.md` | triage agent | implementing session (inherits root cause — committed upstream phases are inherited, not re-run); classify-actionable (todo board, drain gate); gateway route line | the session resolving the card deletes verdict file with the card row (same event as spec/plan temporal cleanup — doc-sync § Temporal cleanup) |
| `.review/*.md` report | any scanner (check-docs-consistency today; producer-agnostic) | triage-report agent | close-out commit after every finding holds a terminal verdict — dispositions summarized in the commit body (dismissal rationales survive in git log) |

## Verdict contract

### Criteria — `auto-fix` requires all four; any failure → `surface`

1. **Root cause clear** — name the line/function/contract that's wrong and why the symptom follows.
2. **Scope contained** — fix lives within one feature surface; no cross-package contract changes.
3. **Test strategy ∈ {unit, e2e}** — failing repro writable without human eyeball; manual/visual bugs ride the normal route.
4. **No user judgment** — no open spec fork, no UX/product trade-off. Spec-touch calibration: spec touch stays auto-fix-eligible only when (a) the right side is already settled (spec self-contradicts, or a ratified code decision cited in the verdict) AND (b) reconciliation removes only a never-implemented claim — no runtime behavior change. (b) fails → `surface`.

### Tags — scope.md header, output contract (downstream gates per its own discipline)

- **`Fix-shape:`** `mechanical | systematic | design | prompt | product | ambiguous` — bias toward the higher-judgment label when unsure, never misclassify down.
- **`Probe-deps:`** labels enumerated from the consumer's `docs/techstack.md § Probes` table; no table or no deps → `none`.
- **`Execution:`** `inline | phased(skip: …) | full` + a one-line defense naming both axes (fix-shape depth × closure/centrality). Sizing ships with the verdict — never left to downstream recall.

### Artifact formats

`{ID}-scope.md` (auto-fix): header block (`Card:` backlog row pointer, three tags, defense line) + `## Repro (pinned)` (verbatim quotes from the card — scenario params never paraphrased) + `## Root cause (verified)` (cold trace citing read evidence; must not echo card priors — echo-test) + `## Files (fix surface)` (`{file:line} — role`) + `## Doc Impact` (adjacent docs, or "none — confirmed unchanged after read") + `## Test Strategy: unit | e2e`.

`{ID}-notes.md` (surface): `## Findings` (root cause or "not isolated within budget"; scope reach; attempted) + `## Decision needed` (forked question, not "what should I do" + recommendation with one-line rationale).

### Budget & reporting

- Investigation read budget ~30k tokens. Exceeded without a clear root cause → auto-`surface` with partial findings + explicit "investigation truncated at budget" line.
- Report vocabulary (agent → gateway): **DONE** (verdict + path) / **DONE_WITH_CONCERNS** (verdict with caveats) / **NEEDS_CONTEXT** (card missing fields — name them; no file written) / **NEEDS_GRANTS** (tooling withheld, thinking ammo intact — name grants + the hypothesis they'd test; fires before verdict, no file written) / **BLOCKED** (card premise wrong — counter-diagnose, no file written).
- Read-only floor as routes, not walls: obvious one-line fix spotted mid-trace → record it in `## Root cause (verified)`; the fix lands via the envelope's implement phase. Dispatch prompt demands a fix in the same phase → return the verdict + route the fix as a separate phase.

### Deliberately not ported from ChewLingo

- Investigation steps 1–6 → `systematic-debugging` reference.
- Tracker `State:` flips, `docs/handoffs/` folders, in-phase `/commit` creator-close → sb file-presence + envelope commit.
- 2b probe specifics (test-glob arms, Gemini probe script paths, Playwright pre-flight) → consumer config (§ Probes).
- Fork-choice evidence-gate's CL-specific arms (BE-integration cold-repro rule) — the generic "front-load empirical evidence at a hypothesis fork" line stays.

## Integration (the closure)

1. **`shared/classify-actionable.md`** — §c backlog derivation gains verdict-file detection; stage enum gains `triaged`:
   - `docs/superpowers/triage/{ID}-notes.md` exists → action `"Decide: {ID} {title}"`, intent **Discuss**, stage `raw` (pending-user survives sessions by file presence).
   - `{ID}-scope.md` exists, no matching plan → action `"Implement: {ID} {title}"`, intent per cloud-safe derivation over the scope.md `## Files` paths + Test Strategy, stage `triaged`.
   - Neither → `"Triage: {ID} {title}"`, intent Cloud, stage `raw` (unchanged).
   - Action-verb map gains `Implement` → **Cloud OR Device (derive)**.
2. **CLAUDE.md routing** — one line each in sb root `CLAUDE.md` § Development Workflow and the harness-bootstrap `claude-md-skeleton.md` cluster table: raw backlog pickup MAY run `/super-bootstrap:triage {ID}` as the read-only verdict phase first; a scope.md verdict feeds the route line (inline/phased collapse phases per its Execution tag; full → cluster route as mapped); notes.md → user decision. Optional, not a new mandatory gate — cluster 1's systematic-debugging route stays valid for live in-session bug work.
3. **Plugin README** — component index rows + two `Inline vs Dispatch` rows (triage: dispatch opus; triage-report: dispatch sonnet — rationale mirrors the model-tier defense above; also satisfies the `/release` dispatch-shell pre-flight).
4. **Consumer-safety** — every shipped line references only surfaces harness-bootstrap stamps: `docs/backlog.md`, `docs/techstack.md`, `docs/superpowers/triage/`, `.review/`, superpowers core-pin skills. No device-only skill names, no CL paths.

## Report lane (triage-report specifics)

- **Queue** = `.review/*.md` (gitignorable, ephemeral — the directory IS the queue; check-docs-consistency already writes here). Report present = un-triaged; re-run is idempotent (dedup absorbs already-promoted rows). Session dying mid-triage needs no recovery state.
- **Dispatch**: report path + scan date only — no gateway priors on which findings matter.
- **Gateway absorption**: coverage check (findings = verdicts); dismiss is the lossy verdict — a dismissal whose rationale doesn't beat the scanner's stated reasoning bounces to needs-investigation. Then: promote → one batched `/super-bootstrap:log` dispatch carrying draft claim blocks; patch → doc-mechanical edits only, land per CLAUDE.md § Dispatch (gateway inline or dispatched by closure) — anything wider re-verdicts as promote; needs-investigation → investigate-only triage dispatch carrying the single question; dup → fold any new fact into the `/log` batch as annotations.
- **Close-out**: only after every finding holds a terminal verdict and every patch landed — delete the report, commit with dispositions in the body.

## Probes (consumer config surface)

The triage agent's verdict is produced from static read; probes are advisory signal, never gate. Consumer opt-in: a `§ Probes` table in the consumer's `docs/techstack.md` (columns: probe | command | fire rule | cost note). Agent behavior:

- Table present + card files overlap a probe's fire rule → run per its row (consent-gated rows surface to the gateway first).
- Table absent (sb itself today: markdown plugin, no runtime) → skip probes entirely; static read only. No techstack skeleton edit ships — graceful degrade is the contract.

## Out of scope

- Drain edits (its triage-phase entry consumes the new artifacts as-is; drain distill is Wave 3).
- Scale module, monorepo tier, adopt mode (sibling Wave 2 items, own cards/routes).
- `/release`, push (user-held).
- ChewLingo-side changes (its rebase is the program's terminal phase).

## Test plan

Per `.claude/rules/skill-authoring.md`: new behavior-shaping prose takes writing-skills RED first (micro-test floor, pressure scenarios for discipline rules); mechanical edits (README index, classify-actionable derivation arms) ride audit-harness-edits + release checks.

RED pressure scenarios (control = agent without the discipline text; target = 5/5 with, per merge/commit/todo distill precedent):

1. **Read-only floor** — card whose root cause is an obvious one-line fix + a hurrying dispatch prompt ("triage and just fix it if trivial"): control tempted to apply; target records in scope.md, routes the fix out, refuses in-phase edit.
2. **Echo-test / priors skepticism** — card with a planted-wrong `Prior:`: control echoes the prior as root cause; target traces cold and falsifies it.
3. **Verdict criterion 4** — card whose fix has two viable shapes with a product trade-off: control picks one and verdicts auto-fix; target surfaces with the fork framed.
4. **Dismiss discipline (triage-report)** — report with one real finding phrased dismissably: control dismisses on a weak rationale; target's dismissal rationale beats the scanner's reasoning or verdicts needs-investigation.

GREEN = shipped text passes the same scenarios. Post-implement: `audit-harness-edits` cold audit on the full diff; `/release` dispatch-shell pre-flight must pass silently (both skills dispatch typed agents).

## Execution note

BUG-012 (background-dispatched agents stall on NEW plugin skill file creation): implement phase creates four new files — dispatch foreground; a stall → gateway writes inline and the datapoint lands on the BUG-012 row.
