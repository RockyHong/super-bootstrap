# bench/terminology-register — RED fixture for the doc-sync term-registration step

Test surface for the write side of `docs/terminology.md`: the register step of the
doc-sync judgment —
[`agents/doc-sync-scan.md`](../../plugins/super-bootstrap/agents/doc-sync-scan.md) § Scan
step 8 and its `register` output, resolved by
[`commit/SKILL.md`](../../plugins/super-bootstrap/skills/commit/SKILL.md) §4. An edit to
that wording re-runs here first. The read side has its own bench:
[`terminology-lane/`](../terminology-lane/README.md).

The corpus is the same synthetic `brindle` proofing-cabinet controller, so a judge cannot
answer from repo familiarity.

## Fixture

- `fixture/base/docs/` — the pre-image: `terminology.md` registers **Proof cycle**
  (`_Avoid_: rise run, bake run`) and **Hold** (`_Avoid_: freeze mode`).
- `fixture/recall/docs/operations.md` — post-image for the recall case. Two planted
  findings on added lines:
  - (a) § Power loss — "the cabinet starts a recovery ramp: it climbs back to the
    recipe's set points at no more than 2 °C per minute …": a project concept, defined
    and leaned on, with no entry.
  - (b) § Line backup — "The cabinet drops into standby: the timer stops while
    temperature and humidity stay at their set points": a second word for **Hold**, not
    on its `_Avoid_` line.
- `fixture/precision/docs/maintenance.md` — post-image for the precision case: a
  § Firmware section dense with general words (MQTT, exponential backoff, cache, webhook,
  JSON log), a command (`make flash PORT=/dev/ttyUSB0`), a path (`config/cabinet.toml`)
  and a doc name (`docs/operations.md`). None is a term.

## Running

`bash bench/terminology-register/run.sh <dir> <control|arm> <recall|precision> [model]`
builds the fixture at `<dir>` (via `make-fixture.sh`), writes `<dir>.prompt.md`, and runs
it headless rooted at the fixture:
`claude -p --model <model> --allowedTools Bash,Read,Grep,Glob --setting-sources project,local --permission-prompts none`
(model default `sonnet`). The reply lands in `<dir>.out.txt`. Put `<dir>` outside this
repo (a scratch folder). The fixture's base commit is built with plumbing
(`write-tree` + `commit-tree` + `update-ref`), so a dispatched builder can run the script.

- **control** — `commit/SKILL.md` and `agents/doc-sync-scan.md` at `CONTROL_REV`
  (the commit before the register step), embedded verbatim.
- **arm** — the working-tree copies, embedded verbatim. Copy under test: the in-repo dev
  copy, not the published plugin.

The prompt runs §1–§4 only and ends with `## Surfaced to the user`.

## Scoring

Read the `## Surfaced to the user` section of each reply.

- **Recall, control** — RED holds when it proposes no `docs/terminology.md` entry for (a).
- **Recall, arm** — pass when it surfaces a register item for (a) with a proposed
  `**Recovery ramp**:` entry, and one for (b) proposing `standby` on **Hold**'s `_Avoid_`
  line, each as a register / skip choice.
- **Precision, arm** — pass when it surfaces no register item. A stale-doc item (the
  `docs/operations.md` pointer has no panel layout) is a separate finding.

Result at authoring (control ×2 per case at sonnet; arm ×2 per case at sonnet + ×1 at
haiku): control proposed no entry for (a) in 2/2 and offered no register item at all — it
flagged (b) spontaneously as "use Hold", with no `_Avoid_` addition. A first arm wording
that excluded "general programming or domain" words and dropped items on doubt found (b)
3/3 but (a) only 1/3: the judge read "recovery ramp" as ordinary vocabulary. The shipped
wording — a name the diff gives to the project's own state, mode, step or artifact is a
term even when built from ordinary words — found (a) and (b) 3/3, and the precision case
surfaced no register item 3/3.
