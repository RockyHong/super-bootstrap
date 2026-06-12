# super-bootstrap (plugin)

Plugin-level contributor doc for the `super-bootstrap` plugin. End-user docs live in the repo-root `README.md`.

## Skill catalog

> Index only — what exists, one line each. **Canonical per-skill contract = that skill's `SKILL.md` frontmatter `description:`.** Edit behavior there; this list follows.

- `super-bootstrap` — public entry, greenfield gate, dispatches to `harness-bootstrap`.
- `harness-bootstrap` — installs/syncs the harness (CLAUDE.md, skeleton docs, rules, picks).
- `resolve-plugins` — curates skill/MCP/hook picks against live sources, writes `.claude/settings.json`.
- `todo` — intent-filtered board scanner; dispatches `agents/todo.md` (Sonnet).
- `log` — capture front door for backlog rows; dispatches `agents/log.md` (Sonnet).
- `help` — on-demand index of installed user-invoke skills; dispatches `agents/help.md` (Haiku).
- `commit` — session-isolated, doc-sync-gated commit.
- `merge` — absorb feature branches; aborts + surfaces on conflict.
- `release-init` — one-shot; generates a project-level `/release` skill.

## Naming convention

**Skill identifiers (file frontmatter `name:`, manifest, dispatch IDs)** stay bare — no `sb-*` prefix. The plugin manager namespaces to `super-bootstrap:<skill>` already; an extra prefix is double-tagging.

**User-facing invocation form** is always the namespaced `/super-bootstrap:<skill>` — *except* the entry skill `/super-bootstrap`, which stays bare (it's the install pitch and Claude Code special-cases the plugin-name == skill-name case). Reasons to namespace everything else:

- `/help` collides with Claude Code's built-in `/help` (bare form is shadowed, never resolves to ours)
- `/commit`, `/todo`, `/merge` are generic enough that other plugins may ship the same bare name; dropdown autocomplete already surfaces the namespaced form, so docs matching that form avoid mental drift
- Forward-proof against future collisions without doc-sync churn

| Shape | Skill name (bare) | Invocation form |
|---|---|---|
| Public entry | `super-bootstrap` | `/super-bootstrap` |
| Lifecycle / one-shot | `harness-bootstrap`, `resolve-plugins`, `release-init` | `/super-bootstrap:<name>` |
| High-freq in-flight ops | `commit`, `todo`, `merge`, `help`, `log` | `/super-bootstrap:<name>` |

**When adding a new skill:** pick the shortest bare name that reads cleanly cold. Reference it as `/super-bootstrap:<name>` everywhere a user might type it (SKILL.md prose, rendered footers, agent menus, READMEs).

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
| `log` | dispatch (Sonnet) | Bounded classify + gate + write — Sonnet fit; dispatch also enforces bias exclusion (shell never pre-classifies buckets) |
| `help` | dispatch (Haiku) | Pure manifest lookup + render — Haiku model fit, skill frontmatter can't pin a model so dispatch is the escape hatch |

When adding a new skill: update this table. This table is the only home for inline-vs-dispatch rationale — SKILL.md bodies carry the dispatch instruction, not the reasoning (harness MDs hold rules, not why-essays).

## Source of truth boundaries

When skills overlap in concern, one is canonical and others delegate:

- **Plugin curation logic** (source pool list, trust tiers, dedupe, settings.json write) — lives ONLY in `resolve-plugins/SKILL.md`. `harness-bootstrap` Phase 3c delegates.
- **Greenfield ideation Q&A** — lives ONLY in `super-bootstrap/SKILL.md`. `harness-bootstrap` redirects empty repos here.
- **Files-as-contract handoff** — skills communicate via committed docs (`docs/overview.md`, `docs/techstack.md`, `.claude/settings.json`), not in-memory state. Lets each skill run standalone.

- **Plugin-level description** — `plugin.json` is canonical; `marketplace.json` entry copies it verbatim at release.

If extracting a new shared concern: pick the canonical home, delete duplicated content elsewhere, replace with one-paragraph delegation. Verify via grep that source-of-truth strings appear in exactly one file.
