## What you were doing

Follow-on to `BUG-055`. That card's fix taught `SLUG_AWK` to strip the unicode marks
GitHub drops from its own heading anchors, so a link written against GitHub's anchor
stopped reading as broken. The residual it left: when the strip list is *short* — a mark
GitHub drops that the list does not yet name — `check` reports the link as broken with no
way for the reader to tell a strip-list gap from a genuinely absent anchor. Both print the
same line.

So this change makes the miss path say which one it is. On an anchor miss, strip every
non-ASCII byte from each computed slug and compare against the anchor the link asked for;
equal means the heading carries a mark the list is missing, and the finding gets a
parenthetical naming the computed slug so the reader can extend the alternation. Extend
the list, never widen the class — a CJK heading cannot reach here, because its anchor
carries those letters and its stripped form matches no anchor anyone would write.

The cost question was live while you wrote it, which is why the early return is there: the
common case is an all-ASCII surface where no miss can ever be a strip-list gap, and one
`tr` fork on the whole table rules the per-slug loop out before it starts. The loop itself
only runs on a surface that actually carries non-ASCII headings, and only on links that
already failed.

## What you read this session

- `docs/work/BUG-055.md` — the parent card
- `docs/work/README.md`, `docs/work/TEMPLATE.md` — card thread contract
- `docs/decisions.md`, `docs/parked.md` — closed-fork and deferred-item checks
- `CLAUDE.md` — the harness brief
- `plugins/super-bootstrap/README.md`
- `plugins/super-bootstrap/skills/commit/assets/doc-links.sh`, `tests/doc-links.test.sh` —
  the files this change edits
