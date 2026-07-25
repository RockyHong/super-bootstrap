# Harness Architecture — What super-bootstrap Owns, and Where the Seam Falls

**Scope.** This doc owns the concern map: which slots super-bootstrap occupies, which
it delegates, and the mechanism at the boundary. It is the grounding artifact for the
de-routing work — a cold reader should be able to act on the backlog cards without
reconstructing the analysis.

Companion docs: [`docs/overview.md`](../overview.md) (product context),
[`docs/techstack.md`](../techstack.md) (stack + architecture rules),
[`docs/decisions.md`](../decisions.md) (closed forks),
[`docs/backlog.md`](../backlog.md) (open cards).

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
| Standing work state | — | defers to a real tracker | **`docs/backlog.md`** |
| Per-feature work order | temporal specs/plans | `to-tickets` → `.scratch/<feature>/issues/NN-slug.md` | `docs/superpowers/plans/` |
| Propagation gate | — | — | **doc-sync** |
| Cold-start data map | — | `CONTEXT.md` + `docs/adr/` | `overview` + `techstack` + `decisions` |
| Awareness wiring | full-body ambient injection | static `## Agent skills` pointers in CLAUDE.md | **path-scoped rules (`paths:` frontmatter)** |
| Parallel throughput | — | — | **drain** |

**Three slots are uncontested:** fast capture, propagation gate, parallel throughput.
Awareness wiring is contested but the mechanisms differ in kind — see §4.

## 3. The routing layer is coupling cost, not capability

super-bootstrap's routing layer exists because superpowers ships entry points without
an entry rule. Filling another container's missing boundary made super-bootstrap
inseparable from it.

**Dissolve test — remove superpowers, and these lose their referent:**

| Component | Outcome | Cut |
| --- | --- | --- |
| Cluster routing table — rows 1 / 2 / 3 (`systematic-debugging` / `brainstorming` / `writing-plans`) | referent dead, **discipline live** | **landed** — rows restated as disciplines (root cause before fix · settle the design · write the sequence), naming no harness |
| Cluster routing table — rows 5 / 6 / 7 / 8 (inline tweak · docs · harness edit · triage lane) | **live** — harness-neutral already; row 8 routes to our own `/super-bootstrap:triage` | untouched |
| Cluster routing table — row 4 (refactor) | live — its "multi-step → cluster 3" pointer now targets a discipline, not a skill | untouched |
| "Inside a route — run it whole" | dead | **landed** — section removed |
| Dispatch § SDD carve-out — the "chain's executor governs" clause | dead | **landed** — clause removed; the bullet's commit-door mechanics are harness-agnostic and stayed |
| § The envelope ambient-laws line (4 skill names) | referent dead, **discipline live** | **landed** — three declared laws inline; `dispatching-parallel-agents` cut as a duplicate of § Dispatch |
| `docs/specs/superpowers-topology.md` | dead | **landed** — deleted |
| `harness-bootstrap` § Core plugin pins — `superpowers` as a **locked** core dep | dead *as core*: the pin's own stated justification is name-backing ("if CLAUDE.md names a skill that isn't installed, the trigger rule misfires silently"), and the names go | **landed** — unpinned in `harness-bootstrap` 2a and delocked in `resolve-plugins` Phase 4; a process harness is now an ordinary adaptive pick |
| `docs/superpowers/specs\|plans/` | dead (that is superpowers' artifact shape) | open — `DEBT-026` |
| drain's stage machine (`raw→triage→plan→execute→review`) | half-dead (stage names are superpowers' phases) | open — `DEBT-028` |
| **log / backlog / commit / doc-sync / rules** | **unaffected** | — |
| `skills/triage/SKILL.md` + `agents/triage.md` — `Doctrine = superpowers:systematic-debugging` | **coupled, not unaffected** (cold audit 2026-07-26 corrected an earlier "triage unaffected" reading): cluster row 8 routes to `/super-bootstrap:triage`, and the shipped skill's description plus the agent body name the foreign skill as their investigation doctrine — so a de-routed repo without superpowers installed hits a dangling doctrine reference | open — `DEBT-031` |

**The table was 8 rows and all 8 survive** — three of them restated. Its real function is
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

**Runtime.** The target state is that super-bootstrap names zero foreign skills. This is
grep-verifiable, not a policy: `rg 'superpowers|systematic-debugging|brainstorming|writing-plans'`
over `plugins/super-bootstrap/` should return zero.

**Where it stands (2026-07-26, after the skeleton cut).** The shipped CLAUDE.md skeleton
names **no skill** — its remaining 8 hits (down from 15 on this pattern) are all
`docs/superpowers/**` path strings, owned by `DEBT-026`. Every surviving hit repo-wide is
now a path string, a naming string, or a consumer of the folder shape:

| Remaining site | Kind | Owner |
| --- | --- | --- |
| `docs/superpowers/**` path strings (widest set, incl. 11 in `harness-bootstrap/SKILL.md`) | folder shape | `DEBT-026` |
| `harness-bootstrap/SKILL.md` `description:` + intro ("generic superpowers runway") | naming | `DEBT-026` |
| `harness-bootstrap/SKILL.md` `chore: scaffold\|sync superpowers pipeline` commit strings | naming **+ detector** | `DEBT-026` |
| `agents/todo.md`, `agents/triage.md`, `shared/classify-actionable.md`, `skills/drain/**`, `skills/todo/SKILL.md` | folder-shape consumers | `DEBT-026` / `DEBT-027` / `DEBT-028` |
| `skills/resolve-plugins/**` (harness-active marker + one example pick) | folder shape / illustrative | `DEBT-026` |

The commit strings are deliberately **not** renamed here: they double as the mature-repo
bootstrap detector (§ Special case), so renaming them separately from the folder would force
two detection-list migrations instead of one.

**Setup-time.** Composition happens through mattpocock's own declared socket. His
`/setup-matt-pocock-skills` presents these issue-tracker options verbatim:

> **GitHub** — issues live in the repo's GitHub Issues (uses the `gh` CLI)
> **GitLab** — issues live in the repo's GitLab Issues (uses the [`glab`](https://gitlab.com/gitlab-org/cli) CLI)
> **Local markdown** — issues live as files under `.scratch/<feature>/` in this repo
> **Other** (Jira, Linear, etc.) — ask the user to describe the workflow

He ships seed templates for the first three (`issue-tracker-github.md`,
`issue-tracker-gitlab.md`, `issue-tracker-local.md`) but **none for "Other"** — that
branch is authored fresh. So super-bootstrap can ship its own seed for that slot,
declaring `docs/backlog.md` + `/super-bootstrap:log` as the repo's tracker. His
`to-spec` and `triage` then write into our home.

**Known weakness of this seam — worse than "prose, not schema".** His setup reads its
seed templates from his own skill folder and has no lookup path to a seed another plugin
ships, so shipping a seed connects to nothing on its own. The shape that could work is
bootstrap pre-writing `docs/agents/issue-tracker.md` so his setup finds it already
present — **whether his setup skips an existing file is unread.**

Two further questions ride the same decision and want one deliberation, not three
tickets: whether provisioning is automatic at bootstrap or a `resolve-plugins`
recommendation behind a confirm (a product default, not an implementation detail), and
whether wiring anything mattpocock-shaped into bootstrap presupposes change B, which §6
leaves open. **`GAP-038` is therefore not executable as its title reads.** Nothing in
`plugins/super-bootstrap/` references mattpocock today (verified 2026-07-25, zero hits);
bootstrap behavior is unchanged.

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
line each, no external referent — test-first, verify-before-claiming,
review-received-not-absorbed. The fourth (`dispatching-parallel-agents`) is cut outright,
because § Dispatch is its single home (VII). The rejected rules-layer direction is recorded
in [`docs/decisions.md`](../decisions.md) so it is not re-proposed.

**What the compression costs is open.** Each named skill carried a full body that loaded at
its fire moment; a one-liner does not. `Verify before claiming` plausibly compresses without
loss, `Review received, not absorbed` does not. `DEBT-032` holds that question — the answer is
not a rule glob (closed above) but whether the repo authors its own discipline bodies.

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

Dispatch doctrine came through intact: of CLAUDE.md § Dispatch's six bullets, only the
"build inside a superpowers chain → that chain's executor governs" clause was coupled, and
it is cut. The other five — closure-judged inline-vs-dispatch, per-phase build dispatch,
transcription is not a build, parallel within a phase not across, create-new-file dispatches
foreground — are harness-agnostic and untouched, and the cut bullet's own commit-door
mechanics survive under a harness-neutral heading.

## 6. Decided vs open

**Decided — de-routing (change A).** super-bootstrap stops routing any external process
harness. This does not depend on which harness wins; it follows from §3's dissolve test.
superpowers may stay installed — it simply stops being routed.

*De-routing rests on the dissolve test alone, not on a measurement.* The de-routed state
is not a bare run — CLAUDE.md minus its routing sections, ~1.6k tokens of skill
descriptions, the path-scoped rules, and the log / backlog / doc-sync / commit doors all
remain. Removing the routing layer gives a clean reading of **that layer's** cost and
nothing wider; it does not test whether the harness as a whole helps or hurts. Most of
what such a test would report is static arithmetic anyway (ambient token count, per-board
cost); the part that is not — omission rate — needs controlled runs this repo has no
apparatus for.

**Open — harness swap (change B).** Whether to move from superpowers to
mattpocock/skills. Depends on evidence graded second-hand in §7.

**Open — drain's anchor.** drain's own doc names its ceiling: "Capacity ceiling = how
many halts the user can resolve, not machine throughput." Whether parallel spawns
produce net progress or net walls is unmeasured. This determines whether drain survives
at 53 KB, shrinks, or goes.

## 7. Evidence index

Verification grades: **A** = literal text read; **B** = model-summarized fetch, claims
usable but not quotable; **C** = inferred, unverified.

### External

| Resource | URL | Grade | Notes |
| --- | --- | --- | --- |
| mattpocock/skills README | `https://raw.githubusercontent.com/mattpocock/skills/main/README.md` | A | Full text retrieved; philosophy + skill index + the user-invoked/model-invoked composition rule |
| `setup-matt-pocock-skills` issue-tracker options | `.../skills/engineering/setup-matt-pocock-skills/SKILL.md` | **A** | Option list + CLAUDE.md block quoted verbatim (2026-07-25). Seed-template filenames confirmed; **template bodies not read** |
| `tdd` | `.../skills/engineering/tdd/SKILL.md` | B | Seam-confirmation gate, three forbidden anti-patterns, vertical-slice rule |
| `code-review` | `.../skills/engineering/code-review/SKILL.md` | B | Two-axis parallel subagents, Fowler ch.3 baseline, `CODING_STANDARDS.md` lookup |
| `to-tickets` | `.../skills/engineering/to-tickets/SKILL.md` | B | `.scratch/<feature-slug>/issues/<NN>-<slug>.md`, `Blocked by:` field |
| `to-spec` | `.../skills/engineering/to-spec/SKILL.md` | B | Publishes to tracker; no interview; publication format unconfirmed |
| `triage` | `.../skills/engineering/triage/SKILL.md` | B | Label state machine: `needs-triage → needs-info → ready-for-agent \| ready-for-human \| wontfix` |
| `wayfinder` | `.../skills/engineering/wayfinder/SKILL.md` | B | Map issue + child decision tickets; one ticket per session |
| `writing-great-skills` | `.../skills/productivity/writing-great-skills/SKILL.md` | B | Predictability as root virtue; split-only-when-the-cut-earns-it |
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

### Open questions blocking change B

1. mattpocock seed-template bodies (`issue-tracker-*.md`) unread — shape of the file we
   would author for the "Other" branch is inferred.
2. drain's wall-vs-progress ratio — unmeasured (§6).
3. Whether mattpocock's dispatch posture is "session as atomic runner" or something
   narrower. His `code-review` does run two axes as parallel `general-purpose`
   sub-agents, with no model tier pinned — so the rationale reads as **dispatch for
   isolation** (keeping one review axis from masking the other) rather than dispatch for
   attention offload. Grade B; the distinction matters for whether our own
   tier-pinned-agent pattern is sound, and warrants reading his repo properly rather than
   inferring from skill summaries.

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
| `superpowers` core pin removed from § Core plugin pins | `.claude/settings.json` pins are on the owned list, but 2a treats pins as missing-or-present with no removal path | **Fresh bootstraps only.** Already-bootstrapped repos keep the pin — superpowers stays installed where it is, which §6 permits |

**DEBT-026 is the exception:** retiring `docs/superpowers/specs|plans/` hits the folder
hole, so downstream repos keep orphaned directories that `/super-bootstrap:todo` and
`drain` still scan. That card carries its own migration mechanism or accepts the orphan.
