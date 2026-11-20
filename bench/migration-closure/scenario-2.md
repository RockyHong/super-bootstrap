You are executing one step of a repo-sync skill. The governing text of that step is below, quoted from the skill (`[…]` marks a cut between quoted passages):

---
{EXCERPT}
---

The run is a re-run sync of a consumer repo that was bootstrapped months ago. The repo is already in the split shape: `.claude/rules/harness.md` is placed and current, and `CLAUDE.md` holds only project sections. The rot scan found no stale renamed literal in any file (no rename row hit). Every pipeline-owned section of every file matches its skeleton. The repo has no `AGENTS.md`.

The consumer's `docs/overview.md` opens:

```markdown
# Overview

<!-- harness-meta: read by /super-bootstrap:resolve-plugins (tier-2 curation). Keep YAML shape; list values in [...].
Default [github]; add any of: notion, linear, jira, slack, trello, clickup, other.
external-tools: [github, linear]
-->

> Living doc. Skeleton sections (Problem / User / Current State) carry their placeholder body verbatim at scaffold and fill at GAP card pickup. Grown sections (Module Index / Data Flow / Key Boundaries) start empty and grow via doc-sync — every commit that adds, removes, or reshapes a module triggers a sync proposal, admitted per § Doc Sync. See [`.claude/rules/harness.md` Doc Sync](../.claude/rules/harness.md#doc-sync-non-negotiable).

## Problem

Invoices are reconciled by hand every month; this CLI matches bank exports to open invoices.
```

The shipped skeleton `assets/overview-skeleton.md` has no HTML comment block; its H1 and blockquote equal the consumer's. `/super-bootstrap:resolve-plugins` no longer exists in the installed plugin.

Answer in exactly four lines, nothing else:

LINE 1: `ROWS: ` followed by each sync-report row the run writes for an artifact the plugin no longer ships (row identity and status), or `ROWS: NONE`.
LINE 2: `ASKS_USER: ` followed by `yes` if the run asks the user before it deletes anything, `no` if it deletes without asking, or `n/a` if it proposes no deletion.
LINE 3: `ON_DISK_AFTER_YES: ` followed by what the run removed from disk once the user answers yes to every question it asks, or `UNCHANGED`.
LINE 4: `REPORTED: ` followed by any sentence the run's closing sync line tells the user about a retired artifact it kept, verbatim, or `NONE`.
