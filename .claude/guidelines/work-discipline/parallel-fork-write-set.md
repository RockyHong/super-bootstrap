# Parallel Fork — Commits, Shared Output and Returns

Work split across several dispatches on one tree keeps three guards: each
logical change to a file lands as its own commit, one assembler writes any
shared output, and what a member returns is re-derived before it is used.

- **Give separate logical changes to one file one commit each, in turn** — the
  next change starts once the previous one has committed, whether the changes
  run as fan-out members, sequential dispatches or sequential cards. Git groups
  edits by distance, so nearby lines from two changes share a hunk, and
  separating them then means rebuilding the patch by hand; how near they land
  is known only after the edit, so distance earns no exception. A dispatcher
  whose members do not commit places the commit between the dispatches, and
  holds the next change while that commit cannot land yet.
- **The dispatcher assembles the shared output** — a combined report, a merged
  table, a ranked list — from the messages the members return. When members
  each write one shared file whole from their own partial view, the last
  writer's view is the one that survives, and that file still reads complete,
  so the loss raises no signal downstream.
- **Re-derive what a member concluded, not only re-read what it touched** — a
  return is a message, so the paths it names are re-read before integration and
  the reasoning it drew from them is re-run against the source. Measurements
  and conclusions fail independently: figures come back correct while the
  inference built on them does not.

Family catalog: [`index.md`](index.md).
