# bench/commit-deferred-verify — does an autorun worker run the staged-tree verify in deferred mode

Test surface for [`skills/commit/SKILL.md`](../../plugins/super-bootstrap/skills/commit/SKILL.md)'s deferred-mode
skip of the staged-tree verify: an autorun worker committing in deferred mode skips the declared verify, and the
gateway runs that declared Staged-Tree Verify at the merge gate, on the base tree ([`skills/autorun/SKILL.md` § Rules](../../plugins/super-bootstrap/skills/autorun/SKILL.md#rules)).
Behavior-shaping prose, so it ships behind the [`skill-authoring`](../../.claude/rules/skill-authoring.md) RED floor.

- [`run.sh`](run.sh) `<dir> <tag> [model]` — one cold headless run: credentials-only `CLAUDE_CONFIG_DIR`, cwd
  an empty directory (no repo `CLAUDE.md`), no tools. Prompt: the skill text from `## Execution` up to
  `## Rules`, then "you are an autorun worker committing in deferred mode; the repo declares a Staged-Tree Verify
  (`npm test`); `git status --porcelain` lists `?? scratch.log` outside your session list; list the commands you
  run". Writes `runs/<tag>.prompt.md` and `.result.txt`. `SKILL_REF=HEAD` takes the skill text from a commit
  instead of the working tree.

Pass an absolute `<dir>` outside this repo.

## Protocol

- **Control** — the pre-fix body (`SKILL_REF` at the commit before the skip landed).
- **Arm** — the shipped body.
- **Assertion** — no `GIT_INDEX_FILE=... git read-tree` / `checkout-index` and no `npm test` among the commands;
  the closing line says the verify did not run because deferred mode skips it.

## Findings

Run 2026-10-20, haiku, three runs per side. Arm r1-r3 ran on an earlier skip sentence that cited the merge-gate verify generically; r4 runs the shipped sentence, which names the declared Staged-Tree Verify at the merge gate.

| Run | staged-tree verify | closing line |
|---|---|---|
| Control r1-r3 | runs it (3/3): throwaway index, `git checkout-index -a --prefix=<tmp>/`, `npm test` in a temp dir outside the worktree | "yes, I run it, because `git status --porcelain` lists `scratch.log`" |
| Arm r1-r3 | absent (3/3): readback, then `git commit -o` | "not run. The worktree is in deferred mode, so the skill skips it" (3/3, merge-gate verify named) |
| Arm r4 (reworded skip sentence) | absent: readback, then `git commit -o` | "I did not run `npm test` here, because deferred mode skips §5's staged-tree verify. The gateway runs the declared verify at the merge gate on the base tree instead." |

RED: the pre-fix body skips only §3 in deferred mode, so the untracked file fires the file-grain verify and the
worker issues the env-prefixed, outside-the-worktree commands its permission template cannot allow. GREEN: the
arm bodies skip the verify 4/4 and name the merge-gate verify as the check.
