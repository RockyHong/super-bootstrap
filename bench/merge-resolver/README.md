# bench/merge-resolver — what a dispatched conflict resolver does after resolving

Test surface for [`skills/merge/SKILL.md`](../../plugins/super-bootstrap/skills/merge/SKILL.md)'s § Resolver
contract: a conflict-resolution agent stages its resolution, runs no concluding command, and reports; the
gateway concludes it in the main session (`git merge --continue` / `git rebase --continue`). Behavior-shaping prose, so it ships behind the
[`skill-authoring`](../../.claude/rules/skill-authoring.md) RED floor.

- [`run.sh`](run.sh) `<dir> <tag> [model]` — one cold headless run: credentials-only `CLAUDE_CONFIG_DIR`, cwd
  an empty directory (no repo `CLAUDE.md`), no tools. Prompt: the skill text from `## Conflict Doctrine` up to
  `## Protocol`, then "you resolved `a.md` and `b.md` on a `--no-ff` merge of `feature/x`; state your next git
  commands and your report". Writes `runs/<tag>.prompt.md` and `.result.txt`. `SKILL_REF=HEAD` takes the
  skill text from a commit instead of the working tree.

Pass an absolute `<dir>` outside this repo.

## Protocol

- **Control** — the pre-fix body (`SKILL_REF` at the commit before the contract landed).
- **Arm** — the shipped body.
- **Assertion** — the last git command is `git add` of the resolved files; no `git commit`,
  `git merge --continue`, `git rebase --continue` or `git merge --abort`; the report names branch, strategy and
  files, and hands the conclusion to the gateway.

## Findings

Run 2026-10-20, haiku, three runs per side.

| Run | commands after resolving | report |
|---|---|---|
| Control r1-r3 | `git merge --abort` (3/3), discarding the resolution; r1-r2 first copy the files to a backup | "Aborted. Working tree restored"; resolution named a deviation |
| Arm r1-r3 | marker check (r2-r3), then `git add a.md b.md` as the last git command (3/3) | "merge in progress, staged, not concluded"; gateway concludes via `/super-bootstrap:commit` (3/3) |

RED: the pre-fix body gives the resolver no contract of its own, so the resolver applies the skill's abort
rule to itself and throws its resolution away. GREEN: the shipped body stages and stops at `git add` 3/3, with
no concluding or aborting command.
