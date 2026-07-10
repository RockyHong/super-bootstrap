# super-bootstrap (plugin)

Plugin-level contributor doc for the `super-bootstrap` plugin. End-user docs live in the repo-root `README.md`.

## Skill catalog

> Index only — what exists, one line each. **Canonical per-skill contract = that skill's `SKILL.md` frontmatter `description:`.** Edit behavior there; this list follows.

- `super-bootstrap` — public entry, thin orchestrator; dispatches the runway, seeds greenfield GAP cards, gates tier-2 curation.
- `harness-bootstrap` — installs/syncs the generic runway (CLAUDE.md, skeleton docs, rules, core pins); monorepo tier fans rule globs + build pre-flight out per package; adopt mode retires a consumer's superseded fork skills/agents (runtime name-collision map, per-deletion confirm); opt-in, earn-gated scale module adds `docs/parked.md` + `docs/test-queue.md` containers, a venue-map rule, and backlog fact fields for repos whose backlog has outgrown one flat list.
- `resolve-plugins` — curates skill/MCP/hook picks against live sources, writes `.claude/settings.json`; Phase 2.5 dispatches `agents/plugin-digest.md` (Haiku) for README→digest parse.
- `todo` — intent-filtered board scanner; dispatches `agents/todo.md` (Sonnet).
- `log` — capture front door for backlog rows; dispatches `agents/log.md` (Sonnet).
- `triage` — read-only verdict phase for one backlog card; dispatches `agents/triage.md` (Opus).
- `triage-report` — drains `.review/` scan reports with per-finding dispositions; dispatches `agents/triage-report.md` (Sonnet).
- `help` — on-demand index of installed user-invoke skills; dispatches `agents/help.md` (Haiku).
- `commit` — session-isolated, doc-sync-gated commit.
- `merge` — absorb feature branches; aborts + surfaces on conflict.
- `check-docs-consistency` — cross-references project docs for drift, stale references, contradictions; timestamped report to `.review/`, report-only.
- `drain` — parallel-worktree auto-drain of the board; spawns one isolated `claude -p` per admissible item (venue-keyed when the scale module is wired, Cloud-safe fallback otherwise; single-item/inline waves roll in-session), each halts at its user wall.
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
| Lifecycle / one-shot | `harness-bootstrap`, `resolve-plugins`, `release-init`, `check-docs-consistency` | `/super-bootstrap:<name>` |
| High-freq in-flight ops | `commit`, `todo`, `merge`, `drain`, `help`, `log`, `triage`, `triage-report` | `/super-bootstrap:<name>` |

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
| `super-bootstrap` | inline | Orchestrator — owns the user thread + dispatch sequencing across runway / log / curation |
| `harness-bootstrap` | inline | Phased scaffolding with mid-flow user steering |
| `resolve-plugins` | inline + dispatch (Haiku, Phase 2.5 only) | 6-pool live queries + user-interactive diff confirm stay inline (gateway owns the thread); Phase 2.5 README-parse→digest split to `agents/plugin-digest.md` — mechanical extraction, Haiku-safe because Phase 3's trust-tier scoring + earn-right gate already judge the digest downstream |
| `commit` | inline + conditional dispatch (Sonnet, doc-sync scan only) | Gateway holds the diff, session file list, and change intent → mechanics (classify, message-gen, stage, commit) run inline, zero closure; only the cold doc-sync scan dispatches, and only on a grep-gate hit — semantic-drift detection sets the Sonnet floor. Push confirm + cycle handoff stay gateway-side |
| `merge` | inline | Context-aware shape (session transcript decides absorption targets); lower freq doesn't pay for relay either |
| `drain` | inline | Gateway orchestrator — owns the user thread, the wave loop, the halts. The per-item work IS the spawned `claude -p` subprocesses; the orchestration itself is gateway reasoning, not an Agent dispatch |
| `release-init` | inline | Detection + Q&A + file generation throughout |
| `check-docs-consistency` | inline | Single-pass scan by default (rung 1); scale rides the opt-in § Workflow Fan-Out — a Workflow launch from the invoking context, not an Agent dispatch |
| `todo` | dispatch (Sonnet) | Multi-file scan + bounded classification + render — Sonnet fit, isolate from gateway |
| `log` | dispatch (Sonnet) | Bounded classify + gate + write — Sonnet fit; dispatch also enforces bias exclusion (shell never pre-classifies buckets) |
| `triage` | dispatch (Opus) | Root-cause trace is the highest-judgment lane (verdict errors propagate into every downstream phase — Opus floor); read-only toolset + clean context enforce the phase identity and priors isolation |
| `triage-report` | dispatch (Sonnet) | Bounded per-finding disposition — Sonnet fit; gateway coverage review + `/log` dedup judge the sheet downstream; dispatch enforces bias exclusion (shell passes no priors) |
| `help` | dispatch (Haiku) | Pure manifest lookup + render — Haiku model fit, skill frontmatter can't pin a model so dispatch is the escape hatch |

When adding a new skill: update this table. This table is the only home for inline-vs-dispatch rationale — SKILL.md bodies carry the dispatch instruction, not the reasoning (harness MDs hold rules, not why-essays).

## Source of truth boundaries

When skills overlap in concern, one is canonical and others delegate:

- **Plugin curation logic** (source pool list, trust tiers, dedupe, settings.json write) — lives ONLY in `resolve-plugins/SKILL.md`. `/super-bootstrap` invokes it as gated tier-2 curation.
- **Greenfield product-seeding** (GAP-card seeding + resolve gate) — lives ONLY in `super-bootstrap/SKILL.md`. `harness-bootstrap` runs the runway on greenfield directly (no redirect); product content fills at GAP-card pickup.
- **Files-as-contract handoff** — skills communicate via committed docs (`docs/overview.md`, `docs/techstack.md`, `.claude/settings.json`), not in-memory state. Lets each skill run standalone.
- **Item classification** (cloud-safe criterion, action-verb intent map, per-source `{action, intent, stage}` derivation) — lives ONLY in `shared/classify-actionable.md`. Both `todo` (ranks + renders) and `drain` (gates + spawns) embed it verbatim at dispatch; neither restates it. Downstream of classification — ranking/render (todo), wave-select/spawn (drain) — stays in each skill's own home.
- **Worktree-drain infra** (settings template, Read-hook, `.claude/worktrees/` gitignore) — frozen assets in `skills/drain/assets/`, installed into consumer repos by `drain`'s `ensure-infra` (idempotent copy/merge); the subprocess boundary anchor rides the dispatch prompt, not the repo. `harness-bootstrap` opt-in seed delegates to that same procedure — one install home, no second copy.
- **Harness hooks** (`harness-grounding` edit-nudge; `entry-nudge` prompt-entry pointer; `commit-channel` confines raw `git commit` to the main-session commit door — that door runs mechanics gateway-inline and dispatches a cold `doc-sync-scan` only on a grep-gate hit) — frozen assets in `skills/harness-bootstrap/assets/hooks/`, installed into consumer repos by `harness-bootstrap`'s `hooks-ensure-infra` (content-aware copy-on-drift, **default-on** — unlike drain's opt-in worktree infra, since all are safe-by-default). Same copy/merge mechanism as drain's `ensure-infra`, reused rather than re-derived.

- **Plugin-level version + description** — `plugin.json` is canonical for both. `marketplace.json` carries no `version` (Claude Code always uses the `plugin.json` value, so a duplicate marketplace `version` would be silently ignored); its `plugins[0].description` is a verbatim copy of `plugin.json` `description`, synced by `/release` at release — direct edits there get overwritten.

If extracting a new shared concern: pick the canonical home, delete duplicated content elsewhere, replace with one-paragraph delegation. Verify via grep that source-of-truth strings appear in exactly one file.
