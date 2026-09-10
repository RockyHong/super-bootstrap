# AGENTS.md

> Standing contract for an agent runtime executing a **build task** in this repo. The task arrives from an orchestrator that holds routing, verification, doc-sync and commits; this file states what it expects back and what stays outside your reach. Sections below are the shipped contract — anything this repo appends under them is binding too.

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
- Work-tracking surfaces: the `docs/work/` card set, and any session-state ledger at the repo root — route to the orchestrator.
- Branch, merge and release decisions — route to the orchestrator.
