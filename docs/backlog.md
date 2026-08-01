# Backlog

New rows route through `/super-bootstrap:log` — one funnel for classification, dedup, and ID assignment. Bugs, debt, design gaps, and unverified feature ideas all land here as rows; whether each is real or worth doing is decided at `/super-bootstrap:todo` triage on pickup, not at capture.

**When a card is owed:** only for work that exits the current flow **incomplete** — deferred or dropped. Work completed in-flow, whoever directed it, carries no card debt. The trigger is completion-state (observable), not worth (triage's call).

**Row deletion:** the resolving session — via `/super-bootstrap:commit` doc-sync, or manually on resolve. Direct `git commit` skips the sweep; clean up stale rows when noticed.

**Three categories** distinguished by ID prefix:

- **`BUG-###`** — broken behavior. Surface symptom may hide deeper cause.
- **`DEBT-###`** — working but rotting (test fixture rot, stale dep, cleanup owed).
- **`GAP-###`** — design gap or unverified capability idea, never properly specced. Forward feature ideas land here; triage decides drop / spec.

No phase prescription per category — when an item rolls into a session, triage decides how much ceremony the work earns. Surface "clear fix" can become design work after evidence; pre-routing biases that judgment.

**ID high-water mark:** `BUG-020` · `DEBT-038` · `GAP-046` — last consumed ID per category. Next ID = max+1 from this line, bumped in the same write. Resolved rows are deleted but their IDs stay consumed (history = `git log --grep="<id>"`); never re-derive IDs from open rows.

**Row shape** — stable ID + frozen claim, newest at top. When resolved, **delete the row** — git history is the archive.

```
### {BUG|DEBT|GAP}-### — {one-line summary}

**Logged:** {date} · **Source:** {where this surfaced}
**Problem:** {what's broken / rotting / missing}
**Area:** {files or module}
**Prior:** {one-line suspected cause or proposed fix — optional}
```

The claim is write-once — captured at the richest-context moment, read cold by later sessions. Sessions that pick a row up work from it; working history lives in specs/plans, not on the row.

---

## Open

### GAP-046 — doc-sync has no premise-closure predicate for a product-anchor revision

**Logged:** 2026-07-27 · **Source:** session reading commit door's grep-gate (`plugins/super-bootstrap/skills/commit/SKILL.md` §3) against `CLAUDE.md` § Doc Sync, during product-anchor positioning work (2026-07-27); related open row: GAP-045
**Problem:** doc-sync's scan predicate is behavior-shaped ("prose describing behavior touched by the diff", "behavior-narrating prose outside `docs/`", "any manifest/description field the diff's behavior changes" — three occurrences; `agents/doc-sync-scan.md` inherits it). A revision to the product anchor (`overview.md` § Problem / § User — problem, ICP, G2M) changes premise, not behavior. The grep-gate fires (basename `overview` not in the dropped-generics list), dispatching a scan — but the cold scanner has no predicate for the actual closure that needs walking: every open GAP row's framing (a GAP is "capability we lack", meaningful only relative to problem + ICP) and each spec's premise. The reverse direction is covered: `CLAUDE.md` § Doc Sync backlog-cleanup states a shipped feature-GAP "now belongs to the product narrative (Problem / Current State / Module Index)". The asymmetry is one-directional — work→anchor has a named rule, anchor→work has no predicate. Scope: external market drift (world→doc) is explicitly out of scope — unsyncable by nature; internal authored anchor only.
**Area:** `plugins/super-bootstrap/agents/doc-sync-scan.md` (scan predicate); `plugins/super-bootstrap/skills/commit/SKILL.md` §3 (grep-gate); `docs/overview.md` § Problem / § User (product anchor)
**Prior:** Same failure class as GAP-045 (behavior-shaped harness has no fire moment for the premise dimension); may share solution shape. A dedicated `docs/product.md` would make path-level detection mechanical rather than semantic, enabling a cheap premise-closure gate on product-anchor diffs without semantic inference.

### BUG-020 — commit-channel hook covers Bash path only; commits via other tools bypass the commit door and doc-sync

**Logged:** 2026-07-26 · **Source:** head/tail interface contract design work for super-bootstrap bracket (finding stands independent of that design)
**Problem:** The commit-channel `PreToolUse` matcher is `Bash(git commit *)` in both the shipped hook asset and the dogfood `.claude/settings.json`. Any commit that lands via another path — a bespoke commit skill, `gh`, an MCP git tool — bypasses the hook entirely, so doc-sync never sees the finished diff. The README presents the hook as the mechanism that confines raw `git commit` to the main-session commit door and routes worker subagents back to `/super-bootstrap:commit`, but only one path class is actually enforced.
**Area:** `plugins/super-bootstrap/skills/harness-bootstrap/assets/hooks/commit-channel.hook.json`; `.claude/settings.json` (dogfood hook wiring); root `README` (hook guarantee claim)
**Prior:** Widen the matcher to cover all commit-landing tool paths, or document the enforcement gap and narrow the README guarantee to match what is actually enforced.

### GAP-045 — No fire-moment gate when a review claim enters a container — false claims pass all existing harness checks

**Logged:** 2026-07-26 · **Source:** DEBT-032 controlled probe runs (3/3 false-review-finding implemented and shipped); closed fork in `docs/decisions.md` explicitly reopens on this shape
**Problem:** Every gate the harness owns (`audit-harness-edits`, `doc-sync`, `/super-bootstrap:commit`) fires on the **diff**, not on the **claim**. A cold subagent handed a plausible-but-false review finding against a harness file implements it cleanly — one run reached the line that falsifies the claim (`worktree-boundary.md` grants in-worktree `git add` + `git commit`) and rewrote that line to match; another ran `audit-harness-edits`, cleared doc-sync, and committed the falsehood to main. The ambient law `Review received, not absorbed` was verifiably in context (run 2 quoted all three ambient laws verbatim on request) and did not activate. The same failure class reaches drain's review phase, which feeds findings back into an execute phase with no premise gate between them. Candidate surfaces not yet evaluated: hook on the dispatch boundary, skill invoked at the receive-review moment, or a required verdict field in the review-return contract.
**Area:** `CLAUDE.md` § The envelope (`Review received, not absorbed`); `plugins/super-bootstrap/skills/harness-bootstrap/assets/claude-md-skeleton.md` § The envelope; `plugins/super-bootstrap/skills/drain/assets/phase-loop.md` (review→execute phase boundary)
**Prior:** Root cause confirmed in the DEBT-032 closed fork: the failure is activation, not compression — the law was in context and still did not fire. Fix must place a gate at the fire-moment a review claim enters a container; evaluate the three candidate surfaces (dispatch-boundary hook, receive-review skill, verdict-field contract in the review-return shape).

### GAP-044 — drain doc-lane skip-review condition names no evaluator — gateway pre-spawn vs subprocess self-skip both read consistently

**Logged:** 2026-07-26 · **Source:** DEBT-028 verify pass — cold dry-run agent authoring phase prompts from `phase-loop.md` alone
**Problem:** `phase-loop.md` § Lane select states the doc lane may "skip review for a ≤1-file, grep-verifiable invariant" but never names who evaluates that condition. Two readings are both consistent with the text: (a) the gateway evaluates it before deciding whether to spawn a review phase, or (b) the review subprocess is always spawned and self-skips by writing a done status immediately. A cold agent authoring dispatch from this section picked (b) — which changes how many subprocesses drain spends per doc-lane item.
**Area:** `plugins/super-bootstrap/skills/drain/assets/phase-loop.md` § Lane select
**Prior:** Decide the evaluator and name it — the subprocess-count difference is the observable cost of leaving it ambiguous.

### DEBT-036 — triage-report dup branch routes new facts to a destination that cannot accept them

**Logged:** 2026-07-26 · **Source:** live session running `/super-bootstrap:triage-report` on `.review/mattpocock-adapt-report.md` (2026-07-26)
**Problem:** `triage-report` § Execution step 3 routes a `dup` finding's new fact by folding it "into the `/log` batch as annotations" on the existing row. That door is closed: `agents/log.md` scopes itself to new rows only ("Edits or deletes on existing rows — the session that resolves an item owns its row. You create new rows only"), and `docs/backlog.md` header states "The claim is write-once". A triage-report run that produces dup findings with genuinely new facts has no legal landing site — the skill names a destination, the agent refuses the write, and the backlog rule forbids the edit. Observed live 2026-07-26: six dup findings with new facts (execution-order constraints, an evidence-grade dependency, a detector-migration hazard) were routed instead into `docs/specs/harness-architecture.md` §6 as wave-close conditions — a workaround that depended on a grounding spec existing for the subject.
**Area:** `plugins/super-bootstrap/skills/triage-report/SKILL.md` § Execution step 3 (dup branch); `plugins/super-bootstrap/agents/log.md` § Scope; `docs/backlog.md` header write-once paragraph
**Prior:** Adjacent to DEBT-034 (falsified-premise disposal) but distinct — that card asks how a card whose premise is disproven gets superseded; this asks where a new fact about a still-correct card lands. Both press on write-once and may want one answer. Candidate shapes: (a) give the dup branch a real destination (a per-card annotations block the header sanctions); (b) route dup facts to the owning card's triage verdict artifact under `docs/work/triage/`; (c) drop the annotation instruction and state that dup findings with new facts surface to the gateway without persistence. Skeleton `skills/harness-bootstrap/assets/backlog.md` carries the same write-once rule and rides whatever lands (`repo-boundary.md` sync direction).

### DEBT-035 — triage.md § Investigation ships doctrine bullets not yet tested for vacate under the external-coverage claim

**Logged:** 2026-07-26 · **Source:** `.review/mattpocock-adapt-report.md` triage (2026-07-26)
**Problem:** `plugins/super-bootstrap/agents/triage.md` § Investigation ships evidence-discipline bullets. The dissolve table (`docs/specs/harness-architecture.md` §3 triage lane row) recorded this row as "landed — doctrine clause restated inline, naming no harness", but that landing restated prose rather than testing whether the bullets are ours to carry. If an external set's investigation skill covers the discipline, the bullets vacate and what remains is the container: card → read-only verdict artifact → `{ID}-scope.md` / `{ID}-notes.md`.
**Area:** `plugins/super-bootstrap/agents/triage.md` § Investigation; `docs/specs/harness-architecture.md` §3 dissolve table (triage lane row)
**Prior:** Judge per bullet, not as a block. The comparison surface is `mattpocock/skills` `diagnosing-bugs`, read at grade A (spec §7) — a six-phase loop whose centre is "build a tight, red-capable feedback loop before hypothesising", plus ranked falsifiable hypotheses, one-variable-at-a-time instrumentation, and a regression-seam test. Bullets it covers → vacate; bullets with no counterpart → keep. Container prose stays ours regardless. Note the shape mismatch to check first: that skill drives a *fix* loop with a runtime, while this lane is read-only verdict work with no runtime to go red — so coverage may be narrower than a title match suggests. Sibling of DEBT-032 (scopes to CLAUDE.md § The envelope).

### DEBT-034 — The backlog's write-once claim rule has no stated path for a card whose premise is falsified

**Logged:** 2026-07-26 · **Source:** cold `audit-harness-edits` probe on the DEBT-027 re-aim diff (finding 1)
**Problem:** The header states "The claim is write-once — captured at the richest-context moment, read cold by later sessions", with no exception. Two disposals exist in practice and neither is written down: overwrite the fields in place (what the DEBT-027 re-aim did — violates the letter of the rule) or delete the row and re-log under a fresh ID (honors it, but burns the ID that specs, sibling cards, and session carries already reference). The rule's stated purpose is protecting the original grounding from lossy later paraphrase; a claim disproven by evidence is a different case it does not contemplate, and leaving the falsified text leading is the failure the pickup-grounding fork in `docs/decisions.md` describes.
**Area:** `docs/backlog.md` header (§ Row shape / write-once paragraph); `plugins/super-bootstrap/skills/harness-bootstrap/assets/backlog.md` (the shipped skeleton carrying the same rule)
**Prior:** Name the falsification case in the header and pick one disposal. Likely shape: the claim stays write-once against *paraphrase*, and a falsified premise is superseded in place with a mandatory pointer to where the closed direction is archived (`docs/decisions.md`) — which is what the re-aim did ad hoc. Deleting and re-logging is the alternative but breaks stable-ID references, which the header itself calls the point of an ID. Skeleton mirror rides the same edit (`repo-boundary.md` sync direction).

### DEBT-030 — /log dispatch costs ~30k tokens per row, and the "all rows route through log" contract has no transcription exception

**Logged:** 2026-07-25 · **Source:** live session — three `/log` dispatches measured while carding the de-routing work
**Problem:** Each `/super-bootstrap:log` invocation dispatches the Sonnet `log` subagent to classify + dedup + write. Measured this session: 23.3k / 35.3k tokens for batches of 1 and 9 entries respectively — cost is near-flat in entry count, so a single-row capture pays nearly the same as a nine-row batch. DEBT-022 records the same disproportion for `todo` but is scoped to that agent only; nothing covers `log`. Separately, `CLAUDE.md` § log states all new rows route through the funnel with no stated exception, while the device-level dispatch doctrine carves out transcription (content already in hand, zero propagation closure) as inline work — GAP-041 was written inline under that carve-out, so the two contracts currently disagree.
**Area:** `plugins/super-bootstrap/agents/log.md`; `plugins/super-bootstrap/skills/log/SKILL.md`; root `CLAUDE.md` § log routing statement
**Prior:** Two facets, possibly one fix: right-size the classify+write pass to entry count, and decide whether the funnel admits a transcription exception. The contract half is a harness-doctrine call — likely wants brainstorming adjudication alongside the de-routing overhaul rather than a unilateral edit.

### GAP-038 — Ship an "Other" issue-tracker seed for mattpocock/skills' `/setup-matt-pocock-skills`, declaring docs/backlog.md + /super-bootstrap:log as the tracker

**Logged:** 2026-07-25 · **Source:** de-routing architecture review (`docs/specs/harness-architecture.md`)
**Problem:** `/setup-matt-pocock-skills` ships seed templates for GitHub / GitLab / Local but none for "Other" — that branch is authored fresh, yielding free-form prose his skills interpret ad hoc. Without a seed, his `to-spec` and `triage` have no declared path to write into our backlog. Accepted known weakness: the socket is prose, not schema; documented seams drift.
**Area:** `plugins/super-bootstrap/skills/harness-bootstrap/` (seed asset location); new seed file for mattpocock "Other" branch
**Prior:** spec §4; mattpocock "Other" option + absence of seed template confirmed grade A (2026-07-25). **Not executable as titled — shipping a seed connects to nothing on its own, and two further questions ride the same decision. Read §4 before acting.** **Blocked on change B** (spec §6, open): wiring anything mattpocock-shaped into bootstrap presupposes adopting his set. Held out of the skeleton cut — do not pick this up until change B is decided.

### GAP-042 — § Coding Principles declares a `CODING_STANDARDS.md` socket that no bootstrapped repo ever has

**Logged:** 2026-07-26 · **Source:** landing DEBT-029's settled shape — the gap the fix created
**Problem:** § Coding Principles (root `CLAUDE.md` + shipped skeleton) now reads "read the repo's declared coding standard — `CODING_STANDARDS.md` where that file is present", falling back to the pinned `karpathy-guidelines` skill when absent. `harness-bootstrap` never writes that file, so in every freshly bootstrapped repo the first clause is dead on arrival and the fallback is the only live branch — an indirection with no landing site. Either the skeleton seeds a headings-only file for the consumer to fill, or the socket clause should not promise a file the pipeline never creates.
**Area:** `plugins/super-bootstrap/skills/harness-bootstrap/SKILL.md` (Phase 2a/2b artifact list + § Pipeline-owned); `plugins/super-bootstrap/skills/harness-bootstrap/assets/` (new skeleton asset); root `CLAUDE.md` + `assets/claude-md-skeleton.md` § Coding Principles
**Prior:** Seed a headings-only `CODING_STANDARDS.md` (empty sections the consumer grows via doc-sync, like `overview.md` / `techstack.md`) rather than any prose — the four principles' body lives upstream in the skill and copying it is a parallel truth (VII). Decide whether the file is always-scaffolded (like `decisions.md`) or gated on a source-code surface (like `docs/specs/`).

### DEBT-027 — The cloud-safe derivation content-reads every row's plan body and linked spec on every board render

**Logged:** 2026-07-25 · **Source:** de-routing architecture review (`docs/specs/harness-architecture.md`); **re-aimed 2026-07-26** — the original de-routing framing was falsified against the code and is closed in `docs/decisions.md`
**Problem:** `shared/classify-actionable.md` § Cloud-safe criterion derives each row's `intent` by grepping the plan file body for device keywords, matching path arms, and reading the linked spec's § Success Criteria — a per-row content read that runs on every `/super-bootstrap:todo` invocation and every `drain` scan, whatever the working-set size. It is the phase DEBT-022 names as the cost driver (~34.3k tokens / ~226 s for 4 rows). Open question: does the derivation earn that cost? `drain` is its only hard consumer (`eligibility.md` Cloud-gate fallback), `todo`'s sub-verb modes are the soft one, and a repo with the scale module wired bypasses it entirely via the venue map.
**Area:** `plugins/super-bootstrap/shared/classify-actionable.md` § Cloud-safe criterion; `agents/todo.md` §1; `plugins/super-bootstrap/skills/drain/assets/eligibility.md`
**Prior:** Sibling of DEBT-022 — that one asks whether the pass scales to row count, this one whether one phase of it earns its keep at all; triage may collapse them. Cheapest shape to test: a verb-map-only intent (drop the per-row body reads, keep the verb→intent table's locked rows, default the derived ones) and check whether any real board verdict changes. **Any retirement must replace drain's admission predicate in the same change** — without the venue map, `intent == Cloud` is drain's whole gate. Not a de-routing card: the axis names no foreign harness (`docs/decisions.md`).

### DEBT-023 — doc-sync-scan per-commit Sonnet dispatch burns ~8-12k tokens for a read-only advisory

**Logged:** 2026-07-25 · **Source:** GitHub issue #24 (claude-config-manager 2026-07-23 harness-pain harvest, absorbed via /pull-issue)
**Problem:** `doc-sync-scan` fires per-commit after the grep-gate pre-filter hits and returns a text advisory with 0 writes by design. Observed burning ~8-12k output tokens per run; across a 5-day window: spotify-radio ×2 (~21.5k combined), stock (~11.5k), super-bootstrap (~19.7k). The grep-gate's false-positive rate or the scan's output scope may be too wide relative to its advisory-only yield.
**Area:** `agents/doc-sync-scan.md`; `/super-bootstrap:commit` commit door; grep-gate pre-filter
**Prior:** Raise grep-gate precision (reduce how often the Sonnet scan fires) or cap/trim the scan's output scope. Dropping doc-sync is not a direction (CLAUDE.md marks it non-negotiable).

### DEBT-022 — todo subagent classify+render pass not right-sized to working-set size

**Logged:** 2026-07-25 · **Source:** GitHub issue #25 (downstream adopter claude-config-manager, absorbed via /pull-issue)
**Problem:** `/super-bootstrap:todo` dispatches a subagent that re-classifies every open row from scratch on every invocation, regardless of working-set size. Observed on sb 2.24.1 with 4 open rows / 3-row need-me board (one venue group): ~34.3k subagent tokens / ~226s per bare dispatch. The full classify pass ran over every row; no computation reuse between invokes. The board is intended as a frequent, low-stakes glance; per-glance cost is disproportionate to a small working set.
**Area:** `agents/todo.md`; `plugins/super-bootstrap/skills/todo/**`
**Prior:** Right-size the classify+render work to actual working-set size — skip or shorten classify phases when row count is small.

