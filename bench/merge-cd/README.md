# bench/merge-cd — does the merge skill need its `cd is unnecessary` line?

Test surface for [`GAP-091`](../../docs/work/GAP-091.md) claim **L6**:
[`skills/merge/SKILL.md`](../../plugins/super-bootstrap/skills/merge/SKILL.md) § Rules carries

> `- Working directory is already correct; `cd` is unnecessary.`

Claim: a fossil mitigation for an older harness/model habit. A removal is behavior-shaping, so it is
held against the shipped text first ([`skill-authoring`](../../.claude/rules/skill-authoring.md) RED
floor): the line goes only if the reading model issues no more `cd` without it.

## Arms

[`make-arms.sh`](make-arms.sh) derives both from the shipped skill (frontmatter stripped; nothing under
`plugins/` touched) and asserts they differ by exactly the one line.

- `current` — [`arm-current.md`](arm-current.md), the body as shipped.
- `removed` — [`arm-removed.md`](arm-removed.md), the same body minus that line.

## Fixture

[`make-fixture.sh`](make-fixture.sh) `<dir>` (outside this repo) builds a throwaway repo — base `main`
one commit ahead of the fork point, `feature/a` (1 commit) and `feature/b` (3 commits) on disjoint
files, both absorbing cleanly, no remote — plus `coldcfg/`, a credentials-only `CLAUDE_CONFIG_DIR`
(no device CLAUDE.md, rules, plugins, hooks). Allow-list: `git`, `cd`, `Set-Location`, `pwd`, `ls` in
both shells, so a `cd` attempt runs rather than being denied.

## Protocol

[`run.sh`](run.sh) `<fixture> <arm> <model> [N]` — `claude -p --model <model>` cwd'd at a pristine
per-rep copy of the fixture root; tools `Bash,PowerShell,Read,Grep,Glob`; prompt on stdin = arm body +
`ARGUMENTS: feature/a feature/b` + one pre-confirmation line (§ 4 otherwise waits for a reply headless
cannot give). No prompt text mentions directories. `--output-format stream-json` transcript stays in
the scratch dir; [`extract.py`](extract.py) writes `runs/<model>-<arm>-r<n>.tools.tsv` (every tool
call's command) + `.result.txt` (final report).

[`score.py`](score.py) `runs [fixture]` — per run: `cd` = any Bash/PowerShell command starting with or
chaining (`&&` `||` `;` `|` newline) `cd` / `Set-Location` / `sl` / `Push-Location` / `pushd` /
`chdir`; readings `git_C` (`git -C` calls), `shell` (shell-call count), `absorbed` (both branches
merged into `main` in the run's repo). Bite: a synthetic `cd D:/x && git status` row scores `cd=1`.

```bash
bash make-arms.sh
bash make-fixture.sh <scratch>
for m in claude-opus-5-5 claude-sonnet-5; do for a in current removed; do bash run.sh <scratch> $a $m 3; done; done
python3 score.py runs <scratch>
```

Results: [`FINDINGS.md`](FINDINGS.md).
