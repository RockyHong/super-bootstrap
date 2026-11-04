# bench/spike-route — RED for the spike route row

Test surface for the Cluster routing row on iterative or spike work in [`CLAUDE.md`](../../CLAUDE.md#cluster-routing)
and its shipped counterpart, [`claude-md-skeleton.md`](../../plugins/super-bootstrap/skills/harness-bootstrap/assets/claude-md-skeleton.md):
branch out, commit in flow, merge when settled. Does a request to try and tune variants by feel branch out
before the first edit? Behavior-shaping prose, so it ships behind a micro-test.

- `make-fixture.sh <dir>` — a small game repo on `main`, tree clean, no remote, no cards. Writes `<dir>.base`.
- `prompt.txt` — the task: "try 3 feel variants of the jump arc, tune by playing". The run has no way to ask or to
  play. The excerpt follows it.
- `run.sh <control|arm> <fixture-dir>` — one headless run. Writes the ordered tool calls to `<dir>.stream.jsonl`.
- `score.py <stream.jsonl>` — (s1). `score-state.sh <fixture-dir>` — (s2) and the reading (r1).
- `bite.sh <scratch-dir>` — each assertion failing on a violating stream or fixture. Zero LLM calls.

## Protocol

Runs are headless, one fresh fixture per run, with the fixture as cwd and the prompt on stdin:
`claude -p --model sonnet --allowedTools Bash,Read,Edit,Write --setting-sources "" --strict-mcp-config --system-prompt <stub> --permission-prompts none --output-format stream-json --verbose`.
The Bash tool's own description stays in both arms, so any tendency it carries sits in the control's reading too.

- **Control** — `CLAUDE.md` § The envelope and § Cluster routing at `bb069c4`.
- **Arm** — the same sections of the working-tree `CLAUDE.md`.

Assertions:

- **(s1)** a branch-out (`git switch -c`, `git checkout -b`, `git branch <name>`, `git worktree add`) precedes the
  first edit. An edit is an Edit or Write call or a Bash write. A card under `docs/work/` does not count as an edit.
- **(s2)** `main`'s tip stays at the base commit.
- **(r1)** reading, non-gating: the commits the branch-out holds. The run may stop before the user plays.

Pass condition, named before any run, three runs per arm:

- Arm: (s1) and (s2) on 3 of 3.
- RED: control fails (s1) on 2 of 3 or more. Otherwise this bench holds no RED, and the report says so.
- One wording round. A failed arm stops the work and reports the numbers.

Limit of this harness: the excerpt is embedded, so it proves the row moves a run that has read it, not that a
session recognizes the shape from the ambient `CLAUDE.md`, and it covers the commit-in-flow and merge limbs
only through the (r1) reading.

## Findings

Control `bb069c4`, arm working tree, one wording, three runs per arm, sonnet, one fresh fixture per run.

| Assertion | Control | Arm |
|---|---|---|
| (s1) branch-out before the first edit | 0 of 3 | 3 of 3 |
| (s2) `main` holds no new commit | 3 of 3 | 3 of 3 |
| (r1) reading | on `main`, 0 commits, 3 of 3 | on `spike/jump-arc-feel`, 1 commit, 3 of 3 |

RED holds and the arm passes. Each control run edits on `main` with no branch, one after writing a `cards/` file.
