# bench/terminology-rule — RED for the registered-term clause in `ssot-doc-link`

Test surface for the `Registered term` bullet in
[`assets/rules-ssot-doc-link-skeleton.md`](../../plugins/super-bootstrap/skills/harness-bootstrap/assets/rules-ssot-doc-link-skeleton.md)
§ Home selection (placed byte-identical at [`.claude/rules/ssot-doc-link.md`](../../.claude/rules/ssot-doc-link.md)):
`docs/terminology.md` is the home of every term it registers, a doc's first substantive use links it even where
another doc also explains the term, and an `_Avoid_` word is replaced by the registered term. Behavior-shaping prose
in a shipped asset, so it ships behind the [`skill-authoring`](../../.claude/rules/skill-authoring.md) RED floor.

## Fixture

A fictional recipe-scaling app.

- [`fixture/`](fixture/) — `docs/terminology.md` with three entries (`Batch`, `Pantry`, `Shortfall`), each with an
  `_Avoid_` line, and a blockquote header that itself states the link-on-first-use rule; `docs/overview.md`;
  `docs/specs/shopping-list.md` (the doc the task edits).
- [`fixture-b/`](fixture-b/) — overlay: `docs/specs/pantry.md`, a doc dedicated to the Pantry concept. Under the
  current rule's "the home is the doc dedicated to the concept", this competes with `docs/terminology.md`.
- [`fixture-c/`](fixture-c/) — overlay on b: `docs/terminology.md` without its header, so the home's own prose no
  longer tells the agent to link it — only the rule can.

## Run

[`run.sh`](run.sh) `<scratch-dir> <tag> <ref> [model]` — `VARIANT=a|b|c` (default `a`). Builds
`<scratch-dir>/<tag>/repo`, embeds the rule text verbatim in the prompt (`ref=HEAD` → `git show HEAD:.claude/rules/ssot-doc-link.md`,
the control; `ref=worktree` → the working-tree file, the arm), and runs
`claude -p --model sonnet --setting-sources project,local --permission-prompts none --allowedTools "Read,Edit,Write,Glob,Grep"`
with the repo as cwd. `--setting-sources project,local` is required: a user-level hook hangs headless runs.
The task asks for a `## Generation` section in `docs/specs/shopping-list.md` worded with the `_Avoid_` words
("recipe run", "deficit", "inventory"). Writes `runs/<tag>.prompt.md`, `.result.txt`, `.section.md` and
`.score.txt` (`terminology.md` link count, `pantry.md` link count, `_Avoid_` words left, registered terms used).

Pass a `<scratch-dir>` outside this repo.

## Pass condition

Arm: the section links `docs/terminology.md` for every registered term it uses (`links-pantry-spec: 0`) and leaves
no `_Avoid_` word. Control fails when it links the dedicated spec instead, or keeps an `_Avoid_` word.

## Readings (sonnet)

| Variant | Control (HEAD) | Arm (worktree) |
|---|---|---|
| a | 1/1 compliant — links terminology.md, no `_Avoid_` word | 2/2 compliant |
| b | 1/1 compliant | 2/2 compliant |
| c | 2/2 **fail** — `[Pantry](pantry.md)` | 2/2 compliant — `[Pantry](../terminology.md)` |

`_Avoid_` replacement did not discriminate: every run, control included, wrote the registered terms. The home-selection
half of the clause is what the arm earns, and only once the home's own header stops carrying the rule (variant c).
