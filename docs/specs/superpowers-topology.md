# Superpowers Topology — Upstream Reference Map

**Upstream:** superpowers **6.1.1** (commit `d884ae0`, released 2026-07-02, obra/superpowers) · **Verified:** 2026-07-08, full-tree read-only probe (14/14 SKILL.md + all prompt templates, scripts, manifests, hooks).
**Why this exists:** super-bootstrap rides superpowers on the user's behalf — this doc is the one home for the beast's *verified* topology, so routing derives from map, not memory. Consulted at entry/route time; cited by [`CLAUDE.md`](../../CLAUDE.md) § Development Workflow.
**Refresh trigger:** on superpowers version change, re-probe and overwrite in place (state doc — no chronicle). Most volatile surfaces by release history: `using-superpowers` body, hook manifests, `subagent-driven-development` scripts/workspace, `references/*.md`.

---

## Constitution — authority + injection

- **Injection:** ONE harness surface — a `SessionStart` hook (`startup|clear|compact`) that injects `using-superpowers` full-body into every session. **0 commands, 0 named agents, 0 MCP** — all subagent dispatch in every skill uses generic `general-purpose` + inline prompt templates.
- **Authority order (their own law):** *"User instructions (CLAUDE.md, AGENTS.md, …, direct requests) take precedence over skills, which in turn override default behavior."* — CLAUDE.md-level routing of entries is **sanctioned by upstream**, not boundary bleed.
- **Subagent exemption:** `<SUBAGENT-STOP>` — *"If you were dispatched as a subagent to execute a specific task, ignore this skill."* Dispatched subagents are exempt from the bootstrap discipline; they follow their dispatch prompt.
- **Human skip valve:** *"Only skip skill workflows or instructions when your human partner has explicitly told you to."*

## Entry points — three, all documented

| Entry | Fires for | Gate at that entry |
|---|---|---|
| `brainstorming` | feature / fuzzy intent ("let's build X") | `<HARD-GATE>` — no implementation action until a design is presented AND user-approved; anti-skip: *"EVERY project regardless of perceived simplicity"* |
| `systematic-debugging` | bug ("fix this bug") | Iron Law — *"NO FIXES WITHOUT ROOT CAUSE INVESTIGATION FIRST"*; no fast path (*"Don't skip when: issue seems simple / you're in a hurry"*); 3+ failed fixes → stop, question architecture |
| `writing-plans` **direct** | **design already intact** — *"Use when you have a spec or requirements for a multi-step task"* | brainstorming's HARD-GATE lives in brainstorming's own body only — direct entry here with an existing spec violates nothing |

## The chain — four links, then convergence

```
brainstorming ──REQUIRED──▶ writing-plans ──choice──▶ subagent-driven-development (recommended)
                                          └────────▶ executing-plans (no-subagent fallback)
systematic-debugging (Phase 4 → TDD; no doc artifact)         │
                                       both paths ──REQUIRED──▶ finishing-a-development-branch
                                       both paths invoke using-git-worktrees at execution time
                                       sdd → requesting-code-review (final whole-branch review)
```

- Every hop is a hard in-body pointer (`REQUIRED SUB-SKILL: superpowers:<name>`); the chain is self-propelling once entered.
- The one legitimate in-chain choice-point: `writing-plans` → subagent-driven vs inline execution (`executing-plans` self-describes as the fallback: *"If subagents are available, use superpowers:subagent-driven-development instead"*).

## Ambient rules — position-free, fire on own trigger (not chain links)

| Skill | Trigger | Skip semantics |
|---|---|---|
| `test-driven-development` | before any production code | Iron Law; narrow human-gated exceptions only: *"Throwaway prototypes / Generated code / Configuration files"* |
| `verification-before-completion` | before any completion claim | none — rationalization table closes every escape |
| `receiving-code-review` | when feedback arrives | none; verify-before-implement always |
| `dispatching-parallel-agents` | 2+ independent problems | has explicit "When NOT to Use" (related failures / need full context / shared state) |

## Per-skill essentials

| Skill | Produces → consumes | Load-bearing machinery |
|---|---|---|
| `brainstorming` | `docs/superpowers/specs/YYYY-MM-DD-<topic>-design.md` (committed) → writing-plans | optional visual-companion (Node WS server); spec-reviewer prompt is **orphaned** (see drift) |
| `writing-plans` | `docs/superpowers/plans/YYYY-MM-DD-<feature>.md`; header embeds the next-skill pointer | plan-reviewer prompt **orphaned** (see drift) |
| `subagent-driven-development` | `.superpowers/sdd/` workspace: per-task brief/report, review diff, **`progress.md` ledger (survives compaction)** | `scripts/review-package`, `scripts/task-brief`, `scripts/sdd-workspace`; implementer + task-reviewer prompt templates; first-class per-dispatch **model-tier rule** (*"Turn count beats token price"*) |
| `executing-plans` | todo-state only | none |
| `using-git-worktrees` | worktree (`.worktrees/<branch>`) or no-op | **Step 0 detect-and-skip built in** (existing isolation → skip creation) |
| `finishing-a-development-branch` | merge/PR/keep/discard outcome | tests-pass hard stop before menu; typed `discard` confirm; worktree provenance check before cleanup |
| `requesting-code-review` | reviewer verdict off `BASE_SHA..HEAD_SHA` | `code-reviewer.md` template; read-only on checkout |
| `systematic-debugging` | root-cause + regression test (via TDD) | `find-polluter.sh` (test-pollution bisect); root-cause-tracing / defense-in-depth / condition-based-waiting references |
| `writing-skills` | tested SKILL.md (meta; outside dev flows) | Iron Law (no skill without failing test); vendored Anthropic best-practices; pressure-test methodology |

## Truth-source taxonomy — shaping entries

| Entry | Truth source | Done = | Handoff |
|---|---|---|---|
| `brainstorming` | user's latent vision (elicited) + project context | user-approved written design | spec file → writing-plans |
| `systematic-debugging` | codebase/runtime truth (repro, traces, instrumentation) | root cause confirmed by minimal test | failing→passing regression test |
| `writing-plans` | an existing approved spec (derived truth) | every requirement mapped to tasks, no placeholders | plan file → execution |
| `using-git-worktrees` | live git state (`GIT_DIR`/`GIT_COMMON`) | isolated workspace w/ clean baseline | worktree path → execution |

## Assumption profile vs this repo's flow

- **Execution tail assumes branch/worktree flow:** sdd — *"Never start implementation on main/master without explicit user consent"* (consent valve, not absolute); `finishing-a-development-branch` is branch/worktree-native (menu + cleanup ordering); `using-git-worktrees` mitigates via Step-0 detect-and-skip.
- This repo is **main-direct solo** ([`CLAUDE.md`](../../CLAUDE.md) § Git Notes: main + feature branches, no PR self-review; merge via `/super-bootstrap:merge`). Tension zone is the tail only — shaping entries carry no branch assumptions.

## Upstream drift findings (verified 2026-07-08 against source)

- `brainstorming/spec-document-reviewer-prompt.md` + `writing-plans/plan-document-reviewer-prompt.md` ship but are referenced by **no live skill body** (orphans of the removed document-review-system).
- Root `GEMINI.md` `@`-includes `references/gemini-tools.md`, which no longer exists (Gemini support removed v6.1.0).
- `AGENTS.md` is a git symlink (`120000`) → `CLAUDE.md`; on Windows checkouts with `core.symlinks=false` it materializes as a 9-byte literal-string file.
