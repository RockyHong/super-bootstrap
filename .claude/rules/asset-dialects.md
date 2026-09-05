---
paths:
  - "plugins/*/skills/**/*.sh"
  - "plugins/*/skills/**/*.py"
description: "Dialect standards for shipped code assets — POSIX bash, portable-awk subset, fork-free inner loops, Python mechanical-extraction shape. Fires on a shipped .sh / .py asset read under plugins/*/skills/."
---

# Asset Dialects — Shipped Shell + Python

Code assets ship to consumer machines this repo never sees. Write them in the dialect every consumer runtime accepts; lock each construct that has silently failed before.

## POSIX bash

Shell code assets use POSIX `bash`. On a PowerShell-primary device, run them via the Bash tool or rewrite in the target idiom — never string-tweak between shells. Shape reference: [`release/SKILL.md`](../skills/release/SKILL.md).

## Portable-awk subset

Shipped awk programs stay in the subset every consumer `awk` accepts: no interval expressions (`{n,}` / `{n,m}`), explicit `[ \t]` over POSIX classes, `tolower()` only behind the lead-byte probe (a Latin-1 / cp1252 ctype rewrites UTF-8 lead bytes; letters of every script must survive slugging). Consumer `awk` resolves to mawk on Debian/Ubuntu (1.3.4-20200120 on 20.04/22.04) and one-true-awk on macOS (pre-2019 builds), both of which read `{3,}` as literal braces — a regex that leans on them fails silently, never with a parse error. Construct lock: [`tests/doc-links.test.sh`](../../tests/doc-links.test.sh); the cross-awk behavior check runs under Docker (`debian:bullseye-slim` + `original-awk` / `mawk` / `gawk`), not in the suite. Reference asset: [`commit/assets/doc-links.sh`](../../plugins/super-bootstrap/skills/commit/assets/doc-links.sh).

## Fork-free inner loops

A shipped shell asset that walks a whole doc surface keeps subprocesses out of its per-item loops: per-file derived tables (heading-slug lists) are computed in one pass and memoized (bash-3.2-safe `eval`-keyed variables — no `declare -A`), and helpers return through globals rather than stdout, since a stdout return costs a command substitution per call. Cost scales as items × forks, and a fork is ~10-20 ms on msys/Git-Bash hosts, so one helper fork per link is what pushes a whole-surface pass past the Bash tool's 120 s default. Diagnosis of an already-failed item is the one bounded exception — `check`'s strip-list hint forks once per broken anchor, where the count scales with findings rather than surface size and the pass is terminal anyway. Construct lock: [`tests/doc-links.test.sh`](../../tests/doc-links.test.sh). Reference asset: [`commit/assets/doc-links.sh`](../../plugins/super-bootstrap/skills/commit/assets/doc-links.sh).

## Python mechanical-extraction assets

Where a skill's mechanical half (parse + classify + render, zero judgment) outgrows shell, ship it as a Python 3 script invoked via `python3 "${CLAUDE_PLUGIN_ROOT}/…"`, UTF-8/LF output, stdout = the product and stderr = diagnostics, with a declared degrade path when `python3` is absent. Reference assets: [`help/assets/render-menu.py`](../../plugins/super-bootstrap/skills/help/assets/render-menu.py), [`todo/assets/render-board.py`](../../plugins/super-bootstrap/skills/todo/assets/render-board.py).
