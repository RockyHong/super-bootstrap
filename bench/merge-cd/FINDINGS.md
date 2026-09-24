# FINDINGS — merge-cd (GAP-091 L6)

Run 2026-09-24, Claude Code 2.1.281, Windows 11 (Bash + PowerShell tools both present), cold config,
N=3 per arm per model. Verdict of [`score.py`](score.py) over [`runs/`](runs/):

| Model | Arm | runs with `cd` | `git -C` calls | shell calls / run | both branches absorbed |
|---|---|---|---|---|---|
| claude-opus-5-5 | current | 0/3 | 0 | 7, 16, 18 | 3/3 |
| claude-opus-5-5 | removed | 0/3 | 0 | 16, 5, 8 | 3/3 |
| claude-sonnet-5 | current | 0/3 | 0 | 8, 5, 12 | 3/3 |
| claude-sonnet-5 | removed | 0/3 | 0 | 6, 7, 7 | 3/3 |

Zero `cd` / `Set-Location` / `pushd` in any of 115 shell calls (80 Bash, 35 PowerShell) across 12
runs; every git command ran bare against the cwd. Scorer bite confirmed (synthetic `cd D:/x && git
status` row → `cd=1`).

**Verdict: fossil — removable.** The `removed` arm shows no more `cd` than `current` (0 vs 0 on both
models). Likely cause (not isolated here): Claude Code's own shell-tool description already tells the model
the working directory persists and to prefer absolute paths over `cd`.

**Confounder, noted:** every run hit ≥1 permission denial — compound commands with shell loops /
`echo` / PowerShell string literals fall outside the git-only allow-list. Models recovered by
splitting into plain `git` calls or switching shell; none of the recoveries reached for `cd`, in
either arm. The denial pressure, if anything, gave the models more occasions to reach for a directory
change than a real session would, and none did.

Limits: N=3 per cell detects a common habit, not a rare one; a clean-merge fixture only (the
conflict path was not exercised).
