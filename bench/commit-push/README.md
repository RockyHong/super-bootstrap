# bench/commit-push — micro-test for the commit door's push probe

Test surface for [`skills/commit/SKILL.md`](../../plugins/super-bootstrap/skills/commit/SKILL.md) § 6's
push step — the probe that decides whether the "Push these now?" question fires at all.
Behavior-shaping prose, so it ships behind the
[`skill-authoring`](../../.claude/rules/skill-authoring.md) RED floor: the wording is held against
the wording it replaces on the same fixtures.

- `make-fixture.sh <dir> <none|remote|upstream>` — scratch repo: one initial commit (`README.md`,
  `a.md`); `a.md` modified, unstaged (this session's work). `none` has no remote; `remote` adds a
  local bare repo (`<dir>.remote.git`) as `origin` with no upstream on `main`; `upstream` also sets
  `main` to track it. Pushes land in the bare repo — read its log to know whether one fired.

## Protocol

Arms run headless (`claude -p`) with the fixture as cwd, the prompt on stdin — a project-level
`commit-channel` hook routes a subagent's raw `git commit` back to the gateway, so an in-session
subagent cannot be the arm.

- **Prompt** — "this session edited `a.md`; commit it as `docs: update a`, then continue the
  procedure from step 6", followed by § 6 + § 7 verbatim, with the instruction to print any
  question to the user as the final output.
- **Control** — the pre-fix § 6 ("present branch → upstream … Ask *Push these now?*"), on `none`.
- **Arm** — the shipped § 6, on each of `none` / `remote` / `upstream`.
- **Assertion** — `none`: output carries no push question, § 7's handoff line is the only output
  after the commit; `remote`: one upstream question, once; `upstream`: "Push these now? (y / skip)"
  unchanged. In every state the bare repo's log is unchanged (no push fired without a yes).

## Findings

Run 2026-09-10, `claude -p --model haiku --allowedTools Bash`, one fixture per run.

| Arm | state | output after the commit | pushed |
|---|---|---|---|
| Control (pre-fix § 6) | `none` | `Push these now? (y / skip)` then the handoff line — asked with no remote to push to | — |
| Arm, first wording (`no question and no "skipped" line`) | `none` | `**No push surface** (no remotes configured).` then the handoff line — a status line the negative clause did not prevent | — |
| Arm, shipped wording (`§7's handoff line is the next and only output`) | `none` | handoff line only — 2/2 | — |
| Arm, shipped wording | `remote` | one line naming `origin` without upstream, then `設置上游並推送 (git push -u origin main)? (y / skip)` | no (bare log unchanged) |
| Arm, shipped wording | `upstream` | `Push these now? (y / skip)` | no (bare log unchanged) |

RED (control asks with no remote) → GREEN (arm probes first: silent on `none`, one upstream ask on
`remote`, the unchanged ask on `upstream`). The negative clause of the first arm wording was replaced
by a positive completion condition after it let a status line through; the § 6 wording shipped is the
second arm's plus one clause the cold audit asked for — which remote `git push -u` names when several
exist (the sole one, else the user's pick). Every fixture here carries one remote, so that clause sits
outside this bench's reach.
