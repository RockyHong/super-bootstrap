# bench/todo-fallback-register — A/B for the todo fallback brief's register (DEBT-118 M1+M2)

Test surface for the text that briefs the Sonnet-pinned `todo` agent on the `/super-bootstrap:todo`
fallback lane: the dispatch prompt template in
[`skills/todo/SKILL.md`](../../plugins/super-bootstrap/skills/todo/SKILL.md) § Execution — dispatch
lane, and the agent body [`agents/todo.md`](../../plugins/super-bootstrap/agents/todo.md) § Classification
+ § Protocol. `DEBT-118` M1/M2 propose removing the caps/prohibition
cluster and the restated "read the spec" lines, and giving the reason instead. A removal is tested
for equivalence: the proposed arm passes when its board is no worse than the shipped arm's.

## Arms

The arm is the briefing text; nothing under `plugins/` is edited.

- `arms/current/` — `git show HEAD:` copies of `SKILL.md` and `agents/todo.md` (as `agent-todo.md`).
- `arms/proposed/` — produced by [`make-arms.py`](make-arms.py): the card's six replacements
  applied verbatim to the current copies; each old string must occur exactly once or it aborts.

## Oracle

The fallback lane must render the board the script lane renders. The golden is
[`render-board.py`](../../plugins/super-bootstrap/skills/todo/assets/render-board.py) run over
[`bench/todo-board/fixture/`](../todo-board/README.md) (13 cards + a 2-entry test queue, every spec
branch) at the run's date; [`make-fixture.sh`](make-fixture.sh) aborts unless that re-render equals
`bench/todo-board/expected/<mode>.md` bar the title date. Modes: `needme` (the default board —
intent buckets as groups) and `full` (the flat board — per-row Stage and Blocker cells).

## Runner

[`make-fixture.sh`](make-fixture.sh) builds a scratch tree: the fixture as a one-commit repo, the
shipped spec under `plugin/shared/`, a credentials-only `CLAUDE_CONFIG_DIR`, and per arm an
`agents.json` (the arm's agent body as the `todo` agent) plus one dispatch prompt per mode, built by
[`build-dispatch.py`](build-dispatch.py) exactly as SKILL.md Steps 2-3 say — the arm's own template,
the resolved mode, the absolute spec path, the chosen-mode section of `assets/scaffolds.md` verbatim.
The two arms' prompts may differ only on the three M1 lines (asserted).

[`run.sh`](run.sh) runs the agent as the session agent — `claude -p --model sonnet --agents
agents.json --agent todo --tools Read,Grep,Glob --add-dir <plugin>` — cwd'd in the fixture repo,
the spec reached through `--add-dir` the way an installed plugin's spec sits outside a consumer repo.
Proxy note: in production the agent is a subagent dispatched by the gateway; here its body is the
session's agent prompt and the dispatch prompt is the user turn — the same two texts, one hop fewer.

## Readings

[`score.py`](score.py) (definitions in its docstring), one TSV row per run via
[`score.sh`](score.sh): `rows` (action verb + intent bucket + stage agreement per golden row),
`drain` / `pending` (the drained-row and hard-block counts), `shape` (title, headings, columns, no
invented rows, no recommendation, footer — k/6), `spec` / `spec_n` (the spec was Read, how often).
[`bite.sh`](bite.sh) proves each assertion fails on an induced bad board.

## Use

```bash
FX=<scratch-dir>
bash bench/todo-fallback-register/make-fixture.sh "$FX"
bash bench/todo-fallback-register/bite.sh "$FX"
for a in current proposed; do for m in needme full; do
  bash bench/todo-fallback-register/run.sh "$FX" $a $m 3; done; done
bash bench/todo-fallback-register/score.sh "$FX"
```

`runs/` keeps each run's board and its tool-call log (`# model:` line first); transcripts stay in
the scratch tree. Results and verdict: `FINDINGS.md`.
