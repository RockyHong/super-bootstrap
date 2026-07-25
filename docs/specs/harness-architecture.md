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
| Entry selection (routing) | **absent** | `ask-matt` (owns its own) | Cluster table (built to fill superpowers' gap) |
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

| Component | Outcome |
| --- | --- |
| Cluster routing table (7 clusters, 6 naming superpowers entries) | dead |
| "Inside a route — run it whole" | dead |
| `docs/superpowers/specs\|plans/` | dead (that is superpowers' artifact shape) |
| `docs/specs/superpowers-topology.md` | dead |
| Dispatch § SDD carve-out | dead |
| drain's stage machine (`raw→triage→plan→execute→review`) | half-dead (stage names are superpowers' phases) |
| **log / backlog / triage / commit / doc-sync / rules** | **unaffected** |

mattpocock ships `ask-matt` — a router over his own user-invoked skills — so the gap
that forced our routing layer does not exist for him. Building one anyway would create
a second routing authority over the same objects.

His skills are additionally designed against being driven: a user-invoked skill may
invoke model-invoked skills but never another user-invoked one, and `implement` carries
`disable-model-invocation: true`.

## 4. The seam: runtime-orthogonal, setup-time-composed

**Runtime.** super-bootstrap names zero foreign skills. This is grep-verifiable, not a
policy: `rg 'superpowers|systematic-debugging|brainstorming|writing-plans'` over
`plugins/super-bootstrap/` returns zero. Current count: **85 occurrences across 19
files** (verified 2026-07-25), of which `harness-bootstrap/assets/claude-md-skeleton.md`
holds 15 — meaning every downstream repo bootstrapped by this plugin carries the routing
table in its own CLAUDE.md. **Downstream migration is part of the change's closure.**

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

**Known weakness of this seam:** the socket is prose, not schema — "ask the user to
describe the workflow" produces free-form text his skills interpret. Documented seams
drift. This is the accepted cost of orthogonality over driving.

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

The one discipline superpowers holds that mattpocock has no independent equivalent for
is **verification-before-completion** (evidence before claiming done, across all
surfaces — not just tests). It is a behavioral rule, not a pipeline stage, so it belongs
in this layer.

## 6. Decided vs open

**Decided — de-routing (change A).** super-bootstrap stops routing any external process
harness. This does not depend on which harness wins; it follows from §3's dissolve test.
superpowers may stay installed — it simply stops being routed.

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
2. Downstream migration path for repos already carrying the routing skeleton.
   `harness-bootstrap` documents an adopt mode that "retires superseded harness forks on
   re-run" — sufficiency unverified.
3. drain's wall-vs-progress ratio — unmeasured (§6).
