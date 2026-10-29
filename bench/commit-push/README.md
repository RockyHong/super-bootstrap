# bench/commit-push — micro-test for the commit door's no-push handoff

Test surface for [`skills/commit/SKILL.md`](../../plugins/super-bootstrap/skills/commit/SKILL.md) § 6 —
the handoff step after the commit. The door commits locally and never pushes or asks to push; no door and no
[`session-close`](../../plugins/super-bootstrap/skills/session-close/SKILL.md) runs or asks push —
when to push is the user's own preference ([`bench/session-close-push`](../session-close-push/README.md)
holds session-close's side). Behavior-shaping
prose, so it ships behind the [`skill-authoring`](../../.claude/rules/skill-authoring.md) RED floor:
the wording is held against the wording it replaces on the same fixtures.

- `make-fixture.sh <dir> <none|remote|upstream>` — scratch repo: one initial commit (`README.md`,
  `a.md`); `a.md` modified, unstaged (this session's work). `none` has no remote; `remote` adds a
  local bare repo (`<dir>.remote.git`) as `origin` with no upstream on `main`; `upstream` also sets
  `main` to track it. Pushes land in the bare repo — read its log to know whether one fired. Pass an
  absolute `<dir>`.

## Protocol

Arms run headless (`claude -p --model haiku --allowedTools Bash --setting-sources project,local --permission-prompts none`) with the
fixture as cwd, the prompt on stdin — a project-level `commit-channel` hook routes a subagent's raw
`git commit` back to the gateway, so an in-session subagent cannot be the arm. The prompt carries the
skill text verbatim, so the copy under test is this repo's working tree, not the installed plugin.
`--permission-prompts none` auto-denies any permission prompt: without it, a user-level
`PermissionRequest` hook can hold a headless run open with no one to answer.

- **Prompt** — "This session edited `a.md`; commit it as `docs: update a` (git add a.md && git commit),
  then continue the procedure from step 6 below. Print any question to the user as your final output.",
  followed by the step text verbatim.
- **Control** — the pre-fix § 6 (push probe + "Push these now? (y / skip)") and § 7 (the
  `Cycle complete. … /clear …` table), on `upstream`.
- **Arm** — the shipped § 6 (handoff), on each of `none` / `remote` / `upstream`.
- **Assertion** — in every state: no push question in the output, the bare repo's log
  (`git --git-dir <dir>.remote.git log --oneline --all`) is unchanged, and the output after the commit
  is § 6's one handoff line — no push named in it.

## Findings

Run 2026-10-29, one fixture per run.

| Arm | state | output after the commit | pushed |
|---|---|---|---|
| Control (pre-fix § 6 + § 7) | `upstream` | `**Push:** \`origin\` exists and \`main\` tracks \`origin/main\`. 1 commit is ahead.` / `Push these now? (y / skip)` / `**Cycle handoff:** Cycle complete. No open cards. Safe to /clear. …` | no (bare log unchanged) |
| Arm (shipped § 6) | `none` | `Committed. When the session's work is done: /super-bootstrap:session-close (push, card resolve, carry).` — only | — |
| Arm (shipped § 6) | `remote` | the same line only | no (bare log unchanged) |
| Arm (shipped § 6) | `upstream` | the same line only | no (bare log unchanged) |

RED (control asks to push and hands off to `/clear`) → GREEN (arm prints the one session-close line in
every state, asks nothing, pushes nothing). A first arm round under the user's own settings gave the same
3/3; the round recorded here ran with `--setting-sources project,local`.

The 2026-10-29 rows above ran against a § 6 handoff line that still named push as a session-close move;
that line is since aimed at no push at all, so a re-run asserts § 6's current line with no push in it.
