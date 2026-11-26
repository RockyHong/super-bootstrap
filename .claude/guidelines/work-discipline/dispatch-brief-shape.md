# Dispatch Brief Shape — What a Brief Pins, Re-sends and Re-shapes

How a dispatch brief is shaped for the round it sends: the decisions it pins,
how much of the frame it re-sends, and when the dispatch itself changes shape.

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
- **Two stalls on one brief = re-shape the dispatch** — a stall is a turn that
  closes on narration of the plan with zero writes. After two, split the
  brief, or author inline when the dispatcher already holds the full frame. A
  third resume re-buys the same stall.

Family catalog: [`index.md`](index.md).
