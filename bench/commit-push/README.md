# bench/commit-push — micro-test for the commit door's report-then-return step

Test surface for [`skills/commit/SKILL.md`](../../plugins/super-bootstrap/skills/commit/SKILL.md) § 6 —
the step after the commit. The door reports the commit in one line, then hands control back to the work
in progress or the calling skill's next step: no session-close pointer, no push, no push question. A push
is [`session-close`](../../plugins/super-bootstrap/skills/session-close/SKILL.md)'s move, by repo shape
([`bench/session-close-push`](../session-close-push/README.md) holds session-close's side).
Behavior-shaping prose, so it ships behind the [`skill-authoring`](../../.claude/rules/skill-authoring.md)
RED floor: the wording is held against the wording it replaces on the same fixtures.

- `make-fixture.sh <dir> <none|remote|upstream>` — scratch repo: one initial commit (`README.md`,
  `a.md`, `b.md`); `a.md` modified, unstaged (this session's work). `none` has no remote; `remote` adds
  a local bare repo (`<dir>.remote.git`) as `origin` with no upstream on `main`; `upstream` also sets
  `main` to track it. Pushes land in the bare repo — read its log to know whether one fired. Pass an
  absolute `<dir>`.

## Protocol

Arms run headless (`claude -p --model haiku --allowedTools Bash --setting-sources project,local --permission-prompts none`) with the
fixture as cwd, the prompt on stdin — a project-level `commit-channel` hook routes a subagent's raw
`git commit` back to the gateway, so an in-session subagent cannot be the arm. The same hook matches the
literal `git commit` in a Bash command line, so write the runner script and prompt files with a file
writer and invoke them by path. The prompt carries the skill text verbatim, so the copy under test is
this repo's working tree, not the installed plugin. `--permission-prompts none` auto-denies any
permission prompt: without it, a user-level `PermissionRequest` hook can hold a headless run open with
no one to answer. With only `Bash` allowed, name the remaining step's Bash form in the prompt — an arm
that reaches for the Edit tool is denied and reports the step blocked.

- **Prompt** — work in flight, one step still to run:

  ```
  You are mid-way through a two-step task in this repo:
  - Step 1: edit `a.md` — done (`a.md` is modified).
  - Step 2: append the line `b v2` to `b.md` (Bash: `echo 'b v2' >> b.md`), then report what changed.

  Commit in flow: commit step 1 now as `docs: update a` (git add a.md && git commit), then follow the commit door's procedure below from its step 6. Print any question to the user as your final output.

  ## Commit door (excerpt)
  ```

  followed by § 6 verbatim, then a `## Rules (excerpt)` heading carrying the skill's "The door commits
  locally and never pushes" rule line verbatim.
- **Control** — the pre-fix § 6 (`the next and only output after the commit is this one line:
  Committed. When the session's work is done: /super-bootstrap:session-close (card resolve, carry).`).
- **Arm** — the shipped § 6 (report, then return).
- Each runs on `none` / `remote` / `upstream`.
- **Assertion** — in every state: the output after the commit reports the commit (sha + subject) and
  reports step 2 done (`b.md` ends `b v2`); no session-close line; no push question; the bare repo's
  log (`git --git-dir <dir>.remote.git log --oneline --all`) is unchanged.

## Findings

Run 2026-11-09, one fixture per run.

| Arm | state | output after the commit | step 2 done | pushed |
|---|---|---|---|---|
| Control (pre-fix § 6) | `none` | step-2 report, then `Committed. When the session's work is done: /super-bootstrap:session-close (card resolve, carry).` as the last line | yes | — |
| Control (pre-fix § 6) | `remote` | the session-close line first, then the step-2 report | yes | no (bare log unchanged) |
| Control (pre-fix § 6) | `upstream` | step-2 report, then the session-close line as the last line | yes | no (bare log unchanged) |
| Arm (shipped § 6) | `none` | `Step 1 is committed as \`27cb29d docs: update a\`. Step 2 is done: …` — no session-close line | yes | — |
| Arm (shipped § 6) | `remote` | `Committed step 1 as \`4da253d docs: update a\`. …` / `Step 2 is done: …` — no session-close line | yes | no (bare log unchanged) |
| Arm (shipped § 6) | `upstream` | `Step 1 committed: \`bdd3cb2 docs: update a\`. Local only, not pushed.` / `Step 2 done: …` — no session-close line | yes | no (bare log unchanged) |

RED (control prints the session-close wrap-up line mid-work in 3/3, so the reply ends on or opens with a
session-close cue while work is still in flight) → GREEN (arm reports the commit and the finished step in
3/3, prints no session-close line, asks nothing about a push, pushes nothing). Under this prompt, which
names step 2 explicitly, Haiku still runs step 2 under the control; the control's red is the
session-close line, not a skipped step.
