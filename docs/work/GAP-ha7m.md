# GAP-ha7m — a repo cannot declare doc-surface globs beyond the commit door's hardcoded set

**Logged:** 2026-11-09 · **Source:** device note from `local__agent-b64ced` (ComfyUI agent-workflows repo, C:/Users/User/Documents/ComfyUI/user/default/workflows/agent), 2026-11-09
**Problem:** `doc-links.sh` hardcodes the doc surface in `surface_files` (`docs/**/*.md` + `README.md` + `plugins/*/README.md`); every lane that walks it (`hits`, `refs`, `self`, `check`, `pins`, `term-uses`, `volatile-ids`, `closure`) inherits it. A repo that ships behavior-narrating prose outside `docs/` has no way to add it. Instance: in the agent-workflows repo, a flag rename (`--fine` retired for `--fast`) passed the commit door with every lane clean while `kinds/h3.md` still told callers to pass `--fine`; that repo's caller-facing guides live in `kinds/*.md`, `prompting/*.md` and `api/*.note.md`. The CLAUDE.md template says the script mirrors the surface CLAUDE.md § Doc Sync defines, but the script cannot read prose. Consumer interim: that repo's CLAUDE.md § Doc Sync names the folders for a hand grep at commit.
**Area:** `plugins/super-bootstrap/skills/commit/assets/doc-links.sh` (`surface_files`, ~line 136); `plugins/super-bootstrap/skills/commit/SKILL.md` §3; CLAUDE.md template § Doc Sync "Doc surface:" line
**Prior:** Sender's proposal: (a) one repo-side declaration of extra surface globs the script reads (e.g. a `## Doc Surface` section in `docs/techstack.md` or a `.claude/doc-surface` file, one glob per line), appended in `surface_files` so every lane picks it up; (b) commit §3 and the template's "Doc surface:" line point at that declaration as SSOT; (c) optional: the doc-sync write boundary sourced from the same declaration.

## Verdict — surface · 2026-11-09

### Findings

- premise age: clean — no commit touched `plugins/super-bootstrap/skills/commit/` or `plugins/super-bootstrap/skills/harness-bootstrap/` since 2026-11-09.
- root cause (gap confirmed): `plugins/super-bootstrap/skills/commit/assets/doc-links.sh:135-140` `collect_surface()` is a fixed three-line walk (`find docs -name '*.md'`, `README.md`, `find plugins -mindepth 2 -maxdepth 2 -name README.md`). It reads no repo-side input. Every surface lane calls it: `check` (:507), `refs` (:551), `index` (:566), `closure` (:578/:581), `hits` (:722), `self` (:844), `term-uses` (:988), `volatile-ids` (:1053), `pins` (:1182). A consumer's `kinds/*.md` is therefore off every lane, so a rename passes clean — the reported instance follows directly.
- card corrections: the function is `collect_surface` (line 135), not `surface_files`. The "mirrors the surface CLAUDE.md § Doc Sync defines" claim sits in the script header (`doc-links.sh:4-6`), not in the CLAUDE.md template; the template line is `claude-md-skeleton.md:74` "Doc surface: …".
- aim: no overlapping open card (grep of `docs/work/`). `docs/decisions.md` row "A project-declared premise-closure map for the commit door's §3b lane" closed a *narrowing* per-repo map on the ground that it must be authored before the lane covers anything. This card is *additive* — an absent declaration keeps today's zero-config surface — so it does not re-walk that fork, but the row's zero-config default is a constraint the design must keep.
- scope reach — the surface is restated, not only computed, at these sites (all would carry stale wording once a declaration exists):
  - `plugins/super-bootstrap/skills/commit/assets/doc-links.sh:4-6` header; `:135` `collect_surface`.
  - `plugins/super-bootstrap/skills/commit/SKILL.md:27` link-hit lane enumerates changed `docs/**` / `README.md` / `plugins/*/README.md` paths in prose — a second hardcoded copy of the surface, outside the script.
  - `plugins/super-bootstrap/skills/harness-bootstrap/assets/claude-md-skeleton.md:74` "Doc surface:" and `:80` write boundary; dogfood `CLAUDE.md` § Doc Sync same two lines (prose lane, dogfood ahead).
  - `plugins/super-bootstrap/agents/doc-sync-scan.md:15` — names CLAUDE.md § Doc Sync as the owner of "the doc-surface definition and write boundary". The new declaration either lives there or this line moves.
  - `claude-md-skeleton.md:121,123` + `rules-dimension-discipline-skeleton.md:5`, `rules-ssot-doc-link-skeleton.md:5` — rule `paths:` frontmatter hardcodes the same three globs. Static YAML cannot read a declaration; reaching it means harness-bootstrap renders the declared globs into the placed rules.
  - `tests/doc-links.test.sh` — the unit test home (surface cases at :500, :606).
  - `plugins/super-bootstrap/skills/check-docs-consistency/SKILL.md:23` — scans `**/*.md` at any depth already; it does not share `collect_surface` and already covers `kinds/*.md`. No change needed.
- implementation constraints the build must hold (`.claude/rules/asset-dialects.md`): bash 3.2 has no `globstar`, so declared globs must match via `find` + quoted `case` pattern (where `*` crosses `/` — semantics the declaration format must state); one read of the declaration per invocation, none inside per-file loops; extended entries limited to `*.md`, since every lane parses markdown.
- attempted: static read of the script, the commit SKILL §3, the skeleton, doc-sync-scan, decisions. Stopped at the design fork below — no spec, decisions row, or measurable proxy settles it, and the choice fixes a new consumer-facing contract that every seeded repo inherits on re-run.

### Decision needed

- Where does the one surface declaration live, so it is the surface's SSOT for the script, the commit SKILL prose, and doc-sync-scan?
  - (A) A fenced machine-read block inside CLAUDE.md § Doc Sync (the section doc-sync-scan already names as surface owner); the skeleton ships it with the three default globs; `doc-links.sh` parses it once per call; no declaration block → today's built-in set.
  - (B) A `.claude/doc-surface` plain file, one extra glob per line; CLAUDE.md § Doc Sync "Doc surface:" line and doc-sync-scan point at it; absent file → built-in set.
  - (C) A `## Doc Surface` section in `docs/techstack.md` (the `§ Probes` pattern); same pointers. Puts doc-sync policy inside a stack-state doc that is itself on the surface.
- Which consumers source from it, beyond the script lanes?
  - (i) lanes + commit SKILL:27 + doc-sync-scan only;
  - (ii) (i) plus the doc-sync write boundary (card Prior (c));
  - (iii) (ii) plus harness-bootstrap rendering the declared globs into the placed `dimension-discipline` / `ssot-doc-link` rule `paths:`.
- recommendation: (B) + (ii). (B) is the only home a bash 3.2 script reads without parsing user-edited markdown, and it keeps CLAUDE.md prose as the narrating pointer — one SSOT, no harness-edit audit per folder added. (ii), because a declared folder is narrative prose by declaration and the write boundary otherwise contradicts the lanes. Leave (iii) to a separate card: it is a harness-bootstrap render change with its own re-run closure.
- settles by: author design preference — a new consumer-facing contract shipped in the harness-bootstrap skeleton. After the pick, the build is `Fix-shape: design`, `Execution: full`; test strategy unit (`tests/doc-links.test.sh`, one fixture with a declared `kinds/*.md` asserting each lane includes it, and one without the declaration asserting today's set); SKILL/skeleton prose edits take the skill-authoring RED floor + `audit-harness-edits`.

## Design — 2026-11-09

Settled by the gateway's climb on the user's delegation ("直接開工解掉"), taking the verdict's recommendation as-is: **(B) + (ii)**.

- The declaration is a `.claude/doc-surface` plain file, one extra glob per line (`*.md` entries only; `*` crosses `/`; `#` comments and blank lines ignored). An absent or empty file keeps the built-in surface (`docs/**/*.md`, `README.md`, `plugins/*/README.md`) — the zero-config default stays.
- Consumers sourced from it: every `doc-links.sh` lane (through `collect_surface`), commit `SKILL.md` §3's link-hit lane prose, `agents/doc-sync-scan.md`, and the doc-sync write boundary (dogfood `CLAUDE.md` + `claude-md-skeleton.md`). CLAUDE.md § Doc Sync's "Doc surface:" line becomes the narrating pointer to the file.
- Out of scope: rendering declared globs into the placed rules' `paths:` frontmatter (option iii) — its own card.
