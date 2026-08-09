# Tracker recipe — issue-tracker declaration for mattpocock/skills

`mattpocock/skills` ships a user-invoked `/setup-matt-pocock-skills` that asks where this
repo tracks issues. Its **Other** branch takes a freeform prose description and records it
as the repo's tracker contract. In a repo this pipeline bootstrapped the tracker is the
`docs/work/` card set — the block below is that description, ready to paste.

**Boundary — recipe, not a destination file.** Surface the block; the human types the
command and pastes the answer. Never pre-write `docs/agents/issue-tracker.md` or any other
`docs/agents/*` file: his setup owns them and may overwrite a pre-seeded copy without
diffing it.

**Sequencing.** The card system must exist first — run this after the harness runway is in
place, so `docs/work/`, `docs/work/README.md`, and `docs/decisions.md` are present and the
`/super-bootstrap:log` door resolves.

## The recipe

Paste verbatim at the **Other** prompt:

```text
Issues for this repo live as card files at `docs/work/{ID}.md` — one file per issue. IDs
take the form `BUG-###`, `DEBT-###`, or `GAP-###`; feature ideas and capability gaps are
`GAP`. `docs/work/README.md` and `docs/work/TEMPLATE.md` are contract files, not issues.

- **Publish** — invoke `/super-bootstrap:log <observation>`. Never write a card file
  directly: the log door classifies the observation, surfaces suspected duplicates, and
  assigns the ID from the high-water line in `docs/work/README.md`.
- **Fetch** — list / read `docs/work/*.md`. A card file present = the issue is open. There
  is no `Status:` field; presence is the status.
- **Comment** — append an `## Amendment — {date} · {source}` block at the end of the card.
  Cards are append-only threads: never rewrite or drop an earlier block. The other block
  types (`Verdict`, `Design`, `Plan`, `Progress`) are written by this repo's own workflow
  doors; `docs/work/README.md` holds the full thread contract.
- **Resolve** — delete the card file. Git history is the archive (`git log --grep="<id>"`).
- **Field shape** — cards carry no `Type:`, `Status:`, or `Blocked by:` fields. Express
  type and blocking relationships in the card's prose body.
- **Before filing an enhancement** — check `docs/decisions.md` for a previously rejected
  direction. It is this repo's `.out-of-scope/` equivalent: a closed fork is expected to
  surface before it is re-walked.
```

## Load-bearing under adaptation

Wording is free to change per repo; these four are what his skills act on, so a variant
that breaks one breaks the coexistence:

- `/super-bootstrap:log` is the only publish path — IDs are assigned there, never invented.
- Presence is status — no `Status:` field to read or set.
- Cards append; earlier blocks are never rewritten.
- Deleting the file resolves the issue.
