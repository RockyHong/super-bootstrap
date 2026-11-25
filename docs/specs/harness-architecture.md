# Harness Architecture — What super-bootstrap Owns, and Where the Seam Falls

**Scope.** This doc owns the concern map: which slots super-bootstrap occupies, which
it delegates, and the mechanism at the boundary — why super-bootstrap routes no external
process harness, and what holds that seam in place.

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

| Slot | superpowers | super-bootstrap |
| --- | --- | --- |
| Procedure / discipline | owns | — |
| Alignment / elicitation | `brainstorming` | — |
| Shared language | — | **`docs/terminology.md`** — one canonical word per concept, `_Avoid_` aliases, linked on first use, entries proposed at commit-time doc-sync when a diff coins a term |
| Entry selection (routing) | **absent** | Cluster table — **shape recognition, not entry routing**; rows name disciplines a harness would otherwise supply |
| Fast capture | — | **`/super-bootstrap:log`** |
| Standing work state | — | **`docs/work/` cards** (the opt-in scale module adds `docs/parked.md` / `docs/test-queue.md` / `docs/outward/` beside them) |
| Per-feature work order | temporal specs/plans | the card's `## Design` / `## Plan` blocks |
| Propagation gate | — | **doc-sync** |
| Cold-start data map | — | `overview` + `techstack` + `decisions` + `terminology` |
| Awareness wiring | full-body ambient injection | **path-scoped rules (`paths:` frontmatter)** |
| Parallel throughput | — | **autorun** |
| Product anchor (problem / user / ICP / G2M) | — | **`overview.md` Problem / User** |

**Five slots are uncontested:** fast capture, shared language, propagation gate,
parallel throughput, product anchor. Awareness wiring is contested but the mechanisms differ in kind — see §5.

**Pipeline-produced pending work rides the same substrate.** Work the pipeline leaves
pending in a consumer repo is carried by `docs/work/` cards, seeded and committed before
the work starts — [`/super-bootstrap:setup`](../../plugins/super-bootstrap/skills/setup/SKILL.md)
seeds them from its pinned [seed-card bodies](../../plugins/super-bootstrap/skills/setup/assets/seed-cards.md)
and then works what it can in the same run — so an interrupted run leaves cold-pickup state
the ordinary doors read, and no second substrate holds it.

**The product-anchor slot is unbuilt on the process-harness side, by design not
oversight.** A process harness addresses the engineer standing in a codebase, and a
codebase answers *solution*; product truth — ICP, problem statement, market — is not the
engineer's to own. There is nothing there to defer to and no coverage claim to test.

That absence is what the [`overview.md`](../overview.md) § User positioning answers: a
codebase answers *solution*, so an agent judging whether to build something needs the
premise written where it reads.

## 3. The routing layer is coupling cost, not capability

superpowers ships entry points without an entry rule. A harness that routes into it fills
another container's missing boundary, and that makes the router inseparable from it.

**Dissolve test — remove superpowers, and hold each component against what it still stands on:**

| Component | What stands |
| --- | --- |
| Cluster routing table — rows 1 / 2 / 3 (`systematic-debugging` / `brainstorming` / `writing-plans`) | Referent dead, **discipline live**: the rows state the disciplines themselves — root cause before fix · settle the design · write the sequence — and name no harness. |
| Cluster routing table — rows 5 / 6 / 7 / 8 (inline tweak · docs · harness edit · triage lane) | **Live**, harness-neutral already; row 8 routes to our own `/super-bootstrap:triage`. |
| Cluster routing table — row 4 (refactor) | **Live** — its "multi-step → cluster 3" pointer targets a discipline, not a skill. |
| Cluster routing table — row 9 (spike / iterative) | **Live** — routes to our own `/super-bootstrap:merge`. |
| § The envelope ambient-laws line | **Discipline live**: four laws stated inline, naming no skill. Container choice — the concern of superpowers' `dispatching-parallel-agents` — belongs to § Dispatch. |
| § Dispatch | **Live** — every bullet is harness-agnostic, the subagent-commit door included (§5). |
| `harness-bootstrap` § Core plugin pin | **Live, harness-free** — no seeded prose names a foreign skill, so nothing needs one installed to resolve. No process harness is pinned; a repo adds one through Claude Code's own plugin install. |
| The temporal work folder | **Ours**, at `docs/work/`. No process harness owns that slot at a fixed path — artifact skills publish to whatever tracker a repo declares — so there is no slot to defer to. |
| The unattended lane (`autorun`) | **Ours, stage-free**: `autorun` spawns one session per admitted card that runs the whole card to done; admission is the one judgment in `shared/user-wall.md`. No stage chain, intent axis or venue map sits between them. |
| **log / cards / commit / doc-sync / rules** | **Unaffected.** |
| `skills/triage/SKILL.md` + `agents/triage.md` — investigation doctrine | Referent dead, **discipline live**: the clause is stated inline, naming no harness. A skill pointer could not resolve there anyway — the agent's tool list carries no `Skill`. |

**The cluster routing table survives the dissolve whole** — rows 1–3 restated as inline disciplines, the rest already harness-neutral. Its real function is
sizing ceremony to shape, and that is harness-independent: clusters 5 and 6 say "no
ceremony", 7 routes harness edits, 8 routes triage to our own door, and 1–3 name the
disciplines a process harness would otherwise supply. Rows 1–3 stay as restated disciplines
rather than deleted rows because the prose is verified load-bearing —
[`docs/decisions.md`](../decisions.md) records a pressure test where the
[route line](../../.claude/rules/harness.md#cluster-routing) alone sent a runtime-symptom bug
to the triage lane in 2/2 control runs.

## 4. The seam: runtime-orthogonal by construction

**Runtime.** super-bootstrap names zero foreign skills **at runtime** — no shipped door
dispatches to one, routes to one, or depends on one resolving. This is grep-verifiable,
not a policy:

```text
rg 'superpowers|systematic-debugging|brainstorm|writing-plans|write-plan|execute-plan|mattpocock|matt-pocock|ask-matt|grill-me|grill-with-docs|to-spec|to-tickets|wayfinder' plugins/super-bootstrap/
```

Every hit falls in the one sanctioned class below. The pattern carries
`brainstorm` **unstemmed** and both hyphenated command spellings deliberately: a
`brainstorming|writing-plans` pattern is blind to `/brainstorm`, `/write-plan`, and
`/execute-plan` — the form a live dispatch actually takes. `mattpocock` and `matt-pocock` are separate alternates for the same
reason: neither spelling matches the other, and mattpocock's setup command uses the
hyphenated one.

**One hit class is sanctioned. It routes nothing.**

- **Historical** — `harness-bootstrap` must keep matching pre-rename spellings it reads out
  of an already-bootstrapped repo: the `chore: scaffold|sync superpowers pipeline` commit
  strings its bootstrap-shaped-commit match greps, and the `docs/superpowers/` folder its Phase 2a
  migration moves to `docs/work/`. Dropping the first costs the doctrine migration its
  provenance read on a `CLAUDE.md` line a pre-rename bootstrap wrote — fresh install versus re-run
  is read off the files present, never off these strings; dropping the second strands its old tree on disk (§8).

The `mattpocock|matt-pocock|ask-matt|grill-me|grill-with-docs|to-spec|to-tickets|wayfinder`
alternates carry no sanctioned hit at all — they stay in the pattern as the standing
regression guard against pairing that skill set, a closed fork in
[`docs/decisions.md`](../decisions.md).

A hit outside that class is a regression — the pattern catches a live command
referent whether it dispatches (a subprocess phase prompt) or only reads as prose, and
prose that seeds through the capture funnel carries the referent into every consumer repo's
own card set, where it outlives any fix here.

The work folder is `docs/work/`; Phase 2a migrates a pre-rename `docs/superpowers/` tree
into it (§8), scaffolds `README.md` + `TEMPLATE.md`, and cards land flat beside them as
work is logged. The
naming rides the same path — skill `description:`, the runway intro, the emitted commit
strings, and the pipeline-family `tags:` keyword are all harness-neutral, so a consumer
re-bootstrapping migrates in one run.

**Agent runtime — the boundary below this seam.** *Runtime* above means door-execution time;
below it sits the agent runtime itself, and that boundary is not orthogonal. The harness is
Claude-hosted and orchestrating: agent-runtime portability is out of scope, and the ambient-prose,
path-scoped-rule, skill, agent, hook and packaging layers stay Claude-bound as the substrate they
run on, not as losses. The pipeline seeds no runtime-neutral artifact, and no shipped door, hook or
rule has to resolve on a foreign runtime. Splitting the harness into a runtime-neutral core plus
per-runtime adapters is a closed fork in [`docs/decisions.md`](../decisions.md).

### The second seam: claude-config-manager, the author's device storehouse

A different seam from the one above, decided on a different axis. super-bootstrap is a
per-repo consumer product; claude-config-manager is the author's device storehouse,
present only on the author's machine and serving every repo there. Both sides hold
harness artifacts, and both sides' routing doors face each other, so the boundary needs
a test either side can apply alone.

**Ownership runs on consumer-resolvability, not on provenance.** Whose tree currently
holds a file says which door a *write* goes through; it does not say whose problem a
finding is. The deciding question is whether the artifact must resolve for a consumer
who has only the installed plugin — the consumer-resolvability test, stated with its
branches and its settled edge at
[`.claude/rules/repo-boundary.md`](../../.claude/rules/repo-boundary.md)
§ Finding lanes, which § Taste-coupling layers there cites for skeleton prose. That
edge — a test surface or bench follows its artifact's owner — is closed, not open, on
the doc-consult hook row in [`docs/decisions.md`](../decisions.md).

**Why the test is placed twice.** A storehouse session cannot read a consumer repo's
rules, so the storehouse needs the same test on its own side rather than a read-through
to this one — one criterion, two placements, each the other's propagation closure.

**The consequence at the doors.** A finding on a served file whose *concern* is this
repo's is logged here, not contributed out — provenance alone would send it away and the
item would round-trip, each hop re-grounding cold on a test that cannot answer the
question being asked.

**The runway receipt is a cross-repo read contract.** The storehouse's device audit hook
reads the runway receipt `.claude/super-bootstrap-runway.json`: its `placed` map,
`{path: sha256}`, written by
[`harness-bootstrap` § 2c](../../plugins/super-bootstrap/skills/harness-bootstrap/SKILL.md#2c-sync-report--commit).
A path whose CR-stripped sha256 equals its entry leaves the hook's audit predicate, so the
placed doctrine `.claude/rules/harness.md` raises no audit nudge. The receipt path, the
`placed` key, its shape and the CR-stripped hash on `.claude/rules/harness.md` therefore
bind both repos. A change to any of them owes claude-config-manager a hand-over
(`/send-note`) in the same change; the reader landed in claude-config-manager `1975191`.

## 5. Awareness wiring is the strongest uncontested position

Docs existing ≠ the agent attending to them. The two systems solve this differently:

| System | Mechanism | Ambient cost | Grain |
| --- | --- | --- | --- |
| superpowers | full skill body injected every session | highest | none (global) |
| super-bootstrap | `.claude/rules/*.md` with `paths:` frontmatter — full body fires when a matching file is read | **zero when irrelevant** | **decision moment** |

[Path-scoped rules](../../CLAUDE.md#rules-auto-load-on-file-match) bind to **file paths, not
skill names**, so this slot is orthogonal by construction — it needs no change when the
process harness is swapped or removed.

### The fences stay ambient, not path-scoped

De-routing removes routing, not discipline. [§ The envelope](../../.claude/rules/harness.md#the-envelope)
of the workflow doctrine file states four ambient laws the repo declares, each inline and
naming no skill: test-first, verify before claiming, closure before a criterion edit, and
review received, not absorbed. Three of them carry the discipline of superpowers skills
(`test-driven-development`, `verification-before-completion`, `receiving-code-review`); the
superpowers skill `dispatching-parallel-agents` maps to § Dispatch instead. The same file's
§ Coding Principles carries one more fence — the coding standard.
Where the fences land is settled by the rules layer's own firing mechanism, not by preference.

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

So **the path-scoped-rule premise is mechanically unavailable**: no `paths:` glob can fire at
"about to claim done". Same failure class as the closed worktree-glob fork in
[`docs/decisions.md`](../decisions.md) — a path rule matches paths *under* a root, never a
moment.

**Ambient prose is this repo's proven carrier.** The fences and the entry discipline load
every turn from the workflow doctrine file,
[`.claude/rules/harness.md`](../../.claude/rules/harness.md). That file carries no `paths:`
frontmatter, so it is not a path-scoped rule: it loads eagerly at session start, reloads
after compaction and reaches every dispatched subagent. The retired-hook closure records the
carrier class on ambient `CLAUDE.md` prose — "present every turn incl. answer-from-memory +
every dispatched subagent" — where 10 control agents were shaped by it with no hook. The
[carrier-equivalence bench](../../bench/carrier-equivalence/README.md) measures the same
doctrine text shaping a card pickup identically from `CLAUDE.md`, the eager rules file and an
`@path` import, in the main session, a subagent and after compaction. A run of closed
forks additionally rejects new rule files that duplicate ambient prose absent a failing
pressure-test, and [`.claude/rules/skill-authoring.md`](../../.claude/rules/skill-authoring.md)
requires RED-first for behavior-shaping prose. Shipping a rule here would be that rejected
shape with no failing test behind it.

**Shipped shape.** The ambient-laws line carries four disciplines **the repo declares**, one
line each, no foreign-harness referent — test-first, verify-before-claiming,
closure-before-a-criterion-edit, review-received-not-absorbed. Closure before a criterion
edit is the repo's own law, not a restated superpowers fence. `dispatching-parallel-agents`
takes no ambient-laws line, because
[§ Dispatch](../../.claude/rules/harness.md#dispatch--who-holds-each-phase) is its single home (VII).
The rejected rules-layer direction is recorded in [`docs/decisions.md`](../decisions.md) so it
is not re-proposed.

**What the compression costs — answered for the review law.** A one-line law carries less
than a full skill body loaded at its fire moment. `Verify before claiming` plausibly
compresses without loss; `Review received, not absorbed` does not, so the repo authors its
own discipline body for it: the `review-intake` agent, with § Dispatch routing
judgment-grade findings through it before any implementer. A rule glob cannot carry it
(closed above).

### § Coding Principles is a standards concern, not a process harness

§3's dissolve test does not list this slot. A coding standard is a **standards** concern,
not a process harness, so de-routing does not touch it. Its own problem stands separately:
a standard bound to one skill invocation is invisible to any reviewer not running that
skill.

An in-repo file carries no such binding, and duplicates no body that lives upstream — so
the parallel-truth constraint (VII) that rules against copying a foreign skill's content
into `CODING_STANDARDS.md` never binds the file itself.

**Shipped:** the ambient slot keeps its fire moment ("before writing, reviewing, or
refactoring code") and names `CODING_STANDARDS.md` as the standard — no pinned default
behind it. The line ships in the workflow doctrine file on every repo and reads
`CODING_STANDARDS.md` where the repo holds one, so it is the guaranteed reader that carries
the file to every code touch. `harness-bootstrap` scaffolds the file headings-only, so a
concern no section declares is left to default judgment. Only the file waits for code: a
docs-only repo — no manifest, no source file — takes none, and the file raises `⊕ new` when
code arrives ([Phase 1 § Code presence](../../plugins/super-bootstrap/skills/harness-bootstrap/SKILL.md)).

The slot routes three ways, so a convention has one home: binding with no clean file glob →
`CODING_STANDARDS.md`, hand-recorded when a review or commit settles it (the file is outside
the doc-sync surface); binding within a path glob → `.claude/rules/<scope>.md`; descriptive —
how the code is written, observed rather than mandated →
[`docs/techstack.md` § Coding Patterns](../techstack.md#coding-patterns), reference read on
demand, never a standard.

§ Dispatch names no harness: closure-judged inline-vs-dispatch, per-phase build dispatch,
transcription is not a build, review findings gated through `review-intake`, subagent
commits routed through the commit door, parallel within a phase not across, and writer run
mode keyed on path overlap are all harness-agnostic.

## 6. Decided vs open

**Decided — de-routing.** super-bootstrap routes no external process harness. This does
not depend on which harness wins; it follows from §3's dissolve test. superpowers may be
installed in a repo; no door routes it.

*De-routing rests on the dissolve test alone, not on a measurement.* The de-routed state
is not a bare run — the workflow doctrine minus its routing sections, `CLAUDE.md`, ~1.6k tokens of skill
descriptions, the path-scoped rules, and the log / card / doc-sync / commit doors all
remain. Removing the routing layer gives a clean reading of **that layer's** cost and
nothing wider; it does not test whether the harness as a whole helps or hurts. Most of
what such a test would report is static arithmetic anyway (ambient token count, per-board
cost); the part that is not — omission rate — needs controlled runs this repo has no
apparatus for.

**Decided — the seeded runway names no harness.** The placed workflow doctrine
([`assets/harness.md`](../../plugins/super-bootstrap/skills/harness-bootstrap/assets/harness.md),
which carries the routing table into every bootstrapped repo), the seeded `CLAUDE.md` and
every scaffolded doc state disciplines, never skill entries; the doctrine's § The envelope
carries no install pointer — the rationale lives here, not ambient. Bootstrap pins the core plugin and
the techstack's language server and seeds no process harness: no seeded prose stands on a foreign harness, which is why taking or dropping one
costs no doc change.

**Decided — no process harness is paired or pinned.** super-bootstrap pins no process
harness. A repo adds one through Claude Code's own plugin install, on separate axes from
sb's slots (§2); no plugin door routes it. Pairing one is a closed fork in
[`docs/decisions.md`](../decisions.md).

**Resolved — autorun's anchor.** The unattended lane's ceiling is how many walls the
user can resolve, not machine throughput. The classification below settles the shape
question without measurement: dependency-ordered elicitation never enters `autorun` —
admission is the one judgment in `shared/user-wall.md`, and a card whose next step needs
the user is `needs-me`'s to recommend — and every wall autorun produces is a one-shot
framed decision the user answers, parks, or drops from one sheet. The model makes that
admission judgment directly; no derived gate or venue map stands in for it. The wall-vs-progress *ratio* stays unmeasured — cheap to instrument
if the sheet grows.

*The classification.* Human gates split by whether the human's answer changes the next
question:

| Gate shape | Mechanism | Parallelizable |
| --- | --- | --- |
| **Elicitation** — design settling, dependency-ordered questioning | question N+1 does not exist until answer N | **No** — batching destroys the mechanism |
| **Verification** — approve a finished diff, land a commit | the N checks are independent | **Yes** |

autorun is sound over verification-shaped halts and becomes engagement-monitoring exactly
where it fans out elicitation-shaped work, because each wall then costs a design
conversation the human cannot hold N of concurrently. Design settling walls out at
admission (`needs-me` owns it) or as a one-line WALL the sheet parks by default.

### No external process harness is routed

super-bootstrap routes no external process harness. The §4 grep returns only the one
sanctioned class, and the shape check holds beside it — zero name-hits is not sufficient on
its own, since a stage chain renamed to harness-neutral words would still carry the foreign
decomposition. So no stage gates a card: the [thread
contract](../work/README.md#thread-contract) carries Design and Plan as conditional
context-scope sections, not default gates, and the unattended lane reads no stage at all.
The seeded runway names no harness (§6 above).

Two constraints bind future work:

- `autorun`'s admission is the one judgment in `shared/user-wall.md`, with no derived proxy
  beside it, so a change to what counts as needing the user lands there and nowhere else.
- A hit outside §4's one sanctioned class is a regression, whether it dispatches or only
  reads as prose.

**Vacating means naming the discipline and shipping nothing.** A card whose fix reads
"point at X instead" is mis-shaped whatever X is — re-pointing a routing line from one
foreign harness to another rebuilds the coupling de-routing removes.

## 7. Evidence index

Verification grades: **A** = literal text read; **B** = model-summarized fetch, claims
usable but not quotable; **C** = inferred, unverified.

**Dimension boundary.** The Internal table is a provenance index: each row records a
measurement taken on a moving artifact, so the read date is the only bound its validity has
and no other record holds it. Dates belong in that table, plus a version-bound pin where one
applies. Everything else in this doc is state prose — it carries no dates and no card
references.

### Internal

| Resource | Path | Grade | Measurement (2026-07-25) |
| --- | --- | --- | --- |
| superpowers install | `~/.claude/plugins/cache/claude-plugins-official/superpowers/6.2.0/` | A | 89 files / 1,105 KB; largest: `writing-skills` 104.9 KB, `brainstorming` 73.8 KB, `subagent-driven-development` 49.1 KB, `systematic-debugging` 39.8 KB |
| `using-superpowers` ambient injection | `<superpowers>/skills/using-superpowers/SKILL.md` | A | 3.0 KB, injected in full every session |
| super-bootstrap plugin source | `plugins/super-bootstrap/` | A | 55 files / 319 KB; `harness-bootstrap` 93.8 KB, `drain` 53 KB (SKILL 12.6 KB + 10 assets) — `drain` since replaced by `autorun` (SKILL + 5 assets) and the board renderer deleted |
| Ambient description weight | all 13 shipped `SKILL.md` frontmatter | A | 6,456 chars ≈ 1.6k tokens, present in every session |
| Foreign-name coupling | `plugins/super-bootstrap/**` | A | 85 occurrences / 19 files; skeleton holds 15 |
| Shipped workflow doctrine | `plugins/super-bootstrap/skills/harness-bootstrap/assets/harness.md` | A | Carries the routing table into every bootstrapped repo |

## 8. Downstream migration — what adopt mode does and does not cover

`harness-bootstrap` reads a repo's shape off the files present — fresh, split or legacy,
never off a version ([Phase 1 § Existing CLAUDE.md](../../plugins/super-bootstrap/skills/harness-bootstrap/SKILL.md)) —
and syncs each artifact by its ownership class:

- **The workflow doctrine is plugin-owned whole.** `.claude/rules/harness.md` is re-placed
  from the shipped asset as one file: current → no write; stale (the placed bytes equal the
  receipt's `placed` record and the asset differs) → silent copy; hand-edited → one
  overwrite-or-keep prompt. Between re-runs a plugin-owned SessionStart hook
  ([`runway-drift.sh`](../../plugins/super-bootstrap/hooks/runway-drift.sh)) advises when the
  placed file, or a placed hook script, differs in content from the shipped asset; in a
  legacy repo its one line names the re-run as the migration.
- **`CLAUDE.md` is project-owned whole.** It is seeded once from the skeleton and never
  drift-diffed. A re-run writes only the § Rules / § Planning line of an artifact a sync-report
  row names: it appends, re-points or drops a registration line, and it rewrites a placed doc
  rule's § Rules fires-on list on that bullet's own approved row. Every re-run compares the bullet
  against the rule's skeleton `paths:` entries, whether or not the rule file drifted.
- **Mixed-ownership docs keep the per-section lane** — techstack, overview, decisions,
  terminology, the work README and template, the doc rules. § Phase 2's per-artifact rule
  applies: missing → write; matches template → skip; **drifted → show diff, approve per
  change, write**; pipeline-owned section absent → `⊕ new`, approve, insert; project-owned →
  never touch; an artifact placed for the first time or deleted → a `registration:` row
  naming the consumer surfaces that enumerate it, edited in the same commit
  ([§ Registration rule](../../plugins/super-bootstrap/skills/harness-bootstrap/SKILL.md)).
  The drift check is produce-then-judge: one enumerated row per pipeline-owned section
  before any verdict.

| Migration shape | Covered? | Why |
| --- | --- | --- |
| Doctrine change of any shape — content changed within a section, a section added, a section dropped — in a **split** repo | **Yes** | The doctrine file is re-placed whole, so no section list is walked and no dropped section orphans |
| Doctrine change of any shape in a **legacy** repo (two or more doctrine headings still in `CLAUDE.md`, no `.claude/rules/harness.md`) | **Yes, on the user's confirm** | The run is the migration and nothing else ([§ Doctrine migration](../../plugins/super-bootstrap/skills/harness-bootstrap/SKILL.md)): the agent sorts every old `CLAUDE.md` line — shipped, old plugin text, the repo's own, project — and the user confirms the delta list before any write. Four mechanical checks gate the single commit: the placed file equals the asset, no doctrine heading is left in `CLAUDE.md`, every old line is kept or on the drop list the user saw, and no new broken link appears. The sorting is judgment and differs run to run; the confirm and the checks are the floor. A second run does the regular sync |
| A change to the `CLAUDE.md` skeleton | **Fresh bootstraps only** | The file is project-owned whole — seeded once, never diffed |
| Content changed **within** a retained section of a mixed-ownership doc | **Yes** | Section stays on the owned list; drift check fires and diffs it |
| A section **added** to a mixed-ownership skeleton after a consumer bootstrapped | **Yes** | The walk is skeleton-driven — the new section gets a `⊕ new` row; Block 2 approval-gates the insert |
| A whole section **dropped** from a mixed-ownership skeleton | **No** | The walk is skeleton-driven — a section no longer on the owned list is never visited, so it orphans in consumer repos |
| A placed artifact the plugin **retired** — a file (`AGENTS.md`) or a marker block (`<!-- harness-meta` in `docs/overview.md`) that [rename-map § Retired files](../../plugins/super-bootstrap/skills/harness-bootstrap/assets/rename-map.md#retired-files) lists | **Yes, on the user's confirm** | A re-run walks the list ([§ 2b Retired artifacts](../../plugins/super-bootstrap/skills/harness-bootstrap/SKILL.md)) and proposes each removal as a `⊘ removed` row; a file is removed only when its content is the plugin's text alone — one holding consumer-authored content is kept and named in the sync line |
| A scaffolded **folder** retired | **No** | Phase 2a states folders have only two states, missing or present ("create if missing, skip if present") — there is no removal path |

**Two retired pins have no removal path.** `.claude/settings.json` pins are on the owned
list, but § 2a treats a pin as missing or present, so a pin the plugin stops seeding stays
in a repo bootstrapped before the cut.

| Retired pin | Shape | Covered? |
| --- | --- | --- |
| `mattpocock-skills` paired pin removed from § 2a | `.claude/settings.json` pins are on the owned list, but 2a treats pins as missing-or-present with no removal path | **Fresh bootstraps only.** An already-bootstrapped consumer keeps the seeded key; it is inert once the plugin is uninstalled there, and clearing it is a hand-sweep |
| `superpowers` core pin removed from § Core plugin pin | `.claude/settings.json` pins are on the owned list, but 2a treats pins as missing-or-present with no removal path | **Fresh bootstraps only.** 2a never strips the pin from an already-bootstrapped repo, so removal there is a hand-sweep — which §6 permits, its de-routing resting on the dissolve test rather than on uninstalling anything |

**The folder hole is closed rather than accepted.** The rename to `docs/work/`
would otherwise strand every already-bootstrapped repo's specs and plans: the scans read
the new path only, so the old tree stays on disk and goes invisible. Phase 2a therefore
migrates before it creates — `git mv docs/superpowers docs/work` when the old tree is
present, contents moved directory by directory when both exist, collisions reported
rather than resolved. It is the one retired shape where adopt mode carries a removal path
rather than an orphan.
