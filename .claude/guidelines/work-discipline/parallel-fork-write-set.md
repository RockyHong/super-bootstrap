# Parallel Fork Write Set — Name What Each Member May Write

A prohibition is not a scope. A fan-out member told only that it must not
write still holds every writing tool and a goal its own reading of the brief
can stretch to justify, and it has nothing to check a proposed write against;
a named set of paths gives it that check. Members sharing one output file
compound the gap: each writes that file whole from its own partial view, the
last one to finish is the one that survives, and the surviving file reads
complete — so the loss raises no signal downstream.

- **Name the write set in every parallel dispatch** — the paths that member
  may create or edit, given as paths, with everything outside them read-only.
  Keep the sets disjoint across members: a path sitting in two write sets is a
  collision the brief has already authored.
- **The dispatcher assembles the shared output** — a combined report, a merged
  table, a ranked list — from the messages the members return. Shared output
  belongs to no member's write set, which is what keeps the sets disjoint when
  the goal is one artifact and the work is split many ways.
- **Re-derive what a member concluded, not only re-read what it touched** — a
  return is a message, so the paths it names are re-read before integration and
  the reasoning it drew from them is re-run against the source. Measurements
  and conclusions fail independently: figures come back correct while the
  inference built on them does not.

Family catalog: [`index.md`](index.md).
