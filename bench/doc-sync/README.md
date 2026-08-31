# doc-sync bench — cold dispatch vs warm gateway-inline

Controlled read-out for `GAP-069`. The commit door dispatches the cold
[`doc-sync-scan`](../../plugins/super-bootstrap/agents/doc-sync-scan.md) agent on
every mechanical gate hit, and that container choice has never been measured
against the warm gateway-inline alternative. This bench holds the diff and the
enumerated scan scope fixed and varies only the container.

Nothing here ships. It is measurement apparatus, on the shape of
[`../consult-hook/`](../consult-hook/README.md).

```
./make-fixtures.sh        rebuild both fixture trees under .fixtures/   (no LLM)
./assemble-prompts.sh     rebuild prompts/ from parts/                  (no LLM)
./check-key-absence.sh    fail if the answer key reached a prompt       (no LLM)
./run.sh --dry-run        preflight + plan, zero `claude` invocations
./run.sh                  15 arms, sequential
./run.sh f1-cold          one arm's N repeats
```

Scoring is human, into [`SCORING.md`](SCORING.md) — which holds the fixture-1
answer key and is the only file in this directory that does.

## Axes

Two, because a coverage-only metric scores the failure that motivated the card as
two clean hits.

| Axis | Fixture | Scores |
|---|---|---|
| **Coverage** | `d3161f3` replay | known-stale surfaces reached, against a key recovered from git history |
| **Verdict stability** | techstack fork-free-inner-loops, Run B revision | agreement rate across N repeats of one fixed prompt — no key exists |

## Arms

15 arms: fixture 1 × {cold, warm, opus-control} × 3, fixture 2 × {cold, warm} × 3.
N=3 keeps the numbers comparable with the 1/15 and 3/3 figures already on record
for this fixture.

- **cold** — the shipped scanner's own framing: dispatched, blind to why the
  change was made, holding only diff + scope.
- **warm** — the gateway's framing: the scan runs inline in the arm's own
  top-level turn, no subagent, and the prompt carries the change intent and the
  session-read doc list as the gateway held them. Reconstruction is
  transcript-sourced, not invented — see § Fixtures.
- **opus-control** — the cold prompt, byte-identical, on Opus. Fixture 1 only.

## Container — why every arm inlines the scanner text

`doc-sync-scan.md` pins `model: sonnet` and the pinned agent rejects a call-site
model override (GAP-058 precedent). If only the Opus arm moved to an inlined
container, tier and container would vary together and the container axis would be
unreadable. So **no arm dispatches the shipped agent**: all five prompts inline
the same scanner body and differ only in the container framing around it.

`assemble-prompts.sh` builds every prompt by concatenating files from `parts/`,
so byte-identity is structural rather than maintained by hand. Within one
fixture, cold and warm share `scanner-body.md`, the scope block, the diff block
and the task line byte for byte. What differs:

| Part | cold | warm |
|---|---|---|
| framing header | `container-cold.md` | `container-warm.md` |
| eyes rule | `rule-cold.md` | `rule-warm.md` |
| intent + session-read block | absent | `f{1,2}-intent.md` |

The warm arm holding more state is the container variable, not a confound — held
state is half of what "warm" means. The other half is declared unmodeled below.

**On reading the intent blocks.** Each is a faithful reconstruction of what its
gateway actually held, which makes them asymmetric: fixture 1's narrates what was
authored, while fixture 2's carries the gateway's own cost argument for the early
return — because that argument genuinely was the change's rationale. A warm arm
that returns `clean` on fixture 2 having been handed that reasoning is the
authoring-confidence effect the card is asking about, not a spoiled prompt. Score
it; do not correct for it.

## The Opus arm is a control

[`docs/decisions.md`](../../docs/decisions.md) row 34 priced Opus out for the
per-commit door, and that row stays closed. The arm buys one thing: a scale for
the warm−cold gap — is it larger or smaller than the known tier gap? An "adopt
Opus for the per-commit door" conclusion would re-walk row 34 and is out of
bounds for anything this bench returns.

Rows 34 and 35 both name same-fixture measurement as their reopen condition,
which fixture 1 structurally satisfies.

## Fixtures

### Fixture 1 — `d3161f3` replay (coverage)

A plain worktree at `d3161f3`, the commit that shipped the mattpocock
coexistence runbook. `make-fixtures.sh` checks it out; nothing is patched, so the
tree is the commit's own post-image. The arm prompt is that commit's diff plus
its date, identical across arms. The scan scope in `parts/f1-scope.md` was
computed mechanically against that old tree by running HEAD's `doc-links.sh`
(`terms` → `hits`, `anchors` → `refs`, plus added-line link-target extraction)
per the commit door's §3 — the block records each lane's output and how it got
there. Five docs, under the 8-doc ceiling.

The answer key was recovered from commits and cards that all postdate
`d3161f3`. It lives in `SCORING.md` and reaches no arm — see § Decontamination.

The fixture is history-anchored and cannot decay: one of the docs it turns on has
since been deleted at `HEAD`, but the replay reads the tree at `d3161f3`.

### Fixture 2 — techstack fork-free-inner-loops, Run B (stability)

Neither revision the card's Amendment describes was ever committed. Run B is
recovered verbatim from the session store
(`~/.claude/projects/D--Git-super-bootstrap/b51b28e0-902f-4bf6-96eb-a29dd41c18cb.jsonl`),
which carries the dispatch prompt embedding the function body. `make-fixtures.sh`
reconstructs the working tree as base `a3418fe` plus `parts/f2-runB-doc-links.patch`.

**Reconstruction is verified against Run B's own recorded numbers** — its
dispatch prompt claims `53 passed, 0 failed`, and the rebuilt tree's suite
returns exactly that. `make-fixtures.sh` asserts it on every rebuild.

Two caveats, both carried forward from the card's verdict:

1. The dispatch prompts in the session store are gateway-*narrated*
   ("## What changed", "Read both from disk"), not raw `git diff`. `parts/f2-diff.txt`
   preserves that narration verbatim, so the "diff" this fixture holds fixed is
   the narrated diff, which is what the original evidence actually varied over.
2. Run B's test-file text is not recorded verbatim. The block shipped at
   `c7f5ce9` matches its stated shape (ten assertions over four fixtures) and is
   used in its place. It is not in any arm's scan scope.

## Declared bounds

Both come from the card's settled Design and both limit what a result here can
claim. They are not caveats to discover after the numbers land.

1. **Authoring confidence is unmodeled.** "Warm" has two components — held state
   (diff + intent + session-read docs) and authoring confidence, the bias the
   card prices the warm arm against. A prompt-reconstructed arm supplies the
   first and only weakly the second, so the warm arm measures closer to the
   untested hybrid in the card's origin Prior than to true gateway-inline.
   Authoring replay — where the arm makes the edits itself — buys the second half
   but trades away the fixed diff, so it is the escalation if this round shows no
   separation, not a substitute for it.

2. **Fixture 2's narration is fixed.** The original evidence varied gateway
   narration alongside the code revision — Run A and Run B differed in prose
   framing as well as in code. The replay fixes one narration, so its stability
   read-out speaks to the fixed-prompt case only.

## Decontamination

The channel analysis is
[`../consult-hook/bench-decontamination.md`](../consult-hook/bench-decontamination.md)
— **cited cross-folder, not hoisted**. It is bench-general prose homed under the
bench that authored it; no mechanical blocker appeared (both benches read it from
the same repo), so a copy would only fork the truth. Applied here:

- **Score only fixture runs.** Both arms run cwd'd inside a `.fixtures/` worktree,
  never in the live repo. `run.sh` asserts the tree's identity before any arm
  fires.
- **Answer-key isolation.** `check-key-absence.sh` reads a leak-literal list from
  `SCORING.md`'s own fenced block and fails the round if any of them reaches
  `prompts/` or `parts/`. One source, so the key and its guard cannot drift.
  `run.sh` runs it in preflight.
- **Tool restriction.** The shipped agent has `tools: Read, Grep, Glob`. Arms run
  with `--disallowedTools Bash Write Edit NotebookEdit WebFetch WebSearch Task
  Agent` plus a matching allow/deny pair in `arm-settings.json`, so no arm can
  reach `git log` — where every fix that postdates the fixture lives.
- **Recent-commits leak.** A fixture worktree's `HEAD` is the fixture commit, so
  the headless system prompt's recent-commits block predates every fix.
- **Ambient self-description.** Both fixture trees carry their own `CLAUDE.md`
  narrating doc-sync. That is inherent to a replay of the real repo state, it was
  the condition the prior rounds ran under, and it is identical across arms — so
  it does not confound the container axis. Stripping it would break comparability
  with the recorded 3/3 and 0/3 baselines.
- **Card contamination, found and removed.** At `a3418fe` the tree carries
  `docs/work/GAP-069.md` — this bench's own specifying card, container hypothesis
  and all — plus `GAP-070`. Both are card-lifecycle files the gate exempts by
  construction, so they sit outside every arm's scan scope; only step 4's
  unlinked-line grep could reach them. `make-fixtures.sh` deletes them from the
  fixture-2 tree, and they are dropped from the warm arm's session-read list.
  Fixture 1's tree carries no card describing this read-out and is left exactly
  as `d3161f3` left it.
- **Device-hook bleed-through.** `arm-settings.json` sets `disableAllHooks`,
  which is stronger than the doc's record-and-compare floor. `run.sh` records the
  device hook set into `runs/ENV.txt` anyway, so a round stays comparable even if
  that key is ignored by the running version.

## Deviations from the card's spec

Recorded rather than silently absorbed.

- **Session-store record index.** The card names "record 2" as Run B. That jsonl
  holds **four** `doc-sync-scan` dispatches, not three — the first is an
  unrelated `BUG-055` scan. The card's numbering counts only the three that embed
  the function body, so Run B is the **third** dispatch in the file. The
  identification is unambiguous either way: Run B is the only one carrying both
  the `for line in $SLUG_TABLE` loop and the all-ASCII early return.
- **Fixture-1 warm read-set is commit-derived, not transcript-derived.** The card
  specifies transcript-sourced reconstruction. `d3161f3`'s authoring session is
  not available (`DEBT-058` recorded that at the time). `parts/f1-intent.md` is
  built from the commit message, the resolved card's own Amendment, and the
  commit's file set — every claim in it is a fact the authoring gateway
  demonstrably held. It names no doc the gateway did not touch, which keeps it
  from becoming a steer toward the key.
- **One word cut from fixture 2's task line.** The recorded prompt reads "Judge
  `docs/overview.md` and `docs/techstack.md` **cold** against the above". The
  task line is shared byte-for-byte across arms, and "cold" inside the warm arm
  would contaminate the container variable. Dropped; the framing header carries
  cold vs warm instead.
- **Fixture-2 helper comment.** `parts/f2-runB-doc-links.patch` carries a short
  header comment above `slug_gap_hint` that the Run-B dispatch prompt does not
  quote (it quotes the function body only). The body itself, early return
  included, is verbatim. The comment is not in any arm's scan scope.
