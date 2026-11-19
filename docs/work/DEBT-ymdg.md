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

## Plan — 2026-11-19 · ownership split

The ownership split, sequenced from a read-only closure scan of the repo. The author delegated the open picks ("you lean"); each is stated here and stays revisable until its phase builds. Out of this plan: `migrate` + sunset, the `setup` merge, the rename, cutting doctrine lines.

Picks:

- Carrier: `.claude/rules/harness.md`, no frontmatter. Shipped asset `harness-bootstrap/assets/harness.md` (named outside the `rules-*-skeleton.md` glob, which marks per-section seeded rules).
- Consumer `CLAUDE.md` keeps the H1, `Tech Stack`, `Commands`, `Rules (auto-load on file match)`, `Planning` — all project-owned, seed-once — plus the `Monorepo` block: it carries fill-in placeholders, and an owned file with per-repo content never matches the shipped bytes.
- `Coding Principles` moves into the owned file unconditionally, reworded to carry its own condition (read `CODING_STANDARDS.md` when the repo root holds one). A doctrine wording change — micro-test against a control.
- Links inside the moved text are re-based for `.claude/rules/` (17 repo-root-relative targets); the shipped doc skeletons' five anchors into `CLAUDE.md` doctrine sections re-point at the owned file.
- Advisory: the plugin-owned SessionStart hook compares the placed file with the shipped asset byte for byte after stripping CR — no stored hash, no version read. It covers the owned file and the three placed hook scripts. The hook file is renamed off `runway-version`.
- Receipt: file and four fields stay. `covered` drops the doctrine rows and gains one whole-file row; `placed` gains the owned file; `version` is still written and no comparison reads it. The layout number belongs to `migrate`.
- State detection, never version: fresh (no owned file, no owned heading in `CLAUDE.md`) → place; split (owned file present) → current / stale (silent whole-file copy) / fork (overwrite-or-keep prompt); legacy (no owned file, `CLAUDE.md` holds an owned heading) → the run stops with zero writes and a fixed message, and the hook stays silent. The owned-heading list is read off the asset's own `## ` lines.
- **No `/release` between this split and `migrate`** — a released split stops every existing consumer's re-run at the legacy state.
- This repo's root `CLAUDE.md` is split by hand as the last build phase; the steps taken are the manual-recipe draft. The dogfood copy of the owned file is byte-identical to the asset, so this repo's additions to the doctrine move to a project-owned section of `CLAUDE.md`.
- `CLAUDE.md` § Rules gets no bullet for the owned file; one pointer line under the skeleton's H1 names it as plugin-owned and synced whole. The rename-map rot scan keeps scanning `CLAUDE.md` and leaves the owned file out.
- Template changes to the remaining mixed-ownership files carry no advisory once the version lane is gone; they are compared only on a re-run. Accepted.
- `docs/decisions.md`: additive notes on the version-staleness rows in this split; the full `Reopened` note lands with `migrate`.

Steps — one commit per phase:

1. RED, new files only: `tests/harness-asset.test.sh` (asset exists, no frontmatter, no whole-line placeholder, every relative link resolves from `.claude/rules/`, the skeleton's heading set is the project set, no doc skeleton anchors into an owned `CLAUDE.md` section); the rewritten hook test (equal → silent; differs → one advisory line, exit 0; owned file absent → silent, legacy fixture included; CRLF-only difference → silent; no `CLAUDE_PLUGIN_ROOT` → silent; version behind with equal content → silent); `bench/ownership-split/` with four headless fixture walks — fresh, legacy, stale, fork — and a control on the current skill text.
2. Placement contract: the new asset; `claude-md-skeleton.md` cut to the project sections; `hooks-ensure-infra.md` gains the fourth whole-file asset (keep the sentence `bench/receipt-eol` anchors on); the six doc and rule skeletons' pointers; `harness-bootstrap/SKILL.md` — the version-staleness signal and its enforcement line go, the three-state detection and the whole-file lane come in, the fact-staleness key reads `CODING_STANDARDS.md` alone; the asset-lane dogfood copies. Checks: step 1's asset test green; a one-time diff of the old plugin sections against the new asset showing only the picked differences; the four walks green; `receipt-eol` and `rule-paths-tail` still extract; a cold dry-run of the changed `hooks-ensure-infra.md` section; `audit-harness-edits`.
3. Advisory hook, test-first, parallel with step 2: the script, `hooks.json`, POSIX bash without `jq`.
4. Pointer rewrites in the other skills and agents to a location-neutral form (`triage`, `triage-report`, `autorun`, `needs-me`, `session-continue`, `setup`, the `triage` agent, `doc-links.sh` comment), parallel with steps 2–3. `agents/doc-sync-scan.md` — its instruction to read the consumer's `CLAUDE.md § Doc Sync` is the one functional read — takes a RED on a split-shaped fixture and so follows step 5. Read `check-docs-consistency`'s Step 1 glob first; add it here if `.claude/rules/*.md` is outside it.
5. Bench rebuild, after step 2: `assertion-liveness/make-fixture.sh` (the runway placer the others call), `carrier-equivalence`, `doc-sync-harness-cochange`, `context-heavy`, `receipt-eol`'s sample rows. Each fixture builder passes its own guards; the carrier-equivalence selftest stays green.
6. Dogfood split, after steps 2, 3, 5: root `CLAUDE.md`, the placed owned file, the receipt, `.claude/rules/repo-boundary.md` § Sync direction (the doctrine moves from the prose lane to the asset lane), the docs' anchors into the moved sections, `bench/spike-route`. Checks: the placed file equals the asset; the hook stays silent here; every line of the old `CLAUDE.md` is found in the new pair or on a stated drop list; no broken anchor; a fresh session logs the owned file as loaded; a harness-edit task still routes through `load-harness-principles` and `audit-harness-edits`.
7. Narrative docs sweep: both READMEs, `docs/overview.md`, `docs/techstack.md`, `docs/terminology.md`, `docs/specs/harness-architecture.md` §5 and §8, `docs/test-queue.md`, `docs/decisions.md`. The two manifest descriptions wait for `/release`.

Open, for the author after step 5: a short `rules`-arm round on the shipped asset — it differs from the measured file by the link re-base, the pointer line and the `Coding Principles` wording (2–6 runs, sonnet).

Seams left for `migrate`: the legacy stop message and the hook's legacy branch; the owned-heading list needs retired heading names added; consumer `docs/` links into `CLAUDE.md#<owned anchor>` need rewriting or every commit's link check fails; receipt → layout number.

Watch-outs: an older plugin version on another device reads a split repo as missing every doctrine section and proposes to insert them back; a consumer's edit to the owned file meets a fork prompt, and `keep` holds for one run only — the file's first line and the README say so; a cut at the wrong boundary loses doctrine silently, so step 2's diff and step 6's line-coverage check are the guard.

## Progress — 2026-11-19 · split steps 1–3 landed

Steps 1, 2 and 3 of the ownership-split Plan are committed: the RED surfaces (`8fbec0a`), the content-drift advisory hook (`1f3a0c9`), the placement contract (`33b26aa`). Next step: 4 (pointer rewrites in the other skills and agents) and 5 (bench rebuild), then 6 (dogfood split), then 7 (narrative sweep).

- `bench/ownership-split`: the control round on the old skill text was red on all four walks. On the new text `fresh`, `legacy` and `fork` pass; `stale` re-copies the file silently (placed bytes equal the asset) and its scorer row fails on a `docs/techstack.md` prompt printed within the scorer's proximity window of the file's name — a scorer limit the bench README names, not a skill defect. Narrowing that window is owed with step 5.
- Legacy detection needs two or more owned headings in `CLAUDE.md`, not one: generic headings (`Git Notes`, `Coding Principles`) would stop a hand-written repo. From the cold audit.
- The moved doctrine carries six re-based link targets, not seventeen — the higher count read this repo's own `CLAUDE.md`.
- `doc-links.sh check` resolves a `docs/` link into `.claude/rules/harness.md` by path and anchor, so a consumer repo missing the file fails every commit's link check — the `migrate` seam in the Plan is binding.
- Step 6 also owes: the asset-lane dogfood copies (`CODING_STANDARDS.md`, `.claude/rules/index.md`, the `docs/decisions.md` scope header) refreshed to the new skeleton text; `docs/specs/harness-architecture.md` §5 and §8, which still narrate the per-section `CLAUDE.md` lane.
- Left untouched, not part of the split: the 2c report example row `docs/techstack.md: Runtime ⚠ drifted → updated` disagrees with the seed-once rule for that section; `harness-bootstrap` reads "fresh / re-run" two ways (a bootstrap-shaped commit in 2b, the files present in Phase 1), which can differ on a repo with a hand-written `CLAUDE.md` and no harness file.
- Sent to the storehouse as a note (`harness-audit-paths-after-ownership-split`): the audit gate fires on a consumer's whole-file sync of `.claude/rules/harness.md` and on `*/CLAUDE.md` bench fixtures; the measured post-compact reload facts; whether anything it serves reads a consumer's `CLAUDE.md` doctrine sections by name. This card waits on no answer.
- **No `/release` until `migrate` lands.**

## Progress — 2026-11-19 · split steps 4–5 landed

Steps 4 (`e751e7d`) and 5 (`1ca8634`) are committed. Next step: the `agents/doc-sync-scan.md` pointer (RED on a split-shaped fixture, `bench/doc-sync-harness-cochange` now builds one), then step 6 (dogfood split), then step 7.

- `bench/ownership-split`, post-change round, rescored with the block-scoped prompt check: all four walks pass (`fresh`, `legacy`, `stale`, `fork`).
- The pointers in the other skills name both locations once per file (`.claude/rules/harness.md`; `CLAUDE.md` in a repo not yet split). The second half is transitional — remove it when `migrate` sunsets. Added to the seams.
- The shipped doctrine's cluster 7 row differs from this repo's own (the asset names no `load-harness-principles` / `audit-harness-edits`). Step 6 keeps the placed file byte-identical to the asset, so this repo's row moves to a project-owned section of `CLAUDE.md`; check after the split that a harness-edit task still routes through both skills.
- Step 6 also owes `bench/spike-route/run.sh`, whose arm slices `### The envelope` out of the root `CLAUDE.md`.
- Not fixed, older than the split: `bench/assertion-liveness`'s placer does not place `docs/terminology.md` or the two doc rules, so the asset's `dimension-discipline.md` link is broken inside that fixture; its README's `SKILL.md` line numbers have drifted.

## Progress — 2026-11-19 · split step 6 landed

Step 6 is committed (`e0ae718`): this repo runs the split shape — `.claude/rules/harness.md` is the placed doctrine, root `CLAUDE.md` holds the project sections and § This repo's additions to the harness doctrine. All eleven `tests/*.test.sh` pass. Most of step 7's narrative sweep landed with steps 2, 3 and 6.

What is left on the split:

- Two checks that need a fresh session in this repo, since a session keeps the instructions it loaded at start: `.claude/rules/harness.md` is listed as loaded (`/memory`), and a harness-edit task states a route through `load-harness-principles` and `audit-harness-edits`.
- `plugins/super-bootstrap/agents/doc-sync-scan.md` still tells the judge to read the consumer's `CLAUDE.md § Doc Sync`; in a split repo that section is in the doctrine file. A behaviour-shaping line — RED first on `bench/doc-sync-harness-cochange`'s split-shaped fixture (headless runs, the author's spend). The doctrine file is eager and a subagent inherits it, so the definition still reaches the judge meanwhile.
- `docs/specs/harness-architecture.md` holds history inside a state doc that now contradicts the text above it: the dated evidence-table row naming the `CLAUDE.md` skeleton as the routing table's carrier, and §8's "skeleton cut landed" table. Waits on the author's ruling — lean: keep only the two still-binding rows (pins with no removal path), present tense; the rest is git's.
- `docs/decisions.md`: the additive notes on the version-staleness rows.
- The two manifest descriptions still name `runway-version` and the per-section shape — `/release`'s lane.
- Open spend for the author: a short `rules`-arm round of `bench/carrier-equivalence` on the shipped asset (2–6 runs, sonnet); `bench/spike-route` was re-pointed but not run.

Then, in order: `migrate` + sunset → merge `setup` into `harness-bootstrap` → rename. **No `/release` until `migrate` lands** — every bootstrapped repo other than this one is in the legacy shape and its re-run now stops.

## Design — 2026-11-19 · migration

Ruling by the author, on two corrections in session: the migration is a brief the consumer's own Claude Code executes inside the `harness-bootstrap` re-run, bounded by mechanical checks. It takes over the migration and sunset bullet of `## Design — 2026-11-16`, the `## Plan — 2026-11-19 · ownership split` pick "legacy … → the run stops with zero writes", and that Plan's seams for a `migrate` skill.

- **No separate `migrate` skill, no sunset, no layout number, no table of shipped-text hashes.** The brief is a section of `harness-bootstrap`, kept for good. The state is still read off the files present.
- **Legacy state → run the migration brief**, in place of the stop. The consumer's Claude sees what a script cannot: which old shape the repo is in (heading names differ across majors), which differences are old plugin text and which are the repo's own rules or a fork, where the repo's own rules belong beside the doctrine, and what else in the repo — docs, rules, hooks — leans on the moved sections. It stops and asks on a case the brief does not cover.
- **The judgment is the agent's; "done, nothing lost" is a check's.** The end state passes, mechanically: the placed `.claude/rules/harness.md` equals the shipped asset, CR aside; `CLAUDE.md` holds no doctrine heading; every non-blank line of the old `CLAUDE.md` is found in the new pair, link re-basing aside, or sits on a drop list the user saw; `doc-links.sh check` is clean. The user confirms the delta list before any write; the migration lands as one commit, undone by one `git revert`.
- **The shape is the one this repo's own split took** (`e0ae718`): enumerate each difference against the asset per doctrine section; the repo's own lines move to a `CLAUDE.md` section of additions, each naming the doctrine line it adds to or takes over; text the repo lacked arrives with the placed file; links into the moved anchors are re-pointed; the receipt takes the whole-file row. That session's brief and its report are the draft to write the section from.
- **The session-start advisory speaks on a legacy repo** — one line naming the re-run as the migration — where it is silent today.
- **Checks to build**: the line-coverage check is new (a small script the brief runs); the other three exist (`runway-drift.sh`'s compare, `tests/harness-asset.test.sh`'s heading set, `doc-links.sh check`).
- **Test before any push**: headless walks of the brief on fixtures built from historical tags — a 2.x runway, a 5.x one, a 6.x one, and one with hand-edited doctrine sections — each scored by the four checks plus "the repo's own lines survived". The author decides the spend; `bench/ownership-split`'s `legacy` walk is the starting fixture and its expected reading flips from "stops" to "migrates".
- **The guard is "do not push", not "do not release".** `.claude-plugin/marketplace.json` sources the plugin from `./plugins/super-bootstrap` with no ref, so `main` may be what a consumer's plugin update reads; whether an unchanged `plugin.json` version holds an update back is unverified. The split's commits stay local until the brief has passed its walks.
- **Stated limits**: a migration spends the consumer's tokens and is not reproducible run to run — the checks and the confirm are the floor. A repo updated on one device and re-run from another still on an older plugin gets the old per-section proposals back; the upgrade note says so. A consumer who updates the plugin and never re-runs keeps working: the other skills cite the doctrine in either location.
- **Release shape**: a major version, an upgrade note in the README, both manifest descriptions through `/release`.

## Progress — 2026-11-19 · session park

The split's build steps are landed and this repo runs the split shape; the migration is re-ruled in `## Design — 2026-11-19 · migration`. Next step: write the migration brief into `harness-bootstrap` in place of the legacy stop, with the line-coverage check — test-first: flip the expected reading of `bench/ownership-split`'s `legacy` walk from "stops" to "migrates", then build the historical-tag fixtures.

- First, in the fresh session: the two checks the step 6 Progress block names (`/memory` lists `.claude/rules/harness.md`; a harness-edit task routes through `load-harness-principles` and `audit-harness-edits`).
- Nothing is pushed: every commit from `ecb02c4` on is local. Hold them until the brief has passed its walks.
- Waiting on the author's spend: the migration walks; the `doc-sync-scan.md` RED; the `rules`-arm round on the shipped asset.
- Waiting on the author's ruling: the history rows in `docs/specs/harness-architecture.md`.

## Progress — 2026-11-19 · migration brief landed

The migration is built and committed, local only: the line-coverage check (`7e10e60`, `3c459c0`), the bench's `legacy` walk flipped to "migrates" (`060b093`), and the brief with the legacy advisory and the doc sweep (`a63c542`). The brief is `harness-bootstrap/SKILL.md` § Doctrine migration. Next step: the headless walks — the author's spend.

- Evidence so far: all twelve `tests/*.test.sh` pass; `bench/ownership-split`'s selftest holds 64 trees; one cold in-session dry-run of the section text on the bench's `legacy` fixture ran steps 1–6 and passed the four checks (104 old lines — 103 in the new pair, 1 on the drop list; the seeded own line kept). No `claude` process ran: the `legacy` control round and green round do not exist yet.
- The `legacy` walk is two-phase: the first turn ends on the confirm with zero writes; `ANSWER=y` adds the turn that migrates. The control is one phase-1 run on the pre-`a63c542` skill text.
- Departs from `## Design — 2026-11-19 · migration` in form: a kept line moves verbatim under a label line naming the doctrine line it adds to or takes over. Folding the attribution into the line, as this repo's own split did, leaves the old line absent — `e0ae718^:CLAUDE.md` against today's pair reads 14 of 122 lines uncovered.
- The gateway's pick, open to the author: the migration is the whole run and commits alone; a second run does the regular sync. A sync write in the same commit would make the revert undo more than the migration.
- `doc-links.sh check` does not read `CLAUDE.md`; the brief has the agent read those links itself. A link the old file already carried broken passes and is named in the closing message.
- Open for the author, from the cold audit of `a63c542`: move the section (about 130 lines, read on every fresh and split run too) to an asset the `legacy` bullet points at, as `hooks-ensure-infra.md` is. Left in place because the Design rules it "a section of `harness-bootstrap`".
- Still owed: the historical-tag fixtures (a 2.x runway, a 5.x one, a 6.x one, one with hand-edited doctrine sections) — the brief has met only the pre-split shape of the current text; `line-coverage.sh` under mawk and one-true-awk (ran under gawk only); the `Reopened` question on the "version-driven update/merge engine" row of `docs/decisions.md`, now that no `migrate` skill or layout number exists; the README upgrade note and both manifest descriptions, with `/release`.
- Unchanged from the session park: nothing is pushed; the `doc-sync-scan.md` RED, the `rules`-arm round and the history rows in `docs/specs/harness-architecture.md` wait as before.

## Progress — 2026-11-19 · walked, release prepared

One headless walk ran — the `v2.22.0` variant, two turns, sonnet — and the migration went end to end through the loaded plugin, commit included. It failed one property: a version-only receipt kept no `placed` record; the receipt step now sets `placed` in every receipt that exists (`e993e9b`). The walk was not re-run after that fix. Next step: the author migrates the fleet's repos, one by one, after the v7.0.0 push.

- The author ruled the rest of the walks unearned: each real migration carries its own confirm, four checks and one-commit revert, so a real repo is stronger evidence than a synthetic fixture. Not run: the control round, the other four variants, the `doc-sync-scan.md` RED, the `rules`-arm round. The fixtures stay (`7d22e09`) for a later regression.
- Seen in the walk: the agent kept two lines of v2.22.0 plugin text (the `karpathy-guidelines` pointer under § Coding Principles) as the repo's own. The direction is safe — kept, shown in the delta list — and the README upgrade note tells the user to say so at the confirm.
- The gateway's three picks stand: the migration is the whole run and commits alone; a kept line moves verbatim under a label line; the section stays in `SKILL.md`.
- The doc tail is closed (`137fa83`): the judge's § Doc Sync pointer, the history rows of `docs/specs/harness-architecture.md`, the note on the version-driven engine row of `docs/decisions.md`.
- Still open on this card: merge `setup` into `harness-bootstrap`; the rename; which doctrine lines are cuttable; `line-coverage.sh` under mawk and one-true-awk; the transitional "`CLAUDE.md` in a repo not yet split" half of the skills' pointers.
