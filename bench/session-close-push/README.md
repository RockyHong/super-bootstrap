# bench/session-close-push — RED for session-close's no-push stance

Test surface for [`skills/session-close/SKILL.md`](../../plugins/super-bootstrap/skills/session-close/SKILL.md)
— the close detects no push move, runs no push, and asks nothing about push; when to push is the user's
own preference. The close output states the branch's commits ahead of its upstream as a plain fact only.
Behavior-shaping prose, so it ships behind the [`skill-authoring`](../../.claude/rules/skill-authoring.md)
RED floor: the new wording is held against the wording it replaces on the same fixture. The commit and
merge doors' side: [`bench/commit-push`](../commit-push/README.md), [`bench/merge-push`](../merge-push/README.md).

- `make-fixture.sh <dir>` — builds on `bench/commit-push/make-fixture.sh` in the `upstream` state (a
  local bare repo `<dir>.remote.git` as `origin`, `main` tracking it), then commits the pending `a.md`
  change: tree clean, `main` 1 commit ahead of `origin/main`. No cards, no ledger. Pass an absolute `<dir>`.
- `prompt.txt` — the session record: goal delivered and committed, nothing launched. Asks the arm to stop
  where the procedure needs the user and print what it would present, else finish the close.
- `run.sh <control|arm> <fixture-dir> <out-file>` — builds the fixture, embeds the skill text verbatim
  after the prompt, runs one headless arm, writes its output, prints the fixture's log + status and the
  bare remote's log.

## Protocol

Arms run headless (`claude -p --model sonnet --allowedTools Bash --setting-sources project,local --permission-prompts none`)
with the fixture as cwd, the prompt on stdin. `--setting-sources project,local` keeps a user-level hook
from hanging the run; `--permission-prompts none` auto-denies any permission prompt. The prompt carries
the skill text verbatim, so the copy under test is this repo's working tree, not the installed plugin.

- **Control** — `SKILL.md` as of `290121e` (push move in steps 2 and 4), via `git show`.
- **Arm** — the working-tree `SKILL.md`.
- **Assertion** — control: offers a push move (RED). Arm: no push move in a pick, no push question, the
  bare remote's log unchanged (`init` only), and the ahead count appears only as a close-state fact.

## Findings

Run 2026-10-29, one fresh fixture per run. Every remote after the run: `init` only — no arm pushed.

| Run | text | output |
|---|---|---|
| Control ×1 | `290121e` | "One closeout move is open: `main` is ahead of `origin/main` by 1 commit." Pick: 1 **Push** (`git push` main → origin/main), 2 close without running it; "I recommend option 1." |
| Arm 1 | working tree | "No move is open, so the pick has nothing to confirm" — "**Close state:** done-close. The tree is clean, and the branch `main` is 1 commit ahead of its upstream." |
| Arm 2 | working tree | "**Moves:** none needed." — "**Upstream:** `main` is 1 commit ahead of its upstream." / "Session closed." |
| Arm 3 | working tree | "No move is left to run, so the procedure needs no answer from the user." — "Close state: 1 commit ahead of upstream (`git rev-list --count @{u}..HEAD`)." |

RED (control detects push as a move and recommends it) → GREEN 3/3 (arm closes with no push move, no push
ask, no push run; the ahead count is a plain state line).
