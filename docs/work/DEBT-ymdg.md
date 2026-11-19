# DEBT-ymdg — Whole-pipeline review of setup / harness-bootstrap / resolve-plugins; one card collects every retire candidate

**Logged:** 2026-11-15 · **Source:** user session — question whether the runway and resolve-plugins earn their cost, grounded on a local scan of `D:/Git` (26 repos: `.claude/settings.json`, `.mcp.json`, `git log -S` on each pin, runway receipts, scaffold-artifact fill)
**Problem:** Repos that stay three major runway versions behind keep working with the current plugin, which questions what the sync re-run and the tier-2 curation add. Retire candidate 1 — `resolve-plugins`: its three community pools (ECC / Composio / VoltAgent) have produced zero pins across the scanned repos; its real output is the techstack-language → `*-lsp` mapping, an occasional `frontend-design` (most `frontend-design` pins were hand-added), and one `modern-python@trailofbits` (QuickCut); MCP servers (`context7` ×15, `playwright` ×1) land through `.mcp.json`, outside it; the ECC python-rules finding only surfaced as cards (QuickCut DEBT-001, claude-tldr), since settings.json cannot seed rules. `claude-code-setup:claude-automation-recommender` already covers the codebase-scan recommendation. Side evidence from the same scan: 13 of 25 super-bootstrap repos carry a v2.x runway receipt with no reported breakage; `docs/terminology.md` holds almost no entries outside this repo; `CODING_STANDARDS.md` is headings-only in most repos; `docs/decisions.md`, `docs/specs/` and `docs/work/` cards are filled in most repos. Still to review on this card: the sync re-run (drift / rot / version / fact lanes), each skeleton doc, `AGENTS.md`, the 2a-hooks set, the scale module, `setup`'s seed cards.
**Area:** `plugins/super-bootstrap/skills/{setup,harness-bootstrap,resolve-plugins}/`, `docs/specs/harness-architecture.md`
**Prior:** Retire `resolve-plugins`; fold the LSP mapping into `harness-bootstrap` as a techstack-derived pin; leave other recommendations to `claude-code-setup`.

## Amendment — 2026-11-16 · user session

- Retire candidate 2 — `AGENTS.md`: the author holds no Codex subscription, so the foreign-executor contract has never run and cannot be tested here. User lean: drop.
- Direction to evaluate — move the shipped doctrine out of the consumer `CLAUDE.md` into plugin-shipped hooks, so it swaps with the plugin version and the sync re-run loses its main job. Facts: only `plugins/super-bootstrap/hooks/runway-version.sh` ships with the plugin today; the 2a-hooks (`commit-channel`, `consult-check-*`) are frozen copies placed in each repo, so they couple like `CLAUDE.md`. Claude Code docs (code.claude.com/docs/en/hooks): plugin `hooks/hooks.json` hooks merge with project hooks; `SessionStart` and `SubagentStart` both accept `additionalContext`, so a subagent can be given the doctrine too. Closed fork to hold against: `docs/decisions.md` row "Hook-based enforcement of the card-entry discipline (`entry-nudge`)" rejected a hook that re-pushed a pointer beside ambient `CLAUDE.md` — a redundancy finding, not a relocation finding.

## Amendment — 2026-11-16 · user session

- `docs/terminology.md` is off the retire list. It shipped 2026-10-29, so most scanned repos (13 on a v2.x runway) never received it — the empty count measured reach, not need — and it serves the doc-sync terminology lane.
- Scope widened by the user: review the plugin's positioning from first principles. The `superpowers` pairing is retired and `resolve-plugins` thins or retires, so the name and the "bootstrap" framing no longer describe the product; working frame is project-management scaffolding — light harness + doc-sync + doc scaffolding. `setup` and `harness-bootstrap` were split as install vs sync; merge is a candidate.

## Amendment — 2026-11-16 · user session (design direction, unverified where marked)

- Corrections to the earlier read. (1) The sync cost comes from mixed ownership inside one file (`CLAUDE.md` holds plugin doctrine + project content, so sync diffs and asks per section), not from the file living in the repo. (2) 8 of 10 sampled v2.x repos already route to `/super-bootstrap:commit|log|triage` in `CLAUDE.md`; only BeatStomper and ayva-stroker-lite still name superpowers skills — the consumer contract barely moved since v2.47, so the version advisory is mostly noise. (3) "Model-bound doctrine can be cut" is unmeasured; `docs/decisions.md` records the route line as load-bearing in 2/2 control runs — cut only by ablation bench. (4) Claude Code memory docs say some subagents start without project instructions — "CLAUDE.md reaches every subagent" needs a check against the sub-agents page.
- Preferred shape: split ownership, keep location. Doctrine moves to one file the plugin owns whole (an unconditional `.claude/rules/` file with no `paths:`, or a `CLAUDE.md` `@path` import — both confirmed in code.claude.com/docs/en/memory); `CLAUDE.md` keeps project content only. Sync becomes a whole-file copy + commit, no judgment. Hook injection stays a later option. Hooks (`commit-channel`, `consult-check-*`) move into the plugin's `hooks.json`.
- After a plugin update: nothing, unless the owned file's content hash differs (advisory keyed on hash, not version; copy runs on the user's command, never automatically) or the repo data layout changed (a numbered migration step).
- Migration of existing repos: state-detected, not version-detected. Steps — strip the owned sections from `CLAUDE.md` (the named section list), show any drifted lines for a keep/drop pick, place the owned file, remove repo hook copies + settings snippets, clear retired items (untouched `AGENTS.md`, `superpowers` pin, `harness-meta` block), replace the receipt with a layout number.
- Sunset mechanism (user requirement: escape hatch + self-retiring; unknown external users, several devices). Migration state lives in git, so one migrate + push covers every device. Permanent and tiny: each plugin hook checks for a legacy repo copy → no-ops (no double fire) and prints one advisory line. Temporary and heavy: the `migrate` skill ships for one major, then is deleted; its removal is a `docs/parked.md` entry triggered by the next major release. Escape hatch after removal: a manual recipe kept in the docs, plus installing the last release that carries `migrate` (marketplace ref-pin — unverified). Own-fleet check: a scan script lists unmigrated repos per device.
- Open: who owns `CLAUDE.md` § Rules summary and § Planning index (lean: project). Rename comes last, after measure → restructure.

## Verdict — surface · 2026-11-16

### Findings

- premise age: clean — no commit touched `skills/{setup,harness-bootstrap,resolve-plugins}/` or `docs/specs/harness-architecture.md` after 2026-11-15.
- root cause (need-check, confirmed): the gap exists as described. The sync cost follows from mixed ownership — the receipt's `covered` list holds ten `CLAUDE.md §` rows beside project-owned rows (`.claude/super-bootstrap-runway.json`), and `harness-bootstrap/SKILL.md` § Version-staleness signal forces "full drift re-check" on any version lag, so every plugin bump re-arms a per-section diff over a file the project also writes. Plugin-owned delivery has one instance today: `plugins/super-bootstrap/hooks/hooks.json` wires only `runway-version.sh`; `commit-channel` and the `consult-check-*` pair are frozen assets under `harness-bootstrap/assets/hooks/`, placed per repo (§ 2a-hooks).
- verified against the local fleet (`D:/Git/*/`, one directory level, 42 folders):
  - 25 `settings.json` files pin `super-bootstrap@super-bootstrap`; 16 repos carry a runway receipt; 10 of the 16 are v2.x (2.22.0–2.51.1), 6 are v5.x. Nine pinned repos carry no receipt at all.
  - Zero pins come from the three community pools (`resolve-plugins/SKILL.md:54-56`). Pins present: `pyright-lsp` ×8, `typescript-lsp` ×6, `rust-analyzer-lsp` ×1, `frontend-design` ×8, `modern-python@trailofbits` ×1.
  - `/super-bootstrap:commit` is named in 24 `CLAUDE.md` files; `superpowers:` skill names remain in 3 (DungeonCLI, ayva-stroker-lite, ok-claude); `superpowers@claude-plugins-official` is still pinned in 10 `settings.json` files.
  - `AGENTS.md` exists in 8 repos; `docs/terminology.md` in 5.
- the two unverified items:
  - subagent reach — settled at local-reference grade: `~/.claude/guidelines/claude-shape/layer-placement.md:64` (citing the official sub-agents page § What loads at startup) states a dispatched subagent loads the full memory hierarchy, project rules included; only the built-in `Explore` and `Plan` agents skip it. Lines 51 and 53 of the same file state an `@path` import and a `.claude/rules/` file without `paths:` both load eagerly and are re-injected. So an owned doctrine file in either form reaches custom and general-purpose subagents. Not probed here.
  - marketplace ref-pin — not settled. No repo doc or local reference states it, and this lane holds no web tool. Local fact that bears on it: the device plugin cache keeps every version ever installed (`~/.claude/plugins/cache/super-bootstrap/super-bootstrap/` holds 2.29.6 through 5.10.6), which helps a device that already had the release and does not help a new one.
- closed forks in `docs/decisions.md` the design touches:
  - "A version-driven update/merge engine for the bootstrapped runway" — collides. Its ground is "`harness-bootstrap` re-run already re-syncs"; the card removes that re-sync's judgment and adds a `migrate` skill with a numbered layout step. The design re-opens this row and needs an additive annotation naming which ground died.
  - "Carry the runway version-staleness signal as a `harness-bootstrap`-placed frozen hook asset" — supports the hook move: it already ruled a placed hook cannot resolve the installed plugin and lags until the re-run it asks for.
  - "Hook-based enforcement of the card-entry discipline (`entry-nudge`)" — no collision for the preferred shape (file relocation, no injector); it binds the later hook-injection option. Its text also asserts ambient `CLAUDE.md` is the verified carrier (10/10 controls) — a measurement on `CLAUDE.md`, not on a rules file or an import.
  - "Carry the de-routed discipline fences ... as path-scoped `.claude/rules/*.md` files" — no collision: it closed `paths:`-fired rules; a rule file without `paths:` is ambient.
  - "Split the shipped harness into a runtime-neutral core plus per-runtime adapters" — `AGENTS.md` is that row's "shipped instead". Dropping it removes the row's shipped residue and needs an annotation.
  - "Switch the shipped `consult-check-check` injection ... to once per session" and the `commit-channel` rows — unaffected by a location move; the behavior stays.
- overlap: `docs/parked.md` PARK-knda ("cut the harness-bootstrap re-run burden") fires on this card — its "Fires on" is the author opening this discussion. Its thread (`GAP-naw8`, restorable from the parent of `4fce16c`) holds two verdicts with options (a)–(d). Its named pending probe — plugin `SessionStart` / `SubagentStart` output reaching the main session, a subagent and a compacted context — has not run, so the card's hook-injection facts stand at docs grade only.
- blast the card does not name:
  - cloud reach. `harness-bootstrap/SKILL.md:242` and `:616` state a cloud session loads no repo-declared plugin. Placed hooks are committed repo files and fire there; hooks moved into the plugin's `hooks.json` fire only where the plugin is installed. Moving `commit-channel` and `consult-check-*` trades the version coupling for that loss. The owned doctrine file stays in the repo, so the doctrine itself keeps cloud reach.
  - scope of fire. A plugin hook runs in every repo where the plugin is enabled, bootstrapped or not; each moved hook needs the same state check `runway-version.sh` uses to stay silent.
  - nine pinned repos with no receipt: state-detected migration must handle "pinned, never receipted" as its own state.
  - `docs/overview.md` carries the `harness-meta` block whose only reader is `resolve-plugins`, and § Problem states the positioning the card revises ("curated skill/MCP/hook picks").
  - `resolve-plugins/SKILL.md:57` already consumes `claude-code-setup:claude-automation-recommender` as a candidate source; a retire removes that consumer and the `tech-curation` seed card in `setup/assets/seed-cards.md`.
- scope reach (tracked files naming each surface): `harness-bootstrap` 98 · `commit-channel` 37 · `consult-check` 35 · `AGENTS.md` 32 · `resolve-plugins` 26 · `super-bootstrap-runway.json` 24 · `super-bootstrap:setup` 17 · `harness-meta` 8. The set spans both manifests (`plugin.json`, `marketplace.json` — `/release` lane), root and plugin READMEs, root `CLAUDE.md` § Dispatch (the foreign-executor bullet), `.claude/rules/repo-boundary.md`, `docs/specs/harness-architecture.md` §4–§6, `docs/overview.md`, `docs/terminology.md`, `docs/techstack.md`, and nine `bench/` fixture sets that embed the current skeleton shape. All touched skill files are native to this repo; the `.claude/guidelines/` reads above are served copies and take no edit here.
- card corrections:
  - "13 of 25 super-bootstrap repos carry a v2.x runway receipt" — this read finds 10 v2.x among 16 receipts (25 is the pin count). The later amendment's "10 sampled v2.x repos" matches 10. A nested or off-`D:/Git` receipt would not show in a one-level read.
  - "only BeatStomper and ayva-stroker-lite still name superpowers skills" — a `superpowers:` grep over `CLAUDE.md` finds DungeonCLI, ayva-stroker-lite and ok-claude; BeatStomper does not match that literal.
  - the pin list omits `fullstack-dev-skills@fullstack-dev-skills` ×2 and `ui-ux-pro-max@ui-ux-pro-max-skill` ×1. Their origin (hand-added or `resolve-plugins`) is not checked here; `git log -S` on each settles it.
  - "the foreign-executor contract has never run and cannot be tested here" — a `codex` CLI is on this device's PATH and `~/.codex/` exists. Whether a subscription backs it is the author's fact; this read did not open the credential file.
- attempted: static reads and one-level fleet greps only. No `§ Probes` table exists in `docs/techstack.md`, so no probe ran. Stopped at the verdict because the card is a positioning and retire review: criteria 2 and 4 fail (cross-surface contract change, product judgment), and it re-opens a closed fork.

### Decision needed

- How this card proceeds: it holds two retire calls that are ready to rule and one restructure whose carrier is unmeasured.
- options:
  - A — split and sequence. Rule the two retires now, each as its own card (`resolve-plugins` → LSP mapping folded into `harness-bootstrap`; `AGENTS.md` drop). Keep this card for the ownership split, gated on the measurements below; migration and sunset follow the split; rename last.
  - B — one redesign. Keep every item on this card and settle the whole pipeline in a single `## Design` block before any retire lands.
  - C — retires only. Land the two retires, return the restructure to `docs/parked.md` under PARK-knda with the new evidence, and keep the per-section sync.
- recommendation: A — the retires rest on fleet evidence already in hand and shrink the surface the restructure must migrate; the ownership split changes the doctrine's carrier, and the only carrier measurement on record is for ambient `CLAUDE.md`.
- rulings A or B also need from the author:
  - re-open the "version-driven update/merge engine" row for the `migrate` skill and layout number, or hold migration to the existing re-run.
  - accept the cloud-session loss of `commit-channel` and `consult-check-*` when they move into the plugin, or keep those three placed.
  - `AGENTS.md`: drop on the stated ground, or first confirm whether the installed `codex` CLI can run the contract once.
- settles by: positioning, the retire list and the row re-open need the author's product and preference authority. The measurements, each sized:
  - marketplace ref-pin — `inline read` of the Claude Code plugin-marketplaces docs page.
  - origin of the three unaccounted pins and the nine receipt-less repos — `inline read` (`git log -S` per pin, per repo).
  - doctrine carrier equivalence (owned rules file without `paths:`, or `@path` import, versus the same text in `CLAUDE.md`; main session, general-purpose subagent, post-compact) — `dispatched probe`, reusing the control-run shape behind the `entry-nudge` row.
  - plugin `SessionStart` / `SubagentStart` reach, PARK-knda's pending probe — `dispatched probe`; needed only if hook injection is taken up.
  - which doctrine lines are cuttable — `phased build` (ablation bench with fixtures).

## Design — 2026-11-16

Ruling: option A — split and sequence. The author re-opened the "version-driven update/merge engine" row of `docs/decisions.md` ("ok go", on the brief naming that row); the row takes its `Reopened` note in the commit that lands the migration.

- **Retires leave this card.** `resolve-plugins` → DEBT-5q1w. `AGENTS.md` → DEBT-wf8f, dropped on the author's ground (no Codex subscription; the contract cannot run here).
- **This card keeps the ownership split.** Doctrine moves to one file the plugin owns whole; `CLAUDE.md` keeps project content only; sync becomes a whole-file copy on the user's command, advisory keyed on content hash. Gate: the carrier-equivalence probe from the Verdict (owned rules file without `paths:` or `@path` import versus the same text in `CLAUDE.md`; main session, general-purpose subagent, post-compact) holds within the control-run margin.
- **The three placed hooks stay placed** (`commit-channel`, `consult-check-*`). They are whole-file plugin-owned already, so the same copy step syncs them, and cloud sessions — which load no repo-declared plugin — keep them. Settled by the gateway's climb: the Verdict's cloud-reach finding.
- **Migration and sunset follow the split**, as the third Amendment states them: state-detected `migrate` skill shipped for one major, its removal a `docs/parked.md` entry fired by the next major release, a permanent manual recipe, and a per-device scan for unmigrated repos. Ref-pin escape hatch confirmed — code.claude.com/docs/en/plugin-marketplaces: a git-based plugin source pins to a `ref` or `sha`.
- **`setup` + `harness-bootstrap` merge** into one init once the sync judgment is gone. **Rename last.** `docs/terminology.md` stays.
- **PARK-knda is consumed by this card** and leaves `docs/parked.md`; its `GAP-naw8` thread restores from the parent of `4fce16c`. Its plugin `SessionStart` / `SubagentStart` probe is needed only if hook injection is taken up later.
- Still open on this card: owner of `CLAUDE.md` § Rules summary and § Planning index (lean: project); the origin of the three unaccounted pins and the nine receipt-less repos (`inline read`); which doctrine lines are cuttable (ablation bench, after the split).

## Progress — 2026-11-16

Design is settled; the two retires live on DEBT-wf8f and DEBT-5q1w. Next step on this card: build the carrier-equivalence probe as a new `bench/` fixture — no reusable fixture exists for the earlier control-agent run; the nearest skeletons are `bench/consult-hook/` (headless arms) and `bench/spike-route/`. It creates new files only, so it can run beside the retire builds.

- Probe terms stated to the author: carriers `CLAUDE.md` / owned rules file without `paths:` / `@path` import; contexts main session / general-purpose subagent / post-compact; 2 reps each, 18 headless runs, one round; pass = each new carrier within one miss of `CLAUDE.md`; after the round, stop and report — the author decides any further spend.
- After the probe passes: ownership split → `migrate` + sunset → merge `setup` into `harness-bootstrap` → rename.
- The Verdict's counts supersede the origin block's: 16 receipts, 10 on v2.x; repos still naming superpowers skills are DungeonCLI, ayva-stroker-lite, ok-claude.

## Plan — 2026-11-19

The carrier-equivalence probe, as a new `bench/carrier-equivalence/` fixture. DEBT-wf8f and DEBT-5q1w are resolved (`1a1c999`, `facbe99`); this is the card's next step.

1. Fixture — reuse the `bench/assertion-liveness/` shape (consumer-shaped repo with the shipped runway placed, cold config dir), not `consult-hook` / `spike-route`: it already places the whole runway and isolates the operator's own configuration. One seeded BUG card and one small source file give the task something to pick up.
2. Arms — the doctrine text is byte-identical across arms; only its carrier moves. `claudemd`: the shipped `CLAUDE.md` whole. `rules`: the plugin-owned sections cut into `.claude/rules/harness.md` with no frontmatter, `CLAUDE.md` keeps project content. `import`: the same sections in `.claude/harness.md`, pulled in by an `@.claude/harness.md` line. `none`: the sections removed and placed nowhere — the control that proves the score can miss.
3. Contexts — `main`: one headless turn. `subagent`: the main turn dispatches one general-purpose subagent with the task verbatim; the subagent's own text is scored, and a run whose dispatch prompt is not the task verbatim is invalid. `compact`: a filler turn, then `/compact` on the resumed session, then the task; a run with no compaction marker is invalid, not a miss.
4. Readings, two per run — load evidence: a fixture `InstructionsLoaded` hook logs each instruction file and its `load_reason`; behavior: the reply to "pick up the card, state how you will proceed, change no file" carries a route line naming a cluster.
5. Round — 3 carriers x 3 contexts x 2 reps = 18 runs, plus `none` x `main` x 2 = 20, one model, one round. Pass = each new carrier within one miss of `claudemd`, both `none` runs miss, no invalid run left unexplained. After the round: stop and report; the author decides any further spend. The two control runs are over the 18 stated on this card's Progress — without them a clean 18 cannot tell a working carrier from a loose score.
6. Open facts the round settles or flags: whether `/compact` runs through `claude -p --resume` (docs give only the Agent SDK form — smoke-tested before the round); whether an `@path` import is re-injected after compaction (docs do not say).

## Progress — 2026-11-19

The bench is built (`bench/carrier-equivalence/`, scorer selftest green) and one 20-run round ran. **The round is invalid — it measured no carrier.** Its outdir sat under Claude Code's temp tree (the session scratchpad), and there no run logged a project instruction file: all 20 `instructions.log` files hold only the operator's `~/.claude/CLAUDE.md`, where the smoke run under `%TEMP%/ce` logged the fixture's `CLAUDE.md` at `session_start`. The scored table (`claudemd` 3 hits of 6, `rules` 0 of 6, `import` 0 of 6, `none` 0 of 2) is therefore not a carrier verdict; the three `claudemd` hits came from runs that opened `CLAUDE.md` with the Read tool. Why that location suppresses project instructions is unverified. Next step: re-run the round with the outdir outside that tree — the author decides the spend (20 runs, sonnet).

- Settled by the smoke runs, valid: `/compact` runs headless both through `claude -p --resume` and as a stream-json user turn in one process; after an in-process compaction `CLAUDE.md` reloads with `load_reason` `compact` and an `@path`-imported file reloads with `include` (one observation each).
- The `compact` context is one process with three turns; a fresh `--resume` process reloads every instruction file at `session_start` and would measure resume, not compaction.
- Unresolved contamination: the operator's `~/.claude/CLAUDE.md` loads in every run despite the cold config; it is constant across arms and both `none` runs missed, so the score discriminates against it.
- The behavior regex was widened after a smoke run showed `**Cluster:** 1` scored as a miss; the `none` runs are the check that it did not become loose.
- A subagent logs no `InstructionsLoaded` line of its own, so the `subagent` context has a behavior reading only.

## Progress — 2026-11-19 · re-run

The round re-ran with the outdir at `%TEMP%/ce-round2` (outside Claude Code's temp tree) and **passes**: 20 runs, sonnet, all valid, every carrier row `loaded 1`. Behavior misses — `claudemd` 0 of 6, `rules` 0 of 6, `import` 0 of 6, `none` 2 of 2. The carrier-equivalence gate of the Design block holds; the ownership split is open, on the author's go.

- No run opened a carrier file (`CLAUDE.md`, `.claude/rules/harness.md`, `.claude/harness.md`) with Read, Grep or Glob, in the main session or a subagent — the confound that produced the invalid round's three hits is absent.
- Post-compact re-injection, two observations each: `CLAUDE.md` and the `paths:`-less rules file reload with `load_reason` `compact`; the `@path`-imported file reloads with `include`.
- Limits: two reps per cell, one model; the `subagent` context has a behavior reading only (its `loaded` value is the main session's); the operator's `~/.claude/CLAUDE.md` still loads in every run, and both `none` runs missed with it present.
- Still unverified: why an outdir under `%TEMP%/claude/` suppresses project instruction files.
- Next step: the ownership split — its carrier (rules file or `@path` import) is a free choice on this evidence; then `migrate` + sunset → merge `setup` into `harness-bootstrap` → rename.
