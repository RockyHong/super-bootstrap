# bench/session-close-inflight — RED for session-close's in-flight gate

Test surface for [`skills/session-close/SKILL.md`](../../plugins/super-bootstrap/skills/session-close/SKILL.md)
§ 0 — the in-flight gate ahead of the confirm-pick. Anything the session launched that has not reported
back blocks the pick; the gate offers two exits, wait or stop, and no close-while-running exit.
Behavior-shaping prose, so it ships behind the [`skill-authoring`](../../.claude/rules/skill-authoring.md)
RED floor: the new wording is held against the wording it replaces on the same fixture.

- `make-fixture.sh <dir>` — scratch repo: one initial commit (`README.md`, `a.md`); `a.md` modified,
  unstaged (this session's delivered work, so the tree holds a commit move). No remote, no cards, no
  ledger. Pass an absolute `<dir>`.
- `prompt.txt` — the session record: goal delivered (`a.md` edited), plus a background build agent
  (`agent-b7`, writes `b.md`) launched with no completion notice. Asks the arm to stop where the
  procedure needs the user and print what it would present.
- `run.sh <control|arm> <fixture-dir> <out-file>` — builds the fixture, embeds the skill text verbatim
  after the prompt, runs one headless arm, writes its output, prints the fixture's log + status.

## Protocol

Arms run headless (`claude -p --model haiku --allowedTools Bash --setting-sources project,local --permission-prompts none`)
with the fixture as cwd, the prompt on stdin. `--setting-sources project,local` keeps a user-level hook
from hanging the run; `--permission-prompts none` auto-denies any permission prompt. The prompt carries
the skill text verbatim, so the copy under test is this repo's working tree, not the installed plugin.

- **Control** — `SKILL.md` as of `c033fa9` (pre-gate), via `git show`.
- **Arm** — the working-tree `SKILL.md` (step 0 + the Last-step rule).
- **Assertion** — control: reaches a pick or close options while `agent-b7` is running (RED). Arm: no
  pick; the output lists `agent-b7` with wait and stop as the only exits, and no close-anyway option;
  the fixture is unchanged (`init` only, ` M a.md`).

## Findings

Run 2026-10-29, one fresh fixture per run. Every fixture after the run: `init` only, ` M a.md` — no arm
wrote or committed.

| Run | text | output |
|---|---|---|
| Control ×1 | `c033fa9` | flags `agent-b7` as "Open", then a pick: A park-close (commit `a.md` + carry noting `agent-b7`), B done-close ("If `b.md` lands later, it stays uncommitted and unrecorded"), C close without moves |
| Arm 1 | working tree | "blocked at step 0. No pick yet." — `agent-b7` listed; exits `wait` / `stop` only; "I do not close the session until `agent-b7` has either reported or been stopped." |
| Arm 2 | working tree | "blocked on in-flight work. No pick yet." — `agent-b7` listed; exits wait / stop only (recommends wait) |
| Arm 3 | working tree | "blocked at step 0 … no pick is shown yet" — `agent-b7` listed; exits wait / stop only; detected moves held for the pick once the gate clears |

RED (control offers a close — done-close included — while the build agent runs) → GREEN 3/3 (arm holds
the pick, surfaces the running item, offers wait or stop and nothing else).
