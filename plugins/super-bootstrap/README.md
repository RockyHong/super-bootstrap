# super-bootstrap (plugin)

Plugin-level contributor doc for the `super-bootstrap` plugin. End-user docs live in the repo-root `README.md`.

## Skill catalog

- `super-bootstrap` — public entry, greenfield gate, dispatches to `harness-bootstrap`.
- `harness-bootstrap` — installs/syncs the harness (CLAUDE.md, skeleton docs, rules, picks).
- `resolve-plugins` — curates skill/MCP/hook picks against live sources, writes `.claude/settings.json`. Standalone or delegated from `harness-bootstrap` Phase 3c.
- `todo` — intent-filtered scanner. Bare `/todo` shows mode picker (Discuss / Cloud / Device / Full); sub-verbs filter directly. Dispatches `agents/todo.md` on Sonnet with scaffold injection.
- `help` — passive on-demand index of installed user-invoke skills, grouped by category. Dispatches `agents/help.md` on Haiku.
- `commit` — session-isolated commit, doc-sync gated, conventional message, no push.
- `merge` — absorb feature branches into base. Per-branch rebase-vs-merge recommendation, clean execution. Hard SoC: on conflict, aborts + surfaces file list + stops. Resolution out of scope (user routes next pass). Inline; same context-awareness rationale as `commit`.
- `release-init` — one-shot. Detects project type (unity / tauri / node / ios-native / android-native / generic) + multi-platform shape, generates a tailored project-level `/release` skill at `.claude/skills/release/SKILL.md`. Optional bonus — run only if the repo ships versioned releases.

## Naming convention

Bare names, no prefix. The plugin manager namespaces to `super-bootstrap:<skill>`, which handles collision resolution; an `sb-*` prefix on top is double-tagging that creators and users both have to remember (and abbreviation guesses — `sb` vs `sp` — are a real failure mode in dropdown search).

| Shape | Examples |
|---|---|
| Short common verb-noun (high-freq in-flight ops) | `commit`, `todo`, `help`, `merge` |
| Self-explanatory verb-noun (lifecycle / one-shot) | `super-bootstrap`, `harness-bootstrap`, `resolve-plugins`, `release-init` |

**When adding a new skill:** pick the shortest name that reads cleanly cold. If a name collides with another plugin's bare skill, users invoke the namespaced form (`super-bootstrap:commit`); the dropdown shows the namespace so they pick the right one. Don't reintroduce a prefix to dodge that — the namespace is already the prefix.

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
| `commit` | inline | Session-aware (transcript memory + doc-sync Q&A) |
| `merge` | inline | Same context-aware shape as `commit`; lower freq doesn't pay for relay either |
| `release-init` | inline | Detection + Q&A + file generation throughout |
| `todo` | dispatch (Sonnet) | Multi-file scan + bounded classification + render — Sonnet fit, isolate from gateway |
| `help` | dispatch (Haiku) | Pure manifest lookup + render — Haiku model fit, skill frontmatter can't pin a model so dispatch is the escape hatch |

When adding a new skill: update this table. Add an in-`SKILL.md` rationale callout only when the choice has nuance worth surfacing near the protocol (e.g. dispatching skills carry it next to their dispatch block; `merge` carries one to record why we rejected dispatch).

## Source of truth boundaries

When skills overlap in concern, one is canonical and others delegate:

- **Plugin curation logic** (source pool list, trust tiers, dedupe, settings.json write) — lives ONLY in `resolve-plugins/SKILL.md`. `harness-bootstrap` Phase 3c delegates.
- **Greenfield ideation Q&A** — lives ONLY in `super-bootstrap/SKILL.md`. `harness-bootstrap` redirects empty repos here.
- **Files-as-contract handoff** — skills communicate via committed docs (`docs/overview.md`, `docs/techstack.md`, `.claude/settings.json`), not in-memory state. Lets each skill run standalone.

If extracting a new shared concern: pick the canonical home, delete duplicated content elsewhere, replace with one-paragraph delegation. Verify via grep that source-of-truth strings appear in exactly one file.
