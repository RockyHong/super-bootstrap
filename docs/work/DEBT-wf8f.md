# DEBT-wf8f — Retire the scaffolded `AGENTS.md` foreign-executor contract

**Logged:** 2026-11-16 · **Source:** split from DEBT-ymdg (`## Design — 2026-11-16`, option A); author's ruling — no Codex subscription, the contract has never run and cannot be tested here
**Problem:** `harness-bootstrap` always scaffolds `AGENTS.md` from `agents-md-skeleton.md` as the standing brief for a foreign cold executor. No such executor has run it, so the artifact ships untested and adds a row to every sync. Stop scaffolding it, remove the skeleton, and state what an already-bootstrapped repo does with its copy (8 local repos hold one). Closure to carry: the `docs/decisions.md` row on a runtime-neutral core, which names `AGENTS.md` as what shipped instead and needs a note; `docs/specs/harness-architecture.md` § 4 "Agent runtime"; root `CLAUDE.md` § Dispatch's foreign-executor bullet and its skeleton counterpart; the receipt's `covered` list; `bench/` fixtures that read the contract.
**Area:** `plugins/super-bootstrap/skills/harness-bootstrap/` (`SKILL.md`, `assets/agents-md-skeleton.md`, `assets/claude-md-skeleton.md`), `docs/specs/harness-architecture.md`
**Prior:** Claude Code now reads a repo's `AGENTS.md` as project instructions when present (code.claude.com/docs/en/memory) — a leftover copy is no longer inert in a consumer repo, so the retire needs a removal path, not only a stop-scaffolding.

## Verdict — surface · 2026-11-16

### Findings

- premise age: clean — no commit touched `skills/harness-bootstrap/`, `docs/specs/harness-architecture.md`, root `AGENTS.md`, `CLAUDE.md` or `docs/decisions.md` after 2026-11-15 (the parent card's log date).
- root cause (need-check, confirmed): the scaffold is unconditional and pipeline-owned. `harness-bootstrap/SKILL.md:236` — "`AGENTS.md` is **always** scaffolded — copy `assets/agents-md-skeleton.md` to the repo root if missing"; `:171` lists it under Pipeline-owned (whole body drift-checked); `:187` lists its grown content under Project-owned; `:335` is its asset-table row; `:581` its stage-list line; `:3` names it in the skill `description:`. Each sync writes an `AGENTS.md` identity into the receipt's `covered` (this repo's `.claude/super-bootstrap-runway.json:27`).
- no removal lane exists for it. The skill's only deletion paths are 2a-scale, 2b legacy-plan and 2b-adopt (`SKILL.md:148`, `:317`, `:493`, `:509-530`), each a confirmed `⊘ removed` row. Nothing reads `AGENTS.md` for removal.
- an old receipt needs no migration: the version lane set-differences the applicable sections against `covered` (`SKILL.md:106`), so a leftover `AGENTS.md` identity is ignored, and the next re-run overwrites the receipt whole (`:568`).
- fleet (`D:/Git/*/AGENTS.md`, one level): 8 copies, this repo included; all tracked, none dirty. Committed blob against the three shipped skeleton versions (`2050816`, `ebe2fa5`, `bf7de23`):
  - current skeleton — super-bootstrap, WCRA, claude-config-manager.
  - `ebe2fa5` skeleton — text-speech-aligner.
  - no shipped version — ArtstyleExplore (+9 lines, a "Product docs" section), LanguageLearning (+5 lines, a "This repo" section), spotify-radio (3 lines changed), DungeonCLI (46 added, 22 removed — rewritten as a project brief).
  - So 4 of 8 hold consumer content; a blanket delete destroys it. Each of the 8 repos' `CLAUDE.md` also names `AGENTS.md` (the Dispatch bullet), so a copy removal leaves a dangling reference until that section syncs.
- the Prior is not verified here. No repo doc or local reference under `~/.claude/guidelines/` states that Claude Code loads a repo's `AGENTS.md`, and this lane holds no web tool. It decides how urgent removal is: if the file loads as project instructions, an untouched copy tells a Claude session "Leave version control to the orchestrator: no commit, no staging" (skeleton § Build contract), against the gateway role; if it does not load, a leftover copy is inert.
- overlap: the parent card already assigns removal. DEBT-ymdg third Amendment lists "clear retired items (untouched `AGENTS.md`, ...)" as a step of its `migrate` skill, and its `## Design — 2026-11-16` says migration follows the ownership split, which is gated on a probe. This card's "state what an already-bootstrapped repo does with its copy" overlaps that step. No other open card overlaps (`DEBT-5q1w` is the `resolve-plugins` retire).
- closed forks: `docs/decisions.md:40` ("Split the shipped harness into a runtime-neutral core plus per-runtime adapters") cites `agents-md-skeleton.md` and root `CLAUDE.md` § Dispatch in its Ref; the retire removes both referents and the row needs an additive note. Rows `:34` and `:103` name `agents-md-skeleton.md` as the target of rejected additions — history, no change. No row closes the retire itself.
- scope reach, by owner:
  - plugin skill (native, behavior-shaping — `skill-authoring` RED applies): `harness-bootstrap/SKILL.md:3, 171, 187, 236, 335, 581`; `assets/agents-md-skeleton.md` (delete); `assets/claude-md-skeleton.md:56`; `setup/SKILL.md:27`; `agents/doc-sync-scan.md:21` (the harness-sweep path list names `AGENTS.md`).
  - dogfood copies (asset lane, `repo-boundary` § Sync direction): root `AGENTS.md`; `CLAUDE.md:56` and `:133`; `.claude/rules/repo-boundary.md:11, 105, 108`; `.claude/super-bootstrap-runway.json:27`.
  - docs: `docs/specs/harness-architecture.md:142-154`; `docs/terminology.md:20`; `README.md:72`; `plugins/super-bootstrap/README.md:10`; `docs/decisions.md:40`.
  - manifests (`/release` lane): `plugins/super-bootstrap/.claude-plugin/plugin.json:3`, `.claude-plugin/marketplace.json:13`.
  - bench: `bench/assertion-liveness/make-fixture.sh:101, 211, 227-232, 243` copies the skeleton and exits FATAL without it; `bench/assertion-liveness/README.md:6` links the skeleton file. `bench/rot-row-contract/` (8 scenario prompts + README), `bench/code-presence-scope/prompt.txt`, `bench/rot-scan-liveness/scenario-gate.md` embed `AGENTS.md` as a sample artifact row in recorded prompts. `bench/scope-replay/results/commits.tsv` holds commit subjects only.
  - not in the closure: `plugins/super-bootstrap/skills/session-close/SKILL.md:35` names a foreign executor (`codex exec`) as a launch class the session may have started — it does not depend on the contract.
  - foreign-owned: `~/.claude/rules/harness-editing.md` names `AGENTS.md` as "the foreign-executor contract it dispatches into", and claude-config-manager holds a copy plus three `CLAUDE.md` mentions. Both are the storehouse's; the author carries them (`/contribute`), no edit from here.
- card corrections: none on counts — "8 local repos hold one" holds, this repo included. The parent's "untouched `AGENTS.md`" describes 4 of the 8.
- attempted: static reads, blob-hash compare across the fleet. No `§ Probes` table in `docs/techstack.md`, so no probe ran. Stopped at the verdict: the gap is confirmed, but criteria 3 and 4 fail — the skill edit is behavior-shaping prose with no unit or e2e surface, and the two forks below change what a consumer repo keeps and what dispatch lane the product states.

### Decision needed

- Fork 1 — what an already-bootstrapped repo does with its copy.
  - A — release ownership. Stop scaffolding; the file drops out of Pipeline-owned and becomes plain project content. No removal step; the release note says so.
  - B — re-run removal lane now. A `harness-bootstrap` re-run that finds a copy whose blob equals one of the three shipped skeleton versions proposes it as a confirmed `⊘ removed` row (the 2b-adopt confirm shape); a copy that matches none is left as project content and reported once.
  - C — defer removal to DEBT-ymdg's `migrate` skill, which already lists the step. This card stops the scaffold and states the copy as project-owned until then.
- Fork 2 — the foreign-executor bullet in `CLAUDE.md` § Dispatch and `claude-md-skeleton.md:56`.
  - A — delete the bullet in both. The lane it states (`codex exec` as a build container) rests on the same untested ground as the contract.
  - B — keep the lane, cut only the "let it read the repo's `AGENTS.md` for the standing contract" clause.
- Fork 3 — recorded bench prompts that embed `AGENTS.md` as a sample row.
  - A — leave them as frozen records; fix only `assertion-liveness/make-fixture.sh` and its README link, which break when the skeleton goes.
  - B — rewrite every prompt to a surviving whole-file artifact.
- recommendation:
  - Fork 1 — B when the docs read below confirms the Prior, else C. A loaded untouched copy contradicts the gateway's commit role in 4 fleet repos today, and `migrate` waits on a probe; an inert copy can wait for `migrate` and spares a lane that `migrate` would replace.
  - Fork 2 — A. It matches the author's ground, and `docs/specs/harness-architecture.md` § 4 then states one thing: the harness is Claude-hosted, with no runtime-neutral artifact.
  - Fork 3 — A. The prompts are measurement records; their results stand for the skill text they ran against.
- settles by:
  - whether Claude Code loads a repo `AGENTS.md` as project instructions — `inline read` of code.claude.com/docs/en/memory. It selects Fork 1's B or C.
  - Fork 1's A-versus-rest and Fork 2 — the author's product authority: what a consumer repo keeps, and which dispatch lane the product states.
  - Fork 3 — the author's preference; no doc rules on frozen bench prompts.
  - After the rulings the build is one logical change: `full` execution (behavior-shaping skill prose, RED first; closure spans skill, dogfood copies, spec, READMEs, the decisions note, bench fixture), with the manifest lines landing at `/release`.

## Amendment — 2026-11-16 · gateway read of code.claude.com/docs/en/memory § AGENTS.md

The origin `Prior:` overstated the load rule. Verbatim from the page: "By default, Claude reads `AGENTS.md` only when you have no `CLAUDE.md` in your working directory or above it." The default **Project instructions** value is `claude-md-or-agents-md`; `claude-md-and-agents-md` (user-scope setting only) loads both. Every bootstrapped repo carries a `CLAUDE.md`, so a leftover `AGENTS.md` copy is inert under the default and loads only on a device whose user settings opt into reading both.

## Design — 2026-11-16

Settled by the gateway's climb on the author's delegation ("your lean, you know the context") and the Amendment above.

- **Fork 1 — existing copies: C.** No removal path in this card. The retire stops the scaffold and deletes the skeleton; clearing a copy whose blob matches a shipped skeleton version is a step of DEBT-ymdg's `migrate`. A copy that matches no shipped version (4 of the 8 local ones) is project content and stays. Settling source: the copies are inert under the default load rule, so nothing forces an early removal.
- **Fork 2 — the foreign-executor bullet: A.** Delete the whole bullet from root `CLAUDE.md` § Dispatch and from `claude-md-skeleton.md`. Settling source: the author's ruling that the contract cannot be tested here covers the lane, not only the file.
- **Fork 3 — recorded bench prompts: A.** Keep them as frozen records; repair `bench/assertion-liveness/make-fixture.sh` and the README link so the fixture still builds.
- Closure: the Verdict's list, plus the `docs/decisions.md` runtime-neutral-core row note. The two foreign-owned copies of `harness-editing.md` go to the author via `/contribute`.
