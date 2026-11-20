You are executing one step of a repo-sync skill. The governing text of that step is below, quoted from the skill (`[…]` marks a cut between quoted passages):

---
{EXCERPT}
---

The run is a re-run sync of a consumer repo that was bootstrapped months ago. The repo is already in the split shape: `.claude/rules/harness.md` is placed and current, and `CLAUDE.md` holds only project sections. The rot scan found no stale renamed literal in any file (no rename row hit). The repo has no `AGENTS.md` and its `docs/overview.md` carries no HTML comment block.

The shipped skeleton `assets/overview-skeleton.md` opens:

```markdown
# Overview

> Living doc. Skeleton sections (Problem / User / Current State) carry their placeholder body verbatim at scaffold and fill at GAP card pickup. Grown sections (Module Index / Data Flow / Key Boundaries) start empty and grow via doc-sync — every commit that adds, removes, or reshapes a module triggers a sync proposal, admitted per § Doc Sync. See [`.claude/rules/harness.md` Doc Sync](../.claude/rules/harness.md#doc-sync-non-negotiable).

## Problem
```

The consumer's `docs/overview.md` opens:

```markdown
# Overview

> Living doc. Skeleton sections (Problem / User / Current State) carry their placeholder body verbatim at scaffold and fill at GAP-card pickup. Grown sections (Module Index / Data Flow / Key Boundaries) start empty and grow via doc-sync — every commit that adds, removes, or reshapes a module triggers a sync proposal, admitted per § Doc Sync. See [`CLAUDE.md` Doc Sync](../CLAUDE.md#doc-sync-non-negotiable).

## Problem

Invoices are reconciled by hand every month; this CLI matches bank exports to open invoices.

## User

The finance team's two analysts.

## Current State

Matching works for one bank format; partial payments are not handled yet.

## Module Index

- `src/match/` — the matcher.
```

Every other pipeline-owned file in the repo matches its skeleton. The user approves every row the run proposes.

Answer in exactly three lines, nothing else:

LINE 1: `PREAMBLE_ROW: ` followed by the sync-report row the run writes for the lines of `docs/overview.md` above `## Problem` (section name and verdict), or `PREAMBLE_ROW: NONE` if the run writes no row for them.
LINE 2: `LINK_AFTER: ` followed by the markdown link at the end of the blockquote as it reads after the run, verbatim.
LINE 3: `PICKUP_AFTER: ` followed by the phrase in the blockquote's first sentence that ends with `pickup`, as it reads after the run, verbatim.
