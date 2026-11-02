# bench/volatile-id-citation — RED for Route 5 in `dimension-discipline`

Test surface for Route 5 in
[`assets/rules-dimension-discipline-skeleton.md`](../../plugins/super-bootstrap/skills/harness-bootstrap/assets/rules-dimension-discipline-skeleton.md)
§ Route (placed byte-identical at [`.claude/rules/dimension-discipline.md`](../../.claude/rules/dimension-discipline.md)):
a durable doc states the limitation present-tense, and the volatile item cites the doc. Behavior-shaping prose in a
shipped asset, so it ships behind the [`skill-authoring`](../../.claude/rules/skill-authoring.md) RED floor. The
ID half alone is decidable: `doc-links.sh volatile-ids` checks it, tested in [`bench/doc-links/`](../doc-links/README.md).

## Fixture

A fictional photo backup service. [`fixture/`](fixture/) holds `docs/overview.md`, `docs/specs/upload.md` (the state
doc the task edits) and a live card, `docs/work/BUG-q7m2.md`, beside that folder's standing `README.md`.

## Run

[`run.sh`](run.sh) `<scratch-dir> <tag> <ref> [model]`. Builds `<scratch-dir>/<tag>/repo`, embeds the rule text verbatim
in the prompt (`ref=HEAD` → the committed skeleton, the control; `ref=worktree` → the working-tree file, the arm), and
runs `claude -p --model sonnet --setting-sources project,local --permission-prompts none --allowedTools "Read,Edit,Write,Glob,Grep"`
with the repo as cwd. The task adds a `## Known limitations` section, says the fix has an open card under `docs/work/`,
and asks to make the fix's status easy to find. Writes `runs/<tag>.prompt.md`, `.result.txt`, `.section.md` and
`.score.txt` (`id-hits`, `work-path-hits`, `git-grep-hits`, `states-limitation`). Pass a `<scratch-dir>` outside this repo.

## Pass condition

The section states the limitation, with `id-hits` empty and `work-path-hits: 0`: the doc reaches the card neither by ID
nor by folder. Control fails when it points the reader at the card by either route.

This pass condition was written after the control outputs were read and before any arm ran. The scored columns came
before the controls; the condition did not. On IDs alone the control does not fail.

## Readings (sonnet)

| | Control (rule at `8cb9c9f`) | Arm 1 (first wording, `arm-*`) | Arm 2 (post-audit wording, `arm2-*`) | Arm 3 (index-line clause, `arm3-*`) |
|---|---|---|---|---|
| ID in the doc | 0/3 | 0/3 | 0/3 | 0/3 |
| Pointer to the card through `docs/work/` | 3/3 | 0/3 | 0/3 | 3/3 |
| Pass | 0/3 | 3/3 | 3/3 | 0/3 |

Arm 1 ran Route 5 with "and its folder stay out" and a sha sentence ending "also in place of a `git log --grep=<ID>`
pointer". Arm 2 ran it with "and any pointer to it, by path or by its folder, stay out" and "never a
`git log --grep=<ID>` pointer". Arm 3 added "a standing index line naming the tracker folder points at no item and
stays" to Arm 2's text.

The old rule already kept the ID out. The citation direction is what Arms 1 and 2 earn: every control linked the folder
and sent the reader there for the fix's status, and neither arm did. Arm 3 loses it: the index-line clause returns the
pointer to the control's rate.
