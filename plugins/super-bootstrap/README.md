# super-bootstrap (plugin)

Plugin-level contributor doc for the `super-bootstrap` plugin. End-user docs live in the repo-root `README.md`.

## Skill catalog

- `super-bootstrap` — public entry, greenfield gate, dispatches to `harness-bootstrap`.
- `harness-bootstrap` — installs/syncs the harness (CLAUDE.md, skeleton docs, rules, picks).
- `resolve-plugins` — curates skill/MCP/hook picks against live sources, writes `.claude/settings.json`. Standalone or delegated from `harness-bootstrap` Phase 3c.
- `sb-todo` — scans active specs/plans, reports cycle stage + blockers. Dispatches `agents/sb-todo.md` on Sonnet.
- `sb-help` — passive on-demand index of installed user-invoke skills, grouped by category. Dispatches `agents/sb-help.md` on Haiku.
- `sb-commit` — session-isolated commit, doc-sync gated, conventional message, no push.
- `sb-merge` — absorb feature branches into base. Per-branch rebase-vs-merge recommendation, clean execution. Hard SoC: on conflict, aborts + surfaces file list + stops. Resolution out of scope (user routes next pass). Inline; same context-awareness rationale as `sb-commit`.
- `release-init` — one-shot. Detects project type (unity / tauri / node / ios-native / android-native / generic) + multi-platform shape, generates a tailored project-level `/release` skill at `.claude/skills/release/SKILL.md`. Optional bonus — run only if the repo ships versioned releases.

## Naming convention

| Prefix shape | Tier | Frequency | Examples |
|---|---|---|---|
| `sb-*` | In-flight ops | High (per-session, per-commit) | `sb-commit`, `sb-todo` |
| Self-explanatory verb-noun | Bootstrap / system / lifecycle | Low (rare invocations) | `super-bootstrap`, `harness-bootstrap`, `resolve-plugins` |

**Why:** `sb-*` shorthand is amortized by repetition. Lifecycle-tier skills fire rarely — name must read clearly cold without prefix knowledge.

**When adding a new skill:** decide tier first. High-freq in-flight (will user invoke this multiple times per session?) → `sb-*`. Lifecycle / one-shot setup → self-explanatory verb-noun. Don't `sb-*`-prefix a rarely-invoked skill — wrong frequency signal.

## Inline vs Dispatch

Each bundled skill picks inline or agent dispatch based on task shape — not a uniform rule. False symmetry (forcing all skills the same way) breaks task-shape match.

| Reason to dispatch | Reason to inline |
|---|---|
| Bounded judgment Sonnet/Haiku handles → save Opus tokens | User-interactive throughout (Q&A, mid-flow approval) |
| Heavy tool output that would pollute gateway working memory | Short scope — handoff overhead > savings |
| Restricted toolset for safety | Gateway needs same context for follow-on work |
| Parallelism / clean restart | Session-aware (transcript memory matters) |

A single matching reason on either side decides.

| Skill | Mode | Rationale |
|---|---|---|
| `super-bootstrap` | inline | Greenfield Q&A throughout |
| `harness-bootstrap` | inline | Phased scaffolding with mid-flow user steering |
| `resolve-plugins` | inline (dispatch candidate) | 6-pool live queries are context-heavy; user-interactive on diff confirm. Revisit. |
| `sb-commit` | inline | Session-aware (transcript memory + doc-sync Q&A) |
| `sb-merge` | inline | Same context-aware shape as `sb-commit`; lower freq doesn't pay for relay either |
| `release-init` | inline | Detection + Q&A + file generation throughout |
| `sb-todo` | dispatch (Sonnet) | Multi-file scan + bounded classification + render — Sonnet fit, isolate from gateway |
| `sb-help` | dispatch (Haiku) | Pure manifest lookup + render — Haiku model fit, skill frontmatter can't pin a model so dispatch is the escape hatch |

When adding a new skill: update this table. Add an in-`SKILL.md` rationale callout only when the choice has nuance worth surfacing near the protocol (e.g. dispatching skills carry it next to their dispatch block; `sb-merge` carries one to record why we rejected dispatch).

## Source of truth boundaries

When skills overlap in concern, one is canonical and others delegate:

- **Plugin curation logic** (source pool list, trust tiers, dedupe, settings.json write) — lives ONLY in `resolve-plugins/SKILL.md`. `harness-bootstrap` Phase 3c delegates.
- **Greenfield ideation Q&A** — lives ONLY in `super-bootstrap/SKILL.md`. `harness-bootstrap` redirects empty repos here.
- **Files-as-contract handoff** — skills communicate via committed docs (`docs/overview.md`, `docs/techstack.md`, `.claude/settings.json`), not in-memory state. Lets each skill run standalone.

If extracting a new shared concern: pick the canonical home, delete duplicated content elsewhere, replace with one-paragraph delegation. Verify via grep that source-of-truth strings appear in exactly one file.
