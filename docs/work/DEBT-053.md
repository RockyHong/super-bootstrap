# DEBT-053 — docs/techstack.md grown sections empty in a mature repo

**Logged:** 2026-08-06 · **Source:** DEBT-047 live-run pass — real doc debt surfaced while staging the drain verification wave
**Problem:** `docs/techstack.md` § Architecture Rules and § Coding Patterns carry only their seed blockquotes while the repo has crystallized real patterns — dispatch-shell + typed-agent split, frozen asset versioning, skeleton/dogfood sync direction, gateway-inline vs dispatched lanes, POSIX-bash asset dialect. Doc-sync never seeded them.
**Area:** `docs/techstack.md` (grown sections only — skeleton sections are current)
**Prior:** distill from existing SSOT surfaces (`CLAUDE.md` § Dispatch, `docs/specs/harness-architecture.md`, `.claude/rules/repo-boundary.md`) as one-line rules with links — never restate bodies (parallel-truth guard).

## Verdict — auto-fix · 2026-08-06

**Fix-shape:** systematic
**Probe-deps:** none
**Execution:** phased(skip: design, plan, red) — depth: shape is pre-settled (one-line linked rules, state dimension, link-don't-restate), no fork to settle and no step sequence to author; closure: one edited file but a real multi-surface read closure (~6 SSOT files to distill from) plus a doc-sync pass, so not bare-inline.

### Repro (pinned)

> `docs/techstack.md` § Architecture Rules and § Coding Patterns carry only their seed blockquotes while the repo has crystallized real patterns — dispatch-shell + typed-agent split, frozen asset versioning, skeleton/dogfood sync direction, gateway-inline vs dispatched lanes, POSIX-bash asset dialect. Doc-sync never seeded them.

### Root cause (verified)

Gap confirmed against current code, both halves.

**Half 1 — the sections are empty.** `docs/techstack.md:30-36` holds `## Architecture Rules` + its seed blockquote and `## Coding Patterns` + its seed blockquote, zero content lines. Byte-identical to the scaffold seed at `plugins/super-bootstrap/skills/harness-bootstrap/assets/techstack-skeleton.md:29-35` — this repo has never grown either section since `f1635b7` (dogfood scaffold). `git log -- docs/techstack.md` shows 7 commits, none touching the grown sections. The doc's own header (`docs/techstack.md:3`) declares the growth contract these sections never received: "Grown sections (Architecture Rules / Coding Patterns) start empty and grow via doc-sync — every commit that touches a relevant area triggers a sync proposal."

**Half 2 — each named pattern is real and has a citable SSOT home.** Not a doc invented from scratch; a distillation with existing sources:

- **dispatch-shell + typed-agent split** — `.claude/skills/release/SKILL.md:28` §1.5 ships a pre-flight that warns on a skill carrying bounded-judgment verbs with no agent dispatch ("Consider splitting into dispatch-shell + typed agent (see `skills/todo` + `agents/todo.md`)"); `.claude/rules/skill-authoring.md:19` names the same check. Live instance: `plugins/super-bootstrap/skills/todo/` (shell) + `plugins/super-bootstrap/agents/todo.md` (typed).
- **frozen asset versioning** — `plugins/super-bootstrap/skills/drain/assets/ensure-infra.md:3`: assets "ship as **frozen assets** beside this file; ensure-infra places them by mechanical copy / merge — never by regeneration, so there is no drift between repos"; same wording at `skills/harness-bootstrap/assets/hooks-ensure-infra.md:7`. The version half: the runway receipt `.claude/super-bootstrap-runway.json` (`harness-bootstrap/SKILL.md:138`) and the propagation cost recorded in `docs/decisions.md` row (BUG-020): "any frozen-asset touch costs a version-bump propagation for zero behavior".
- **skeleton/dogfood sync direction** — `.claude/rules/repo-boundary.md` § Sync direction: dogfood harness is the ahead-SSOT, shipped skeletons its seed, and a dogfood-section edit pulls the skeleton counterpart into its closure; § Taste-coupling layers carries the self-containment asymmetry (dogfood MAY wire `.claude/guidelines/`, shipped skeletons MUST NOT).
- **gateway-inline vs dispatched lanes** — root `CLAUDE.md` § Dispatch: closure-judged, not diff-size-judged; "transcription is not a build"; parallel within a phase, not across; create-new-file subagents dispatch foreground.
- **POSIX-bash asset dialect** — `.claude/skills/release/SKILL.md:20` and `plugins/super-bootstrap/skills/release-init/assets/template.md:26` carry the identical dialect declaration: "Code blocks below are POSIX `bash` — on a PowerShell-primary device, run them via the Bash tool; if porting to PowerShell, rewrite in its idiom and single-quote git's caret/brace revisions". Backed by the `.sh` assets under `skills/harness-bootstrap/assets/hooks/`.

**Aim validated.** No overlapping open card — `DEBT-052` is the sibling for `docs/overview.md` grown sections, a disjoint file with no write collision. No closed fork in `docs/decisions.md` blocks this; the one adjacent row rejects `docs/techstack.md` § *Rejected Alternatives* as a closed-fork home (dimension pollution — history in a state doc), which constrains content but does not forbid growth. The card's Prior is confirmed, not merely plausible: every source it names exists and carries the claimed rule.

### Files (fix surface)

- `docs/techstack.md:30-32` — § Architecture Rules; seed blockquote stays, rules append below it. Natural home for 4 of the 5: dispatch-shell/typed-agent split, frozen-asset propagation, skeleton/dogfood sync direction, gateway-inline vs dispatched lanes (all map to the seed's "module boundaries, data flow direction, dependency philosophy, layering rules").
- `docs/techstack.md:34-36` — § Coding Patterns; the seed's language-code axes (import style, error handling, type usage) have no referent in a markdown-only repo, so this section takes the authoring-dialect class: POSIX-bash asset dialect, plus any sibling authoring convention the implementer can cite to an SSOT.
- `.claude/rules/repo-boundary.md` — SSOT to link, not to edit.
- `plugins/super-bootstrap/skills/drain/assets/ensure-infra.md` + `skills/harness-bootstrap/assets/hooks-ensure-infra.md` — frozen-asset SSOT, link targets.
- `.claude/skills/release/SKILL.md` §1.5 + §Dialect line — dispatch-shell + POSIX-dialect SSOT, link targets.
- root `CLAUDE.md` § Dispatch — inline-vs-dispatch SSOT, link target (`../CLAUDE.md` from `docs/`).

Two constraints ride the edit surface:

1. **State dimension only** (`.claude/rules/dimension-discipline.md` fires on `docs/**/*.md`) — present-tense constraints, no dates, no "we decided", no rejected-alternative content (that is `docs/decisions.md`'s, per its own scope header).
2. **Link, never restate** (`.claude/rules/ssot-doc-link.md`) — one line + one SSOT link per rule. A `../.claude/...` relative link is already precedented in this file at `docs/techstack.md:67`.

### Doc Impact

- `plugins/super-bootstrap/skills/harness-bootstrap/assets/techstack-skeleton.md` — **read, confirmed must stay unchanged.** The repo-boundary sync-direction reflex does not apply: `harness-bootstrap/SKILL.md:143` lists `docs/techstack.md` grown sections (Architecture Rules, Coding Patterns) under **Project-owned (never touched)**, so the skeleton's job is to ship them empty and each consumer grows its own. Mirroring this repo's rules into the skeleton would be a self-containment breach (dogfood-only referents) and a drift-check false positive.
- `docs/overview.md` — read-and-confirm only. `DEBT-052` fills its grown sections in parallel; keep module-index rows out of techstack (no duplication across the two).
- `docs/specs/harness-architecture.md` — unchanged; it is a link target for the dispatch/awareness-wiring rules, not a co-edit.
- `docs/decisions.md` — no entry owed. This change leaves a diff, so its history is git log's; nothing here closes a fork.
- root `README.md` + `plugins/super-bootstrap/README.md` — read-and-confirm; no behavior changes, so no narration goes stale.

**Adjacent drift found, out of scope, needs its own card:** `plugins/super-bootstrap/skills/harness-bootstrap/SKILL.md:306` routes "Reference material — rejected alternatives, design rationale, architecture decisions, deep examples" to `docs/techstack.md § Coding Patterns`, which contradicts `docs/techstack.md:3` and `techstack-skeleton.md:3` ("Rejected stack directions are history, not state → `docs/decisions.md`, never a section here") plus the `docs/decisions.md` row that retired exactly that home. It is a harness file with its own verify pass — not this card's fix. It matters here only as a boundary: the implementer must not admit rejected-alternative content into § Coding Patterns on that row's authority.

### Test Strategy: e2e
