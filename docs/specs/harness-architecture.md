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

| Slot | superpowers | super-bootstrap |
| --- | --- | --- |
| Procedure / discipline | owns | — |
| Alignment / elicitation | `brainstorming` | — |
| Shared language | — | — |
| Entry selection (routing) | **absent** | Cluster table — **shape recognition, not entry routing**; rows name disciplines a harness would otherwise supply |
| Fast capture | — | **`/super-bootstrap:log`** |
| Standing work state | — | **`docs/work/` cards** (the opt-in scale module adds `docs/parked.md` / `docs/test-queue.md` / `docs/outward/` beside them) |
| Per-feature work order | temporal specs/plans | the card's `## Design` / `## Plan` blocks |
| Propagation gate | — | **doc-sync** |
| Cold-start data map | — | `overview` + `techstack` + `decisions` |
| Awareness wiring | full-body ambient injection | **path-scoped rules (`paths:` frontmatter)** |
| Parallel throughput | — | **drain** |
| Product anchor (problem / user / ICP / G2M) | — | **`overview.md` Problem / User** |

**Four slots are uncontested:** fast capture, propagation gate, parallel throughput,
product anchor. Awareness wiring is contested but the mechanisms differ in kind — see §5.

**The product-anchor slot is unbuilt on the process-harness side, by design not
oversight.** A process harness addresses the engineer standing in a codebase, and a
codebase answers *solution*; product truth — ICP, problem statement, market — is not the
engineer's to own. There is nothing there to defer to and no coverage claim to test.

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
| `harness-bootstrap` § Core plugin pin — `superpowers` as a **locked** core dep | Dead *as core* — the pin's own justification was name-backing ("if CLAUDE.md names a skill that isn't installed, the trigger rule misfires silently"), and the names are gone. superpowers is pinned by nothing, and neither is any other process harness — the slot is filled by whichever one a repo takes as an ordinary adaptive pick in `resolve-plugins`. |
| The temporal work folder | **Ours**, at `docs/work/`. No process harness owns that slot at a fixed path — artifact skills publish to whatever tracker a repo declares — so there was no slot to defer to. |
| drain's stage machine (`raw→triage→plan→execute→review`) | **Dead as a stage chain, drain live** — the per-phase command dispatch was distillation-shaped; drain now spawns one scoped-brief session per item (anchor + breadcrumb rendered from the card thread), running drain-till-wall with typed walls (`user`\|`shape`). Stage vocabulary `aimed`/`executing` keys entry only. |
| **log / cards / commit / doc-sync / rules** | **Unaffected.** |
| `skills/triage/SKILL.md` + `agents/triage.md` — investigation doctrine | Referent dead, **discipline live**: the clause is stated inline, naming no harness. The pointer never resolved even where superpowers is installed — the agent's tool list carries no `Skill`. |

**The cluster routing table survives the dissolve whole** — rows 1–3 restated as inline disciplines, the rest already harness-neutral. Its real function is
sizing ceremony to shape, and that is harness-independent: clusters 5 and 6 say "no
ceremony", 7 routes harness edits, 8 routes triage to our own door, and 1–3 name the
disciplines a process harness would otherwise supply. Deleting rows rather than restating
them would have dropped verified-load-bearing prose — [`docs/decisions.md`](../decisions.md)
records a pressure test where the [route line](../../CLAUDE.md#cluster-routing) alone sent a
runtime-symptom bug to the triage lane in 2/2 control runs.

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
`/execute-plan` — the form a live dispatch actually takes, and the form that survived the
skeleton cut unseen. `mattpocock` and `matt-pocock` are separate alternates for the same
reason: neither spelling matches the other, and mattpocock's setup command uses the
hyphenated one.

**One hit class is sanctioned. It routes nothing.**

- **Historical** — `harness-bootstrap` must keep matching pre-rename spellings it reads out
  of an already-bootstrapped repo: the `chore: scaffold|sync superpowers pipeline` commit
  strings its mature-repo detector greps, and the `docs/superpowers/` folder its Phase 2a
  migration moves to `docs/work/`. Dropping the first makes every existing consumer read as
  never-bootstrapped; dropping the second strands its old tree on disk (§8).

The `mattpocock|matt-pocock|ask-matt|grill-me|grill-with-docs|to-spec|to-tickets|wayfinder`
alternates carry no sanctioned hit at all — they stay in the pattern as the standing
regression guard for a pairing this repo once shipped and has since removed.

A hit outside that class is a regression — the pattern catches a live command
referent whether it dispatches (a subprocess phase prompt) or only reads as prose, and
prose that seeds through the capture funnel carries the referent into every consumer repo's
own card set, where it outlives the cut.

The folder shape is gone: `docs/superpowers/` is now `docs/work/`. Phase 2a scaffolds
`README.md` + `TEMPLATE.md`; cards land flat beside them as work is logged. The
naming rides the same path — skill `description:`, the runway intro, the emitted commit
strings, and the pipeline-family `tags:` keyword are all harness-neutral, so a consumer
re-bootstrapping migrates in one run.

## 5. Awareness wiring is the strongest uncontested position

Docs existing ≠ the agent attending to them. The two systems solve this differently:

| System | Mechanism | Ambient cost | Grain |
| --- | --- | --- | --- |
| superpowers | full skill body injected every session | highest | none (global) |
| super-bootstrap | `.claude/rules/*.md` with `paths:` frontmatter — full body fires when a matching file is read | **zero when irrelevant** | **decision moment** |

[Path-scoped rules](../../CLAUDE.md#rules-auto-load-on-file-match) bind to **file paths, not
skill names**, so this slot is orthogonal by construction — it needs no change when the
process harness is swapped or removed.

### The fences stay ambient — the cut is a rename, not a relocation

De-routing removes routing, not discipline. Four laws named in `CLAUDE.md` § The envelope
(`test-driven-development`, `verification-before-completion`, `receiving-code-review`,
`dispatching-parallel-agents`) are superpowers skill names (the pre-cut state, superseded by
the shipped [§ The envelope](../../CLAUDE.md#the-envelope), which binds and names three
declared disciplines), and § Coding Principles carries a fifth fence — the coding standard.
Where they land is settled by the rules layer's own firing mechanism, not by preference.

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
because [§ Dispatch](../../CLAUDE.md#dispatch--who-holds-each-phase) is its single home (VII).
The rejected rules-layer direction is recorded in [`docs/decisions.md`](../decisions.md) so it
is not re-proposed.

**What the compression costs — answered for the review law.** Each named skill carried a full
body that loaded at its fire moment; a one-liner does not. `Verify before claiming` plausibly
compresses without loss; `Review received, not absorbed` did not — the repo authors its own
discipline body for it: the `review-intake` agent, with § Dispatch routing judgment-grade
findings through it before any implementer. The answer was never a rule glob (closed above).

### § Coding Principles is a different concern, riding Wave 1 by name-adjacency

§3's dissolve test does not list this slot. A coding standard is a **standards** concern,
not a process harness, so de-routing does not touch it. Its own problem stands separately:
a standard bound to one skill invocation is invisible to any reviewer not running that
skill.

An in-repo file carries no such binding, and duplicates no body that lives upstream — so
the parallel-truth constraint (VII) that rules against copying a foreign skill's content
into `CODING_STANDARDS.md` never binds the file itself.

**Shipped:** the ambient slot keeps its fire moment ("before writing, reviewing, or
refactoring code") and names `CODING_STANDARDS.md` as the standard — no pinned default
behind it. `harness-bootstrap` scaffolds the file headings-only, so a concern no section
declares is left to default judgment. The ambient line is the guaranteed reader that
carries the file to every code touch.

The slot routes three ways, so a convention has one home: binding with no clean file glob →
`CODING_STANDARDS.md`, hand-recorded when a review or commit settles it (the file is outside
the doc-sync surface); binding within a path glob → `.claude/rules/<scope>.md`; descriptive —
how the code is written, observed rather than mandated →
[`docs/techstack.md` § Coding Patterns](../techstack.md#coding-patterns), reference read on
demand, never a standard.

Dispatch doctrine came through intact: of CLAUDE.md § Dispatch's bullets, only the
"build inside a superpowers chain → that chain's executor governs" clause was coupled, and
it is cut. The rest — closure-judged inline-vs-dispatch, per-phase build dispatch,
transcription is not a build, review findings gated through `review-intake`, parallel within
a phase not across, writer run mode keyed on path overlap — are harness-agnostic, and the cut
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

**Decided — the seeded runway names no harness.** The seeded `CLAUDE.md` and every
scaffolded doc state disciplines, never skill entries; § The envelope carries no
install pointer — the `resolve-plugins` skill description names the process-harness case, and
the rationale lives here, not ambient. Bootstrap seeds the core self-pin and nothing
else: no seeded prose stands on a foreign harness, which is why taking or dropping one
costs no doc change.

**Decided — no process harness is paired or pinned (change B, reversed).** super-bootstrap
seeds one pin, its own. A process harness is an ordinary `/super-bootstrap:resolve-plugins`
candidate a repo takes or leaves, on separate axes from sb's slots (§2), and no sb door
routes one. The pairing this repo shipped and then removed on a zero-usage read-out is a
closed fork in [`docs/decisions.md`](../decisions.md).

**Resolved — drain's anchor.** drain's own doc names its ceiling: "Capacity
ceiling = how many halts the user can resolve, not machine throughput." The
classification below settles the shape question without measurement: dependency-ordered
elicitation never enters drain — the `Discuss` intent excludes it at admission — and
every halt drain actually produces (surface verdict, pre-build wall check, merge gate)
is a one-shot framed decision the user can batch. `intent == Cloud` was a proxy for
"verification-shaped": the gate was sound and mis-named. Admission now scores the next
phase only and the session runs drain-till-wall with typed walls (`user`|`shape`). The
wall-vs-progress *ratio* stays unmeasured — cheap to instrument if batch-review load
grows.

*The classification.* Human gates split by whether the human's answer changes the next
question:

| Gate shape | Mechanism | Parallelizable |
| --- | --- | --- |
| **Elicitation** — design settling, dependency-ordered questioning | question N+1 does not exist until answer N | **No** — batching destroys the mechanism |
| **Verification** — approve a finished diff, land a commit | the N checks are independent | **Yes** |

drain is sound over verification-shaped halts and becomes engagement-monitoring exactly
where it fans out elicitation-shaped work, because each halt then costs a design
conversation the human cannot hold N of concurrently. The halt audit found no
elicitation-shaped halt inside drain's lane — design settling walls out at admission or
via the typed `user` wall, one-shot per item.

### Change A is complete

super-bootstrap routes no external process harness. The §4 grep returns only the one
sanctioned class, and the shape check holds beside it — zero name-hits was never
sufficient on its own, since a stage chain renamed to harness-neutral words would still
carry the foreign decomposition. The per-slot audit confirmed that risk was real:
the staging ceremony (Design/Plan as default gates) was distillation residue — the [thread
contract](../work/README.md#thread-contract) now carries them as conditional context-scope
sections, and drain's stage set re-derives from grounding-native artifacts. The seeded runway
names no harness (§6 above).

Two constraints outlive the change:

- Retiring the cloud-safe derivation must replace drain's admission predicate
  (`eligibility.md` Cloud-gate fallback) in the same change — without the venue map
  `intent == Cloud` is drain's whole admission gate (the intent lane guards — `Harness`,
  `Discuss` — sit in front of it either way).
- A hit outside §4's one sanctioned class is a regression, whether it dispatches or only
  reads as prose.

**Vacating means naming the discipline and shipping nothing.** A card whose fix reads
"point at X instead" is mis-shaped whatever X is — re-pointing a routing line from one
foreign harness to another rebuilds the coupling change A paid to remove.

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
| super-bootstrap plugin source | `plugins/super-bootstrap/` | A | 55 files / 319 KB; `harness-bootstrap` 93.8 KB, `drain` 53 KB (SKILL 12.6 KB + 10 assets) |
| Ambient description weight | all 13 shipped `SKILL.md` frontmatter | A | 6,456 chars ≈ 1.6k tokens, present in every session |
| Foreign-name coupling | `plugins/super-bootstrap/**` | A | 85 occurrences / 19 files; skeleton holds 15 |
| todo dispatch-lane driver cost | `agents/todo.md` | A | ~33.5k subagent tokens / ~197 s for a 3-row board; ~34.3k / ~226 s for 4 rows. Measures the agent dispatch, since demoted to the script-failure fallback — the primary render is the bundled `render-board.py` (zero model tokens) |
| Shipped CLAUDE.md skeleton | `plugins/super-bootstrap/skills/harness-bootstrap/assets/claude-md-skeleton.md` | A | Carries the routing table into every bootstrapped repo |

## 8. Downstream migration — what adopt mode does and does not cover

`harness-bootstrap` § Phase 2 applies a per-artifact rule: missing → write; matches
template → skip; **drifted → show diff, approve per change, write**; pipeline-owned
section absent → `⊕ new`, approve, insert; project-owned → never touch; an artifact
placed for the first time or deleted → a `registration:` row naming the consumer surfaces
that enumerate it, edited in the same commit ([§ Registration rule](../../plugins/super-bootstrap/skills/harness-bootstrap/SKILL.md)). Its CLAUDE.md
coverage is **keyed to a named section list** (Development
Workflow, Dispatch, Doc Sync, Coding Principles, Edit Discipline, Context Hygiene,
Finding Triage, Rules, Git Notes, Planning).

| Migration shape | Covered? | Why |
| --- | --- | --- |
| Content removed **within** a retained section | **Yes** | Section stays on the owned list; drift check fires and diffs it |
| A section **added** to the skeleton after a consumer bootstrapped | **Yes** | The walk is skeleton-driven — the new section gets a `⊕ new` row; Block 2 approval-gates the insert |
| A whole section **dropped** from the skeleton | **No** | The walk is skeleton-driven — a section no longer on the owned list is never visited, so it orphans in consumer repos |
| A scaffolded **folder** retired | **No** | Phase 2a states folders have only two states, missing or present ("create if missing, skip if present") — there is no removal path |

**The skeleton cut landed inside covered shapes.** No section was dropped, so nothing
orphans — `§ Inside a route` was a `###` subsection under § Development Workflow, which stays
on the owned list.

| Cut site (landed) | Shape | Covered? |
| --- | --- | --- |
| Routing rows restated, "inside a route" removed, SDD clause cut, ambient-laws line rewritten | content changed within § Development Workflow / § Dispatch (both on the owned list) | Yes |
| Topology doc deleted | repo-local; the shipped skeleton never referenced it (zero grep hits) | N/A downstream |
| § Coding Principles body replaced | section retained on the owned list | Yes |
| triage lane's doctrine clause restated inline | `plugins/super-bootstrap/**` ships with the plugin, never scaffolded into a consumer repo | N/A downstream |
| todo lane's `brainstorm` vocabulary renamed + `/brainstorm` empty-state door repointed | same — `shared/`, `agents/`, `skills/todo/` all ship with the plugin | N/A downstream |
| `mattpocock-skills` paired pin removed from § 2a | `.claude/settings.json` pins are on the owned list, but 2a treats pins as missing-or-present with no removal path | **Fresh bootstraps only.** An already-bootstrapped consumer keeps the seeded key; it is inert once the plugin is uninstalled there, and clearing it is a hand-sweep |
| `superpowers` core pin removed from § Core plugin pin | `.claude/settings.json` pins are on the owned list, but 2a treats pins as missing-or-present with no removal path | **Fresh bootstraps only.** 2a never strips the pin from an already-bootstrapped repo, so removal there is a hand-sweep — which §6 permits, its de-routing resting on the dissolve test rather than on uninstalling anything |

**The folder hole is closed rather than accepted.** The rename to `docs/work/`
would otherwise strand every already-bootstrapped repo's specs and plans: the scans read
the new path only, so the old tree stays on disk and goes invisible. Phase 2a therefore
migrates before it creates — `git mv docs/superpowers docs/work` when the old tree is
present, contents moved directory by directory when both exist, collisions reported
rather than resolved. This is the one cut where adopt mode gained a removal path instead
of documenting an orphan.
