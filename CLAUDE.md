# super-bootstrap

## Development Workflow

Work enters by picking up a card — a `docs/work/` card file (`/super-bootstrap:todo` pickup or a prose ID) — or grounding a new one via `/super-bootstrap:log`. The card is the grounding artifact (root-cause claim for a bug, problem statement for a feature) and the unit/anchor/boundary/SSOT of the change. Fresh work and resumed work use the same door.

### The envelope

`ground → route → implement → verify → doc-sync → commit`. Red and verify are structurally empty — no ceremony — on a diff with no test/runtime surface (docs-only). Verify on a harness-file change (CLAUDE.md, rules, skills, agents) = `audit-harness-edits`. Commit = `/super-bootstrap:commit`.

**Ambient laws inside implement:**

- **Test-first** — where a test surface exists, a failing test precedes the implementation.
- **Verify before claiming** — evidence before "done / fixed / passing": run the check, read the output, then claim.
- **Review received, not absorbed** — check a review claim against the code before implementing it; disagree with grounds rather than complying performatively. Judgment-grade findings: `review-intake` first (§ Dispatch).

Bootstrap pins one process harness behind these laws, droppable per repo. To add another: `/super-bootstrap:resolve-plugins` — an ordinary adaptive pick, not a requirement.

### Cluster routing

Recognize the card's shape, then take that row's discipline; a repo that installs a process harness maps its entries onto these shapes.

| # | Cluster | Route |
|---|---|---|
| 1 | Bug / broken behavior | root cause before fix — reproduce, trace to the mechanism, then change |
| 2 | Fuzzy feature / new capability | settle the design with the user before building |
| 3 | Design-intact multi-step | write the step sequence down before touching code |
| 4 | Refactor | ground the card; multi-step → cluster 3, atomic → envelope only |
| 5 | Config / taste / bounded tweak | inline; taste that iterates or drifts → card it |
| 6 | Docs / prose | envelope only |
| 7 | Harness edit | `load-harness-principles` pre, `audit-harness-edits` post |
| 8 | Triage / investigation-only | card → `/super-bootstrap:triage {ID}` (verdict phase appending a Verdict block to the card); ad-hoc question → inline reads + dispatched probes |

### Framing + Route — state, don't gate

State the card's **problem-aim** before routing — premise / problem / scenario only, synthesized self-coherent (hold back the card's Prior; restate rather than paste index-quotes) — then state cluster + route. Both scale together: resolvable from the card/SSOT → post in one line and proceed (framing line + route line); stop for the user's explicit OK only on a genuine fork — ambiguous cluster, a conflict with a closed fork in [`docs/decisions.md`](docs/decisions.md), high blast radius, or card-claim ambiguity / suspected mis-aim. Hold the aligned aim as the check on everything machinery returns: a verdict or solution that re-aims the problem is surfaced, not absorbed (`aligned ≠ correct` — the user confirms the target, not the answer).

### Sizing — scale ceremony to the work's shape

Route defaults assume worst-case — fuzzy-new work, a cold executor, every task equally central. Scale each down to the shape in hand; § Dispatch's closure valves scale dispatch grade the same way.

- **Route depth keys on shape-familiarity, not cluster alone** — a known-shape repeat (the Nth same-shape artifact) routes lighter than its nominal cluster, skipping the discovery ceremony (design settling, a full written plan) a first-of-shape needs.
- **Task boundary = logical-change-unit, not surface-group** — one change narrated across N file clusters is one task + one commit, not N. Batch same-logical-change surfaces.
- **Per-task verify depth scales to surface centrality** — an ambient-loaded harness surface (CLAUDE.md, a rule, an agent) earns a full cold audit whatever the change size; an isolated low-centrality surface (a README line, a manifest field, a docs paragraph) earns a light pass.
- **Same-session author == executor → reference, don't embed** — a plan written for a cold executor embeds full file bodies; when the authoring session also executes, reference draft bodies by section instead of re-embedding full file text.

Settled design and step sequence land as `## Design` / `## Plan` blocks on the card's own thread ([`docs/work/`](docs/work/README.md)).

## Dispatch — who holds each phase

The gateway orchestrates; it does not build. Inline lane = orchestration, reads, bounded live tweaks (aesthetic / config value, applied + checked in-app). Everything carrying a **propagation closure** — the edit plus every truth it must keep in sync — dispatches to a clean subagent. Judge by closure, not diff size: a one-line config tweak owns no closure → inline; a one-line fix that chains triage + multi-file reads + doc-sync has a closure → dispatch.

- **Build** (within Implement) → dispatch per phase, gateway integrates + verifies between. Build is never a live tweak. **Every build-dispatch prompt carries the commit convention up front** — finish, report the work as built with the file list, do not `git commit`; the gateway fires `/super-bootstrap:commit`.
- **Transcription is not a build** — when the exact content is already in hand (a plan supplies verbatim old/new text, or the gateway already holds the final text) with no runtime to derive against, applying it carries zero closure: inline it, even mid-dispatch-regime. Reserve dispatch for content a container must derive: reads, integration, judgment.
- **Review findings are claims, not instructions** — a judgment-grade review finding routes through the cold `review-intake` judge before any implementer sees it: claims pass numbered + verbatim with their cited surfaces (pointer-less ones marked `(no surface citation)`), minus fix preferences and dispatcher theories; per-claim `confirmed | falsified | needs-evidence` + a coverage line return to the gateway. Confirmed → dispatch at fix grade; falsified → stops at the gateway; needs-evidence → run or delegate the named check. A transcription-grade patch skips intake only when the gateway itself verified the cited text.
- **Subagent commits route through the commit door** — a dispatched implementer implements + tests + reports (built + file list); the gateway commits via `/super-bootstrap:commit`. A fix→re-review loop scales to fix grade — a transcription-grade fix (shape fully supplied) → dispatcher verifies against the diff, no re-review dispatch; a judgment-grade fix (shape left to the implementer) → re-review dispatches. For free per-implementer commits, use the drain-worktree path — isolated commits, doc-sync deferred to the merge boundary.
- **Doc-sync scan** (envelope step) → gateway-inline; a mechanical gate dispatches the cold `doc-sync-scan` agent only on a doc-surface hit (mechanism: § Doc Sync); resolving writes land inline or dispatched by closure.
- **Parallel within a phase, not across it** — N build sub-goals or N doc surfaces fan out together; build → doc-sync stays ordered (doc-sync needs the finished diff).
- **Writer run mode keys on path overlap, not writer class** — foreground when the writer's paths overlap what the session will keep editing; no overlap (new files included) → background, long build-class dispatches included. Full criterion: `.claude/guidelines/work-discipline/dispatch-run-mode.md`. Narrow exception: under a paired PreToolUse(Write) context-injector hook that is **not subagent-gated** — it still emits when the payload carries `agent_type` — a backgrounded subagent's new-file Write can stall before writing (platform defect); with such a hook wired, new-file writers dispatch foreground. Conformance is read off the wired hook in `settings.json`: a gated or unpaired injector leaves background dispatch free. Full: `~/.claude/guidelines/claude-shape/hook-feedback-channels.md` § Background-subagent Write-create.

## Doc Sync (non-negotiable)

**The guarantee is retrieval-shaped:** any restated fact a reader lands on reaches its SSOT home in one hop — a markdown link on the asserting line, authored when the line is written (`ssot-doc-link` rule). Structure carries the guarantee; the commit door maintains the structure rather than re-deriving the whole doc surface per commit.

Named pipeline step — every route includes it between user review and commit. The commit door (`/super-bootstrap:commit`) runs gateway-inline and maintains the guarantee in three layers:

1. **Link integrity (mechanical, every non-deferred commit)** — broken path/anchor surfaces with the commit; fix or acknowledge, never silently skip.
2. **Touched-truth propagation (mechanical enumeration, cold judgment)** — term-grep, reverse-citer lookup, and forward link-target extraction enumerate who narrates, cites, or is cited by what the diff changed; a hit dispatches the cold `doc-sync-scan` agent scoped to those docs plus the diff, and its `stale-docs` return goes to the gateway, which resolves with the user before the commit lands.
3. **New-assertion residual (diff-scoped judgment)** — the same scan checks the diff's new asserting lines only: a linked line is read against its link target, an unlinked one against any existing doc answering the same question.

Doc surface: `docs/` (specs, overview, techstack, the [`docs/work/`](docs/work/README.md) card set) **plus behavior-narrating prose outside `docs/`: the root `README`, any plugin README the repo ships (`plugins/*/README.md`), and any manifest/description field the diff's behavior changes**. Refinements — card-lifecycle skip, premise-closure lane — live in the commit door's skill body. Coverage backstop: `/super-bootstrap:check-docs-consistency` (on-demand — the one remaining whole-surface pass).

Stale candidates resolve together: report path + what looks outdated + relevant diff context; update or acknowledge still-accurate — never silently fix or skip. Every doc the gate enumerates gets an outcome marker (updated, or read-and-confirmed-unchanged): [`.claude/guidelines/work-discipline/doc-impact-mirror.md`](.claude/guidelines/work-discipline/doc-impact-mirror.md).

**Write boundary** — doc-sync writes narrative docs only: `docs/`, the root `README`, and plugin READMEs (`plugins/*/README.md`). All harness — `CLAUDE.md`, `.claude/rules/`, skills, agents, plugin manifests — is **read-only within this step**: flag the drift and route the fix to its owner (a deliberate harness edit carrying its own verify pass; `/release` for manifests).

**Dimension routing (state XOR history — decide before writing any `docs/` file):**

State docs (`overview.md`, `techstack.md`, specs) hold what is **true now** — never timestamp precedent into them. Route by dimension:

- Decision still **binding** current work → present-tense constraint in the state doc it governs, stripped of when/why-decided. ("Refinement deferred behind the port" — not "on <date> we decided to defer refinement because…").
- Committed change history (what changed / when / why-of-a-change) → **git log + commit messages**. Don't hand-chronicle it into a doc.
- A direction evaluated and **closed** that left no diff (road-not-taken, wall foreseen) and would otherwise be re-proposed → [`docs/decisions.md`](docs/decisions.md).

**Card resolution:** if work resolves a `BUG-###` / `DEBT-###` / `GAP-###`, delete `docs/work/{ID}.md` — including a shipped feature-`GAP`, which now belongs to the product narrative (Problem / Current State / Module Index). Git history is the archive.

## Coding Principles

Before writing, reviewing, or refactoring code, read `CODING_STANDARDS.md` at the repo root — a filled section governs its concern; where no section declares a concern, default judgment applies.

## Edit Discipline — Renames, Replace-All & Stale State

Rename preference order: per-occurrence Edit (call sites from LSP `findReferences` or Grep) → `sed` (unique 8+ char literals) → `replace_all` (long unique literals only).

Stale-state family: Read a file before its first Edit; re-Read after a stale/unread Edit error, or after any write that landed behind your read-tracker (formatter hook, a returned file-writing subagent — `git diff` is not a Read). Two consecutive same-file Edit failures = mandatory re-Read.

Banned-terms list + pre-flight checklist + recovery protocol + stale-state predicate + re-Read triggers: [`docs/techstack.md` § Edit Discipline](docs/techstack.md#edit-discipline).

## Context Hygiene

Subagent-first is the default container for build and doc phases (§ Dispatch); context weight is an additional dispatch trigger, not the only one. Compact while warm, clear on topic shift. Park mid-implementation state to the card's `## Progress` block before `/clear`.

## Finding Triage — Log vs Fix Now

Decide on two axes: **context budget** (is the window heavy?) and **topic distance** (on-goal, or far blast radius?).

- Context heavy **OR** off-topic / far blast → **log** via `/super-bootstrap:log`.
- On-topic **AND** context clean **AND** fix small + safe → **fix now**.

Surface a real fork to the user as an MCQ with the recommended path badged `(recommended)`. No real fork (trivial fix or trivial tangent) → act and mention, skip the MCQ.

## Rules (auto-load on file match)

`.claude/rules/*.md` files attach to file reads via `paths:` frontmatter — full-body rule fires at the decision moment, zero ambient cost when irrelevant.

- **`dimension-discipline.md`** — fires on `docs/**/*.md`, `README.md`, `plugins/*/README.md`
  • Before editing a prose doc, classify what it owns: state (overwrite in place) vs history (append-only, git's job).
- **`ssot-doc-link.md`** — fires on `docs/**/*.md`, `README.md`, `plugins/*/README.md`
  • Link each concept to its SSOT home as you write — born-linked, not back-filled.
- **`config-overlay.md`** — fires on `.claude/settings.json`, `.claude/settings.local.json`, `.claude/hooks/**`, `.mcp.json`
  • Default to upstream canonical wiring as shipped; empirically prove canonical fails before authoring an overlay, and date-stamp any overlay kept as decay debt.
  • Place ambient-behavior config at the lowest layer every target runtime loads; document parity exceptions explicitly.
- **`repo-boundary.md`** (native) — fires on `CLAUDE.md`, `plugins/**`, `.claude/{rules,guidelines,hooks,skills,agents}/**`
  • State which copy is under test (published vs in-repo dev). Route findings by provenance: this repo's own artifacts → `/super-bootstrap:log`; served or imported copies (under this repo's `.claude/` too) → `/contribute`, never a local-clone edit.
  • Taste-coupling: dogfood harness (this repo's own CLAUDE.md/rules) may wire served guidelines; shipped skeletons (`plugins/*/skills/*/assets/**`) must be self-contained — downstream ≠ author.
  • Sync direction: editing a dogfood-harness section pulls any shipped-skeleton counterpart into the edit's closure; propagate stripped of dogfood-only refs, or state it's dogfood-specific.
- **`skill-authoring.md`** (native) — fires on `plugins/*/skills/**`
  • Skill edits route by test surface: behavior-shaping prose → RED first (micro-test floor); mechanical → audit + release checks.

First three served from the personal claude-config repo (predicates in `.claude/guidelines/work-discipline/`). Add a project-specific rule file when a path-scoped pattern emerges (e.g. a SKILL.md authoring convention), then mirror a one-line summary here.

If rule body needs more context than its summary provides during planning, read the rule file directly before designing — `Read .claude/rules/<name>.md`.

## Tech Stack

Markdown-authored Claude Code plugin + self-hosted marketplace — no language runtime or build step.

→ Full stack table, dependency philosophy, architecture rules, coding patterns in [`docs/techstack.md`](docs/techstack.md).

## Commands

```bash
# No build system — skills/agents are markdown, loaded by Claude Code's plugin loader.
# Release (bump plugin.json version, sync marketplace description mirror, commit, tag):
/release
```

## Git Notes

- Only commit current session's changes — leave unrelated uncommitted work alone
- Atomic commits — one logical change per commit
- Conventional commits — `feat:`, `fix:`, `refactor:`, `docs:`, `test:`, `chore:`
- No PR self-review — commit directly. Main + feature branches. No force push.
- Merge conflict → stop and ask.

## Planning

- [`docs/overview.md`](docs/overview.md) — product context, data flow, module index.
- [`docs/techstack.md`](docs/techstack.md) — stack, architecture rules, coding patterns.
- [`docs/specs/`](docs/specs/) — feature specs, one `.md` per feature. Filename + heading is the catalog; no index.
- [`docs/work/`](docs/work/README.md) — open cards (`BUG-###` / `DEBT-###` / `GAP-###` append-only threads), captured via `/super-bootstrap:log`, deleted on resolve; `README.md` holds the thread contract + ID high-water line.
- [`docs/decisions.md`](docs/decisions.md) — closed forks / rejected directions, all domains (history dimension). See its scope header for admission criteria; checked at triage.
- `.claude/rules/` — path-scoped rules, full-body fires on file match (see Rules section above)

> `docs/specs/` = permanent source of truth; working design and plan live as blocks on the owning card's thread.

## Agent skills

Configuration read by the installed mattpocock/skills set ([coexistence runbook](docs/specs/mattpocock-coexistence.md)).

### Issue tracker

This repo's card tracker (§ Planning). See [`docs/agents/issue-tracker.md`](docs/agents/issue-tracker.md).

### Triage labels

The canonical five, mapped onto card state (`## Verdict` block). See [`docs/agents/triage-labels.md`](docs/agents/triage-labels.md).

### Domain docs

Single-context, retargeted at `docs/` (`overview.md` = CONTEXT role, `decisions.md` = ADR role). See [`docs/agents/domain.md`](docs/agents/domain.md).
