# GAP-045 bench v2 — retrieval-awareness A/B findings

> **SSOT / revisit entry point.** This file is the durable single home for the GAP-045 experiment's outcome — verdict, numbers, caveats, inherited build constraints, build record, annex lift, reusable harness. The temporal spec + research-annex files were deleted at close (2026-07-05) per the specs contract; still-load-bearing annex evidence lives in § Annex lift below, and git history holds the full spec text (pre-registered gate, probe design). Raw data: `bench/runs-gap045/`.

**Date:** 2026-07-05 · **Tier:** sonnet (headless `claude -p`, stream-json) · **Runs:** 98 scored (15 probes × arms × 2 replicates + 8 hermetic B6 reruns; 3 contaminated in-repo runs archived unscored)
**Spec:** pre-registered gate spec (temporal, deleted at close — git history) · **Probes:** `bench/probes-gap045.jsonl` (9 should-consult / 6 should-NOT) · **Env:** decontaminated consumer-shaped fixture (`bench/make-fixture.sh`), lore via device plant, map derived fresh from plant, per-run hermetic reset.

## Verdict — **forcedeval-compact passes all four pre-registered gate conditions; build earned**

| Gate condition (pre-registered) | pointer | forcedeval | forcedeval-compact |
|---|---|---|---|
| 1. Consult recall ≥ +30pt vs baseline | 16/18 = 89% (+22) **✗** | 18/18 = 100% (+33) ✓ | 18/18 = 100% (**+33**) ✓ |
| 2. TN ≥ 90% on should-NOT set | 12/12 ✓ | 12/12 ✓ | **12/12 = 100%** ✓ |
| 3. Answer quality non-negative (blind judge, 0/1/2) | 60/60 (+4) ✓ | 60/60 (+4) ✓ | **59/60 (+3)** ✓ |
| 4. Overhead ≤ ~500 injected tok, ≤ ~2s | ~+300 tok ✓ | **~+1,570 tok ✗** | **~+330-340 tok ✓**; latency +1.9s (borderline) ✓ |

Baseline pooled: consult 12/18 (67%, stable 6/9 both reps), quality 56/60, TN 12/12. Keyed-doc hit for both forced-eval arms: 18/18.

## Arms

- **baseline** — no wire. Fixture baseline is NOT saturated (unlike in-repo pilot): consult 67%, quality losses concentrated on lore-type probes (A3 push-vs-pull scored 0 from memory in r1; stochastic 1s elsewhere).
- **pointer** — grep keyword→doc map (mechanically derived: stem phrase + df≤2 tokens + backticked identifiers), inject ≤3 pointer lines on match. **Failed on ignorability:** r2 skipped consulting twice — including A5 where the keyed doc was literally in the injected list and the model answered from memory anyway. Trigger-level routing was also noisy (keyed-doc-in-list 6/9; trigger TN 2/6) but *behavior-level* TN was perfect — sonnet ignores irrelevant pointers. Passive nudge ≠ binding.
- **forcedeval** — full catalog + forced YES/NO per doc, every prompt (Anthropic skill-activation template, docs for skills). Perfect recall/TN both reps; killed by catalog size (absolute paths + why-text ≈ +1,570 tok/turn).
- **forcedeval-compact** — same forced YES/NO, catalog = path stems only (~340 tok). Recall/TN identical to full catalog: **the why-text is not load-bearing for YES/NO accuracy; stems carry it.** Consult-set runs are also faster + cheaper than baseline (direct read beats unaided crawl; e.g. A-probes ~8-17s vs baseline 15-77s).

## Mechanism finding

The active ingredient is the **forced evaluation moment**, not the information content: pointer (same docs listed, no forced YES/NO) is skippable and missed twice; forced-eval never missed across 36 consult cells (both variants × 2 reps). Reconfirms the Anthropic 55→100 lineage on our substrate, at a different task (docs vs skills).

## Caveats — carry these with the verdict

1. **Margins are thin at n=2.** Recall gate +33 vs +30: one baseline consult flip in either rep → +28 = fail. Latency +1.9s vs ~2s gate. Pre-registered repeat clause honored (full second replicate); a third replicate would firm the margin if the build decision is ever contested.
2. **Single-grader blind judge** (sonnet, per-answer vs key, arm-blind via shuffled letters). Rubric consistent across 3 judging rounds; no second judge.
3. **External validity: cold single-turn ≠ lived failure condition.** The measured layer-3 misses came from long interactive sessions under attention pressure; this bench measures cold-start consult behavior. Fixture baseline (67%) is likely an *overestimate* of mid-session baseline — the forced-eval margin may widen under real load, but that is untested here.
4. **In-repo runs are structurally contaminated** — recent-commits block leaks same-window fix commits; taste-center ambient catalogs the lore tree (in-repo pilot saturated 3/3 where fixture went 0/3). Never score bench runs cwd'd in this repo.
5. **B6 hermeticity incident:** the one task-doing probe leaked its written file across runs ("already exists" answers); all 8 B6 cells rerun after the per-run fixture reset landed. Q&A probes unaffected.
6. Probe set is Claude-Code/harness-domain heavy (by design — that's where the lore lives); generalization to non-harness doc corpora unmeasured.

## What the build inherits (design constraints proven here)

- Ship the **forced-eval consult check** shape: UserPromptSubmit, full compact catalog (stems only), forced YES/NO, every prompt. No grep pre-filter (pointer's map routing was the weak link; the model is the better classifier at equal TN).
- Catalog must be **mechanically derived from curated signal** (`bench/derive-map.sh` pattern: index tables / filenames; zero generated prose) and stay in the ~300-500 token band.
- The deriver, not the map, is the distributable (consumer repos derive from their own docs; the device-plant source was dropped 2026-08-10, § Source-scope revision).
- Keep the injector LLM-free bash (substrate + TN both proven).

## Build shipped (2026-07-05) — `consult-check` hook bundle

Productionized as `templates/consult-check-{sessionstart,check}.sh`, project-served via `must-have.txt` `hook:consult-check` (wiring + channel rationale: `docs/architecture.md` § Hook Distribution). Deviations from the bench arm, all repackaging not redesign: catalog derives by filename sweep + stem dedup instead of index-table parsing (derive-map's term/why extraction was pointer-arm machinery; forced-eval consumes paths only); delivery splits into SessionStart-derive → gitignored `.claude/.consult-catalog` → UserPromptSubmit-inject (staleness tolerance = one session); the injected block keeps the measured forced-eval sentence verbatim, with a path-resolution tail adapted for the multi-root catalog. Production-wiring spot-check in the decontaminated fixture (`bench/arm-prodbundle.json`, 5 probes) — **the canonical home of these numbers**: consult 3/3 keyed-doc hits (incl. A3 lore-reinvention), TN 2/2, A3 answer key-aligned — zero regression. SessionStart verified to fire in headless `-p` mode (2026-07-05). Deferred by design: mode-toggle skill (until measured friction), doc-health lint (candidate, flag-only), pressure-condition extension (below).

**Grouped-catalog revision (2026-07-07, GAP-052).** Catalog render changed from one line per doc to one line per directory (`- <dir>/: stem, stem, …`; known guideline trees carry a short hint), and sources widened from top-level `docs/*.md` to recursive `docs/**/*.md` with `superpowers/` excluded. Motivation (lived skew, ChewLingo): per-line rendering let the 30-file device plant fill ~70% of the 1700-char budget while 28 nested project docs stayed invisible — the catalog read as a lore index with near-zero project signal. Grouping keeps **every stem** (stems are the measured recall carrier — § Arms, forcedeval-compact) and cuts only repeated path prefixes: ChewLingo 45 lines/1694 chars with 28 docs invisible → 9 lines/1614 chars with all docs listed; this repo 1170 chars, nothing dropped. The grouped line is an untested deviation from the per-line measured arm, so the 5-probe prodbundle spot-check was re-run against the revised bundle (`__r2` runs): consult 3/3 keyed-doc hits, TN 2/2, A3 answer grounded in the keyed doc — zero regression. Environment delta vs the 2026-07-05 originals: the device `model-reminder` SessionStart hook (landed 2026-07-06 batch) now also fires in fixture runs — orthogonal to consult scoring, and ceiling scores on both sides moot the confound; device-hook bleed-through is now a recorded decontamination channel (`bench/bench-decontamination.md`). Index files stay excluded and the forced-eval sentences stay verbatim; "inject a pointer to the index instead" was evaluated and rejected — it reintroduces the measured-dead passive-pointer hop (the catalog *is* the index, materialized into context).

**Source-scope revision (2026-08-10, GAP-123).** The derivation's source set narrowed from three trees to one: project `docs/**/*.md` only, dropping project `.claude/guidelines/**` and the device plant `~/.claude/guidelines/**` (with them, the stem-dedup pass and the per-tree hint table). Motivation is measured composition, the same disease GAP-052 caught at per-line granularity and fixed only at the render layer: across the seven consumer trees on the author's device the plant was a **fixed 943 chars in every catalog, 62–72% of the render**, against 49–200 chars of the project docs the bundle exists to surface (`claude-tldr`: 943 vs 49). Lore's reach never depended on this listing — `/load-harness-principles` enumerates axiom + claude-shape through their `index.md` catalogs, and each *wired* `work-discipline` principle has its own path-scoped carrier — four are cold-ref-by-design with no wire, three of which lost their de-facto ambient reach here (parked as GAP-124). Post-change catalogs render 49–585 chars, so the 1700-char cap no longer binds anywhere.

**The 5-probe prodbundle spot-check was deliberately NOT re-run.** Probe A3 keys on a lore doc and would now score as a regression, but the arm cannot measure this change: its fixture's baseline is *no wire at all*, while the wires this revision relies on (`/load-harness-principles`, `/audit-harness-edits`, the `harness-author` + `harness-audit` hooks, the `harness-editing` + `lore-editing` rules) do not exist in it. Re-running would score a configuration that no longer ships. The re-run condition below still holds for a change to the **injector** or the forced-eval sentences — neither was touched.

## Annex lift (research annex is temporal — still-load-bearing evidence moved here at cleanup)

- **Context rot mandates the tight injection budget** — recall degrades with token count across all models, distractors worsen it, bigger windows don't fix it; "smallest set of high-signal tokens" is Anthropic's stated optimum. Basis of the ~300-500 tok band. (Anthropic context-engineering post; Chroma 18-model study, verified 3-0.)
- **Placement matters for small injections** — short gold contexts are disproportionately lost mid-context (arxiv 2505.18148, verified 3-0; stronger companion claims refuted). The injected block rides UserPromptSubmit adjacent to the prompt, not sandwiched in tool noise.
- **Curation caution (AGENTS.md field study, arXiv 2601.20404)** — human-curated context files: −28.6% runtime; LLM-*generated* files: −0.5..−2% success, +20% cost. Why the deriver extracts curated signal only and generates zero prose; red line for any future doc-health lint (flag, never auto-rewrite).
- **OKF (feeds GAP-032):** zero-dep YAML-frontmatter + markdown-link *shape* confirmed real; its load-bearing query promise (deterministic mechanical queryability without embeddings) refuted 0-3, link-stability and redundancy-elimination also 0-3. Design target to prototype, not a mechanism to adopt.
- **LLM-pre-classifier 20% TN / Anthropic forced-eval 55→100 lineage** — already embedded in §§ Arms / Mechanism above.

## Reusable

`bench/probes-gap045.jsonl` + `arm-*.json` + `*-inject.sh` + `make-fixture.sh` + `run-gap045.sh` (hermetic, replicate-aware) + `score-gap045.sh`: a working blind-judged A/B harness for prompt-lifecycle injection quality. Re-run condition: any injector redesign, threshold contest, or a pressure-condition (long-context) extension.
