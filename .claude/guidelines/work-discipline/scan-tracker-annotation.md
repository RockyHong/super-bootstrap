# Scan-Tracker Annotation

A scan or audit that emits a finding set often runs in a project that keeps an
open-item tracker — a backlog, an issue list, a parked/deferred queue.
Cross-referencing findings against that tracker adds triage context, but only as
a layer applied *after* the scan, never as a filter during it. Running the scan
blind to prior decisions keeps it empirical; pre-filtering lets a stale "fixed"
claim suppress a real regression.

This file owns the annotation contract — sibling scan skills cite it; only their
domain-specific index targets and report section name live with them.

## When it runs

Only when the project keeps an open-item tracker (e.g. `docs/backlog.md`); skip
otherwise. Run AFTER all findings are identified and classified — the annotation
is a layer over a finished finding set, never a gate on it. Every finding stays
in the report regardless of tag.

## The contract

Read the tracker (and any parked/deferred list the project keeps). Build a
lightweight index of the location references (file + line/section) and named
identifiers (endpoints, field names, component names, concepts) the scan's domain
produces — the invoking skill names which targets to index.

For a delete-on-close tracker (closed rows are removed, not archived), a finding
that matches no open row but reads as previously handled is verified via
`git log --all --grep="<ID or identifier>"` before tagging — the git history is
the only surviving record of a closed decision.

Assign each finding exactly one tag:

| Overlap | Tag |
|---|---|
| None | `new` |
| Open tracker row | `tracked ({ID}, open)` |
| Closed row, git log claims fixed | `⚠️ potential regression ({ID} claims fixed)` |
| Closed row, git log shows dismissed | `🚫 previously dismissed — rationale may be stale` |
| Parked/deferred item | `🅿️ parked — trigger: {trigger text}` |

Matching is simple, no fuzzy match: exact file path + location → match; exact
file path + identifier → match; a globally unique identifier alone → match;
anything ambiguous → annotate anyway. A false `tracked` tag is less harmful than
a missed regression.

Tags land in the report's annotation section; the priority finding tables are
never modified.

## Boundary

Applies to: any scan/audit skill that emits a finding set and may run against a
project tracker. Consumer skills cite this file by path — the table lives here only.
