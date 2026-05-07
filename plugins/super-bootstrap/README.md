# super-bootstrap (plugin)

Plugin-level contributor doc for the `super-bootstrap` plugin. End-user docs live in the repo-root `README.md`.

## Skill catalog

- `super-bootstrap` — public entry, greenfield gate, dispatches to `harness-bootstrap`.
- `harness-bootstrap` — installs/syncs the harness (CLAUDE.md, skeleton docs, rules, picks).
- `resolve-plugins` — curates skill/MCP/hook picks against live sources, writes `.claude/settings.json`. Standalone or delegated from `harness-bootstrap` Phase 3c.
- `sb-todo` — scans active specs/plans, reports cycle stage + blockers.
- `sb-commit` — session-isolated commit, doc-sync gated, conventional message, no push.

## Naming convention

| Prefix shape | Tier | Frequency | Examples |
|---|---|---|---|
| `sb-*` | In-flight ops | High (per-session, per-commit) | `sb-commit`, `sb-todo` |
| Self-explanatory verb-noun | Bootstrap / system / lifecycle | Low (rare invocations) | `super-bootstrap`, `harness-bootstrap`, `resolve-plugins` |

**Why:** `sb-*` shorthand is amortized by repetition. Lifecycle-tier skills fire rarely — name must read clearly cold without prefix knowledge.

**When adding a new skill:** decide tier first. High-freq in-flight (will user invoke this multiple times per session?) → `sb-*`. Lifecycle / one-shot setup → self-explanatory verb-noun. Don't `sb-*`-prefix a rarely-invoked skill — wrong frequency signal.

## Source of truth boundaries

When skills overlap in concern, one is canonical and others delegate:

- **Plugin curation logic** (source pool list, trust tiers, dedupe, settings.json write) — lives ONLY in `resolve-plugins/SKILL.md`. `harness-bootstrap` Phase 3c delegates.
- **Greenfield ideation Q&A** — lives ONLY in `super-bootstrap/SKILL.md`. `harness-bootstrap` redirects empty repos here.
- **Files-as-contract handoff** — skills communicate via committed docs (`docs/overview.md`, `docs/techstack.md`, `.claude/settings.json`), not in-memory state. Lets each skill run standalone.

If extracting a new shared concern: pick the canonical home, delete duplicated content elsewhere, replace with one-paragraph delegation. Verify via grep that source-of-truth strings appear in exactly one file.
