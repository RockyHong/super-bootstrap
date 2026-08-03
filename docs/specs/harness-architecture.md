# Harness Architecture — What super-bootstrap Owns, and Where the Seam Falls

**Scope.** This doc owns the concern map: which slots super-bootstrap occupies, which
it delegates, and the mechanism at the boundary. It is the grounding artifact for the
de-routing work — a cold reader should be able to act on the cards without
reconstructing the analysis.

Companion docs: [`docs/overview.md`](../overview.md) (product context),
[`docs/techstack.md`](../techstack.md) (stack + architecture rules),
[`docs/decisions.md`](../decisions.md) (closed forks),
[`docs/work/`](../work/README.md) (open cards).

---

## 1. The failure modes a harness can address

Derived from the three properties of attention as a finite resource, not from
observation. Each property yields one necessary failure mode; a fourth follows from
goal-holding, a fifth from the human being a finite actor too.

| Failure mode | Source | Dissolves as models improve? |
| --- | --- | --- |
| Attention dilution within a window (omission) | finite fuel | **Yes — largely has** |
| Anchor drift (motion outlives the goal) | goal-holding | **Yes — largely has** |
| State dies at context reset | volatility | **Never** |
| Footprint unowned (edit made, truth not propagated) | irreversibility | **Never** |
| Description cost of domain concepts | no shared language exists a priori | **Never** (but reducible) |
| Human wall-throughput ceiling | the human is a finite actor | **Never** |

**The load-bearing split:** the first two are model-generation-bound; the rest are
substrate-permanent. Harness engineering's durable work domain is the permanent set.

## 2. Which slot each system occupies

| Slot | superpowers | mattpocock/skills | super-bootstrap |
| --- | --- | --- | --- |
| Procedure / discipline | owns | owns (model-invoked) | — |
| Alignment / elicitation | `brainstorming` | `grill-me` / `grill-with-docs` | — |
| Shared language | — | `CONTEXT.md` + ADR | — |
| Entry selection (routing) | **absent** | `ask-matt` (owns its own) | Cluster table — **shape recognition, not entry routing**; rows name disciplines a harness would otherwise supply |
| Fast capture | — | — | **`/log`** |
| Standing work state | — | defers to a real tracker | **`docs/work/` cards** |
| Per-feature work order | temporal specs/plans | `to-tickets` → whatever tracker setup configured | the card's `## Design` / `## Plan` blocks |
| Propagation gate | — | — | **doc-sync** |
| Cold-start data map | — | `CONTEXT.md` + `docs/adr/` | `overview` + `techstack` + `decisions` |
| Awareness wiring | full-body ambient injection | static `## Agent skills` pointers in CLAUDE.md | **path-scoped rules (`paths:` frontmatter)** |
| Parallel throughput | — | — | **drain** |
| Product anchor (problem / user / ICP / G2M) | — | — | **`overview.md` Problem / User** |

**Four slots are uncontested:** fast capture, propagation gate, parallel throughput,
product anchor. Awareness wiring is contested but the mechanisms differ in kind — see §4.

**The product-anchor slot is unbuilt on the other side, by design not oversight.**
mattpocock's cold-doc layer is real but entirely solution-space: `CONTEXT.md` is a
glossary and states so outright ("totally devoid of implementation details… a glossary and
nothing else"), `docs/adr/` holds why-decided, `.out-of-scope/*.md` holds rejected
enhancements. No ICP, no problem statement, no market. His set is addressed to the
engineer in a codebase, so product truth is not the engineer's to own — there is nothing
here to defer to and no coverage claim to test.

That absence is what the [`overview.md`](../overview.md) § User positioning answers: a
codebase answers *solution*, so an agent judging whether to build something needs the
premise written where it reads.

## 3. The routing layer is coupling cost, not capability

super-bootstrap's routing layer exists because superpowers ships entry points without
an entry rule. Filling another container's missing boundary made super-bootstrap
inseparable from it.

**Dissolve test — remove superpowers, and these lose their referent:**

| Component | Verdict — and what stands now |
| --- | --- |
| Cluster routing table — rows 1 / 2 / 3 (`systematic-debugging` / `brainstorming` / `writing-plans`) | Referent dead, **discipline live**: the rows state the disciplines themselves — root cause before fix · settle the design · write the sequence — and name no harness. |
| Cluster routing table — rows 5 / 6 / 7 / 8 (inline tweak · docs · harness edit · triage lane) | **Live**, harness-neutral already; row 8 routes to our own `/super-bootstrap:triage`. |
| Cluster routing table — row 4 (refactor) | **Live** — its "multi-step → cluster 3" pointer targets a discipline, not a skill. |
| "Inside a route — run it whole" | Dead. The section is gone. |
| Dispatch § SDD carve-out — the "chain's executor governs" clause | Dead. The clause is gone; the bullet's commit-door mechanics are harness-agnostic and stand. |
| § The envelope ambient-laws line (4 skill names) | Referent dead, **discipline live**: three laws stated inline. `dispatching-parallel-agents` carried nothing § Dispatch does not already own. |
| `docs/specs/superpowers-topology.md` | Dead. The file is gone. |
| `harness-bootstrap` § Core plugin pins — `superpowers` as a **locked** core dep | Dead *as core* — the pin's own justification was name-backing ("if CLAUDE.md names a skill that isn't installed, the trigger rule misfires silently"), and the names are gone. A process harness is an ordinary adaptive pick in `resolve-plugins`, pinned by nothing. |
| The temporal work folder | **Ours**, at `docs/work/`. His artifact skills own no path — they publish to whatever tracker is configured (§4) — so there was no slot to defer to. |
| drain's stage machine (`raw→triage→plan→execute→review`) | **Re-cut by GAP-050** — the stage set was distillation-shaped after all: Design/Plan slots are now conditional context-scope sections (thread contract), stage vocabulary re-cut to `aimed`/`executing`. Drain's surviving value — cold-executor parallelism over scoped briefs — re-derives via `GAP-051`. |
| **log / cards / commit / doc-sync / rules** | **Unaffected.** |
| `skills/triage/SKILL.md` + `agents/triage.md` — investigation doctrine | Referent dead, **discipline live**: the clause is stated inline, naming no harness. The pointer never resolved even where superpowers is installed — the agent's tool list carries no `Skill`. |

**The table was 8 rows; 7 survive** (drain's stage machine re-cut by GAP-050 → `GAP-051`) — three of them restated. Its real function is
sizing ceremony to shape, and that is harness-independent: clusters 5 and 6 say "no
ceremony", 7 routes harness edits, 8 routes triage to our own door, and 1–3 name the
disciplines a process harness would otherwise supply. Deleting rows rather than restating
them would have dropped verified-load-bearing prose — [`docs/decisions.md`](../decisions.md)
records a pressure test where the route line alone sent a runtime-symptom bug to the triage
lane in 2/2 control runs.

mattpocock ships `ask-matt` — a router over his own user-invoked skills — so the gap
that forced our routing layer does not exist for him. Building one anyway would create
a second routing authority over the same objects.

His skills are additionally designed against being driven: a user-invoked skill may
invoke model-invoked skills but never another user-invoked one, and `implement` carries
`disable-model-invocation: true`.

## 4. The seam: runtime-orthogonal, setup-time-composed

**Runtime.** super-bootstrap names zero foreign skills. This is grep-verifiable, not a
policy: `rg 'superpowers|systematic-debugging|brainstorm|writing-plans|write-plan|execute-plan'`
over `plugins/super-bootstrap/` returns only the sanctioned exceptions below. The
pattern carries `brainstorm` **unstemmed** and both hyphenated command spellings
deliberately: a `brainstorming|writing-plans` pattern is blind to `/brainstorm`,
`/write-plan`, and `/execute-plan` — the form a live dispatch actually takes, and the form
that survived the skeleton cut unseen.

**One hit class is sanctioned and stays.** It routes nothing:

- **Historical** — `harness-bootstrap`'s mature-repo detector must keep matching the
  pre-rename `chore: scaffold|sync superpowers pipeline` strings, because it reads commit
  history. Dropping them would make every already-bootstrapped repo read as
  never-bootstrapped.

No live couplings remain. A hit outside that class is a regression — the pattern
catches a live command referent whether it dispatches (a subprocess phase prompt) or only
reads as prose, and prose that seeds through the capture funnel carries the referent into
every consumer repo's own card set, where it outlives the cut.

The folder shape is gone: `docs/superpowers/` is now `docs/work/`. Phase 2a scaffolds
`README.md` + `TEMPLATE.md`; cards land flat beside them as work is logged. The
naming rides the same path — skill `description:`, the runway intro, the emitted commit
strings, and the pipeline-family `tags:` keyword are all harness-neutral, so a consumer
re-bootstrapping migrates in one run.

**Setup-time.** Composition happens through mattpocock's own declared socket. His
`/setup-matt-pocock-skills` presents these issue-tracker options verbatim:

> **GitHub** — issues live in the repo's GitHub Issues (uses the `gh` CLI)
> **GitLab** — issues live in the repo's GitLab Issues (uses the [`glab`](https://gitlab.com/gitlab-org/cli) CLI)
> **Local markdown** — issues live as files under `.scratch/<feature>/` in this repo
> **Other** (Jira, Linear, etc.) — ask the user to describe the workflow

He ships seed templates for the first three (`issue-tracker-github.md`,
`issue-tracker-gitlab.md`, `issue-tracker-local.md`) but **none for "Other"** — that
branch is authored fresh. So super-bootstrap can ship its own seed for that slot,
declaring `docs/work/` + `/super-bootstrap:log` as the repo's tracker. His
`to-spec` and `triage` then write into our home.

**His artifact skills own no paths — they ask the repo.** Read at grade A (2026-07-26):
`to-tickets` §5 publishes "depending on the tracker `/setup-matt-pocock-skills`
configured", and `.scratch/<feature-slug>/issues/` is only its *local-files fallback*;
`wayfinder` says outright that where its map and tickets "physically live is
tracker-specific", defaulting to local markdown **only when no tracker was provided**.

**The temporal work folder therefore stays ours**, as `docs/work/`. Retiring it outright
would only have made sense if his set owned that slot at a fixed path; it does not, so
declaring our own path through the tracker socket composes with his skills exactly as
well as deleting the slot would. That raises `GAP-038` from nice-to-have to the actual
composition mechanism — the seed is what tells his skills where to publish. His taxonomy
is spec → tickets → implement, with no "plans" artifact at all, so our `## Plan` block has
no counterpart to defer to.

**Known weakness of this seam — read out, and worse than "prose, not schema".** His setup
writes `docs/agents/issue-tracker.md`, `docs/agents/domain.md`,
`docs/agents/triage-labels.md`, and a `## Agent skills` block into `CLAUDE.md`/`AGENTS.md`.
It carries an in-place rule for that block alone ("update its contents in-place rather than
appending a duplicate") and is **silent on pre-existing `docs/agents/*`** — so
bootstrap pre-writing the file has no skip guarantee and may simply be overwritten.
Shipping a seed template connects to nothing either: his templates load from
`./issue-tracker-*.md` inside his own skill folder, with no cross-plugin lookup path.

**The socket that does work is the "Other" branch** — it ships no template and is authored
at setup time from the user's own description of the workflow. So the composable artifact
is *a description the operator supplies*, not a file we ship. `GAP-038` needs that re-aim
before it is executable at all.

The seed shape it would have to match is known: `Status:`, `Type:
research|prototype|grilling|task`, `Blocked by: NN, NN`, a `## Comments` section, the
publish–fetch–resolve operations, and a `map.md` wayfinding file. **Our cards carry
none of those fields** — the scale module's fact fields are the only plausible home.

**The middle of any sandwich can only be human-typed.** Every user-invoked skill sampled
carries `disable-model-invocation: true` — `ask-matt`, `implement`, `grill-me`, `triage`
(4/4). His user-invoked layer is unreachable to a model, which settles three questions at
once:

- A head that auto-dispatches into his router is **impossible, not mis-shaped**. `ask-matt`
  emits a recommendation for the human to type over the 20 commands it routes; its input is
  a situation question, not a work item.
- **A dispatched subagent is also a model, so drain cannot drive his lane.** The wall is the
  flag, not `wayfinder`'s one-ticket-per-session rule — that rule holds per-agent, since
  each drain worktree is its own atomic session and the entry session orchestrates rather
  than works.
- The only bypass is pasting his skill bodies into a dispatch prompt, which is the
  distil-foreign-doctrine direction §6 already rules out.

An unnamed middle is therefore the only mechanically available shape; our end of the seam
stays head-and-tail by construction.

One further question rides the same decision: whether wiring anything mattpocock-shaped
into bootstrap presupposes change B, which §6 leaves open. The provisioning half is
settled — §6 decides the runway ships bare, so bootstrap recommends nothing and the only
live route is `resolve-plugins`' ordinary adaptive pick. **`GAP-038` is therefore not
executable as its title reads.** `plugins/super-bootstrap/` references mattpocock nowhere,
so bootstrap behavior is unchanged.

**A second socket exists for coding standards:** his `code-review` reads
`CODING_STANDARDS.md` / `CONTRIBUTING.md`, and a documented repo standard overrides its
built-in Fowler baseline. Repo-level coding principles belong in that file rather than
as a mandatory skill invocation wired into CLAUDE.md.

## 5. Awareness wiring is the strongest uncontested position

Docs existing ≠ the agent attending to them. The three systems solve this differently:

| System | Mechanism | Ambient cost | Grain |
| --- | --- | --- | --- |
| superpowers | full skill body injected every session | highest | none (global) |
| mattpocock | static `## Agent skills` pointer block in CLAUDE.md | low | coarse |
| super-bootstrap | `.claude/rules/*.md` with `paths:` frontmatter — full body fires when a matching file is read | **zero when irrelevant** | **decision moment** |

Path-scoped rules bind to **file paths, not skill names**, so this slot is orthogonal by
construction — it needs no change when the process harness is swapped or removed.

### The fences stay ambient — the cut is a rename, not a relocation

De-routing removes routing, not discipline. Four laws named in `CLAUDE.md` § The envelope
(`test-driven-development`, `verification-before-completion`, `receiving-code-review`,
`dispatching-parallel-agents`) are superpowers skill names, and § Coding Principles mandates
a `karpathy-guidelines` invocation. Where they land is settled by the rules layer's own
firing mechanism, not by preference.

**A path-scoped rule fires on file *read*, not on intent** — stated in the shipped
rule-authoring guide (`rules-index-skeleton.md`: "a rule fires on file *read*, not on
intent") and in § Rules above. Hold each fence against that:

| Fence | Fire moment | File-read surface? |
| --- | --- | --- |
| verification-before-completion | about to claim done / fixed / passing | **No** — a claim is not a file read |
| receiving-code-review | review feedback arrives | **No** |
| dispatching-parallel-agents | choosing a container | **No** — and § Dispatch already owns it |
| test-driven-development | about to write implementation | Source globs — but unknowable in the skeleton (stack detected at Phase 1) |
| coding principles | about to write code | same as above |

So **`GAP-039`'s premise is mechanically unavailable**: no `paths:` glob can fire at "about
to claim done". Same failure class as the closed worktree-glob fork in
[`docs/decisions.md`](../decisions.md) — a path rule matches paths *under* a root, never a
moment.

**Ambient prose is this repo's proven carrier.** The retired-hook closure records it: the
entry-discipline's home is `CLAUDE.md`, "present every turn incl. answer-from-memory + every
dispatched subagent", and 10 control agents were shaped by it with no hook. A run of closed
forks additionally rejects new rule files that duplicate ambient prose absent a failing
pressure-test, and [`.claude/rules/skill-authoring.md`](../../.claude/rules/skill-authoring.md)
requires RED-first for behavior-shaping prose. Shipping a rule here would be that rejected
shape with no failing test behind it.

**Shipped shape.** The ambient-laws line carries three disciplines **the repo declares**, one
line each, no foreign-harness referent — test-first, verify-before-claiming,
review-received-not-absorbed. The fourth (`dispatching-parallel-agents`) is cut outright,
because § Dispatch is its single home (VII). The rejected rules-layer direction is recorded
in [`docs/decisions.md`](../decisions.md) so it is not re-proposed.

**What the compression costs — answered for the review law.** Each named skill carried a full
body that loaded at its fire moment; a one-liner does not. `Verify before claiming` plausibly
compresses without loss; `Review received, not absorbed` did not — the repo authors its own
discipline body for it: the `review-intake` agent, with § Dispatch routing judgment-grade
findings through it before any implementer. The answer was never a rule glob (closed above).

### § Coding Principles is a different concern, riding Wave 1 by name-adjacency

§3's dissolve test does not list it. `karpathy-guidelines` is a **standards** skill, not a
process harness, so de-routing does not touch it and `DEBT-029` is not a de-routing card.
Its real problem stands on its own: a standard bound to one invocation, invisible to any
reviewer not running that skill.

Its carded fix has an SSOT constraint. Copying the skill's four principles into
`CODING_STANDARDS.md` duplicates a body that lives upstream — a parallel truth (VII), and
`CLAUDE.md` already says "Skill body is upstream — don't paraphrase it here."

**Shipped:** the ambient slot keeps its fire moment ("before writing, reviewing, or
refactoring code"), the *mandatory* invocation is gone, the pinned skill is the default
standard, and `CODING_STANDARDS.md` overrides it where a repo declares one. The ambient line
is the guaranteed reader the card's title assumed a file could be. The default leads and the
socket follows deliberately: `harness-bootstrap` writes no such file, so leading with the
socket would lead with the branch that fires in no repo the runway produces. That residual is
`GAP-042`.

Dispatch doctrine came through intact: of CLAUDE.md § Dispatch's bullets, only the
"build inside a superpowers chain → that chain's executor governs" clause was coupled, and
it is cut. The rest — closure-judged inline-vs-dispatch, per-phase build dispatch,
transcription is not a build, review findings gated through `review-intake`, parallel within
a phase not across, create-new-file dispatches foreground — are harness-agnostic, and the cut
bullet's own commit-door mechanics survive under a harness-neutral heading.

## 6. Decided vs open

**Decided — de-routing (change A).** super-bootstrap stops routing any external process
harness. This does not depend on which harness wins; it follows from §3's dissolve test.
superpowers may stay installed — it simply stops being routed.

*De-routing rests on the dissolve test alone, not on a measurement.* The de-routed state
is not a bare run — CLAUDE.md minus its routing sections, ~1.6k tokens of skill
descriptions, the path-scoped rules, and the log / card / doc-sync / commit doors all
remain. Removing the routing layer gives a clean reading of **that layer's** cost and
nothing wider; it does not test whether the harness as a whole helps or hurts. Most of
what such a test would report is static arithmetic anyway (ambient token count, per-board
cost); the part that is not — omission rate — needs controlled runs this repo has no
apparatus for.

**Decided — the runway is bare by design.** No process harness stands behind the seeded
disciplines, and the seeded `CLAUDE.md` says so under § The envelope. Installing one is an
operator choice `resolve-plugins` already handles as an ordinary adaptive pick; bootstrap
recommends nothing. Independent of change B — adopting a harness there does not make the
bare runway retroactively a gap.

**Open — harness swap (change B).** Whether to move from superpowers to
mattpocock/skills. Depends on evidence graded second-hand in §7.

**Decided — orthogonal trial precedes any interface work.** Nothing composes with
mattpocock's set until it has been run independently on a greenfield repo, with
super-bootstrap's own gaps fixed first. The seam's shape is read out of a real run, not
designed against read skill text: §4's head/tail contracts are mechanically constrained
(the middle is human-typed only) but the *content* of a head hand-off — what a work item
must carry for his lane to consume it — is unknown until his lane has consumed one. Any
interface proposal authored before that trial is speculation dressed as a contract.

**Open — drain's anchor.** drain's own doc names its ceiling: "Capacity ceiling = how
many halts the user can resolve, not machine throughput." Whether parallel spawns produce
net progress or net walls is unmeasured. This determines whether drain survives at 53 KB,
shrinks, or goes.

*One classification cheapens that question before any measurement.* Human gates split by
whether the human's answer changes the next question:

| Gate shape | Mechanism | Parallelizable |
| --- | --- | --- |
| **Elicitation** — design settling, `grilling`'s dependency-ordered questions | question N+1 does not exist until answer N | **No** — batching destroys the mechanism |
| **Verification** — approve a finished diff, land a commit | the N checks are independent | **Yes** |

drain is sound over verification-shaped halts and becomes engagement-monitoring exactly
where it fans out elicitation-shaped work, because each halt then costs a design
conversation the human cannot hold N of concurrently. So the open question reduces to
classifying drain's existing halts — and to whether `intent == Cloud` is in fact a proxy
for "verification-shaped", in which case the gate is sound and mis-named.

This is also why mattpocock's set reads as gate-maximal without being ceremony: his gates
are almost entirely elicitation (`grilling` asks one question at a time, supplies a
recommended answer, and lets no action proceed before confirmed alignment;
`improve-codebase-architecture` proposes only; `triage` labels `ready-for-agent` vs
`ready-for-human` rather than assuming either). Monitoring gates — approve-each-step with
no information flowing back — are the antipattern, and he ships nearly none.

### Change A is complete; change B is open

super-bootstrap routes no external process harness. The §4 grep returns only the two
sanctioned classes, and the shape check holds beside it — zero name-hits was never
sufficient on its own, since a stage chain renamed to harness-neutral words would still
carry the foreign decomposition. GAP-050's per-slot audit confirmed that risk was real:
the staging ceremony (Design/Plan as default gates) was distillation residue — the thread
contract now carries them as conditional context-scope sections, and drain's stage set
re-derives from grounding-native artifacts (`GAP-051`). The runway declares its bare
posture (§6 above). `GAP-038` stays parked behind change B.

Two constraints outlive the change:

- Retiring the cloud-safe derivation must replace drain's admission predicate
  (`eligibility.md` Cloud-gate fallback) in the same change — without the venue map
  `intent == Cloud` is drain's whole gate.
- A hit outside §4's one sanctioned class is a regression, whether it dispatches or only
  reads as prose.

**Vacating means naming the discipline and shipping nothing.** A card whose fix reads
"point at X instead" is mis-shaped whatever X is — re-pointing a routing line from one
foreign harness to another rebuilds the coupling change A paid to remove.

## 7. Evidence index

Verification grades: **A** = literal text read; **B** = model-summarized fetch, claims
usable but not quotable; **C** = inferred, unverified.

### External

| Resource | URL | Grade | Notes |
| --- | --- | --- | --- |
| mattpocock/skills README | `https://raw.githubusercontent.com/mattpocock/skills/main/README.md` | A | Full text retrieved; philosophy + skill index + the user-invoked/model-invoked composition rule |
| `setup-matt-pocock-skills` issue-tracker options | `.../skills/engineering/setup-matt-pocock-skills/SKILL.md` | **A** | Option list + CLAUDE.md block quoted verbatim (2026-07-25). Re-read for file-collision behavior (2026-07-27): writes `docs/agents/issue-tracker.md`, `docs/agents/domain.md`, `docs/agents/triage-labels.md`, and a `## Agent skills` block into `CLAUDE.md`/`AGENTS.md`. In-place-update rule exists **for that block only**; **silent on pre-existing `docs/agents/*`**. Templates load from `./issue-tracker-{github,gitlab,local}.md`, `./triage-labels.md`, `./domain.md` inside his own skill folder — no cross-plugin lookup path |
| `tdd` | `.../skills/engineering/tdd/SKILL.md` | B | Seam-confirmation gate, three forbidden anti-patterns, vertical-slice rule |
| `code-review` | `.../skills/engineering/code-review/SKILL.md` | **A** | Literal text (2026-07-26). Step 4 pins no tier: "Use the `general-purpose` subagent for both." Parallel is for isolation — "so they don't pollute each other's context"; step 5 forbids reranking across axes. Sub-agent prompts paste the smell baseline in full because "the sub-agent has no other access to it" |
| `implement` | `.../skills/engineering/implement/SKILL.md` | **A** | Literal text (2026-07-26). Nine lines, `disable-model-invocation: true`, dispatches nothing — a session-level orchestration note pointing at `/tdd` and `/code-review` |
| `research` | `.../skills/engineering/research/SKILL.md` | **A** | Literal text (2026-07-26). "Spin up a **background agent** to do the research, so you keep working while it reads" — offload stated outright, no tier pinned. Primary sources only; findings to one Markdown file matching the repo's existing convention |
| `to-tickets` | `.../skills/engineering/to-tickets/SKILL.md` | **A** | Literal text (2026-07-26). **Owns no path**: §5 publishes to whatever `/setup-matt-pocock-skills` configured — `.scratch/<feature-slug>/issues/<NN>-<slug>.md` is the *local-files fallback branch*, a real tracker takes native issues. Tracer-bullet vertical slices, `Blocked by:` edges, expand–contract for wide refactors |
| `wayfinder` | `.../skills/engineering/wayfinder/SKILL.md` | **A** | Literal text (2026-07-26). "**Never resolve more than one ticket per session** — with the exception of research tickets." Research tickets are AFK, "Resolved by a `/research` **subagent**"; prototype / grilling / task are HITL and stay in-session. Physical location "is tracker-specific", defaulting to local-markdown only when none is provided |
| `to-spec` | `.../skills/engineering/to-spec/SKILL.md` | B | Publishes to tracker; no interview; publication format unconfirmed |
| `diagnosing-bugs` | `.../skills/engineering/diagnosing-bugs/SKILL.md` | **A** | Literal text (2026-07-26). Six phases; "**This is the skill**" is phase 1, a tight red-capable feedback loop, with "no red-capable command, no Phase 2" as a hard gate. Then 3–5 ranked falsifiable hypotheses shown to the user before testing, one-variable instrumentation with tagged debug logs, regression test at a correct seam (absence of one is itself the finding). Assumes a runtime to go red against — read-only verdict work has none |
| `triage` | `.../skills/engineering/triage/SKILL.md` | **A** | Literal text (2026-07-27). `disable-model-invocation: true`. Two-layer labels — one category role (`bug` \| `enhancement`) + one state role (`needs-triage → needs-info → ready-for-agent \| ready-for-human \| wontfix`). **Targeted verification, not root-cause analysis**: reproduce (bugs) or read the diff (PRs), redundancy search by domain concept, prior-rejection check against `.out-of-scope/*.md`. Writes AI-labelled issue comments, agent briefs, triage notes, `.out-of-scope/` entries. `/grilling` + `/domain-modeling` invoked inline and conditionally |
| `ask-matt` | `.../skills/engineering/ask-matt/SKILL.md` | **A** | Frontmatter read (2026-07-27): `disable-model-invocation: true`. Routes 20 user-invoked commands and **emits a recommendation for the human to type** — a recommender, not a dispatcher. Input is a situation question, not a work item |
| `grill-me` | `.../skills/productivity/grill-me/SKILL.md` | **A** | Frontmatter read (2026-07-27): "A relentless interview to sharpen a plan or design", `disable-model-invocation: true`. Opens a `/grilling` session; lands no artifact, hands off to no downstream skill |
| `grilling` | `.../skills/productivity/grilling/SKILL.md` | **A** | Literal text (2026-07-27). **One question at a time**, awaiting the answer before the next; a recommended answer supplied with each; factual claims verified against the environment while decision answers are queued into the decision tree; dependencies resolved sequentially. Purely conversational — no artifact, no path. Ends on shared understanding; **no action proceeds without explicit confirmation of alignment** |
| `improve-codebase-architecture` | `.../skills/engineering/improve-codebase-architecture/SKILL.md` | **A** | Literal text (2026-07-27). `disable-model-invocation: true`. Walks commit history for hot spots, dispatches `subagent_type=Explore` to scan for architectural friction (shallow modules, poor locality, leaky seams), applies a deletion test, writes a **self-contained HTML report to a tmpdir** for the user to pick from, then hands the pick to `/grilling`. **Proposes only** — implements after confirmation during grilling |
| `domain-modeling` / `CONTEXT.md` | `.../skills/engineering/domain-modeling/SKILL.md` | **A** | Literal text (2026-07-27). `CONTEXT.md` is **a glossary and nothing else** — "totally devoid of implementation details… not a spec, a scratch pad, or a repository for implementation decisions". **Zero product/business dimension** (no ICP, problem, market, target user). **No staleness protocol** — only a session-time check: "when the user states how something works, check whether the code agrees… surface it" |
| `issue-tracker-local.md` seed template | `.../setup-matt-pocock-skills/issue-tracker-local.md` | B | Seed shape a tracker declaration must match: `Status:`, `Type: research\|prototype\|grilling\|task`, `Blocked by: NN, NN`, `## Comments`; publish–fetch–resolve operations; `map.md` holding Notes / Decisions-so-far / current fog |
| `writing-great-skills` | `.../skills/productivity/writing-great-skills/SKILL.md` | **A** | Literal text (2026-07-26). Predictability as root virtue; invocation / information hierarchy / granularity / pruning / leading words / failure modes. **States no dispatch doctrine** — subagents, tiers, and offload appear nowhere in his authoring reference |
| mattpocock `docs/` tree | `https://github.com/mattpocock/skills/tree/main/docs` | C | Only `engineering/` + `productivity/` subdirs visible; contents unread |
| ADR on shipping as a plugin | `.agents/adr/0002-ship-as-a-claude-code-plugin.md` (in his repo) | C | Referenced by README, unread |

Install paths (per his README): `npx skills@latest add mattpocock/skills` (editable
copy) or `/plugin marketplace add mattpocock/skills` + `/plugin install
mattpocock-skills@mattpocock` (managed bundle). Both require
`/setup-matt-pocock-skills` once per repo.

### Internal

| Resource | Path | Grade | Measurement (2026-07-25) |
| --- | --- | --- | --- |
| superpowers install | `~/.claude/plugins/cache/claude-plugins-official/superpowers/6.2.0/` | A | 89 files / 1,105 KB; largest: `writing-skills` 104.9 KB, `brainstorming` 73.8 KB, `subagent-driven-development` 49.1 KB, `systematic-debugging` 39.8 KB |
| `using-superpowers` ambient injection | `<superpowers>/skills/using-superpowers/SKILL.md` | A | 3.0 KB, injected in full every session |
| super-bootstrap plugin source | `plugins/super-bootstrap/` | A | 55 files / 319 KB; `harness-bootstrap` 93.8 KB, `drain` 53 KB (SKILL 12.6 KB + 10 assets) |
| Ambient description weight | all 13 shipped `SKILL.md` frontmatter | A | 6,456 chars ≈ 1.6k tokens, present in every session |
| Foreign-name coupling | `plugins/super-bootstrap/**` | A | 85 occurrences / 19 files; skeleton holds 15 |
| todo driver cost | `agents/todo.md` | A | ~33.5k subagent tokens / ~197 s for a 3-row board (this session); `DEBT-022` records ~34.3k / ~226 s for 4 rows |
| Shipped CLAUDE.md skeleton | `plugins/super-bootstrap/skills/harness-bootstrap/assets/claude-md-skeleton.md` | A | Carries the routing table into every bootstrapped repo |

### His path per card shape

| Card shape | His path | Method core |
| --- | --- | --- |
| Build / feature | `grill-me`→`grilling` → `to-spec` → `to-tickets` → `wayfinder` → `implement` (`tdd` + `code-review`) | Elicitation first, one question at a time; tickets carry `Type` + `Blocked by` edges; one ticket per session |
| Bug fix | `diagnosing-bugs` | Six phases with "build a tight, red-capable feedback loop" as a **hard gate** — no red-capable command, no Phase 2 — then 3–5 ranked falsifiable hypotheses shown before testing |
| Triage | `triage` | **Label state machine, not root cause.** Inbox sorting over a tracker (external PRs included); targeted verification, redundancy search, prior-rejection check; emits agent brief or triage note |
| Maintenance / debt | `improve-codebase-architecture` | Commit-history hot spots → `Explore` subagent scan → deletion test → throwaway HTML report for the human to pick → `/grilling`; proposes only |

Three cross-cutting artifacts carry the state: `CONTEXT.md` (glossary, maintained by
`domain-modeling`), `docs/adr/` (why-decided), `.out-of-scope/*.md` (rejected enhancements).
The last is the counterpart of [`docs/decisions.md`](../decisions.md), narrower — it admits
rejected enhancements only, while ours admits closed forks across every domain.

**Two lanes collide by name, not by work.** His `triage` sorts an inbox; our
`/super-bootstrap:triage` is a cold single-card grounding phase (premise verify / aim
validate / blast collect). They coexist. The
comparison surface for `DEBT-035`'s vacate question is therefore `diagnosing-bugs`, which is
what that card already names.

### Open questions blocking change B

1. Seed-template shape read at grade B (§4) — but `GAP-038`'s premise is the deeper block:
   the shippable artifact is an operator-supplied description for the "Other" branch, not a
   file, and a pre-written `docs/agents/issue-tracker.md` has no skip guarantee.
2. drain's wall-vs-progress ratio — unmeasured, though §6's elicitation-vs-verification
   classification answers much of it without measurement.
3. **No orthogonal run exists.** §6 makes this the gating item: his set has never been run
   independently on a greenfield repo, so every head-contract content question is inference
   off skill text.
### His dispatch posture — settled at grade A

Dispatch is not his default; it fires at three triggers and nowhere else.

- **Isolation** — `code-review` runs its two axes as parallel sub-agents "so they don't
  pollute each other's context", and forbids reranking across them at aggregation.
- **Offload** — `research` spins up a background agent "so you keep working while it
  reads". The description sells it as "reading legwork delegated to a background agent".
- **Scan** — `improve-codebase-architecture` dispatches `subagent_type=Explore` to sweep for
  architectural friction before it has candidates to show. Still no tier pinned.

Everything else stays in-session. `wayfinder` states the rule outright — **"never resolve
more than one ticket per session — with the exception of research tickets"** — and its
ticket taxonomy carries the same seam: `research` is AFK and subagent-resolved, while
`prototype` / `grilling` / `task` are human-in-the-loop and never dispatched. `implement`
is nine lines and dispatches nothing.

So the posture *is* session-as-atomic-runner, with bounded reading as the sole sanctioned
exit. It is not an isolation-specific exception.

**No model tier appears anywhere in his set** — `code-review` actively specifies
`general-purpose` for both axes, and `writing-great-skills`, his authoring reference,
states no dispatch doctrine at all: its levers are invocation, information hierarchy,
granularity, pruning, and leading words.

That absence does not convict our tier pins. His skills delegate the model choice to the
session because cost is not a concern his set addresses; ours pin because dispatch grade
and cost are the same decision here. The two answer different questions, so neither is
copied from the other — but our pins carry no written justification, which is the gap
`DEBT-035`'s sibling reasoning applies to: a pattern nobody wrote a reason for is
indistinguishable from one nobody chose.

## 8. Downstream migration — what adopt mode does and does not retire

`harness-bootstrap` § Phase 2 applies a per-artifact rule: missing → write; matches
template → skip; **drifted → show diff, approve per change, write**; project-owned →
never touch. Its CLAUDE.md coverage is **keyed to a named section list** (Development
Workflow, Dispatch, Doc Sync, Coding Principles, Edit Discipline, Context Hygiene,
Finding Triage, Rules, Git Notes, Planning).

| Retirement shape | Covered? | Why |
| --- | --- | --- |
| Content removed **within** a retained section | **Yes** | Section stays on the owned list; drift check fires and diffs it |
| A whole section **dropped** from the skeleton | **No** | The walk is skeleton-driven — a section no longer on the owned list is never visited, so it orphans in consumer repos |
| A scaffolded **folder** retired | **No** | Phase 2a states folders have only two states, missing or present ("create if missing, skip if present") — there is no removal path |

**The skeleton cut landed inside covered shapes.** No section was dropped, so nothing
orphans — `§ Inside a route` was a `###` subsection under § Development Workflow, which stays
on the owned list.

| Cut site (landed) | Shape | Covered? |
| --- | --- | --- |
| Routing rows restated, "inside a route" removed, SDD clause cut, ambient-laws line rewritten | content changed within § Development Workflow / § Dispatch (both on the owned list) | Yes |
| Topology doc deleted | repo-local; the shipped skeleton never referenced it (verified 2026-07-26, zero hits) | N/A downstream |
| § Coding Principles body replaced | section retained on the owned list | Yes |
| triage lane's doctrine clause restated inline | `plugins/super-bootstrap/**` ships with the plugin, never scaffolded into a consumer repo | N/A downstream |
| todo lane's `brainstorm` vocabulary renamed + `/brainstorm` empty-state door repointed | same — `shared/`, `agents/`, `skills/todo/` all ship with the plugin | N/A downstream |
| `superpowers` core pin removed from § Core plugin pins | `.claude/settings.json` pins are on the owned list, but 2a treats pins as missing-or-present with no removal path | **Fresh bootstraps only.** Already-bootstrapped repos keep the pin — superpowers stays installed where it is, which §6 permits |

**DEBT-026 closed the folder hole rather than accepting it.** The rename to `docs/work/`
would otherwise strand every already-bootstrapped repo's specs and plans: the scans read
the new path only, so the old tree stays on disk and goes invisible. Phase 2a therefore
migrates before it creates — `git mv docs/superpowers docs/work` when the old tree is
present, contents moved directory by directory when both exist, collisions reported
rather than resolved. This is the one cut where adopt mode gained a removal path instead
of documenting an orphan.
