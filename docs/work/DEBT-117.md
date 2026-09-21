# DEBT-117 — triage's "Batch = sequential dispatches" keys on time, not write set

**Logged:** 2026-09-21 · **Source:** GitHub issue [#72](https://github.com/RockyHong/super-bootstrap/issues/72) (super-bootstrap 2.51.1), pulled via `/pull-issue`
**Problem:** [`skills/triage/SKILL.md`](../../plugins/super-bootstrap/skills/triage/SKILL.md) § Rules asserts "**One card per dispatch.** Batch = sequential dispatches; verdicts stay per-card atomic." The stated rationale — per-card verdict atomicity — is already secured by "one card per dispatch": a triage dispatch's only write is an append to its own `docs/work/{ID}.md`, so N cards are N disjoint write sets that cannot interleave. The word *sequential* adds a constraint in time the rationale never asks for, leaving a session grounding a batch to choose between the letter and the reason. The cost is measured: three cards, one dispatch each, run concurrently — 309s / 351s / 390s, wall-clock ≈6.5 min; the same batch serialized is the sum, ≈17.5 min, 2.7×, scaling linearly with batch size. Nothing in the run signals that a session obeying the letter is paying it. Proposed shape (issue's own wording, not settled): key the rule on the write set — "A batch fans out concurrently — each dispatch's write set is its own card file, so verdicts stay per-card atomic" — or keep *sequential* and name what it protects so a reader can tell whether it binds them. Verification named by the reporter: dispatch triage concurrently on N cards carrying no Verdict block, confirm each card receives exactly one Verdict block, no card is written by more than one dispatch, and wall-clock tracks the slowest dispatch rather than the sum.
**Area:** `plugins/super-bootstrap/skills/triage/SKILL.md` § Rules (the one-card-per-dispatch line)
**Prior:** Suspected shape — the line compressed a write-set-disjointness guarantee into a temporal ordering when authored; no closed fork in [`decisions.md`](../decisions.md) defends the serialization.
**Test-feel:** doc-only
**Blast:** pkg

## Verdict — auto-fix · 2026-09-21

**Fix-shape:** systematic
**Probe-deps:** none
**Execution:** phased(skip: design-settling) — depth: direction is an existing codified rule applied to a new instance (two cited sources settle it), wording is authoring; closure: one shipped skill line + the `skill-authoring` RED floor + cluster-7 audit + `/release` propagation is not self-contained.

### Repro (pinned)

- The line under test, quoted from the card: "**One card per dispatch.** Batch = sequential dispatches; verdicts stay per-card atomic."
- Scenario: "a session grounding a batch to choose between the letter and the reason."
- Measured cost: "three cards, one dispatch each, run concurrently — 309s / 351s / 390s, wall-clock ≈6.5 min; the same batch serialized is the sum, ≈17.5 min, 2.7×, scaling linearly with batch size."
- Verification named by the reporter: "dispatch triage concurrently on N cards carrying no Verdict block, confirm each card receives exactly one Verdict block, no card is written by more than one dispatch, and wall-clock tracks the slowest dispatch rather than the sum."

### Root cause (verified)

Premise confirmed, and it grounds harder than the card claims — the letter is not merely unjustified, it is already contradicted by a shipped door in this plugin.

1. **Write-set disjointness holds by construction.** `plugins/super-bootstrap/agents/triage.md` frontmatter grants `tools: Read, Grep, Glob, Bash, Edit` — no `Write`; § Phase identity floors the door at "Your one write: append a `## Verdict …` block at the end of `docs/work/{ID}.md`. Everything else is read-only … Bash stays read-only". `skills/triage/SKILL.md` step 4 adds "The verdict artifact rides the session's normal envelope commit — no in-phase commit", so no dispatch touches the git index either. N dispatches on N distinct IDs therefore hold N disjoint single-file write sets. Nothing shared is mutated, so per-card atomicity is a property of the write set, not of arrival order — exactly as the card states.
2. **The shipped drain lane already runs triage concurrently.** `skills/drain/SKILL.md:21` enters each item's chain at its stage, `raw`→ground; `assets/phase-loop.md:53` names that ground phase's executor as `/super-bootstrap:triage`; `assets/parallel-worktrees.md:60` confirms the subprocess dispatches the triage subagent ("the triage phase spawns `/super-bootstrap:triage`, which dispatches a subagent"); `SKILL.md:80` dispatches each item via `Bash(run_in_background: true)` so subprocesses run concurrently. A drain wave containing two or more raw cards is therefore N concurrent triage dispatches, shipped. Read literally and unscoped, § Rules line 34 forbids what the repo's widest fan-out door does by design — the direct falsifying evidence against the temporal reading.
3. **The repo's own concurrency criterion is already the write-set criterion.** `skills/drain/assets/relations.md` admits a wave by file overlap, not by time — "Two items touching the same files can't safely run concurrently … So classify by file overlap"; `scopeFiles(a) ∩ scopeFiles(b)` empty → disjoint → admitted. `docs/specs/harness-architecture.md` § gate classification is the same rule one level up: a gate whose "N checks are independent" is `Parallelizable | Yes`, against elicitation-shaped gates where "question N+1 does not exist until answer N". Read-only per-card grounding is the independent-checks shape.
4. **What `sequential` does buy is ordering-arbitrary, not a guarantee.** The only ordering-sensitive read in the lane is § Aim + blast's "grep `docs/work/` for overlapping open cards" — a serialized run lets a later dispatch see an earlier card's appended verdict. But that judgment reads a sibling card's *claim* (its frozen origin block), not its verdict, and dispatch order is unspecified, so the extra information is luck rather than a contract. No deterministic property is lost by fan-out.
5. **The live conflict a reader hits.** The consumer-facing skeleton ships "Parallel within a phase, not across it — N build sub-goals or N doc surfaces fan out together" (`skills/harness-bootstrap/assets/claude-md-skeleton.md:57`, mirrored at root `CLAUDE.md:57`) beside this skill's "Batch = sequential dispatches". A cold session batching cards reads both and must pick — the cost the card names.

**Direction settled (not a user fork; cited, per verdict criterion 4):** take the card's first shape — re-key the rule on the write set and license the fan-out — because `docs/specs/harness-architecture.md` § gate classification and `skills/drain/assets/relations.md` already codify independence/file-overlap as the admission test, and drain ships the behavior. The second shape (keep *sequential*, name what it protects) is available only if something is protected; finding 4 shows nothing deterministic is, so it loses.

**Guard the new wording must carry (settled by the same spec, not left to the implementer):** the fan-out covers the read-only grounding dispatches only. The gateway's absorb protocol (`skills/triage/SKILL.md` step 3) climbs each `surface` verdict and may reach the user — an elicitation-shaped halt the same spec warns "the human cannot hold N of concurrently". Dispatches fan out; the climbs and any user decision stay serial at the gateway.

**Unverified in this lane (read-only, advisory):** the 309/351/390s telemetry is card-captured external observation and was not re-measured here — a re-run would be a live multi-dispatch. Its arithmetic is self-consistent (sum 1050s ≈ 17.5 min, max 390s ≈ 6.5 min, 2.7×) and the premise does not rest on the multiplier.

### Files (fix surface)

- `plugins/super-bootstrap/skills/triage/SKILL.md:34` — the edit. Sole live instance of the line in the repo; this repo owns `plugins/**` as source (`.claude/rules/repo-boundary.md`), so the fix lands here and reaches consumers via `/release`. The installed copy under `~/.claude/plugins/cache/super-bootstrap/…/2.51.1/` is the published/served copy — never edited directly.
- `bench/doc-sync/.fixtures/f1-d3161f3/plugins/super-bootstrap/skills/triage/SKILL.md:34` and `bench/doc-sync/.fixtures/f2-runB/…:34` — byte-frozen bench snapshots carrying the same line. **Do not edit**; a fixture edit invalidates the bench baseline.
- `docs/specs/harness-architecture.md` § gate classification table — cited authority for the fan-out direction; read-only, already correct.
- `plugins/super-bootstrap/skills/drain/assets/relations.md` — cited authority (file-overlap admission); read-only, already correct.
- `plugins/super-bootstrap/skills/drain/assets/parallel-worktrees.md:60`, `assets/phase-loop.md:53`, `drain/SKILL.md:21,80` — the shipped concurrent-triage path; read-only evidence, no change (drain needs no amendment once the triage line stops contradicting it).

### Doc Impact

none — confirmed unchanged after read. Three surfaces narrate triage's per-card scope and all survive the edit verbatim: `plugins/super-bootstrap/README.md:14` ("for one backlog card"), root `README.md:81` ("Every card pickup"), `docs/overview.md:58` (per-`{ID}` dispatch → Verdict append). Each states the per-dispatch scope, which the fix keeps; none asserts batch ordering. No `docs/decisions.md` row defends the serialization (checked), and no other open card overlaps (`BUG-064` = skeleton envelope/cluster-7 verify; `DEBT-116` = rot-scan frozen-provenance skip).

### Test Strategy: e2e

`.claude/rules/skill-authoring.md` fires on `plugins/*/skills/**` and classes this as behavior-shaping prose (a § Rules discipline a consuming agent obeys), not a mechanical edit — so the RED is owed, and the card's `Test-feel: doc-only` understates it. Two-arm micro-test, one scenario (a gateway handed N raw cards carrying no Verdict block): control = current line, arm = new wording. Pass = the arm fans the dispatches out in one block while the control serializes, plus the reporter's own machine-checkable assertions — each card receives exactly one Verdict block, no card is written by more than one dispatch, wall-clock tracks the slowest dispatch rather than the sum. No human eyeball needed. Post-edit verify is cluster 7 — `audit-harness-edits`.
