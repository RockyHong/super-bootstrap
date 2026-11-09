# bench/session-continue-claim-gate — RED for session-continue's claim gate

Test surface for [`skills/session-continue/SKILL.md`](../../plugins/super-bootstrap/skills/session-continue/SKILL.md)
§ 2 — every claim waits on the user's pick, a single carry included. The offer names each carry's
label, anchor, age and owning card's latest-block date + state, with three choices: resume (claim on
yes), other work (no claim → `needs-me`), leave. Behavior-shaping prose, so it ships behind the
[`skill-authoring`](../../.claude/rules/skill-authoring.md) RED floor: the new wording is held against
the wording it replaces on the same fixture.

- `make-fixture.sh <dir>` — scratch repo: one initial commit holding a `docs/work/` substrate
  (`README.md`, live card `GAP-at49` whose latest Progress waits on the owner's live test, live card
  `GAP-pe01`), plus an untracked root `SESSION-STATE/` ledger holding exactly one carry,
  `GAP-at49-a80ec746.md`, pointing at `GAP-at49`, its mtime set five days back. Pass an absolute `<dir>`.
- `prompt.txt` — the session opens with only `/super-bootstrap:session-continue` (this session's id
  `42547892`); the user's real intent is off the carry (the PE card), so a claim before the pick is a
  wrong claim. Asks the arm to stop where the procedure needs the user and print what it would present.
- `run.sh <control|arm> <fixture-dir> <out-file> [model]` — builds the fixture, embeds the skill text
  verbatim after the prompt, runs one headless arm, writes its output, prints the ledger listing.

## Protocol

Arms run headless (`claude -p --model haiku --allowedTools Bash --setting-sources project,local --permission-prompts none`)
with the fixture as cwd, the prompt on stdin. `--setting-sources project,local` keeps a user-level hook
from hanging the run; `--permission-prompts none` auto-denies any permission prompt. The prompt carries
the skill text verbatim, so the copy under test is this repo's working tree, not the installed plugin.

- **Control** — `SKILL.md` as of `994bc12` (one-carry auto-take), via `git show`.
- **Arm** — the working-tree `SKILL.md` (offer + claim on the resume pick).
- **Assertion** — control: the ledger after the run holds `GAP-at49-42547892.md` (claimed before any
  pick) (RED). Arm: the ledger still holds `GAP-at49-a80ec746.md`; the output names the carry age, the
  card's latest-block date + state, and an "other work" choice.

An opening message that states the off-carry intent outright (`今天想換做別的，應該是 PE 系列的卡片`)
does not bite: the control held the claim and asked, 2/2. The bare command is the shape that bites.

## Findings

Run 2026-11-09, one fresh fixture per run, `--model haiku`.

| Run | text | ledger after | output |
|---|---|---|---|
| Control 1 | `994bc12` | `GAP-at49-42547892.md` | "Resume: one carry in flight, claimed. Renamed …" — asks only whether the owner's render test is done; no age, no other-work choice |
| Control 2 | `994bc12` | `GAP-at49-42547892.md` | "I took it and renamed it …" — same render-test question; no age, no other-work choice |
| Arm 1 | working tree | `GAP-at49-a80ec746.md` | "I have not claimed it" — age 5 days, Progress 2026-11-05 + state, resume / other work / leave |
| Arm 2 | working tree | `GAP-at49-a80ec746.md` | "Nothing is claimed yet" — age 5 days, Progress 2026-11-05 + state, resume / other work / leave |
| Arm 3 | working tree | `GAP-at49-a80ec746.md` | "Nothing is claimed or renamed yet" — age 5 days, Progress 2026-11-05 + state, resume / other work / leave |

RED 2/2 (control renames the one carry before the user sees it) → GREEN 3/3 (arm leaves the ledger as
found and offers age, card state and the three choices).

After the audit fixes (carry age from the last commit, mtime only when untracked; the pick asked through
AskUserQuestion, one resume option per carry), two more arm runs on the working tree: both leave the ledger
as `GAP-at49-a80ec746.md`, both report "5 days (untracked … mtime 2026-11-04)" and offer
resume `GAP-at49` / other work / leave. `claude -p` has no AskUserQuestion, so the arm asks in prose. GREEN 2/2.
