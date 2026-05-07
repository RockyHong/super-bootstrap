# Spec — Skill Earn-Right Gate + Atomic Install Verify

**Date:** 2026-05-08
**Status:** Ready for implementation (single-repo, lean)
**Scope:** super-bootstrap plugin only — zero cross-repo touch

---

## TL;DR

`/resolve-plugins` admits skills/plugins/MCPs by stack-match + trust signal (stars × recency × license). Both filters necessary, both insufficient. Empirical evidence: 66-skill `Jeffallan/claude-skills` plugin = 0 invocations across 69 sessions; `graphify` query side cold because install incomplete (Claude hallucinated wiring steps). Add: pre-install earn-right gate (Phase 3) + post-install atomic install + slim verify (Phase 5) + on-demand `/sb-help` discovery surface for cold-by-nature user-invoke skills.

Three-four clean commits. No cross-repo touch. No doctrine doc anywhere except this spec.

---

## Empirical Evidence (motivating data)

| Pick | Sessions | Skill invocations | Cause |
|---|---|---|---|
| `Jeffallan/claude-skills` (66-skill bundle) | 69 | 0 | Description-match autopilot orphans; no hard invocation path |
| `graphify` query side | 69 | 0 (Skill: 1 misc, slash: 0, prescribed query/path/explain: 0) | Install hallucinated complete; wiring claimed but binary/hook/setup gaps |

Both verified via raw transcript grep against `~/.claude/projects/<proj>/sessions/*.jsonl`. Mention counts (e.g., react-expert: 377) trace to session-start skill-list injection, not actual fires.

---

## Concepts (REFERENCE — informs design, NOT loaded into SKILL.md)

These concepts shape the gate's behavior. They live HERE for authoring + debugging context. SKILL.md ships only operational steps + decision rules — no doctrine prose at runtime cost.

### Three failure-mode buckets

| Bucket | Failure | Detect | Fix |
|---|---|---|---|
| **Unwired** | Slot in registry, no harness reference | `enabledPlugins[<pick>]` exists + zero references in `CLAUDE.md` / hooks/ / rules/ / other skills | Wire OR drop |
| **Mis-installed** | Wiring claimed, install incomplete (binary missing, hook not chmod+x, Claude hallucinated "done") | Wiring exists, fires fail silently or error at runtime | Mechanical post-install verify |
| **Cold** | Wired + installed correctly + 0 fires across N sessions | Empirical: declared:fired = 1:0 over meaningful window | If no hard invocation path possible, drop the slot |

Misdiagnosis costs. Bucket 2 → Bucket 3 = drop a useful skill that would fire if installed correctly. Bucket 3 → Bucket 1 = add wiring around an already-wired slot whose actual break is description-match autopilot.

### Hard vs soft invocation paths

| Path | Determinism | Why |
|---|---|---|
| Hook (`PreToolUse` / `PostToolUse` / `UserPromptSubmit`) | Hard | Claude Code runtime fires on event; model can't skip |
| Slash command + concrete user-trigger context | Hard-ish | User types `/name` (observable intent); hard when context is concrete ("user types /name when ___"), soft when no context |
| Pipeline delegation by name | Hard | Skill A invokes Skill B explicitly via `Skill(skill="B")` or documented chain |
| Frontmatter-bundled deps (`agents:` / `related-skills:`) | Hard | Serve-time auto-include when parent skill served |
| `CLAUDE.md` soft prescription ("before X, do Y") | Soft | Model reads prose, decides whether to summon under load — drifts under context pressure |
| Description-match registry autopilot | Soft | Model matches description vs intent on every turn — drifts under context pressure |

**Soft prescription = description-match at the failure surface.** Both depend on model attention + reading prose. Both fail under context pressure.

### Earn-right principle

A candidate earns its registry slot only if AT LEAST ONE hard invocation path exists for it in THIS project. Soft prescription alone doesn't count. Three legitimate hard paths:

1. **Wired** — code-enforced trigger (hook / rule)
2. **Commanded** — slash-invocable AND concrete user-trigger context (author can finish "user types `/name` when ___")
3. **Delegated** — pipeline skill or subagent dispatch calls it by name

Else → reject by default. User override allowed with single-line justification.

### Anti-patterns

- **"It's in CLAUDE.md so it counts as wired"** — prose drifts under load
- **"The skill description is so specific the model will obviously pick it up"** — observed at 0/69 in real projects despite stack-aligned descriptions
- **"Time-based reminder for cold user-invoke skills"** — umbrella-shouting on sunny days; passive discovery surface (`/sb-help`) is the right shape

---

## Implementation Spec — what ships

### Files modified (super-bootstrap repo only)

| File | Action |
|---|---|
| `plugins/super-bootstrap/skills/resolve-plugins/SKILL.md` | MODIFY — add Phase 2.5, Phase 3 gate, Phase 4 tags, Phase 5 layered, Phase 7 report |
| `plugins/super-bootstrap/skills/sb-help/SKILL.md` | CREATE |
| `plugins/super-bootstrap/skills/sb-todo/SKILL.md` | MODIFY — append footer hint to render block |
| `plugins/super-bootstrap/skills/harness-bootstrap/SKILL.md` | MODIFY — one-sentence note in Phase 3c |
| `plugins/super-bootstrap/.claude-plugin/plugin.json` | MODIFY — extend description to mention /sb-help |

Zero cross-repo touch. Zero references to user-local paths (no `~/.claude/.repo-path/...`). All concepts live in this spec doc, not in any SKILL.md.

### Phase 2.5 — README parse → cached digest (insert between existing Phase 2 and Phase 3)

For each candidate emitted by Phase 2, single README parse → structured digest. Phase 3 (gate) and Phase 5 (install) consume the same digest.

Digest fields:
- `hard_paths_shipped` — hooks declared, slash commands shipped, frontmatter delegations, MCP server config presence
- `manual_install_steps` — ordered imperative steps from `## Installation` / `## Setup` / `## Quick Start` headings
- `user_invoke_trigger` — one-sentence "user types /name when ___" hypothesis (empty if no slash command)
- `multi_component` — boolean; flags Phase 5 atomic install plan

If README absent: warn user, accept best-effort interpretation from SKILL.md only. Don't auto-decide.

Cache lifetime: per `/resolve-plugins` invocation, discarded at end. Re-runs re-fetch (README content drifts).

### Phase 3 — earn-right gate (lean, append after `### Trust tiers`)

Operational test + decision rules. ~15 lines max. NO doctrine prose, NO "Why this gate sits at admission" subsection — those concepts live in THIS spec, not in SKILL.md.

```markdown
### Earn-right gate

For each candidate that survived dedupe + trust scoring, name one hard invocation path that exists in **this project** (use Phase 2.5 digest's `hard_paths_shipped` as primary signal):

- [ ] hook (which event? which file glob?)
- [ ] slash command (concrete user-trigger context — "user types /name when ___")
- [ ] pipeline delegation (which existing skill calls it by name?)
- [ ] frontmatter agents: / related-skills bundle (which orchestrator pulls it?)
- [ ] none — only CLAUDE.md prescription / description match

#### Decision rules

- **≥1 of the first four boxes** → admit. Tag the path: `[hook]`, `[slash]`, `[delegation]`, `[bundle]`.
- **Only the last box** → reject by default. Description-match autopilot orphan.
- **User override** → admit on single-line justification; tag becomes `[override: <reason>]`. Surfaces in Phase 7 report only (no persistent tracking in v1).

#### Mass-rejection collapsing

If many candidates from the same source reject for the same reason, collapse to one batch line — e.g., `Rejected 66 candidates from Jeffallan/claude-skills (description-match-only)`. Default collapsed; user types `expand rejected` to expand.
```

### Phase 4 — batch render (extend existing batch with earn-right tags)

Existing `### Batch presentation format` fenced example gains:
- Per-row path tag between candidate name and action verbs: `[hook]`, `[slash]`, `[delegation]`, `[bundle]`, or `[override: <reason>]`
- Optional top-of-batch `rejected_summary_line` — renders only if Phase 3 produced rejections, default collapsed, on-demand expand via `expand rejected`

Two short prose lines below the fence explain the path tag column and the rejected_summary line. Existing `also in:` paragraph and `Catalog stays chat` paragraph unchanged.

### Phase 5 — atomic install + slim verify

Replace existing Phase 5 single-block with layered structure. Existing `settings.json` write logic preserved as Phase 5.2.

#### Phase 5.1 — Install plan

For each accepted candidate, expand digest into ordered install steps. Render before execution.

```text
candidate: graphify
  [skill]   graphify@market           -> .claude/skills/graphify/
  [mcp]     graphify-mcp              -> .mcp.json
  [hook]    post-commit-graphify      -> .claude/hooks/ + settings.json wiring
  [bin]     graphify (manual: brew install graphify per README)

candidate: superpowers
  [plugin]  superpowers@claude-plugins-official  -> enabledPlugins
```

Atomic boundary = per-candidate. Steps execute sequentially within candidate. Multiple candidates parallel OK.

#### Phase 5.2 — Settings.json write (existing behavior preserved)

Unchanged from current SKILL.md content. Add accepted picks to `enabledPlugins`. Drop rejected. Never drop core pins (superpowers when harness-active). Ensure non-anthropic sources have `extraKnownMarketplaces` entry. Example shape preserved.

#### Phase 5.3 — Verify per component (slim — 4 rows max)

For each install step: log to user → execute → mechanical verify.

| Component | Verify | Pass |
|---|---|---|
| Plugin install | `claude plugin install <pick>` exits 0 AND `jq -e '.enabledPlugins["<pick>"]' .claude/settings.json` | both 0 |
| Binary (manual install) | `command -v <bin>` | exit 0 |
| Hook script | `[ -x .claude/hooks/<name>.sh ]` AND `bash -n .claude/hooks/<name>.sh` AND `jq -e '.hooks.<event>[]?  \| select(.command \| contains("<name>"))' .claude/settings.json` | all 0 |
| Local file copy (rare) | `[ -f <dest> ]` | exit 0 |

Drop: SHA match (no normal install path triggers it), MCP curl (Claude Code's own MCP probe handles it), schema check (jq -e key presence is sufficient), skill-body grep (file existence sufficient).

Why these specific commands: `bash -n` catches syntax pre-runtime; `jq -e` is structural (exits non-zero on missing keys, not substring match); `command -v` is POSIX-portable.

Never claim "done ✓" without an observable check.

#### Phase 5.4 — Halt-or-rollback on verify fail

If any step fails verify:
1. Halt remaining steps for THIS candidate (other candidates continue independently — atomic boundary is per-candidate, not per-batch)
2. Surface failure: failed step (component type + name), verify command + observed output, candidate's progress so far
3. Offer three resolutions:
   - **Rollback** — best-effort undo of already-applied steps. Some manual installs (e.g., `brew install`) aren't rollback-able — surface that.
   - **Pause** — leave partial state, surface summary, user fixes manually then re-runs
   - **Drop** — accept candidate didn't install, drop from accepted set, revert settings.json edit

Never silently skip. Never claim "done" with half-installed state.

#### Phase 5.5 — Commit only fully-installed candidates

`/sb-commit` handoff (existing). Restrict commit to candidates where every Phase 5.3 verify exited 0. Half-installed candidates excluded; user resolves before re-running.

If delta non-empty → `/sb-commit` to stage `.claude/settings.json` (and `.mcp.json` / `.claude/hooks/` / `.claude/skills/` if written by atomic install) + commit message `chore: refresh plugin picks` (or `chore: pin plugin picks` first run).

If delta empty → report `✓ all pinned picks current`, skip commit.

### Phase 7 — Report (insert before § Principles)

```markdown
## Phase 7: Report

Single summary block after Phase 5 completes:

\`\`\`text
✓ Resolve complete.

Pins applied: {N} ({list-of-names})
Pins unchanged: {M}
Pins dropped: {K} ({reasons})

Earn-right rejections: {R}
  {if R > 0: list collapsed sources or `expand rejected` hint}

Verify failures: {V}
  {if V > 0: list candidates that halted, with chosen resolution per candidate}
\`\`\`

If R == 0 and V == 0, omit those rows entirely.
```

NO phantom Phase 6 reference — there is no Phase 6 freshness check in this iteration.

### /sb-help skill (NEW)

`plugins/super-bootstrap/skills/sb-help/SKILL.md`:

Frontmatter:
- `name: sb-help`
- `description`: passive on-demand index of installed user-invoke skills, grouped by category; bundled with super-bootstrap; `/sb-help` for full menu, `/sb-help <category>` to filter
- `tags: [help, discovery, menu, pipeline]`

Body sections (all concise):
1. **When to use** — user forgot what slash commands exist; just installed plugin; wants category filter
2. **Protocol step 1: read sources** — `~/.claude/plugins/installed_plugins.json` (skip silently if absent), `<project>/.claude/settings.json::enabledPlugins`, `<project>/.claude/skills/*/SKILL.md` (skip silently if absent), per-plugin bundled skills
3. **Protocol step 2: filter to user-invoke** — frontmatter `name:` begins with `/`, or description includes user-trigger phrasing, or registered as slash command in plugin manifest. Drop delegation-only / hook-only.
4. **Protocol step 3: group by category** — parse `tags:` frontmatter, map to coarse categories (git/docs/pipeline/meta/dev/utils). Ambiguous → leftmost match. Spans multiple → list under primary.
5. **Protocol step 4: render menu** — table-style, one line per skill: name + one-line summary + when-to-use trigger phrase. Example fenced block.
6. **Protocol step 5: filtered mode** — `/sb-help <category>` shows only that group; unknown category → list available.
7. **Why no active reminder** — time-based reminders are umbrella-shouting; footer-hint convention on existing surfaces is zero-cost discovery.
8. **Why gateway-side, not subagent-dispatched** — token cost minimal; subagent dispatch ships parent context, pure overhead.

Out of scope (explicit in SKILL.md): active context-aware suggestion (description-match autopilot territory, unreliable); time-based reminders; `!command` token-saving syntax (not a CC feature today).

### /sb-todo footer hint

Edit existing render block in `sb-todo/SKILL.md` Step 4. Append `more: /sb-help` to the rendered "Next up" output (one blank line separator). Brief instruction paragraph explaining "footer-hint convention: existing surfaces add one line pointing at /sb-help; zero new ambient cost."

### harness-bootstrap Phase 3c note

Append one sentence to the existing `**Delegated to /resolve-plugins.**` paragraph (or as a new short paragraph after the standalone-runnable line):

> Phase 3c invokes `/resolve-plugins`, which gates picks via earn-right and atomic install + verify. Re-running `/harness-bootstrap` safely re-evaluates all picks against current upstream state and current harness wiring.

### plugin.json description

Extend existing `description` field. Current sentence: `Bundles /sb-commit (session-isolated, doc-sync-gated) and /sb-todo (active-work scanner).` New sentence: `Bundles /sb-commit (session-isolated, doc-sync-gated), /sb-todo (active-work scanner), and /sb-help (user-invoke skill discovery surface).`

---

## Out of Scope (explicit, with reasons)

| Item | Why excluded |
|---|---|
| Doctrine doc in claude-config-manager (or any other repo) | super-bootstrap is public plugin = self-contained. No cross-repo coupling. Concepts live in THIS spec doc, not in SKILL.md, not in another repo. |
| `/skill-audit` empirical drift skill | Different cadence (monthly vs admission-time), different domain (transcript audit vs candidate gate), wrong repo for it (project-scoped tooling, not personal-config). LLM judgment sufficient for monthly audit cadence — bash + jq + fixtures + tests is overbuild. |
| Marketplace update hints (`claude plugin update`) | Separate concern from admit/reject/verify. User runs `claude plugin update --all` independently. Add as separate skill (e.g. `/sb-update`) in a future iteration if wanted. |
| File SHA match verify | No normal install path copies raw files. Marketplace plugins handle their own integrity. |
| MCP server reachable curl | Claude Code's own MCP probe at session start handles this. |
| Schema check via jq beyond key presence | `jq -e '.<key>'` is sufficient; deeper schema is overengineering. |
| Skill body landed: head + grep frontmatter | `[ -f path/SKILL.md ]` is sufficient. |
| TDD / subagent-driven-development / dual code-review per task | Skill body IS prose. Edit, eyeball, commit. ~3-4 clean commits, not 13 with dual review per task. |
| Phase 6 plugin freshness check | Doesn't currently exist; adding is separate work. Phase 7 references "after Phase 5 completes", not "after Phase 6 freshness". |
| Active context-aware skill suggestion at session start | Description-match autopilot territory; evidence shows it's unreliable. Same failure mode it tries to fix. |
| Time-based "you haven't used X in N days" reminders | Umbrella-shouting on sunny days. `/sb-help` discovery surface replaces it. |
| Cross-project audit aggregation | Out of scope for this work entirely. |
| Empirical audit feeding back into resolve-plugins priors automatically | Out of scope. |

---

## Implementation Hints

- **Skill body = prose.** Edit + eyeball + commit. NO TDD, NO subagents, NO per-task code review, NO dual reviews. The 13-commit prior attempt with subagent-driven-development was ceremony-bloat for prose changes.

- **Target ~3-4 clean commits.** Suggested grouping:
  1. `feat(resolve-plugins): add Phase 2.5 README parse + Phase 3 earn-right gate + Phase 4 path tags`
  2. `feat(resolve-plugins): add Phase 5 atomic install + slim verify + Phase 7 report`
  3. `feat(sb-help): add user-invoke skill discovery surface + register in plugin.json`
  4. `feat(sb-todo,harness-bootstrap): footer hint + Phase 3c re-run note`

  (Combine if logical; split if too large. Use /sb-commit pattern: explicit `git add <paths>`, no `-A`, HEREDOC commit message, no push.)

- **Concepts (3-bucket model, hard/soft taxonomy, anti-patterns) live in THIS spec.** SKILL.md keeps only operational steps + decision rules + concrete worked examples by reference — no taxonomies, no bucket-explanation paragraphs, no "Why this gate exists" subsections.

- **Verify table = 4 rows max.** Resist re-adding SHA match / MCP curl / schema check / skill-body grep. They're overbuild — most picks install via marketplace, not raw file copy; MCPs are probed by Claude Code itself; structural jq -e key presence is sufficient.

- **Cross-repo discipline.** super-bootstrap is a PUBLIC PLUGIN. Cloud sessions, fresh machines, other users have NO access to user's local `~/.claude/.repo-path` or claude-config-manager L3 doctrine. Any path cited in SKILL.md must be plugin-internal or a stable Claude Code framework concept. Run `grep -rn "claude-config-manager\|\.repo-path\|agent-design-guide" plugins/ docs/` before commit — must return zero matches.

- **No phantom phase references.** Phase 7 references "after Phase 5 completes". There is no Phase 6 in this iteration.

- **Length discipline.** resolve-plugins SKILL.md was ~370 lines after the 13-commit attempt with doctrine bloat. Target after lean rewrite: ~280-300 lines (existing Phases 1-4 ~210 lines + Phase 2.5 ~30 lines + Phase 3 gate ~15 lines + Phase 5 layered ~80 lines + Phase 7 ~20 lines + § Principles ~10 lines).

- **/sb-help body length.** ~80-100 lines. Frontmatter + 5 protocol steps + 2 rationale paragraphs + Out of Scope.

- **Implementer is not the author of this spec.** Implementer reads spec doc + implements clean. Spec doc gives the WHAT and constrains. Implementer chooses HOW within those constraints.

---

## References (not loaded; for implementer's research)

- Empirical evidence transcript audit method: parse `~/.claude/projects/<proj>/sessions/*.jsonl` for actual `Skill` tool invocations + slash command typings + hook fires. Aggregate per declared slot.
- Pre-existing super-bootstrap structure (before this work): Phases 1 (read inputs), 2 (live-query source pool), 3 (filter/dedupe/trust tiers), 4 (batch render), 5 (apply settings.json + commit), § Principles. This work adds Phase 2.5, extends Phase 3 (gate), Phase 4 (tags), restructures Phase 5 (5.1-5.5), adds Phase 7.
- Original surface trigger: 66-skill `Jeffallan/claude-skills` plugin appears as a Knowledge-bulk pick in `/resolve-plugins` source pool. Cherry-pick design abandoned — earn-right gate makes the question moot (all 66 reject as description-match-only by construction).
