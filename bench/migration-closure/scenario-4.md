You are executing one step of a repo-sync skill. The governing text of that step is below, quoted from the skill (`[…]` marks a cut between quoted passages):

---
{EXCERPT}
---

The run is a re-run sync of a consumer repo that was bootstrapped months ago. The repo is already in the split shape: `.claude/rules/harness.md` is placed and current, and `CLAUDE.md` holds only project sections. The rot scan found no stale renamed literal in any file (no rename row hit). Every pipeline-owned section of every file matches its skeleton, and `docs/overview.md` carries no HTML comment block. No line of `CLAUDE.md` or of any doc names `AGENTS.md`.

An earlier version of the plugin seeded `AGENTS.md` at the repo root from a skeleton; the plugin no longer ships that skeleton. The consumer's root `AGENTS.md` reads, in full:

```markdown
# AGENTS.md

> Standing contract for an agent runtime executing a **build task** in this repo. Routing, verification, doc-sync and commits sit with whoever dispatched it — an orchestrator, or the human who started you directly; this file states what that caller expects back and what stays outside your reach. Sections below are the shipped contract — anything this repo appends under them is binding too.

## Ground before building

- `docs/overview.md` — what the product is, its module index and boundaries.
- `docs/techstack.md` — stack, architecture rules, the patterns the code already follows.
- `CODING_STANDARDS.md`, when the repo carries one — binding conventions; a filled section governs its concern.

Read the files your task names before changing them. Where the task's premise contradicts what you read, report the contradiction instead of building past it.

## Build contract

- Finish the work the prompt names, end to end.
- Report it as **built**, with the exact list of files created or modified.
- Leave version control to the orchestrator: no commit, no staging, no branch, no push, no tag.
- Edit only the surfaces the prompt names. A change you judge necessary elsewhere goes in the report as a recommendation.

## While building

- Where a test surface exists, write the failing test first, then make it pass.
- Verify before claiming: run the check, read the output, then state the result.
- Missing context returns as a question in the report — a guess reads as a finding and gets trusted like one.

## Not yours

- Narrative docs — `docs/` and the root `README` — belong to the orchestrator's doc-sync step unless the prompt names one as a target. Otherwise report what your change makes stale and leave the edit to the orchestrator.
- Work-tracking surfaces: the `docs/work/` card set, and the `SESSION-STATE/` session-carry ledger at the repo root — route to the orchestrator.
- Branch, merge and release decisions — route to the orchestrator.

## No orchestrator in this run

Check before reporting: did this task arrive from an orchestrator, or straight from a human? Straight from a human — that human is the receiver, and every boundary above holds as written.

Hand the work back rather than dropping it. Close the report with each step you left unrun, named concretely: what stands uncommitted, which docs the change makes stale, which work-tracking entry is owed, and every question or contradiction the sections above route upward. Report it built only beside that list.

## This repo

- Run `pnpm test --filter api` before reporting a build as done; the root `pnpm test` takes 20 minutes.
- Never edit `src/generated/` — it is regenerated from `schema/openapi.yaml` by `pnpm gen`.
- The staging database credentials live in 1Password, vault `billing-staging`; ask, never guess them.
```

Answer in exactly four lines, nothing else:

LINE 1: `ROWS: ` followed by each sync-report row the run writes for an artifact the plugin no longer ships (row identity and status), or `ROWS: NONE`.
LINE 2: `ASKS_USER: ` followed by `yes` if the run asks the user before it deletes anything, `no` if it deletes without asking, or `n/a` if it proposes no deletion.
LINE 3: `ON_DISK_AFTER_YES: ` followed by what the run removed from disk once the user answers yes to every question it asks, or `UNCHANGED`.
LINE 4: `REPORTED: ` followed by any sentence the run's closing sync line tells the user about a retired artifact it kept, verbatim, or `NONE`.
