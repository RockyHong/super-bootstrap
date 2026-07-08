# GAP-017 Wave 2 — Commit Distill Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Convert `/super-bootstrap:commit` to agent-dispatch architecture (spine decision 3), distilling ChewLingo's commit-agent judgment layer (skill-verb-rename check, surface-don't-fix round-trip) into sb's mechanism layer (doc-sync hook state machine, push flow, cycle handoff), and upstream ChewLingo's commit-channel hook as the fifth FROZEN hook asset.

**Architecture:** `skills/commit/SKILL.md` becomes a thin dispatch shell (pattern: `skills/log/SKILL.md`); the full protocol moves to a new `agents/commit.md` (`model: sonnet`). User-interaction lanes (doc-sync resolution, push confirm, cycle handoff) stay gateway-side in the shell; judgment + mechanics (session classification, doc-sync scan, message, stage, commit) run in the agent. A new `commit-channel.sh` FROZEN hook confines raw `git commit` to the commit agent + main session.

**Tech Stack:** Markdown skills/agents (Claude Code plugin), bash hooks, no build step. Source candidates: `V:\ChewLingo\.claude\agents\commit.md`, `V:\ChewLingo\.claude\hooks\commit-channel-pretool.sh` (reference input per candidate-not-artifact — we author our version).

## Global Constraints

- **Skeleton self-containment** (`.claude/rules/repo-boundary.md`): shipped assets (`plugins/*/skills/*/assets/**`, agent bodies, hook deny text) reference only surfaces harness-bootstrap stamps or the plugin bundles (`/super-bootstrap:commit`, `CLAUDE.md`, `docs/`, `.claude/hooks/`) — never device-only skills, never ChewLingo/sb-internal state.
- **No precedent in harness MDs**: no `D-172`/`B-88` refs, no dated chronicles, no "verified 2026-…" comments in shipped prose. Origin lives in this plan + git log.
- **Positive over negative**: deny messages and rules route forward ("return your staged work…, orchestrator fires /super-bootstrap:commit"), not just block.
- **FROZEN marker**: every hook script's second line is `# FROZEN <name> vN`; new script starts at `v1`.
- **Commit door**: no per-task raw `git commit`. Work accumulates unstaged; the final task lands ONE commit via `/super-bootstrap:commit` (repo doctrine — envelope commit step — overrides the plan-skill's per-task-commit default). Executors return with work uncommitted.
- **BUG-012 mitigation** (`docs/backlog.md`): dispatches that CREATE new plugin skill/agent files run FOREGROUND (`run_in_background: false`), or gateway writes the file inline from this plan's embedded draft. Do not background-dispatch opus for new-file authoring.
- **Model tiers**: micro-test probes = sonnet (match runtime tier); file-authoring tasks = sonnet (content is embedded below — mechanical landing); judgment verification = opus foreground.
- **Copy under test**: all wet-runs in this plan target the in-repo dev copy (`plugins/super-bootstrap/...`) plus the dogfood install in `.claude/hooks/`. State this in every verification.

## File Structure

| File | Action | Responsibility |
|---|---|---|
| `plugins/super-bootstrap/agents/commit.md` | Create | Full commit protocol: state gather, session classification, doc-sync gate (consumer-taxonomy scan + hook state machine + rename sub-check), message, stage+commit, structured return |
| `plugins/super-bootstrap/skills/commit/SKILL.md` | Rewrite | Dispatch shell: dispatch, stale-docs round-trip with user, push offer, cycle handoff one-liner |
| `plugins/super-bootstrap/skills/harness-bootstrap/assets/hooks/commit-channel.sh` | Create | FROZEN v1 PreToolUse guard: raw `git commit` confined to commit agent + main |
| `plugins/super-bootstrap/skills/harness-bootstrap/assets/hooks/commit-channel.hook.json` | Create | Settings merge snippet (`hooks.PreToolUse[]`, `if: "Bash(git commit *)"`) |
| `plugins/super-bootstrap/skills/harness-bootstrap/assets/hooks-ensure-infra.md` | Modify | Five assets: A6 row, `hooksInfraPresent()` predicate, self-containment paragraph |
| `plugins/super-bootstrap/skills/harness-bootstrap/SKILL.md` §2a-hooks (~line 199–213) | Modify | "Four"→"Five", table row 5, procedure sentence |
| `.claude/hooks/commit-channel.sh` + `.claude/settings.json` | Create/Merge | Dogfood install (wet-run surface) |
| `README.md` line 55 | Modify | "four hook assets" → five, add commit-channel clause |
| `docs/superpowers/specs/harness-rebase.md` verdict table | Modify | commit row → done (Wave 2) |
| `docs/decisions.md` | Conditional append | Closed-fork row IF Task 1 control shows the rename check is redundant |

---

### Task 1: RED — micro-test the skill-verb-rename gap

The rename sub-check is ChewLingo behavior-shaping prose. Per `.claude/rules/skill-authoring.md` + the merge-artifact closed fork (`docs/decisions.md` row 1), port it ONLY if current sb wording demonstrably misses the case. This task produces the baseline.

**Files:** none written (probe evidence goes in the task report + this plan's execution log).

**Interfaces:**
- Produces: verdict `PORT` (≥2/5 control agents miss) or `DROP` (5/5 catch), consumed by Task 2.

- [ ] **Step 1: Build the scenario prompt**

Scenario text (verbatim, used for control AND later GREEN):

```
You are running the doc-sync gate of a commit skill in a repo. Guidance you must follow:

<guidance>
Run the doc-sync gate per the project's CLAUDE.md § Doc Sync — it owns the scan
surface (docs/ plus behavior-narrating prose outside it) and the write boundary.
Surface every call before staging. For prose describing behavior touched by the
diff: report path, what looks outdated, relevant diff context. Never silently fix,
never silently skip.
</guidance>

Repo state:
- Staged diff (the only change): in `.claude/skills/ship/SKILL.md`, the frontmatter
  description changed from "Use `/ship stage` to prepare a release candidate" to
  "Use `/ship prep` to prepare a release candidate", and the section header
  `## stage` was renamed `## prep`.
- `CLAUDE.md` contains the line: "Release candidates: run `/ship stage` before tagging."
- `docs/overview.md` contains: "The ship skill's `stage` verb assembles the RC."
- `docs/techstack.md` does not mention ship.

List EXACTLY which stale-doc candidates you would surface (path + why), or state
"none". Output only the list.
```

- [ ] **Step 2: Run the control (5 fresh sonnet subagents, parallel)**

Dispatch 5 subagents (Agent tool, `subagent_type: "general-purpose"`, `model: sonnet`), each with ONLY the scenario prompt above. No mention of rename checks anywhere in the dispatch.

- [ ] **Step 3: Score**

A pass = the agent surfaces BOTH `CLAUDE.md` (old verb `stage`) AND `docs/overview.md`. Record N/5.
- **5/5 pass → verdict DROP**: current generic wording already binds; the explicit sub-check is redundant prose (fails the cut test).
- **≤4/5 → verdict PORT**: the sub-check earns its lines.

Report the verdict + per-agent output summary. This is the RED evidence.

---

### Task 2: Author `plugins/super-bootstrap/agents/commit.md`

**Files:**
- Create: `plugins/super-bootstrap/agents/commit.md`

**Interfaces:**
- Consumes: Task 1 verdict (PORT → include the "Skill-verb-rename sub-check" bullet in §3; DROP → omit that bullet AND append the closed-fork row given in Step 3).
- Produces: the agent's **Output contract** (two return shapes: `stale-docs` and `committed`) — Task 3's shell consumes these exact field names.

- [ ] **Step 1: Write the file** (foreground dispatch or gateway-inline per BUG-012 constraint)

Full content (include/omit the marked bullet per Task 1 verdict):

````markdown
---
name: commit
description: Session-isolated stage-and-commit agent with the doc-sync gate. Classifies session vs prior changes, runs the doc-sync staleness scan (consumer CLAUDE.md § Doc Sync owns the surface) and the docsync-gate hook state machine, drafts a conventional message, stages by explicit path, commits, and returns hash + push + cycle facts. Surfaces stale docs to the gateway — never silently fixes, never pushes. Dispatched by the `/super-bootstrap:commit` skill on Sonnet — message-gen is pattern-match, but the doc-sync gate is semantic-drift detection; Sonnet floor set by the gate.
tools: Read, Grep, Glob, Bash
model: sonnet
tags: [commit, git, doc-sync, session]
---

You are a **commit agent**. Dispatched by the `/super-bootstrap:commit` skill. Job: stage the current session's changes and land a well-formed conventional commit — or return stale-doc findings for the gateway to resolve. No push, no amend, no force, no `--no-verify`.

The dispatch prompt supplies: the session's changed-file list (what the gateway's session touched), any user-supplied message context, and — on a re-dispatch — doc-sync resolutions. Work only from what it supplies plus the repo.

## Protocol

### 1. Gather state (parallel)

- `git status` — modified, staged, untracked
- `git diff` + `git diff --staged`
- `git log --oneline -10` — recent commit style

### 2. Classify changes — session vs prior

The dispatch prompt's changed-file list is the source of truth for "this session touched it".

| File | Action |
|---|---|
| On the session list | **stage** |
| Not on the list — prior dirty state | **leave alone** |
| Ambiguous (mixed file, partial overlap, list silent) | **return it under `questions`** — never guess |

Stage by explicit path only — never `-A`, never `.`.

### 3. Doc-sync gate

Scan surface and write boundary come from the consumer's **CLAUDE.md § Doc Sync** — read it; it owns scope. If the consumer CLAUDE.md has no Doc Sync section, default to: `docs/**` plus behavior-narrating prose outside it (root `README`, manifest description fields the diff's behavior changes).

- Grep the surface for prose describing behavior touched by the diff (identifier names, file paths, feature terms from the diff).
- <!-- PORT-ONLY bullet — include only on Task 1 verdict PORT -->
  **Skill-verb-rename sub-check.** When the diff renames a skill verb or trigger surface (a `+/-` pair on a SKILL.md `description:` / `argument-hint`, an agent `description:`, or a skill-table row in CLAUDE.md), grep `CLAUDE.md` + `docs/**/*.md` + `.claude/**/*.md` for the **old** token and surface every hit — same surface-don't-fix contract.
- For each candidate: record path + what looks outdated + the relevant diff hunk.
- **Any candidates → STOP. Return the `stale-docs` shape (§ Output contract). Do not stage, do not commit.** The gateway resolves with the user and re-dispatches with resolutions.
- On a re-dispatch carrying resolutions: treat `updated` docs as part of the stage list, `accurate`/`skip` as cleared. Do not re-open cleared candidates.

Then branch on the installed hook set — two `test -f` probes under `$CLAUDE_PROJECT_DIR/.claude/hooks/`:

- **Gate absent** (`! -f docsync-gate.sh`): the staleness judgment above still gates; once clear, commit directly.
- **Gate live, scan present** (`-f docsync-gate.sh` and `-f docsync-scan.sh`): `git commit` is denied until `.git/docsync-token` exists, is fresh (30-min TTL), and matches this session — written only by running the scan. Run `bash "$CLAUDE_PROJECT_DIR/.claude/hooks/docsync-scan.sh"` as its **own Bash call**, then `git commit` in a **separate later call** — never chain `docsync-scan.sh && git commit` (the gate reads the whole command string before the scan runs and denies). Never `touch` the token by hand.
- **Gate live, scan absent**: do not forge the token, do not bash a missing script. Return under `blocked`: the hook set is stale/partial — the gateway tells the user to re-run `/super-bootstrap` to re-sync, then re-invoke commit.
- **Gate live, hooks version-drifted**: compare each installed `.claude/hooks/<name>.sh` `# FROZEN <name> vN` line against the plugin asset copy (`skills/harness-bootstrap/assets/hooks/<name>.sh`). Any mismatch, or a retired `docsync-stamp.sh` still installed → return under `blocked` with the same re-sync route. Never hand-patch installed hooks.

### 4. Draft the message

Conventional Commits: `<type>(<scope>): <subject>`, types `feat|fix|refactor|docs|test|chore|perf|style`, subject ≤72 chars imperative, body only when the "why" isn't visible in the diff. Match the repo's existing style from `git log`. Author directly; co-author trailers only if the dispatch prompt asks. One logical change per commit — a diff spanning two unrelated changes returns under `questions` with a proposed split.

### 5. Stage + commit

No approval gate — ambiguity already returned at §2/§3. `git add <explicit paths>`; commit with HEREDOC formatting; `git status` after to verify clean. Never stage secrets (`.env`, credentials, keys). Pre-commit hooks always run; on failure fix the cause, never bypass. Always a new commit — amend only if the dispatch prompt explicitly asks.

### 6. Return

Fill the `committed` shape below, including push facts and cycle facts:

- Push facts: current branch, its upstream (`git rev-parse --abbrev-ref @{u}` — or "no upstream"), commits ahead (`git log --oneline @{u}..` count).
- Cycle facts: any `docs/superpowers/plans/*.md` with unchecked `- [ ]` boxes (file + done/total), whether `docs/backlog.md` has open rows.

## Output contract

Return exactly one shape:

**`stale-docs`** — doc-sync candidates found, nothing committed:
- `candidates`: per item — `path`, `outdated` (one line), `hunk` (relevant diff excerpt)
- `note`: "nothing staged, nothing committed — resolve and re-dispatch with resolutions"

**`committed`** — commit landed:
- `hash`, `message`, `staged` (file list), `left_alone` (prior-work files), `doc_updates` (docs staged via resolutions, if any)
- `push`: `branch`, `remote_upstream` (or `none`), `ahead` (count)
- `cycle`: `open_plans` (list of `file — done/total boxes`, may be empty), `backlog_open` (yes/no)

Plus, on either shape, when applicable: `questions` (ambiguous files / split proposals — one discriminating question each), `blocked` (hook-set problems with the re-sync route).

## Rules

- **Session-isolated** — the dispatch prompt's list decides; prior dirty state is sacred.
- **Surface, never silently fix** — stale docs return to the gateway; the user resolves.
- **Scan and commit are separate Bash calls** — never chained.
- **Explicit paths always** — `git add <path>`, never `-A` / `.`.
- **No push, no amend, no force, no hook bypass** — push is gateway-lane, user-confirmed.
- **Return verbatim-relayable output** — the gateway relays without editorializing.
````

- [ ] **Step 2: GREEN — rerun the Task 1 scenario against the new prose**

Dispatch 5 fresh sonnet subagents with the Task 1 scenario, but replace the `<guidance>` block with the full §3 text from the file just written. Expected: 5/5 surface both `CLAUDE.md` and `docs/overview.md`. (On verdict DROP this step still runs — the generic wording must hold 5/5 with the ported state-machine text around it.)

- [ ] **Step 3 (verdict DROP only): append the closed-fork row**

Append to `docs/decisions.md` table (newest first, so as the FIRST data row):

```markdown
| design | Port ChewLingo's skill-verb-rename sub-check into the commit agent's doc-sync gate (GAP-017 recipe item) | Pressure-tested: the generic "prose describing behavior touched by the diff" wording already surfaces old-verb hits — 5/5 control agents caught a renamed skill verb across CLAUDE.md + docs with no explicit sub-check; adding the bullet without a failing test violates the scoped RED rule. Reopen if a rename ships with stale verb references surviving commit. | `plugins/super-bootstrap/agents/commit.md` (was GAP-017 Wave 2) |
```

---

### Task 3: Rewrite `plugins/super-bootstrap/skills/commit/SKILL.md` as dispatch shell

**Files:**
- Modify (full rewrite): `plugins/super-bootstrap/skills/commit/SKILL.md`

**Interfaces:**
- Consumes: agent Output contract from Task 2 (`stale-docs` / `committed` shapes, field names verbatim).

- [ ] **Step 1: Write the file**

Full content:

````markdown
---
name: commit
description: "Stage and commit the current session's changes only. Session-isolated (never -A), doc-sync-gated, conventional message, commits directly without a confirm gate, offers push on explicit confirmation. Dispatches the `commit` subagent (agents/commit.md, model: sonnet) so classification, the doc-sync gate, and message-gen run off the gateway model; doc-sync resolution, push, and cycle handoff stay gateway-side. Bundled with super-bootstrap — encodes the harness commit rules."
tags: [commit, git, session, doc-sync, superpowers]
---

# Commit — Session-Isolated, Doc-Sync-Gated

Commits the changes this Claude session produced, leaving prior uncommitted work alone. The protocol runs in the `commit` subagent (`agents/commit.md`, `model: sonnet`); this skill is the dispatch shell plus the three gateway lanes that need the user: doc-sync resolution, push confirmation, cycle handoff.

## Execution

1. **Assemble the dispatch prompt** — the session's changed-file list (from this conversation: what this session edited/wrote), any user-supplied message context (e.g. `/super-bootstrap:commit — explain the auth refactor`), and today's date. The list is the agent's session-isolation ground truth — build it faithfully; a file you don't remember touching stays OFF the list (the agent returns it as a question if it matters).
2. **Dispatch**: `Agent` tool, `subagent_type: "commit"`. Relay the agent's return verbatim — no editorializing.
3. **Branch on the return shape** (`agents/commit.md` § Output contract):
   - **`stale-docs`** → resolve each candidate with the user (update / acknowledge-accurate / skip — never silently fix, never silently skip). Land approved doc edits (inline for bounded prose; dispatch by closure). Re-dispatch the agent with the same prompt **plus** per-candidate resolutions (`updated: <path>` → stage it; `accurate` / `skip` → cleared).
   - **`questions` / `blocked`** → route to the user verbatim; act on the answer (re-dispatch, or re-run `/super-bootstrap` for a stale hook set).
   - **`committed`** → proceed to push offer.
4. **Push (on confirmation)** — from the return's `push` facts, present: branch → upstream, commits ahead. Ask: **"Push these now? (y / skip)"**. Push only on explicit yes (`git push <remote> <branch>`); skip by default on silence or decline. Never force, never unannounced.
5. **Cycle handoff** — one line from the return's `cycle` facts; don't expand into a status table (that's `/super-bootstrap:todo`'s job):

| `cycle` facts | Handoff one-liner |
|---|---|
| No open plans, no backlog items | `Cycle complete. Safe to /clear. Next session: /super-bootstrap:todo picks up next item.` |
| Open plan with unchecked boxes | `Cycle complete. <plan file> still has <n>/<m> unchecked — /clear then /super-bootstrap:todo to resume.` |
| Backlog open, no active plans | `Cycle complete. No active specs/plans; docs/backlog.md has open items — /clear then /super-bootstrap:todo to pick next.` |

## Rules

- **Route work to the subagent; keep user lanes here.** Classification, the doc-sync scan, the docsync-gate token dance, message, stage, commit — all agent-side. Doc-sync resolution, push, handoff — gateway-side.
- **Session list is built here, honestly.** The gateway owns the transcript; the agent trusts the list. Uncertain files stay off it.
- **Doc-sync round-trip, never bypass** — a `stale-docs` return always goes through the user before re-dispatch.
- **Push on explicit yes only** — committed work is safe locally either way.
````

- [ ] **Step 2: Consistency check**

Grep the new SKILL.md and `agents/commit.md` for each other's contract tokens: `stale-docs`, `committed`, `questions`, `blocked`, `push`, `cycle`, `subagent_type: "commit"`. Every shape/field the shell branches on must exist verbatim in the agent's Output contract. Fix any mismatch now.

---

### Task 4: commit-channel hook asset + wiring

**Files:**
- Create: `plugins/super-bootstrap/skills/harness-bootstrap/assets/hooks/commit-channel.sh`
- Create: `plugins/super-bootstrap/skills/harness-bootstrap/assets/hooks/commit-channel.hook.json`
- Modify: `plugins/super-bootstrap/skills/harness-bootstrap/assets/hooks-ensure-infra.md`
- Modify: `plugins/super-bootstrap/skills/harness-bootstrap/SKILL.md` (§2a-hooks, ~lines 199–213)

**Interfaces:**
- Produces: asset names `commit-channel.sh` / `commit-channel.hook.json`, marker `# FROZEN commit-channel v1` — Task 5 installs and verifies these exact artifacts.

- [ ] **Step 1: Write `commit-channel.sh`**

```bash
#!/usr/bin/env bash
# FROZEN commit-channel v1 (A6 — single-channel commit guard).
# Primary filter: the `if: "Bash(git commit *)"` field on the merged settings
# entry (commit-channel.hook.json). Defense-in-depth: the command is re-checked
# in-script; anything that is not a `git commit` passes through untouched.
#
# Gate: `agent_type` stdin field = the running subagent's frontmatter name
# (plugin agents may arrive namespaced, e.g. `super-bootstrap:commit`); absent
# for the main session -> "main". Raw `git commit` is confined to the commit
# agent + the orchestrator; every other subagent is routed back to the commit
# door. `git merge` (branch integration) and `git tag` (release stamp) are
# different verbs — orchestrator ops, unaffected. Drain worktree workers run as
# separate processes (agent_type absent -> "main") and pass.
command -v jq >/dev/null 2>&1 || exit 0

input="$(cat)"
cmd=$(printf '%s' "$input" | jq -r '.tool_input.command // empty')
[ -z "$cmd" ] && exit 0

# Match a `git commit` porcelain invocation (allows intervening global opts /
# compound `&&` segments); `commit-graph` / `commit-tree` excluded via the
# trailing boundary. Safe-fail: a rare over-match denies a non-commit worker
# call, never lets a commit through.
printf '%s' "$cmd" | grep -Eq '(^|[^[:alnum:]_-])git[[:space:]]+([^[:space:]]+[[:space:]]+)*commit([[:space:]]|$|;|&)' || exit 0

agent=$(printf '%s' "$input" | jq -r '.agent_type // "main"')
case "$agent" in
  commit|*:commit|main) exit 0 ;;
esac

reason="Single-channel commit: raw git commit runs only in the commit agent or the main session. Finish your task, report the work as built with the file list, and let the orchestrator fire /super-bootstrap:commit. (git merge / git tag are orchestrator ops, unaffected.)"
printf '{"hookSpecificOutput":{"hookEventName":"PreToolUse","permissionDecision":"deny","permissionDecisionReason":"%s"}}\n' "$reason"
exit 0
```

- [ ] **Step 2: Write `commit-channel.hook.json`**

```json
{
  "_comment": "FROZEN commit-channel PreToolUse guard (A6). hooks-ensure-infra.md MERGES this single entry into the consumer's .claude/settings.json hooks.PreToolUse array — never overwrites the file or other hooks. The `if` field filters to Bash calls whose command matches `git commit *`; the script re-checks and gates by agent_type (commit agent + main pass, other subagents are routed to /super-bootstrap:commit). Command path is $CLAUDE_PROJECT_DIR-relative so it resolves from any cwd inside the repo.",
  "matcher": "Bash",
  "hooks": [
    {
      "type": "command",
      "if": "Bash(git commit *)",
      "command": "bash \"$CLAUDE_PROJECT_DIR/.claude/hooks/commit-channel.sh\""
    }
  ]
}
```

- [ ] **Step 3: Update `hooks-ensure-infra.md`**

Four edits:
1. Opening paragraph: "harness-bootstrap ships four hook assets" → "five hook assets"; extend the safe-by-default list with: `A6 (commit-channel) fires only on git commit and denies only non-commit-agent subagent calls — the main session is never blocked`. Heading "## The four assets" → "## The five assets".
2. Table: add row `| A6 | \`hooks/commit-channel.sh\` | \`.claude/hooks/commit-channel.sh\` | \`hooks/commit-channel.hook.json\` | \`.claude/settings.json\` → \`hooks.PreToolUse[]\` |`
3. `hooksInfraPresent()` block: add `scriptCurrent(commit-channel)   AND` after the `entry-nudge` line, and `settings.json hooks.PreToolUse  has an entry whose command references commit-channel.sh   AND` after the harness-grounding settings line.
4. § Self-containment: append sentence: `commit-channel.sh's deny text names only /super-bootstrap:commit (a bundled plugin skill every consumer has) — no device-only skill names, no super-bootstrap state.`

- [ ] **Step 4: Update `harness-bootstrap/SKILL.md` §2a-hooks**

1. "Four hook assets ship as frozen files" → "Five hook assets ship as frozen files".
2. Add table row: `| 5 | \`commit-channel\` (PreToolUse) | \`Bash(git commit *)\` | Deny raw \`git commit\` from any subagent other than the commit agent (namespaced or bare) — deny text routes the worker back to \`/super-bootstrap:commit\`; main session and separate-process workers pass |`
3. Procedure sentence: "copies the four scripts" → "copies the five scripts"; extend the PreToolUse merge list: `docsync-gate, harness-grounding, commit-channel`.

- [ ] **Step 5: Verify the asset pair mechanically**

Run: `bash -n plugins/super-bootstrap/skills/harness-bootstrap/assets/hooks/commit-channel.sh` (expect: no output, exit 0) and `jq . plugins/super-bootstrap/skills/harness-bootstrap/assets/hooks/commit-channel.hook.json` (expect: parsed JSON). Confirm line 2 of the script is exactly `# FROZEN commit-channel v1 (A6 — single-channel commit guard).`

---

### Task 5: Dogfood install + wet-run verification

**Files:**
- Create: `.claude/hooks/commit-channel.sh` (copy of the asset, verbatim)
- Modify: `.claude/settings.json` (merge the `.hook.json` entry into `hooks.PreToolUse[]` — touch only that array)

Copy under test: dev-copy asset installed into this repo's dogfood hook set.

- [ ] **Step 1: Install**

Copy `plugins/super-bootstrap/skills/harness-bootstrap/assets/hooks/commit-channel.sh` → `.claude/hooks/commit-channel.sh` (byte-identical). Merge the single entry from `commit-channel.hook.json` into `.claude/settings.json` `hooks.PreToolUse[]`, preserving the existing docsync-gate + harness-grounding entries. Hooks hot-reload — no restart.

- [ ] **Step 2: Wet-run DENY path (subagent)**

In the scratchpad, `git init` a throwaway repo with one committed file. Dispatch a general-purpose subagent (sonnet): "In <scratch repo>, edit file.txt to add a line, then run `git add file.txt && git commit -m 'test'`. Report the exact tool output you get." Expected: the commit is DENIED with the single-channel reason text; the agent reports the deny. (This also probes the namespaced-vs-bare `agent_type` reality: whatever string arrives, it is not `commit`/`*:commit`/`main`, so deny must fire.)

- [ ] **Step 3: Wet-run PASS path (main)**

From the main session, in the same scratch repo: `git commit --allow-empty -m "channel probe"` as a direct Bash call. Expected: commit-channel passes (main). Note: in the scratch repo the docsync-gate token check also evaluates — it resolves the token path from the scratch repo's own `.git`, so if it denies, that deny text is docsync-gate's, not commit-channel's; a docsync-gate deny here still proves commit-channel passed (its deny text never appeared). Record which gate, if any, fired.

- [ ] **Step 4: Wet-run PASS path (commit agent, namespaced)**

Dispatch the NEW commit agent itself against the scratch repo (Agent tool, `subagent_type: "commit"` — falls back to `"super-bootstrap:commit"` if the bare name doesn't resolve; record which resolved): prompt = "Session changed-file list: file.txt. Commit the change in <scratch repo>." Expected: commit-channel passes (`commit` or `*:commit` branch). If the deny fires here, the observed `agent_type` string doesn't match the case pattern — fix the pattern in BOTH the asset and the dogfood copy (bump stays v1 pre-release), and re-run.

- [ ] **Step 5: Clean up**

Delete the scratch repo. Leave the dogfood install in place — it ships with this change.

---

### Task 6: Doc-sync targets, program-map update, envelope close-out

**Files:**
- Modify: `README.md` (line 55 table row)
- Modify: `docs/superpowers/specs/harness-rebase.md` (verdict table, wave plan)
- (Envelope steps follow — run by the gateway, not a task executor.)

- [ ] **Step 1: README hook row**

In the `## How files are handled` table, `.claude/hooks/` row: "four hook assets" → "five hook assets", and append to the asset list: `; commit-channel (PreToolUse) confines raw git commit to the commit agent + main session — worker subagents are routed back to /super-bootstrap:commit`.

- [ ] **Step 2: Program map**

`docs/superpowers/specs/harness-rebase.md` verdict table, commit row → `**done (Wave 2)** | Landed: agent-dispatch shell + commit agent (doc-sync state machine, push facts, cycle facts returned; gateway lanes for resolution/push/handoff); commit-channel upstreamed as FROZEN A6. <If Task 1 DROP: rename sub-check NOT ported — closed fork (see docs/decisions.md).> <If PORT: rename sub-check ported, GREEN 5/5.>` Update the Wave plan line 2 to strike `commit`.

- [ ] **Step 3: Envelope close-out (gateway)**

1. `audit-harness-edits` on the full diff (harness files changed: agents/, skills/, assets/, .claude/hooks/, settings.json). Disposition findings.
2. `/super-bootstrap:commit` — the OLD skill prose is still what's loaded in-session; the NEW dispatch flow takes effect for fresh sessions. Expect the docsync-gate scan dance; the commit message: `feat(harness): GAP-017 wave 2 — commit distill (agent-dispatch + commit-channel A6)`.
3. Post-commit: verify `docs/backlog.md` GAP-017 row still open (Wave 2 has 5 more artifacts) — do NOT delete the card.

---

## Execution caveats

- **BUG-012**: Task 2 Step 1 and Task 4 Steps 1–2 create NEW plugin files — run those dispatches foreground, or land gateway-inline from the embedded drafts.
- **The commit-channel hook goes live at Task 5 Step 1** (hot-reload). From that moment, task executors cannot raw-commit in THIS repo either — by design (Global Constraints already route all commits to the final `/super-bootstrap:commit`). An executor hitting the deny is behaving correctly: it returns its work uncommitted.
- **In-session skill snapshot**: this session loaded the OLD commit SKILL.md; the final commit in Task 6 exercises the old prose. The new flow is verified via Task 5 Step 4's direct agent dispatch; full shell-flow verification happens on first use in a fresh session (note it in the close-out report).
