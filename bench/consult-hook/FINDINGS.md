# doc-graph v2 gate — benchmark findings (GAP-017)

**Date:** 2026-06-20 · **Tier:** opus (warm, the tier actually used) · **Runs:** 9 (3 probes × 3 arms)

> **Scope of this report — facts, judge for yourself.** Sample: **one run per cell**
> (9 runs = 3 probes × 3 arms), graded **once** by the dispatcher (no blind judge).
> Route: warm **opus** tier · small repo (**52 nodes**, shallow closures) ·
> `net = gain − tax` scoring in a pure-reasoning session. Under these conditions the
> **baseline scored 2/2 on every probe** (saturated). Carry-along risks a reader
> should weigh: a saturated baseline leaves no room for any arm to win (structural
> loser regardless of real value); single-grader calibration is unchecked; the tax
> penalty may not reflect real attention-pressure sessions. Treat what follows as one
> data point under this setup, not a general verdict either way. Detail: §Limitations
> + §Caveats.

## Question

GAP-017 asked: is doc-graph **v2** (inline hard-edge constraint *text* on typed
edges) worth building, after **v1** (pointer-dump of the whole authored closure)
was shelved 2026-06-18? Prior shelve rested on 2 hand-injected probes judged by
feel and could not reproduce the target failure (warm-session false-confidence
under-read). This bench replaces gut with a scored measurement.

## Method

- **Arms:** `baseline` (no wire) · `v1-auto` (real `doc-graph-inject.sh`,
  whole-closure pointer dump) · `v2-oracle` (perfect selection — inline ONLY the
  one keyed neighbor's hard-edge sentence, zero noise; control probe injects
  nothing). v2-oracle = the **ceiling** of the v2 idea.
- **Driver:** headless `claude -p --model opus --settings bench/arm-<arm>.json
  --output-format stream-json`. Each run = fresh process → SessionStart +
  UserPromptSubmit fire (Phase 0 proved hooks fire headless & `additionalContext`
  reaches the model). The Agent/Task tool does NOT fire UserPromptSubmit — only a
  subprocess `claude -p` exercises the real wire.
- **Probes** (`bench/probes.jsonl`): each names a stem (triggers the inject) with
  the correct answer hiding in an un-named neighbor. P1 hard-miss, P2 completeness
  delta, P3 control (self-contained answer; detects narrowing/over-fetch).
- **Score = gain − tax.** Gain: read-keyed-neighbor (crawl-path from stream-json
  Read events) + answer 0/1/2 vs key. Tax: injected noise + wasted neighbor reads
  + answer drift.

## Result

| Probe | Arm | Read keyed nbr | Noise reads | Answer |
|---|---|---|---|---|
| P1 | baseline | yes (unaided) | 0 | 2 complete |
| P1 | v1-auto | yes | 0 | 2 complete |
| P1 | v2-oracle | yes | 0 | 2 complete |
| P2 | baseline | yes (unaided) | 0 | 2 complete |
| P2 | v1-auto | yes | **2 wasted** | 2 complete |
| P2 | v2-oracle | yes | 0 | 2 complete |
| P3 | baseline | n/a self-contained | 0 | 2 complete |
| P3 | v1-auto | n/a | 0 | 2 complete |
| P3 | v2-oracle | n/a (nothing injected) | 0 | 2 complete |

- **Baseline opus is complete on all 3 probes and crawls to the keyed neighbor
  unaided.** Gain available to any wire: **zero.**
- **v1-auto:** gain 0; on P2 read 2 docs baseline didn't (≥1 its injected noise)
  → **net negative** (over-fetch tax for no gain).
- **v2-oracle (ceiling):** gain 0, tax 0 → **net zero.**

## Verdict — NOT BUILT (this test under-favored the wire; unproven either way)

Decision: **don't build v2 now.** Not "v2 is worthless" — the test could not
show value if it existed. In this run baseline opus over-read and already reached
the keyed neighbor, so v2-oracle netted 0 and v1-auto netted negative. But that
result is **structurally entangled with the test design** (see Limitations): a
saturated baseline leaves no room for any arm to win. So the honest status is
**no value shown in a setting that could not show it** — not a disproof.

Acted on: GAP-017 parked (not deleted), scripts shelved+unwired, authored doc
links kept (costless, net-positive — and the thing baseline actually follows).
Re-open with a test where baseline has room to FAIL.

## Limitations — why this test under-favored the wire

1. **Ceiling-saturation bias (the load-bearing flaw).** The v2-oracle "ceiling"
   logic only holds if baseline can fail. Baseline scored 2/2 on every probe →
   the metric saturated at baseline → every arm is a forced loser by construction.
   "0 gain" is confounded with "0 *possible* gain in this setup." Not a fair fight.
2. **Small repo under-stresses the mechanism.** 52 nodes, shallow closures — opus
   over-reads the whole relevant set cheaply. The wire's value only appears where
   baseline *can't* hold the context: large repo, deep closures, forced read-choice.
   This was the least favorable setting.
3. **Tax over-weighted.** `net = gain − tax` penalized over-fetch, but in a
   pure-reasoning session the attention tax barely bites — it is only load-bearing
   under real attention pressure (huge context, many tools). The test's own clean
   conditions did not impose the cost it scored against.
4. **Precedent is not hearsay.** The under-read / false-confidence failure recurs
   in real use (reported by the maintainer and others). Failure to reproduce it in
   a small synthetic test ≠ it does not happen. Absence of evidence here, against
   lived precedent, is weak.

**A fair re-test must:** give baseline room to fail (large repo opus cannot hold,
OR a weaker / hurried tier, OR a measured real under-read), not penalize tax in
reasoning sessions, use a larger probe set — and will likely test **v3 or a new
method**, not v1/v2.

## Caveats

- n=3 probes; engineered under-reads did NOT reproduce on opus even when designed
  to — that is itself the finding.
- `additionalContext` is not echoed in stream-json; injection confirmed via
  standalone injector tests + Phase 0 marker-echo, not per-run. Immaterial:
  baseline reached the docs regardless.
- P3-v2-oracle: the model **hallucinated** that a hook injected a bundled-skill
  constraint (nothing was injected — injector returns empty, no other
  UserPromptSubmit hook wired, `[doc-graph v2]` marker absent from stream). A
  model-confabulation artifact, not a harness leak.
- Grading was dispatcher-read (answers unambiguous); a blind sonnet judge could
  reconfirm.

## Reusable

`bench/` is a working headless A/B harness for hook-injection quality:
`probes.jsonl` + `arm-*.json` + `v2-oracle-inject.sh` + `run.sh`. Re-runnable if a
future Claude tier under-reads where opus over-reads.
