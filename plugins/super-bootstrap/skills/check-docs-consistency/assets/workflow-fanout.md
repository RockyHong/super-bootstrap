# Scan Workflow Fan-Out

A scan escalates by attention-fit, not by surface size alone. The default is a
single inline pass — one container greps, triages, and writes the report. When
the surface outgrows what one container reads cleanly, the scan climbs an
escalation ladder: fan the reads out across a Workflow, a judge merging.

The decision pattern is the same at every rung: discover the file set inline →
size it with the pre-flight → pick the rung → for a fan-out rung, encode the
shape in a deterministic Workflow script. Default-with-override: the sizing
pre-flight defaults the rung, the human can force a different one.

## Sizing pre-flight

Before choosing a rung, gather four cheap proxies over the discovered file set —
no file reading, just filesystem facts collected in the invoking context:

| Proxy | Reads on | Sharpens |
|---|---|---|
| File count | how many files in the discovered set | cluster count if fanning out |
| Total bytes | aggregate scan surface | whether one container holds it cleanly |
| Max single-doc size | largest single file | whether one cluster overflows a reader (rung 4 signal) |
| Directory spread | distinct directories / natural cluster count | partition seams for a fan-out |

The proxies make the surface *visible*; they do not gate. The rung stays a
judgment over the proxies **plus** attention-fit — a scoped run a single
container holds cleanly stays inline even at a high file count; a tangled small
set may still earn a fan-out. No fixed thresholds: the trigger is attention-fit,
the proxies only inform it.

The pre-flight fires in the invoking context *before* any Workflow launches — a
blocked scan never spawns agents. For a fan-out rung, author the script in the
invoking context; the Workflow tool description carries the API there.

## The escalation ladder

- **Rung 1 — inline solo.** One container greps, triages, writes the report. The
  default. A surface a single context holds without recall decay stops here.
- **Rung 2 — fan-out reads + one judge.** Parallel readers each extract one
  cluster's working set; one judge consumes all extractions and writes the
  report. The § Fan-out contract below binds this rung. Climb here when parallel
  containers buy attention-relief — each cluster read clean, no single-container
  recall decay across a wide set.

Rungs 3–5 are named routes, not yet built — climb only when a run actually hits
the shape:

- **Rung 3 — lossy/large-reader escalation.** A reader that drops working-set
  items, or holds a cluster too large for its tier, gets pinned up a tier on the
  next run rather than accepting misses — see § Fan-out contract item 4.
- **Rung 4 — intra-doc chunking.** A single doc too large for one reader splits
  into overlapping section chunks, each its own reader.
- **Rung 5 — split judge.** When one judge can't hold all extractions cleanly,
  split the judge by finding-axis, then a merge judge reconciles.

## Fan-out contract

Binds rung 2, and the reader/judge core that rungs 3–5 extend.

1. **Decomposition** — partition the discovered file set into clusters (e.g. by
   directory), one reader `agent()` per cluster extracting the scan's working set
   as structured output; one judge consuming all extractions. The judge needs the
   full extraction set — a barrier before it is correct. The judge runs with full
   tool access: it reads the tracker, runs the git-log verification from
   `tracker-annotation.md`, and writes the report itself.
2. **Output contract (hard)** — the judge emits the invoking skill's report schema
   exactly. Orchestration stays soft; the report format is the binding contract.
3. **Merge rule** — the same finding location appears once, under the
   highest-priority match.
4. **Model tiers** — pin `model:` on every `agent()` call; omitted, each agent
   silently inherits the main-loop tier. Readers `haiku` only where a judge stage
   cross-checks their extractions (this contract's shape); a reader whose output
   feeds the report or triage with no judge behind it floors at `sonnet` — an
   unchecked lossy read has no recovery stage. Judge `sonnet` (cross-reference
   judgment). Ceiling is `sonnet`: the scan's verdicts feed the user-owned
   triage — the direction-setting step is the triage, not the scan. Extraction
   completeness is the recall floor — the invoker spot-checks reader output
   between runs and pins a lossy reader to `sonnet` on the next run rather than
   accepting misses (rung 3).
