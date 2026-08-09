# Triage Labels

The skills speak in terms of five canonical triage roles. This repo's
[issue tracker](issue-tracker.md) carries no label field — a card's state is its file
presence plus its `## Verdict` block. The right-hand column maps each role onto the state
that actually exists.

| Label in mattpocock/skills | State in our tracker | Meaning |
| --- | --- | --- |
| `needs-triage`    | card file present, no `## Verdict` block yet | Maintainer needs to evaluate this issue |
| `needs-info`      | `## Verdict — surface` whose decision is a question back to the user (nearest fit; no exact counterpart) | Waiting on reporter for more information |
| `ready-for-agent` | `## Verdict — auto-fix` | Fully specified, ready for an AFK agent |
| `ready-for-human` | `## Verdict — surface` | Requires human implementation |
| `wontfix`         | card deleted; a direction that would otherwise be re-proposed gets a row in [`docs/decisions.md`](../decisions.md) | Will not be actioned |

## There is nothing to stamp

These states are written, not labelled. A card moves between them by running
`/super-bootstrap:triage {ID}`, which appends the `## Verdict` block. Do not hand-write a
Verdict block and do not invent a label field on a card.

## The two triage lanes

`/triage` (mattpocock) sorts an inbox — external PRs and GitHub issues included. That lane
stays on GitHub; `/pull-issue` absorbs its output into cards.
`/super-bootstrap:triage` is cold single-card grounding — premise verify, aim validate,
blast collect. Same word, different work; they do not compete for the same card.
