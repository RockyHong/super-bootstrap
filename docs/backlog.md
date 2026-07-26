# Backlog

New rows route through `/super-bootstrap:log` — one funnel for classification, dedup, and ID assignment. Bugs, debt, design gaps, and unverified feature ideas all land here as rows; whether each is real or worth doing is decided at `/super-bootstrap:todo` triage on pickup, not at capture.

**When a card is owed:** only for work that exits the current flow **incomplete** — deferred or dropped. Work completed in-flow, whoever directed it, carries no card debt. The trigger is completion-state (observable), not worth (triage's call).

**Row deletion:** the resolving session — via `/super-bootstrap:commit` doc-sync, or manually on resolve. Direct `git commit` skips the sweep; clean up stale rows when noticed.

**Three categories** distinguished by ID prefix:

- **`BUG-###`** — broken behavior. Surface symptom may hide deeper cause.
- **`DEBT-###`** — working but rotting (test fixture rot, stale dep, cleanup owed).
- **`GAP-###`** — design gap or unverified capability idea, never properly specced. Forward feature ideas land here; triage decides drop / spec.

No phase prescription per category — when an item rolls into a session, triage decides how much ceremony the work earns. Surface "clear fix" can become design work after evidence; pre-routing biases that judgment.

**ID high-water mark:** `BUG-019` · `DEBT-035` · `GAP-043` — last consumed ID per category. Next ID = max+1 from this line, bumped in the same write. Resolved rows are deleted but their IDs stay consumed (history = `git log --grep="<id>"`); never re-derive IDs from open rows.

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

### GAP-043 — The runway declares no process-harness posture, so a bootstrapped repo runs bare without saying so

**Logged:** 2026-07-26 · **Source:** `.review/mattpocock-adapt-report.md` triage (2026-07-26)
**Problem:** De-routing unpinned `superpowers` from `harness-bootstrap` and delocked it in `resolve-plugins`. The slot is not unnamed — `resolve-plugins` Phase 4 declares a process harness "an ordinary adaptive pick here — proposable, droppable" (`SKILL.md:169`), and `docs/techstack.md` states no process harness is a dependency. What is missing is a *posture*: nothing surfaces the slot proactively, and `docs/specs/harness-architecture.md` §6 marks the harness swap (change B) open without stating what holds in the interim. So a repo bootstrapped today runs with no process harness behind its one-line disciplines, and nothing tells the operator whether that is a default or a decision.
**Area:** `plugins/super-bootstrap/skills/resolve-plugins/SKILL.md`; `docs/specs/harness-architecture.md` §6
**Prior:** Two shapes — (a) `resolve-plugins` recommends a process harness at setup time per the §4 setup-time-composition seam, needing change B resolved or a non-committal "if you use a process harness, install it here"; or (b) the runway ships intentionally bare and says so, positioning a process harness as an operator choice. Decision lands in spec §6 or `docs/decisions.md`; `resolve-plugins` changes only under shape (a). GAP-042's `CODING_STANDARDS.md` closure depends on this posture — a seeded standards file has no live reader in a bare runway.

### DEBT-035 — triage.md § Investigation ships doctrine bullets not yet tested for vacate under the external-coverage claim

**Logged:** 2026-07-26 · **Source:** `.review/mattpocock-adapt-report.md` triage (2026-07-26)
**Problem:** `plugins/super-bootstrap/agents/triage.md` § Investigation ships evidence-discipline bullets. The dissolve table (`docs/specs/harness-architecture.md` §3 triage lane row) recorded this row as "landed — doctrine clause restated inline, naming no harness", but that landing restated prose rather than testing whether the bullets are ours to carry. If an external set's investigation skill covers the discipline, the bullets vacate and what remains is the container: card → read-only verdict artifact → `{ID}-scope.md` / `{ID}-notes.md`. Coverage claim is grade B, gated on GAP-041.
**Area:** `plugins/super-bootstrap/agents/triage.md` § Investigation; `docs/specs/harness-architecture.md` §3 dissolve table (triage lane row)
**Prior:** Judge per bullet, not as a block. After GAP-041 raises the coverage claim to grade A: bullets it covers → vacate; bullets with no counterpart → keep. Container prose stays ours regardless. Sibling of DEBT-032 (scopes to CLAUDE.md § The envelope). Blocked on GAP-041.

### DEBT-034 — The backlog's write-once claim rule has no stated path for a card whose premise is falsified

**Logged:** 2026-07-26 · **Source:** cold `audit-harness-edits` probe on the DEBT-027 re-aim diff (finding 1)
**Problem:** The header states "The claim is write-once — captured at the richest-context moment, read cold by later sessions", with no exception. Two disposals exist in practice and neither is written down: overwrite the fields in place (what the DEBT-027 re-aim did — violates the letter of the rule) or delete the row and re-log under a fresh ID (honors it, but burns the ID that specs, sibling cards, and session carries already reference). The rule's stated purpose is protecting the original grounding from lossy later paraphrase; a claim disproven by evidence is a different case it does not contemplate, and leaving the falsified text leading is the failure the pickup-grounding fork in `docs/decisions.md` describes.
**Area:** `docs/backlog.md` header (§ Row shape / write-once paragraph); `plugins/super-bootstrap/skills/harness-bootstrap/assets/backlog.md` (the shipped skeleton carrying the same rule)
**Prior:** Name the falsification case in the header and pick one disposal. Likely shape: the claim stays write-once against *paraphrase*, and a falsified premise is superseded in place with a mandatory pointer to where the closed direction is archived (`docs/decisions.md`) — which is what the re-aim did ad hoc. Deleting and re-logging is the alternative but breaks stable-ID references, which the header itself calls the point of an ID. Skeleton mirror rides the same edit (`repo-boundary.md` sync direction).

### DEBT-033 — The help and bootstrap lanes still route to foreign pipeline commands that resolve to nothing

**Logged:** 2026-07-26 · **Source:** widened spec §4 grep sweep during the DEBT-027 re-aim — the old `brainstorming|writing-plans` pattern was blind to the slash-command spellings
**Problem:** Two sites outside the todo lane still name foreign pipeline entries. `agents/help.md:40` maps the `pipeline` category from the keyword exemplars `brainstorm, write-plan, execute-plan` — in a de-routed repo no shipped skill carries those tags, so the row matches nothing. `skills/super-bootstrap/SKILL.md:42` and `:52` route overview resolution "via brainstorm": `:42` is the observation text seeded through the capture funnel into the **consumer repo's own backlog**, so the foreign routing hint propagates into every bootstrapped repo's card text and outlives the cut there. Neither site is owned by an existing card — `DEBT-028` owns drain's phase-loop dispatch, `DEBT-026` owns the folder shape.
**Area:** `plugins/super-bootstrap/agents/help.md` § Step 3; `plugins/super-bootstrap/skills/super-bootstrap/SKILL.md` § greenfield seeding + § Resolve gate
**Prior:** Same vocabulary-residue class as the todo-lane rename shipped alongside this card — Wave 1 restated cluster 2 as "settle the design with the user before building", and the lane's replacements should name a discipline or the repo's own door (`/super-bootstrap:log`), never a foreign command. The `:42` seeded-card-text site is the sharper half: it writes into repos this repo does not control.

### DEBT-032 — De-routed ambient laws are one-liners where the cut removed a full-body fire-moment surface

**Logged:** 2026-07-26 · **Source:** cold `audit-harness-edits` probe on the Wave 1 diff (finding 9)
**Problem:** § The envelope's ambient laws previously named superpowers skills, each of which loaded a full body at its fire moment. The de-routed replacement keeps a one-line recognition signal ambient and gives the body no home — the probe cites the harness-authoring rule that compressing what should fire every turn "trades ammo for noise reduction — wrong trade." `Verify before claiming` arguably compresses losslessly; `Review received, not absorbed` does not — the discipline it replaces carries named anti-patterns that one line cannot hold. The `.claude/rules/` layer is not the answer (a `paths:` rule fires on file read, not on intent — `docs/specs/harness-architecture.md` §5, and the direction is closed in `docs/decisions.md`), so the open question is whether the repo authors its own discipline bodies and what points at them.
**Area:** Root `CLAUDE.md` § The envelope; `plugins/super-bootstrap/skills/harness-bootstrap/assets/claude-md-skeleton.md` § The envelope
**Prior:** Judge per law, not as a block — a one-liner that is the whole rule needs no body. Where a body is owed, the socket pattern § Coding Principles now uses (ambient line names the standard, a repo-declared file holds it) is the shape already in the harness; the fire-moment reader is the ambient line, not a rule glob.

### DEBT-030 — /log dispatch costs ~30k tokens per row, and the "all rows route through log" contract has no transcription exception

**Logged:** 2026-07-25 · **Source:** live session — three `/log` dispatches measured while carding the de-routing work
**Problem:** Each `/super-bootstrap:log` invocation dispatches the Sonnet `log` subagent to classify + dedup + write. Measured this session: 23.3k / 35.3k tokens for batches of 1 and 9 entries respectively — cost is near-flat in entry count, so a single-row capture pays nearly the same as a nine-row batch. DEBT-022 records the same disproportion for `todo` but is scoped to that agent only; nothing covers `log`. Separately, `CLAUDE.md` § log states all new rows route through the funnel with no stated exception, while the device-level dispatch doctrine carves out transcription (content already in hand, zero propagation closure) as inline work — GAP-041 was written inline under that carve-out, so the two contracts currently disagree.
**Area:** `plugins/super-bootstrap/agents/log.md`; `plugins/super-bootstrap/skills/log/SKILL.md`; root `CLAUDE.md` § log routing statement
**Prior:** Two facets, possibly one fix: right-size the classify+write pass to entry count, and decide whether the funnel admits a transcription exception. The contract half is a harness-doctrine call — likely wants brainstorming adjudication alongside the de-routing overhaul rather than a unilateral edit.

### GAP-041 — Read mattpocock/skills for its real dispatch posture before trusting our tier-pinned-agent pattern

**Logged:** 2026-07-25 · **Source:** de-routing architecture review (`docs/specs/harness-architecture.md` §7 q3)
**Problem:** Our pattern pins a model tier on every agent and dispatches for attention offload. mattpocock's set reads differently — `code-review` runs two axes as parallel `general-purpose` sub-agents with no tier pinned, and the stated reason is isolation ("reports remain separate to prevent one axis masking the other"), not offload. Whether that generalizes to a "session as atomic runner" stance, or is one isolation-specific exception inside an otherwise orchestrating session, is unknown — every claim about his dispatch posture so far is grade B, derived from summaries rather than his source. The answer bears on whether our own tier-pinning is sound or cargo.
**Area:** `plugins/super-bootstrap/agents/*.md` (tier pins); read surface = `mattpocock/skills` repo, esp. `skills/engineering/{code-review,implement,research,wayfinder}/` + `skills/productivity/writing-great-skills/`
**Prior:** Read his repo properly — grade-A text, not fetch summaries. `writing-great-skills` is the likeliest home for a stated dispatch doctrine.

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

### DEBT-028 — Convert drain's stage machine from hardcoded superpowers phases to interface-driven dispatch

**Logged:** 2026-07-25 · **Source:** de-routing architecture review (`docs/specs/harness-architecture.md`)
**Problem:** `skills/drain/SKILL.md` § Invariants hardcodes the stage-resume chain `raw→triage, triaged→plan, spec→plan, plan→execute, review→review`; `assets/phase-loop.md` hardcodes phase prompts naming superpowers skills. Stage names are superpowers' phases — half-dead once de-routing lands. drain should dispatch whatever discipline entry the repo declares, without naming specific skills.
**Area:** `plugins/super-bootstrap/skills/drain/SKILL.md` § Invariants; `plugins/super-bootstrap/skills/drain/assets/phase-loop.md`
**Prior:** spec §3 (drain listed half-dead) + §4 (seam mechanism — dispatch to declared entry, not named skills).

### DEBT-027 — The cloud-safe derivation content-reads every row's plan body and linked spec on every board render

**Logged:** 2026-07-25 · **Source:** de-routing architecture review (`docs/specs/harness-architecture.md`); **re-aimed 2026-07-26** — the original de-routing framing was falsified against the code and is closed in `docs/decisions.md`
**Problem:** `shared/classify-actionable.md` § Cloud-safe criterion derives each row's `intent` by grepping the plan file body for device keywords, matching path arms, and reading the linked spec's § Success Criteria — a per-row content read that runs on every `/super-bootstrap:todo` invocation and every `drain` scan, whatever the working-set size. It is the phase DEBT-022 names as the cost driver (~34.3k tokens / ~226 s for 4 rows). Open question: does the derivation earn that cost? `drain` is its only hard consumer (`eligibility.md` Cloud-gate fallback), `todo`'s sub-verb modes are the soft one, and a repo with the scale module wired bypasses it entirely via the venue map.
**Area:** `plugins/super-bootstrap/shared/classify-actionable.md` § Cloud-safe criterion; `agents/todo.md` §1; `plugins/super-bootstrap/skills/drain/assets/eligibility.md`
**Prior:** Sibling of DEBT-022 — that one asks whether the pass scales to row count, this one whether one phase of it earns its keep at all; triage may collapse them. Cheapest shape to test: a verb-map-only intent (drop the per-row body reads, keep the verb→intent table's locked rows, default the derived ones) and check whether any real board verdict changes. **Any retirement must replace drain's admission predicate in the same change** — without the venue map, `intent == Cloud` is drain's whole gate. Not a de-routing card: the axis names no foreign harness (`docs/decisions.md`).

### DEBT-026 — Retire or rename `docs/superpowers/specs|plans/` path shape and update all consumers

**Logged:** 2026-07-25 · **Source:** de-routing architecture review (`docs/specs/harness-architecture.md`)
**Problem:** The `docs/superpowers/` directory layout is superpowers' artifact shape (temporal specs/plans from brainstorming and writing-plans); it carries a foreign namespace once routing is cut. Decision needed: drop the slot entirely (per-feature work orders delegate to whatever process harness the repo installs) or rename to a harness-neutral path. Consumers: `agents/todo.md`, `agents/triage.md`, `skills/drain/SKILL.md`, `shared/classify-actionable.md`, `skills/harness-bootstrap` (creates the dirs), root `CLAUDE.md` § Planning.
**Area:** `docs/superpowers/` dir; `agents/todo.md`; `agents/triage.md`; `plugins/super-bootstrap/skills/drain/SKILL.md`; `plugins/super-bootstrap/shared/classify-actionable.md`; `plugins/super-bootstrap/skills/harness-bootstrap/`; root `CLAUDE.md` § Planning
**Prior:** spec §2; mattpocock's `to-tickets` occupies the per-feature work order slot at `.scratch/<feature>/issues/NN-slug.md`. Carries its own downstream migration: adopt mode has no folder-removal path (spec §8), so retiring these dirs orphans them in every bootstrapped repo — unlike the other cut sites, which adopt mode migrates.

### BUG-019 — `todo full` scaffold renders empty table in spec-free repos, contradicting "every row, flat" contract

**Logged:** 2026-07-25 · **Source:** live session running `/super-bootstrap:todo all` on super-bootstrap source repo (2026-07-25, 3 open DEBT rows)
**Problem:** `SKILL.md` Arguments table documents `full` as "every row (need-me + drainable), ungrouped, ranked"; plugin.json description says "flat everything". But `assets/scaffolds.md` § Full table only accepts `specs/{date}-{slug}.md` and `plans/{date}-{slug}.md` rows — backlog rows are collapsed to a single count line ("Backlog: N BUG, M DEBT, K GAP open"). In a repo with no spec/plan files the rendered output is an empty table plus the count line — less informative than the default need-me board, which surfaces individual backlog rows as `Triage: {ID}` lines. Observed render on 2026-07-25: table header only, no data rows, then "Backlog: 0 BUG, 3 DEBT, 0 GAP open".
**Area:** `plugins/super-bootstrap/skills/todo/SKILL.md` Arguments table · `plugins/super-bootstrap/skills/todo/assets/scaffolds.md` § Full · `plugins/super-bootstrap/.claude-plugin/plugin.json` todo description
**Prior:** Either (a) make the Full scaffold render each backlog row as a table row (one row per open ID, same table or separate), or (b) align SKILL.md / plugin.json wording to match the scaffold's actual output shape.

### GAP-037 — `todo` sub-verb has no fallback contract for unlisted argument values

**Logged:** 2026-07-25 · **Source:** incidental observation alongside BUG-019 (same live session)
**Problem:** `all` is not listed in SKILL.md's Arguments table; the gateway inferred a mapping to `full` by semantic proximity. No fallback behavior is documented — the contract is silent on what happens when an unrecognized sub-verb is passed (fail / default to need-me / map to nearest match). Any unlisted value silently falls through to model-discretion resolution.
**Area:** `plugins/super-bootstrap/skills/todo/SKILL.md` Arguments table
**Prior:** Add a fallback contract to the Arguments table: unrecognized sub-verb → default to need-me board (or explicit error), so behavior is specified rather than inferred.

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

### DEBT-021 — log agent ID allocation has no recovery contract for concurrent session collision

**Logged:** 2026-07-25 · **Source:** GitHub issue #26 (repo owner, absorbed via /pull-issue)
**Problem:** `agents/log.md` step 4 requires bumping the ID high-water mark in the same write, but specifies no recovery when two concurrent sessions both read the header before either writes — both compute the same `max+1` and allocate the same ID. The Edit tool's `old_string` mismatch catches the collision (stale-state detection), but what the subagent does after that failure is model discretion, not a spec contract. Same exposure on `PARK-000` high-water in `docs/parked.md`. Cost of a slip is higher than volatile state — the backlog is a durable queue, not something a fresh session regenerates.
**Area:** `agents/log.md` step 4; `docs/backlog.md` ID high-water mark line; `docs/parked.md` `PARK-000` line
**Prior:** Add explicit recovery to step 4: on Edit failure (HWM mismatch), re-read the header and recompute the ID before retrying.
