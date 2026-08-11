# Issue Tracker

Issues for this repo live as **card files** at [`docs/work/{ID}.md`](../work/README.md) — one
file per issue. IDs take the form `BUG-###`, `DEBT-###`, or `GAP-###` (feature ideas are
GAP). `docs/work/README.md` and `docs/work/TEMPLATE.md` are contract files, not issues.

## Publish

Two doors, per [`docs/work/README.md` § Routing](../work/README.md#routing): invoke
`/super-bootstrap:log <observation>` (classifies the observation, surfaces suspected
duplicates, assigns the ID), or hand-copy `TEMPLATE.md` to `{ID}.md` — taking the next
ID from the README high-water line and bumping it in the same change.

## Fetch

List / read `docs/work/*.md`. A card file present = the issue is open. There is no
`Status` field; presence is the status.

## Comment

Append an `## Amendment — {date} · {source}` block to the card. Cards are append-only
[threads](../work/README.md#thread-contract) — never rewrite or drop an earlier block.

## Resolve

Delete the card file. Git history is the archive (`git log --grep="<id>"`).

## Field shape

Cards carry no `Type:`, `Status:`, or `Blocked by:` fields. Express type and blocking
relationships in the card's prose body.

## Before filing an enhancement

Check [`docs/decisions.md`](../decisions.md) for a previously rejected direction — it is
this repo's [`.out-of-scope/` superset](../specs/harness-architecture.md#7-evidence-index), and a closed fork is expected to surface before it
is re-walked.
