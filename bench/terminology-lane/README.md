# bench/terminology-lane — RED fixture for the commit door's terminology lane

Test surface for the per-commit terminology lane: the `term-uses` verb of
[`commit/assets/doc-links.sh`](../../plugins/super-bootstrap/skills/commit/assets/doc-links.sh)
feeding candidates to the judgment in
[`commit/SKILL.md`](../../plugins/super-bootstrap/skills/commit/SKILL.md) §3/§4 and
[`agents/doc-sync-scan.md`](../../plugins/super-bootstrap/agents/doc-sync-scan.md) § Scan
step 7, judged with
[`link-predicate.md`](../../plugins/super-bootstrap/skills/check-docs-consistency/assets/link-predicate.md).
An edit to that wording, the verb, or the predicate re-runs here first.

The corpus is synthetic: `brindle`, a fictional proofing-cabinet controller. A judge
cannot answer from repo familiarity.

## Fixture

- `fixture/base/docs/` — the pre-image: `terminology.md` registers **Proof cycle**
  (`_Avoid_: rise run, bake run`) and **Hold** (`_Avoid_: freeze mode`);
  `operations.md` and `maintenance.md` link nothing.
- `fixture/change/docs/` — the post-image, copied over the base after its commit. Three
  planted cases on added lines:
  - (a) `operations.md` § Pausing — "The cabinet enters Hold: the cycle timer stops …":
    a substantive, unlinked use of **Hold**.
  - (b) `operations.md` — "Each rise run writes its humidity curve …": an `_Avoid_`
    word for **Proof cycle**.
  - (c) `maintenance.md` § Faults — "hold the reset button for five seconds": a verb
    homonym of **Hold**.

The mechanical lane prints all three (`term-uses` is a whole-word match with no
judgment); only the judgment separates (c).

## Running

`bash bench/terminology-lane/run.sh <dir> <control|arm>` builds the fixture at `<dir>`
(via `make-fixture.sh`), writes `<dir>.prompt.md`, and runs it headless rooted at the
fixture:
`claude -p --model sonnet --allowedTools Bash,Read,Grep,Glob --setting-sources project,local --permission-prompts none`.
The reply lands in `<dir>.out.txt`. Put `<dir>` outside this repo (a scratch folder).

- **control** — `commit/SKILL.md` and `agents/doc-sync-scan.md` at `CONTROL_REV`
  (the commit before the lane), embedded verbatim; `<skill-base>` is that revision's
  commit skill, exported beside the fixture.
- **arm** — the working-tree copies, embedded verbatim; `<skill-base>` is this
  checkout's commit skill. Copy under test: the in-repo dev copy, not the published
  plugin.

The prompt runs §1–§4 only and ends with `## Surfaced to the user`.

## Scoring

Read the `## Surfaced to the user` section of each reply.

- **Control** — RED holds when it surfaces none of (a), (b), (c) as a terminology item.
- **Arm** — pass when it surfaces (a) as a missing link to `docs/terminology.md`, (b) as
  "use the registered term Proof cycle", and nothing for (c). A stale-doc item on
  either file is a separate finding — read it by hand.

Runs: control ×1, arm ×3, at `sonnet` (the cold lane's tier).

Result at authoring (control ×1, arm ×3): control surfaced no terminology item — it
missed (a), and reported (b) as a stale-doc candidate to resolve before commit, not as
a non-blocking item. Arm 3/3 surfaced (a) as "link `docs/terminology.md`" and (b) as
"use the registered term Proof cycle", each with a card offer, and dropped (c) as a verb
homonym.
