# Dispatch Brief Shape — One Artifact per Authoring Dispatch

A wide-read → wide-author brief ("read all N sources, then author all M outputs")
puts the whole plan in flight at the read→write boundary; the agent's turn
reliably closes on narration of the plan ("Now I'll author…") with zero writes,
and a resume repeats the stall. The stall correlates with brief *shape*, not
size — narrow briefs complete arbitrarily long tool-call runs.

- **Scope one authoring dispatch to one artifact** (or one tightly-coupled
  pair) plus its minimal read set. Fan the artifact list out across dispatches,
  not inside one brief.
- **Pass shared decisions as literals in the brief** — vocabulary maps, enums,
  design verdicts. Parallel agents re-deriving a shared decision diverge; a
  literal costs nothing and pins them.
- **Two stalls on one brief = re-shape the dispatch** — split the brief, or
  author inline when the dispatcher already holds the full frame. A third
  resume re-buys the same stall.

Sibling: [`dispatch-breadcrumb.md`](dispatch-breadcrumb.md) — what a brief
carries (the scope's entry doc); this file — how much a brief carries.
