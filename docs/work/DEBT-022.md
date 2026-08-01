# DEBT-022 — todo subagent classify+render pass not right-sized to working-set size

**Logged:** 2026-07-25 · **Source:** GitHub issue #25 (downstream adopter claude-config-manager, absorbed via /pull-issue)
**Problem:** `/super-bootstrap:todo` dispatches a subagent that re-classifies every open row from scratch on every invocation, regardless of working-set size. Observed on sb 2.24.1 with 4 open rows / 3-row need-me board (one venue group): ~34.3k subagent tokens / ~226s per bare dispatch. The full classify pass ran over every row; no computation reuse between invokes. The board is intended as a frequent, low-stakes glance; per-glance cost is disproportionate to a small working set.
**Area:** `agents/todo.md`; `plugins/super-bootstrap/skills/todo/**`
**Prior:** Right-size the classify+render work to actual working-set size — skip or shorten classify phases when row count is small.
