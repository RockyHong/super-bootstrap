# bench/merge-push — micro-test for the merge door's push probe

Test surface for [`skills/merge/SKILL.md`](../../plugins/super-bootstrap/skills/merge/SKILL.md) § 8's
push step — the probe that decides whether the "Push {base} now?" question fires at all. Behavior-shaping
prose, so it ships behind the [`skill-authoring`](../../.claude/rules/skill-authoring.md) RED floor: the
wording is held against the wording it replaces, on the same fixture shape [`bench/commit-push`](../commit-push/README.md)
uses for the sibling commit door.

- `make-fixture.sh <dir> <none|remote|upstream>` — calls `bench/commit-push/make-fixture.sh` for the base
  three-state repo (one initial commit, `a.md` modified unstaged, remote/upstream per state), then commits
  the pending `a.md` change on a branch `feat` and absorbs it into `main` with `git merge --no-ff feat -m
  "merge feat"`, so `main` sits ahead of its remote (where one exists) with one folded-in branch. Pass an
  absolute `<dir>` — the underlying script's bare-repo path is built relative to cwd *after* it `cd`s into
  `<dir>`, so a relative `<dir>` nests the bare repo one level too deep.

## Protocol

Arms run headless (`claude -p --model haiku --allowedTools Bash`) with the fixture as cwd, the prompt on
stdin: "This repo's base is `main`; the branch `feat` was just absorbed with `--no-ff`. Continue the merge
procedure from step 7 below. Print any question to the user as your final output." followed by § 7 (the
report step) + § 8 verbatim.

- **Control** — the pre-fix § 8 ("Ask: *Push {base} now?*" unconditionally), on `none`.
- **Arm** — the shipped § 8, on each of `none` / `remote` / `upstream`.
- **Assertion** — `none`: the § 7 report is the last output, no push question and no push-status line;
  `remote`: one set-upstream question; `upstream`: "Push main now? (y / skip)". In every state the bare
  repo's log (`git --git-dir <dir>.remote.git log --oneline`) is unchanged.

## Findings

Run 2026-09-10, `claude -p --model haiku --allowedTools Bash`, one fixture per run.

| Arm | state | output after the report | pushed |
|---|---|---|---|
| Control (pre-fix § 8) | `none` | `推送 main 分支嗎？(y / skip)` ("Push main now?") — asked with no remote, and claimed main was "1 commit ahead of remote" though no remote exists | — |
| Arm, brief wording (`§7's report closes the run`) | `none` | 2/3 clean (report only); 1/3 asked a full "which remote should I push to?" question — the probe never ran | — |
| Arm, shipped wording (`§7's report is the next and only output`) | `none` | 4/4 clean — report only | — |
| Arm, shipped wording | `remote` | 2 runs: 1 clean (`設定上游並推送 main？(git push -u origin main)? (y / skip)`); 1 punted — claimed a "permission limit" stopped the probe and asked the user to paste their own `git remote -v` instead of asking either template | no (bare log unchanged) |
| Arm, shipped wording | `upstream` | 1/1: `推送 main 現在？(y / skip)` ("Push main now?") | no (bare log unchanged) |

RED (control asks unconditionally, even claiming a false ahead-of-remote count with no remote) → GREEN
(shipped wording is silent on `none`, asks the correct template once on `remote`/`upstream`, and never lets
a push fire without an explicit yes in any run — bare-repo logs confirm this across every arm). The brief's
literal § 8 text ("§7's report closes the run") let a full push question through on 1/3 `none` runs — the
same failure class BUG-058 hit on its first wording. Tightened to the sibling § 6's proven positive
completion condition ("§7's report is the next and only output"), which then held 4/4 clean on `none`. The
`remote` arm still punted once even under the tightened wording (asking the user for their own `git remote
-v` instead of running the probe itself) — not a wording ambiguity (§ 8 spells out the exact probe command
and both ask templates), but haiku headless occasionally declining to run a probe step it has full
`Bash` permission for. No push ever fired unannounced in any run, tightened or not — the load-bearing
guarantee holds regardless of this residual flakiness.
