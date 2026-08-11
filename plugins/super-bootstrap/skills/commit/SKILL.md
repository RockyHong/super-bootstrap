---
name: commit
description: "Commit the current session's changes only, gateway-inline. Session-isolated (never -A), doc-sync-gated. The gateway runs the commit inline — it already holds the diff, session file list, and change intent; the doc-sync scan dispatches on a mechanical grep-gate hit, and the premise-closure judge on a product-anchor hit — nothing else leaves the gateway. Conventional message, commits directly, offers push on explicit confirmation. Bundled with super-bootstrap — encodes the harness commit rules."
tags: [commit, git, session, doc-sync]
---

# Commit — Session-Isolated, Doc-Sync-Gated (gateway-inline)

Commits the changes this Claude session produced, leaving prior uncommitted work alone. The gateway runs the flow inline — it holds the session's diff, file list, and change intent, so the mechanics carry no closure a fresh container would hold. Only the **doc-sync scan** dispatches, and only when the diff touches the doc surface: it is the one step that earns a cold, context-clean pass — cold-eyes catch staleness the author is blind to.

## Execution (gateway-inline)

1. **Session file list** — from this conversation, the files this session edited/wrote. This is the session-isolation ground truth; a file you don't remember touching stays off it. Stage by explicit path only.

2. **Gather state** — `git status`, `git diff`, `git diff --staged`, `git log --oneline -10` (recent style).

3. **Doc-sync grep-gate** — mechanical, no judgment:
   - **Deferred mode — check first** (drain-worktree isolated commit): doc-sync belongs to the merge boundary — skip all of §3, go to §5.
   - **Card-lifecycle exemption:** every changed path inside `docs/work/` (card-thread appends, card deletions, work-README high-water bump) → skip the gate, go to the link check below then §5. Card threads are self-contained; cross-card ID mentions are frozen provenance, not behavior narration. Mixed diff → run the gate on the non-`docs/work/` paths only.
   - **Premise lane — product-anchor paths:** the diff touches the product anchor (`docs/overview.md` § Problem / § User, or a dedicated product doc where the repo splits one out) → route the anchor portion through §3b instead of the behavior scan; the rest of the diff continues through this gate.
   - Extract terms from the changed files: `*/skills/<X>/SKILL.md`, `*/agents/<X>.md`, `*/rules/<X>.md` → `<X>`; else basename sans extension. Drop generics (`SKILL`, `CLAUDE`, `README`, `TEMPLATE`, `backlog`, `marketplace`, `plugin`, `gitignore`).
   - Grep the doc surface (CLAUDE.md § Doc Sync owns it — `docs/**` + root `README` + manifest description fields) for any term, excluding the changed files themselves. Grep-hit files join the scan scope — the agent judges them cold (§4).
   - **Link-hit (reverse citers) — mechanical, beside the grep:** for each changed `docs/**` / root `README.md` path, run `<skill-base>/assets/doc-links.sh refs <path>` (narrow to `refs <path>#<anchor>` when every hunk in that file sits under one heading), excluding the changed files themselves. Every file returned is a declared citer of the changed truth — collect them as the **citer read-set**.
   - **Link-target extraction (forward links) — mechanical, beside the reverse lookup:** from the diff's added lines, extract every markdown link target (`grep -oE '\]\([^)]+\.md[^)]*\)'` over `+` lines), resolve each relative to its linking file. Each target is a doc the new prose claims agreement with — add the target files to the scan scope. A target that is itself a changed file still joins: its unchanged sections are exactly where a same-commit contradiction hides.
   - **Any grep hit OR any citer OR any link-target found → dispatch the doc-sync scan (§4), the scan scope — citer read-set + grep-hit files + link-target files — riding the prompt.**
   - **Neither → the diff narrates nothing; go to §5.**
   - **Link integrity (every non-deferred commit, exemption included):** run `<skill-base>/assets/doc-links.sh check` from the repo root — `<skill-base>` is the `Base directory for this skill:` path surfaced at invocation; zero model tokens. Broken links (path or anchor) surface to the user with the commit: fix or explicitly acknowledge before landing; never silently skip.

3b. **Premise-closure lane (product-anchor diff)** — a problem/ICP revision changes premise, not behavior; its closure is every doc whose framing leans on the anchor. Enumerate mechanically — union of `<skill-base>/assets/doc-links.sh refs <anchor-path>` (reverse index) and the fallback glob `docs/work/GAP-*.md` + `docs/specs/*.md` (a GAP names a capability gap relative to problem + ICP; a spec builds on the premise). Judgment runs only over the enumerated set — dispatch the `premise-closure` agent (`Agent` tool, `subagent_type: "premise-closure"`; prompt = the anchor diff hunks + the anchor path + the enumerated paths, no staleness leans): its sheet (holds / re-frame / dangling per doc + coverage line) returns here; resolve with the user before the commit lands — re-frame: update the doc to align / acknowledge still-accurate; dangling: drop / merge / defer. Never silently fix, never silently skip. Then continue §3 on the rest of the diff.

4. **Doc-sync scan (dispatched on hit)** — `Agent`, `subagent_type: "doc-sync-scan"`; prompt = the diff (`git diff` + `git diff --staged`) + today's date + the scan scope (§3's citer read-set + grep-hit files + link-target files). The agent judges cold and scoped: each scope doc against the diff's claims, plus the diff-scoped new-assertion residual (each new asserting line verified against its link target, or — unlinked — against any existing doc answering the same question) — never a whole-surface re-derivation; whole-surface coverage belongs to `/check-docs-consistency`. Returns one shape:
   - **`stale-docs`** → resolve each candidate with the user (update / acknowledge-accurate / skip — never silently fix, never silently skip). Land approved doc edits (inline for bounded prose; dispatch by closure). Resolved docs join the stage list.
   - **`clean`** → proceed.

5. **Message + commit** — draft a Conventional Commit (`<type>(<scope>): <subject>`, imperative ≤72 chars, body only when the why isn't in the diff, match `git log` style; one logical change per commit — a diff spanning two unrelated changes splits). `git add <explicit paths>` — never `-A` / `.`, never secrets (`.env`, keys). Commit with HEREDOC formatting; `git status` after to verify clean. Pre-commit hooks run; on failure fix the cause, never bypass. Always a new commit — amend only if asked.

6. **Push (on confirmation)** — present branch → upstream, commits ahead. Ask **"Push these now? (y / skip)"**. Push on explicit yes only (`git push <remote> <branch>`); skip on silence or decline. Never force, never unannounced.

7. **Cycle handoff** — one line from cycle facts (any `docs/work/{BUG,DEBT,GAP}-###.md` present; a card whose latest Plan block has steps the latest Progress doesn't report done = in-flight). Don't expand into a status table — that's `/super-bootstrap:todo`'s job:

| Cycle facts | Handoff one-liner |
|---|---|
| No open cards | `Cycle complete. Safe to /clear. Next session: /super-bootstrap:todo picks up next item.` |
| In-flight card (Plan steps not all reported done in latest Progress) | `Cycle complete. {ID} still in-flight — /clear then /super-bootstrap:todo to resume.` |
| Open cards, none in-flight | `Cycle complete. Open cards, none in-flight — /clear then /super-bootstrap:todo to pick next.` |

## Rules

- **Gateway-inline; two dispatch paths, each on its own gate.** The gateway holds the diff, session list, and intent → mechanics stay inline (no closure a fresh container would hold). The cold doc-sync scan (grep-gate hit) and the premise-closure judge (product-anchor hit) are the steps a clean context serves.
- **Grep-gate is mechanical.** Term extraction is path-structure only, never a judgment about which identifiers matter — a judgment gate gets omitted. Any hit dispatches; conservative by design. A pure asset/binary diff with no narrated path is the skippable class.
- **Session-isolated.** The session list decides; prior dirty state is sacred. Explicit paths, never `-A`.
- **Doc-sync round-trip, never bypass** — a `stale-docs` return goes through the user before commit.
- **Whole-diff-once.** Doc-sync runs at the integration boundary, on the whole diff, once. Drain-worktree defers it to merge; an implementer never owns doc-sync — a partial-slice view gives false confidence.
- **Push on explicit yes only** — committed work is safe locally either way.
