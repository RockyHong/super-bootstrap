# {Project Name}

<!--
  Skeleton target: every line earns its always-on slot.
  Length is downstream of that — opinionated lean, ~120 lines.
  Path-scoped patterns live in .claude/rules/ (full-body, fires on file match).
  Reference material (code patterns, examples) lives in docs/techstack.md.
  CLAUDE.md is the orchestrator brief — workflow gates + always-on rules + rules index.
-->

## Development Workflow

Every session runs under the superpowers frame. Routing = **which phases this work needs**, judged on evidence — not file count, not size labels. Triage phases, propose route, wait for user confirm.

### Phase Gates

| Phase | Run when | Skip when |
|---|---|---|
| **Brainstorm** | Intent fuzzy, design space unexplored, multiple viable shapes | Intent + approach obvious from repo context or user direction |
| **Spec** | Persistent design surface — behavior worth pinning for future sessions | One-time tactical change, no behavior to document |
| **Plan** | Multi-step, ordering matters, want checkpoint review, half-done risk | Single atomic edit obvious from context |
| **Execute (TDD + verify)** | Touching code | Always-on when code changes — never skip discipline |
| **Doc sync** | Pre-commit | Always-on — never skip |
| **Commit (`/super-bootstrap:commit`)** | Work done | Always-on — terminal step. |

### Triage output

Propose phase composition + justify each skip with repo-grounded evidence:

```
Phases: brainstorm → plan → execute → doc-sync → commit
Skipped: spec (no persistent design surface — internal helper, no behavior contract)
Evidence: BUG-042 has clean repro in issue, fix touches one auth helper
OK to proceed?
```

### Phase entailments

Don't ship a later phase while an earlier one is still fuzzy:

- **Spec** implies brainstorm-grade thinking happened (inline OK if intent was clear). No spec while intent unclear.
- **Plan** implies design settled. No plan while design surface still moving.
- **Execute** implies steps known (from plan, or from atomic-edit obviousness). No execute on multi-step work without a plan.
- **Symptom-driven work** (bug / regression / rot): no plan or execute until cause confirmed via `superpowers:systematic-debugging`. Symptom location ≠ cause location.

If user pushes back on triage → re-evaluate the gate that triggered the disagreement, not the whole route.

**User instructions override Superpowers defaults.** User can add or drop phases.

Spec/plan locations: `docs/superpowers/specs/` and `docs/superpowers/plans/` (temporal). Persistent specs (kept after merge) go to `docs/specs/`.

## Doc Sync (non-negotiable)

Named pipeline step — every route includes it between user review and commit.

Before every commit, scan `docs/` for files describing behavior touched by the diff (specs, overview, techstack, backlog). If any doc looks stale:

1. Report it — doc path, what looks outdated, relevant diff context
2. Resolve together — update or acknowledge it's still accurate
3. Never silently fix. Never silently skip.

**Temporal cleanup:** if work completes a feature branch, delete its spec and plan files from `docs/superpowers/specs/` and `docs/superpowers/plans/`. Once merged, they're noise.

**Roadmap cleanup:** if work ships a feature listed in `docs/overview.md` § Roadmap, remove that line — feature now belongs to product narrative (Problem / Current State / Module Index), not the forward list.

{**Backlog cleanup:** if work resolves a `BUG-###` / `DEBT-###` / `GAP-###` from `docs/backlog.md`, delete that item. Git history is the archive.}

## Coding Principles

Before writing, reviewing, or refactoring code, invoke the `karpathy-guidelines` skill.

It owns four principles (think-before-coding, simplicity-first, surgical-changes, goal-driven-execution). Skill body is upstream — don't paraphrase it here. Pin lives in `.claude/settings.json` (`andrej-karpathy-skills@karpathy-skills`).

## Edit Discipline — Renames & Replace-All

`Edit replace_all: true` is naive whole-file string replace — no AST, no scope, no token boundaries. Running on common identifiers silently corrupts unrelated code (`state` → `swipe` rewrites `SwipeState` to `SwipeSwipe`, import paths, comments, CSS selectors). The trap is invisible until the next type-check.

**Preference order:**

1. **LSP rename** — symbol-aware, scope-respecting. Best for typed languages (TS, Rust, Go, Java, Python with pyright, C#).
2. **Per-occurrence Edit with unique surrounding context** — when LSP unavailable. Grep call sites; each Edit's `old_string` includes enough context to be unique to that call.
3. **`sed` / scripted bulk replace** — only when term is **8+ chars and unique to the domain** (`Conversation`, `MerchandiseInventory`). Always case-preserving pair: `s/OldName/NewName/g; s/oldName/newName/g; s/OLD_NAME/NEW_NAME/g`. Run build/test cycle immediately.
4. **`Edit replace_all: true`** — only on unique long string literals (URLs, full sentences, hash IDs). Never on identifiers <8 chars. Never on common English words.

**Pre-flight checklist (any bulk replace):**

1. Grep the exact term. Look at count + sample matches.
2. If hits >5 OR length <8 OR common English word → switch to options 1–3.
3. Scan sample matches for false positives (substrings inside other identifiers, string literals, CSS classes overlapping HTML tags, comments).
4. Any doubt → per-occurrence Edit. Caution token cost ≪ silent-corruption debug cost.

**Banned terms for `replace_all`** (always per-occurrence):
`state`, `name`, `data`, `value`, `item`, `key`, `id`, `type`, `props`, `node`, `text`, `link`, `error`, `result`, `body`, `head`, `main`, `time`, `path`, `file`, `index`, `count`, `child`, `style`, `class`, `tag`, `event`, `target`, `source`, `from`, `to`, `next`, `prev`, `init`, `done`.

**When a `replace_all` slips through:**

1. `git diff` first — see damage scope.
2. If uncommitted, `git checkout` the file and redo with the right tool.
3. If committed, fix as a NEW commit (preserves mistake in history).
4. Run type-check / lint / test — usually points straight at corruption.

Always run build/test after bulk operations.

## Context Hygiene

Multi-needle recall degrades past ~200k input tokens. Sweet spot: ≤80k = 100% recall, 200-300k = 95%. Cache solves token cost; quality is the constraint.

- **Subagent-first for verbose work** — reading 10+ files, noisy test suites, parallel-safe chunks, fresh-eye review. Subagent gets a clean window; orchestrator stays sharp. Skip for <3-5k token tasks (init overhead swamps gain).
- **Compact while warm.** `/compact` only inside cache TTL (5min default, 1hr extended). Idle compact pays full price to summarize. If away, prefer `/clear`.
- **Clear on topic shift.** Cache wasted across topic boundaries anyway. Free quality reset.
- **Park before /clear** mid-implementation. Short handoff note (state, next step, open questions) so next session resumes.

Default order when context heavy: subagent → compact (warm) → clear (cold/topic-shifted) → park (mid-implementation at risk).

## Finding Triage — Log vs Fix Now

When a finding worth acting on surfaces mid-work (during/after implementation, or when a subagent reports back) but isn't the current goal, fork it — don't drift into it silently, don't drop it silently.

Decide on two axes: **context budget** (is the window heavy? — see Context Hygiene) and **topic distance** (on-goal, or far blast radius?).

- Context heavy **OR** off-topic / far blast → **log** it: `docs/backlog.md` (BUG/DEBT/GAP) if present, else a deferred note to the user.
- On-topic **AND** context clean **AND** fix small + safe → **fix now**.

Surface a real fork to the user as an MCQ with the recommended path badged `(recommended)`. No real fork (trivial fix or trivial tangent) → act and mention, skip the MCQ.

## Rules (auto-load on file match)

`.claude/rules/*.md` files attach to file reads via glob frontmatter — full-body rule fires at the decision moment, zero ambient cost when irrelevant. Summary below so this orchestrator knows the rule exists during planning.

{seeded by sp-bootstrap based on Phase 1 stack signals — examples:}

{- **`rules/<framework>.md`** — fires on `{framework component glob}`}
{  • {one-line key rule}}
{  • {one-line key rule}}

{- **`rules/mv3.md`** — fires on `src/background/**`, `src/content/**`}
{  • {one-line key rule}}
{  • {one-line key rule}}

{If rule body needs more context than its summary provides during planning, read the rule file directly before designing — `Read .claude/rules/<name>.md`.}

## Solo Dev Assumptions

Single developer across multiple Claude Code sessions.

- No PR self-review — commit directly to working branch
- Simple branching — `main` + feature branches, no rebasing
- No force push — every commit is sacred
- Session isolation — each Claude session commits only its own changes
- No merge conflicts expected — if one occurs, stop and ask

## Tech Stack

{detected one-line summary, e.g. "Node 20 + Next 14 + Postgres + pnpm"}

→ Full stack table, dependency philosophy, architecture rules, coding patterns in [`docs/techstack.md`](docs/techstack.md).

## Commands

```bash
{detected from scripts/Makefile/Cargo — only what exists right now}
```

## Git Notes

- Only commit current session's changes — leave unrelated uncommitted work alone
- Atomic commits — one logical change per commit
- Conventional commits — `feat:`, `fix:`, `refactor:`, `docs:`, `test:`, `chore:`

## Planning

- [`docs/overview.md`](docs/overview.md) — product context, data flow, module index, `## Roadmap` (forward feature list — single pillar for "what product will become"; read by `/super-bootstrap:todo`). Skeleton seeded at scaffold; grown sections fill via doc-sync.
- [`docs/techstack.md`](docs/techstack.md) — stack, architecture rules, coding patterns. Skeleton seeded at scaffold; grown sections fill via doc-sync.
{- [`docs/specs/`](docs/specs/) — persistent feature specs, one `.md` per feature. Filename + heading is the catalog; no index.}
{- [`docs/backlog.md`](docs/backlog.md) — deferred items (`BUG-###` / `DEBT-###` / `GAP-###`), deleted on resolve.}
- `docs/superpowers/specs/` — design specs from brainstorming (temporal — deleted after merge)
- `docs/superpowers/plans/` — implementation plans (temporal — deleted after merge)
- `.claude/rules/` — path-scoped rules, full-body fires on file match (see Rules section above)

> **Two kinds of specs:** `docs/specs/` = permanent source of truth. `docs/superpowers/specs/` = temporal work orders.
