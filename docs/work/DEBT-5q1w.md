# DEBT-5q1w — Retire `resolve-plugins`; fold the language → LSP pin into `harness-bootstrap`

**Logged:** 2026-11-16 · **Source:** split from DEBT-ymdg (`## Design — 2026-11-16`, option A); fleet evidence in that card's origin block and Verdict
**Problem:** `resolve-plugins` live-queries five GitHub pools, digests READMEs (`plugin-digest` agent) and scores trust tiers on every run, and across the local fleet its three community pools have produced zero pins. What it does deliver is the techstack-language → `*-lsp` pin, an occasional `frontend-design`, and one `modern-python@trailofbits`. Retire the skill and the `plugin-digest` agent; keep the LSP pin as a techstack-derived step in `harness-bootstrap`; leave other recommendations to `claude-code-setup:claude-automation-recommender`. Closure to carry: `setup`'s substantive branch and its `tech-curation` seed card, the `<!-- harness-meta -->` block in `overview-skeleton.md` (read only by this skill), the skill catalog and data-flow lines in both READMEs and `docs/overview.md`, both manifests (via `/release`), `bench/` fixtures that exercise the skill, and the `docs/decisions.md` rows that cite it.
**Area:** `plugins/super-bootstrap/skills/{resolve-plugins,setup,harness-bootstrap}/`, `plugins/super-bootstrap/agents/plugin-digest.md`
**Prior:** Unaccounted pins seen in the fleet (`fullstack-dev-skills` ×2, `ui-ux-pro-max` ×1) may be this skill's output — check with `git log -S` before calling the community pools empty.

## Verdict — surface · 2026-11-16

### Findings

- premise age: clean — no commit touched `skills/{resolve-plugins,setup,harness-bootstrap}/` or `agents/plugin-digest.md` after 2026-11-15 (the parent card's observation date).
- root cause (need-check, confirmed): the gap exists as described, and the retire is already ruled (DEBT-ymdg `## Design — 2026-11-16`). Current code:
  - `resolve-plugins/SKILL.md:46-61` runs the live query on every invocation ("Non-skippable"), `:81-98` dispatches `plugin-digest`, `:128-155` scores trust tiers and the earn-right gate.
  - The LSP pin is not a step of its own today. It is the sum of the pre-filter at `:63-77` and the `committed-stack` admission at `:143` + `:149`, and it reaches `settings.json` only through the user-approved batch (Phase 4) with two rider notes (`:196` — the language-server binary is a separate install; coverage is typed symbols only).
  - `harness-bootstrap/SKILL.md:242-262` writes one pin, `super-bootstrap@super-bootstrap`, as a two-state row (missing → insert, no prompt). It holds no language → plugin mapping.
- the fold has no source table in the repo. `resolve-plugins/SKILL.md:65` lists example names (`python-lsp`, `rust-lsp`, `go-lsp`, …). The fleet pins the parent Verdict counted are `pyright-lsp`, `typescript-lsp`, `rust-analyzer-lsp`. Two of the three do not match the skill's own examples, because the skill read the names live. A static table must be built from the marketplace listing, not from this file.
- timing constraint: on greenfield the runway runs while `docs/techstack.md` is an empty skeleton (`setup/SKILL.md:55`), so a techstack-derived pin cannot land on the first run. It lands on the re-run after the techstack fills. That re-run is what the `tech-curation` seed card and the resolve-gate text (`setup/SKILL.md:66-68`) point at today.
- `setup`'s substantive branch does not empty out: step 2 (`release-init` offer, `setup/SKILL.md:76`) is independent of the retired skill and stays.
- Prior check (`git log -S` over `D:/Git/*/.claude/settings.json`): `fullstack-dev-skills` appears in 5 settings files, not 2 — BeatStomper `f1cdd92c` and PuzzleSnake `e6009af8` ("chore: resolve skills and disable irrelevant plugins", 2026-04-05), RockyHong.com.2025 `53bf45c` ("chore: resolve skills for project stack", 2026-04-07), Claudia `7882a00` ("chore: disable unused plugins for this project", 2026-04-02), ayva-stroker-lite `68fa7e0` ("chore: complete pipeline bootstrap", 2026-05-03). `ui-ux-pro-max` ×1 comes from the same ayva-stroker-lite commit. None carries the current skill's commit subjects (`chore: pin plugin picks` / `chore: refresh plugin picks`, `resolve-plugins/SKILL.md:260`). The subjects read as an earlier pipeline version's output from April–May 2026; no pin from either marketplace is newer than 2026-05-03. Whether each entry is enabled or `false` was not read. This does not overturn the retire; "zero pins from the three community pools" stands for the current skill and is unproven for its predecessor.
- overlap: no duplicate open card. DEBT-wf8f edits the same files on other lines (`harness-bootstrap/SKILL.md`, both manifests' description, the receipt `covered` list) — the two retires need one order or one `/release`. DEBT-ymdg keeps the later `setup` + `harness-bootstrap` merge and the migration step that clears existing `harness-meta` blocks (its third Amendment), so this card stops seeding the block and does not strip it from already-bootstrapped repos.
- closed forks: the card re-walks none. Five `docs/decisions.md` rows cite the skill and take additive annotations only (the file's own scope header forbids rewording):
  - `:30` — its "Shipped instead" is the `harness-meta` shape-only compare this card removes.
  - `:31` and `:59` — each ends in a "Reopen if/on" condition that names a `resolve-plugins` run; the condition can no longer fire.
  - `:51` — names `resolve-plugins`' harness-active marker as one of three grounds; that ground dies, the other two carry the verdict.
  - `:57` — cites the skill as the adaptive-pick door in superseded text; verify at implement whether a note is owed.
- blast the card does not name:
  - process-harness door. `docs/specs/harness-architecture.md:293` and `:299` (both under "Decided"), `:87`, `docs/techstack.md:16` and root `README.md:117` state that a repo takes a process harness as an ordinary `resolve-plugins` candidate. After the retire no plugin door installs one.
  - `harness-bootstrap/assets/rename-map.md:35` and `:48` map legacy command names to `/super-bootstrap:resolve-plugins`; the target dies.
  - `.claude/super-bootstrap-runway.json:20` — this repo's own receipt holds the `docs/overview.md harness-meta` row, and `docs/overview.md:3-6` holds the dogfood copy of the block. How Phase 1's set-difference reads a prior receipt row that the current runway no longer covers was not traced.
  - root `README.md:3` — the hero image's alt text says "curates MCPs + skills"; the image file `.github/assets/hero.webp` may show the same claim. Taste item: the author judges the image.
  - `README.md:113-123` § Sources is a table of the retired pools; `docs/techstack.md:17` links it and links `resolve-plugins/SKILL.md#phase-2-live-query-source-pool`, which becomes a broken anchor.
  - `docs/overview.md:40` counts 6 agents and `:48` counts 44 bench fixtures; both drop by one.
- scope reach (every touched path is native to this repo; no served or imported copy):
  - delete: `plugins/super-bootstrap/skills/resolve-plugins/` (`SKILL.md`, `assets/formats.md`), `plugins/super-bootstrap/agents/plugin-digest.md`, `bench/plugin-digest-fabricate/` (a bench follows its artifact).
  - edit, skills: `setup/SKILL.md:3`, `:17-19`, `:57`, `:66-68`, `:71-81`, `:85`; `setup/assets/seed-cards.md:3`, `:25-33`; `harness-bootstrap/SKILL.md:3`, `:166`, `:242`, `:329`, the receipt example list near `:557`, plus the new pin step; `harness-bootstrap/assets/overview-skeleton.md:3-6`; `assets/rename-map.md:35`, `:48`.
  - edit, docs: root `README.md:3`, `:46-47`, `:57-60` (mermaid), `:110`, `:113-123`; `plugins/super-bootstrap/README.md:9`, `:11`, `:38`, `:60`, `:62`, `:83`; `docs/overview.md:3-6`, `:12`, `:40`, `:48`, `:54`; `docs/techstack.md:16-17`; `docs/specs/harness-architecture.md:87`, `:293`, `:299`; `docs/decisions.md` rows above.
  - `/release` lane: `plugins/super-bootstrap/.claude-plugin/plugin.json:3`, `.claude-plugin/marketplace.json:4` and `:13`. Removing a public command is a breaking change for the version bump.
  - no change: `bench/doc-sync/` (`SCORING.md`, `parts/f1-diff.txt`, `prompts/f1-*.txt`) and `bench/term-census/results/` name the skill inside frozen fixture snapshots and recorded results.
- attempted: static reads, one fleet `git log -S` pass. No `§ Probes` table exists in `docs/techstack.md`, so no probe ran. The official marketplace listing was not read (this lane holds no network read). Stopped at the verdict because criterion 2 fails (two skills, one agent, a spec, both manifests) and criterion 4 fails: the retire is ruled, the shape of what replaces it is not.

### Decision needed

- What the folded LSP pin is, as a `harness-bootstrap` step. The card says "keep the LSP pin as a techstack-derived step" and leaves its source, its consent and its lifetime open.
- options:
  - A — static table, two-state row. `harness-bootstrap` holds a language → plugin table and treats each matched pin like the core pin: missing → insert with no prompt, present → `✓ pinned`, never dropped. The run report carries the binary-install line per inserted pin. No network read at run time.
  - B — static table, ask first. Same table; the runway shows the matched pins and writes them only on the user's yes. Keeps the consent the retired batch gave; adds a prompt to a sync the parent Design is making judgment-free.
  - C — live list, two-state row. The runway reads the official marketplace's `*-lsp` entries at run time and matches them against the techstack. No table to go stale; keeps one of the live queries the card retires and fails when offline.
- recommendation: A — it matches the existing core-pin mechanism (`harness-bootstrap/SKILL.md:242-262`) and the parent Design's no-judgment sync, and a pin without its binary is inert rather than harmful once the report states the install command.
- the ruling also needs from the author:
  - process-harness door: the spec's two "Decided" paragraphs name `resolve-plugins` as how a repo takes a process harness. Lean: reword them to "a repo adds one through Claude Code's own plugin install; no plugin door routes it" — the decision (nothing paired, nothing pinned) holds, only the named door goes.
  - greenfield seed set: drop the `tech-curation` card (greenfield seeds two cards; the resolve-gate text keeps the "re-run `/super-bootstrap:setup`" line, and that re-run lands the LSP pin and the `release-init` offer), or keep it under a new summary. Lean: drop. Either way `setup` keeps a clear step that matches the old "Run tech curation" summary, because consumer repos hold open copies.
  - recommender pointer: whether `setup`'s closing output names `claude-code-setup:claude-automation-recommender`, or the hand-off stays a README line only. Lean: README line only — a pointer in the run output re-creates a recommendation step.
  - root `README.md` hero image: keep, re-word the alt text only, or replace the image.
- settles by: the pin's consent and lifetime, the process-harness wording and the seed set need the author's product and preference authority. One measurement, sized `inline read`: the `*-lsp` directory names under `anthropics/claude-plugins-official` `plugins/` — the table's content for A or B, since the repo holds only stale example names.

## Amendment — 2026-11-16 · gateway read of the installed `claude-plugins-official` marketplace tree

`*-lsp` plugin directory names under `plugins/` (local marketplace copy, `~/.claude/plugins/marketplaces/claude-plugins-official/`): `clangd-lsp`, `csharp-lsp`, `gopls-lsp`, `jdtls-lsp`, `kotlin-lsp`, `lua-lsp`, `php-lsp`, `pyright-lsp`, `ruby-lsp`, `rust-analyzer-lsp`, `swift-lsp`, `typescript-lsp`. The copy is not a git checkout, so its date is unread.

## Design — 2026-11-16

Settled by the gateway's climb on the author's delegation ("your lean, you know the context").

- **LSP pin shape: A — static table, two-state row.** `harness-bootstrap` holds a language → plugin table built from the Amendment's twelve names and treats each matching pin like the core pin: absent → insert, present → skip, never asks, never removes; the report carries the language-server binary install hint. It lands on the run where `docs/techstack.md` names a runtime — a greenfield first run pins nothing. Settling source: parent DEBT-ymdg `## Design` (sync without judgment) and the existing core-pin mechanism.
- **Process-harness wording:** a repo adds one through Claude Code's own plugin install; no plugin door routes it.
- **`tech-curation` seed card:** dropped — greenfield seeds two cards. `setup` keeps a clear step for an open card carrying the old summary.
- **Recommender pointer:** one README line; nothing in `setup`'s run output.
- **Hero image:** alt text follows the retire in this card; whether the image itself changes is the author's eye — hand it over at build time (`### Taste needed` shape).
- **Order:** DEBT-wf8f builds first, this card second — both edit `harness-bootstrap/SKILL.md`, the manifest descriptions and the receipt's `covered` list — and one `/release` carries both (a removed public command is a breaking change). Clearing `harness-meta` blocks in already-bootstrapped repos is DEBT-ymdg's `migrate`.
