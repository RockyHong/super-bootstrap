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
- **A delta brief continues; a full brief restarts.** Whether to continue is
  decided first: continue only while the container's thread holds what the
  next round builds on. The criterion lives in
  `~/.claude/guidelines/axiom-principles/agent-shapes.md` § Gateway and the
  resume cost in `~/.claude/guidelines/claude-shape/subagent-continuation.md`
  (both device-planted).
  A continuing round's brief names the files, the rule that changed, and the
  check that decides — the container already holds the rest. Re-sending the
  full read set turns the continuation into a cold rebuild at a new dispatch's
  cost. A fresh round's brief is compact: the goal, the task's progress record, and
  the directions already rejected.
- **Two stalls on one brief = re-shape the dispatch** — split the brief, or
  author inline when the dispatcher already holds the full frame. A third
  resume re-buys the same stall.

Family catalog: [`index.md`](index.md).
