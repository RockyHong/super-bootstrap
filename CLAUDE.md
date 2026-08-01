# super-bootstrap

## Development Workflow

Work enters by picking up a card — a `docs/work/` card file (`/super-bootstrap:todo` pickup or a prose ID) — or grounding a new one via `/super-bootstrap:log`. The card is the grounding artifact (root-cause claim for a bug, problem statement for a feature) and the unit/anchor/boundary/SSOT of the change. Fresh work and resumed work use the same door.

### The envelope

`ground → route → implement → verify → doc-sync → commit`. Red and verify are structurally empty — no ceremony — on a diff with no test/runtime surface (docs-only). Verify on a harness-file change (CLAUDE.md, rules, skills, agents) = `audit-harness-edits`. Commit = `/super-bootstrap:commit`.

**Ambient laws inside implement:**

- **Test-first** — where a test surface exists, a failing test precedes the implementation.
- **Verify before claiming** — evidence before "done / fixed / passing": run the check, read the output, then claim.
- **Review received, not absorbed** — check a review claim against the code before implementing it; disagree with grounds rather than complying performatively.

**The runway ships bare by design** — no process-harness plugin stands behind these laws; installing one is an operator choice `/super-bootstrap:resolve-plugins` treats as an ordinary adaptive pick.

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

Settled design and step sequence land as `## Design` / `## Plan` blocks on the card's own thread ([`docs/work/`](docs/work/README.md)). Persistent specs (kept after merge) go to `docs/specs/`.

## Dispatch — who holds each phase

The gateway orchestrates; it does not build. Inline lane = orchestration, reads, bounded live tweaks (aesthetic / config value, applied + checked in-app). Everything carrying a **propagation closure** — the edit plus every truth it must keep in sync — dispatches to a clean subagent. Judge by closure, not diff size: a one-line config tweak owns no closure → inline; a one-line fix that chains triage + multi-file reads + doc-sync has a closure → dispatch.

- **Build** (within Implement) → dispatch per phase, gateway integrates + verifies between. Build is never a live tweak. **Every build-dispatch prompt carries the commit convention up front** — finish, report the work as built with the file list, do not `git commit`; the gateway fires `/super-bootstrap:commit`.
- **Transcription is not a build** — when the exact content is already in hand (a plan supplies verbatim old/new text, or the gateway already holds the final text) with no runtime to derive against, applying it carries zero closure: inline it, even mid-dispatch-regime. Reserve dispatch for content a container must derive: reads, integration, judgment.
- **Subagent commits route through the commit door** — a dispatched implementer implements + tests + reports (built + file list); the gateway commits via `/super-bootstrap:commit` (gateway-inline mechanics; the cold doc-sync scan dispatches only when its grep-gate hits). A fix→re-review loop scales to fix grade — a transcription-grade fix (shape fully supplied) → dispatcher verifies against the diff, no re-review dispatch; a judgment-grade fix (shape left to the implementer) → re-review dispatches. For free per-implementer commits, use the drain-worktree path — isolated commits, doc-sync deferred to the merge boundary.
- **Doc-sync scan** (envelope step) → gateway-inline; a grep-gate dispatches the cold `doc-sync-scan` agent only on a doc-surface hit (mechanism: § Doc Sync); resolving writes land inline or dispatched by closure.
- **Parallel within a phase, not across it** — N build sub-goals or N doc surfaces fan out together; build → doc-sync stays ordered (doc-sync needs the finished diff).
- **Create-new-file subagents dispatch foreground** — a subagent tasked to CREATE a new harness/skill file runs foreground, not `run_in_background`: backgrounded, its new-file Write fails and the subagent stalls before writing. Editing an existing file and creating a non-harness file background cleanly.

## Doc Sync (non-negotiable)

Named pipeline step — every route includes it between user review and commit. The commit door (`/super-bootstrap:commit`) runs gateway-inline; a mechanical grep-gate dispatches the cold `doc-sync-scan` agent when the diff touches the doc surface, and its `stale-docs` return goes to the gateway, which resolves with the user before the commit lands. Coverage backstop: `/check-docs-consistency` (on-demand, whole-repo).

Before every commit, scan for prose describing behavior touched by the diff — `docs/` (specs, overview, techstack, the [`docs/work/`](docs/work/README.md) card set) **and behavior-narrating prose outside `docs/`: the root `README`, plus any manifest/description field the diff's behavior changes**. If any looks stale:

1. Report it — path, what looks outdated, relevant diff context
2. Resolve together — update or acknowledge it's still accurate
3. Never silently fix. Never silently skip.

**Write boundary** — doc-sync writes narrative docs only: `docs/` and the root `README`. All harness — `CLAUDE.md`, `.claude/rules/`, skills, agents, plugin manifests — is **read-only within this step**: flag the drift and route the fix to its owner (a deliberate harness edit carrying its own verify pass; `/release` for manifests).

**Dimension routing (state XOR history — decide before writing any `docs/` file):**

State docs (`overview.md`, `techstack.md`, specs) hold what is **true now** — never timestamp precedent into them. Route by dimension:

- Decision still **binding** current work → present-tense constraint in the state doc it governs, stripped of when/why-decided. ("Refinement deferred behind the port" — not "on <date> we decided to defer refinement because…").
- Committed change history (what changed / when / why-of-a-change) → **git log + commit messages**. Don't hand-chronicle it into a doc.
- A direction evaluated and **closed** that left no diff (road-not-taken, wall foreseen) and would otherwise be re-proposed → [`docs/decisions.md`](docs/decisions.md).

**Card resolution:** if work resolves a `BUG-###` / `DEBT-###` / `GAP-###`, delete `docs/work/{ID}.md` — including a shipped feature-`GAP`, which now belongs to the product narrative (Problem / Current State / Module Index). Git history is the archive.

## Coding Principles

Before writing, reviewing, or refactoring code, read the coding standard: the pinned `karpathy-guidelines` skill — four principles (think-before-coding, simplicity-first, surgical-changes, goal-driven-execution). Skill body is upstream — don't paraphrase it.

A repo that declares its own `CODING_STANDARDS.md` overrides that default; the file is the standard where it exists.

## Edit Discipline — Renames & Replace-All

Rename preference order: LSP rename → per-occurrence Edit → `sed` (unique 8+ char literals) → `replace_all` (long unique literals only).

Banned-terms list + pre-flight checklist + recovery protocol: [`docs/techstack.md` § Edit Discipline](docs/techstack.md#edit-discipline).

## Context Hygiene

Subagent-first is the default container for build and doc phases (§ Dispatch); context weight is an additional dispatch trigger, not the only one. Compact while warm, clear on topic shift. Park mid-implementation state to the card's `## Progress` block before `/clear`.

## Finding Triage — Log vs Fix Now

Decide on two axes: **context budget** (is the window heavy?) and **topic distance** (on-goal, or far blast radius?).

- Context heavy **OR** off-topic / far blast → **log** via `/super-bootstrap:log`.
- On-topic **AND** context clean **AND** fix small + safe → **fix now**.

Surface a real fork to the user as an MCQ with the recommended path badged `(recommended)`. No real fork (trivial fix or trivial tangent) → act and mention, skip the MCQ.

## Rules (auto-load on file match)

`.claude/rules/*.md` files attach to file reads via `paths:` frontmatter — full-body rule fires at the decision moment, zero ambient cost when irrelevant.

- **`dimension-discipline.md`** — fires on `docs/**/*.md`, `README.md`
  • Before editing a prose doc, classify what it owns: state (overwrite in place) vs history (append-only, git's job).
- **`ssot-doc-link.md`** — fires on `docs/**/*.md`, `README.md`
  • Link each concept to its SSOT home as you write — born-linked, not back-filled.
- **`repo-boundary.md`** (native) — fires on `CLAUDE.md`, `plugins/**`, `.claude/rules/**`, `.claude/guidelines/**`
  • State which copy is under test (published vs in-repo dev). Route findings: this repo's artifacts → `/super-bootstrap:log`; device/global config → `/contribute` (imported artifacts read-only).
  • Taste-coupling: dogfood harness (this repo's own CLAUDE.md/rules) may wire served guidelines; shipped skeletons (`plugins/*/skills/*/assets/**`) must be self-contained — downstream ≠ author.
  • Sync direction: editing a dogfood-harness section pulls any shipped-skeleton counterpart into the edit's closure; propagate stripped of dogfood-only refs, or state it's dogfood-specific.
- **`skill-authoring.md`** (native) — fires on `plugins/*/skills/**`
  • Skill edits route by test surface: behavior-shaping prose → `superpowers:writing-skills` RED first (micro-test floor); mechanical → audit + release checks.

First two served from the personal claude-config repo (predicates in `.claude/guidelines/work-discipline/`). Add a project-specific rule file when a path-scoped pattern emerges (e.g. a SKILL.md authoring convention), then mirror a one-line summary here.

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
- [`docs/work/`](docs/work/README.md) — open cards (`BUG-###` / `DEBT-###` / `GAP-###` append-only threads), captured via `/super-bootstrap:log`, deleted on resolve; `README.md` holds the thread contract + ID high-water line.
- [`docs/decisions.md`](docs/decisions.md) — closed forks / rejected directions, all domains (history dimension). See its scope header for admission criteria; checked at triage.
- `.claude/rules/` — path-scoped rules, full-body fires on file match (see Rules section above)

> `docs/specs/` = permanent source of truth; working design and plan live as blocks on the owning card's thread.
