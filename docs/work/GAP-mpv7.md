# GAP-mpv7 — A § Rules bullet left stale by an earlier sync has no row that names it

**Logged:** 2026-11-20 · **Source:** DEBT-w0xk build report (gateway session) — `bench/rule-paths-cochange/README.md` Declared bounds 3
**Problem:** The `paths:` co-change only fires on a placed doc rule's drift row. A repo whose rule file an earlier sync already moved to the current skeleton entries (e.g. `README.md` → `/README.md`) gets no drift row on the next run, so its consumer `CLAUDE.md` § Rules bullet that still restates the old fires-on list is never named and stays stale. The reporting ComfyUI `workflows/agent` repo likely sits in this state (migration, then a regular sync).
**Area:** `plugins/super-bootstrap/skills/harness-bootstrap/SKILL.md` § 2b Per-doc handling; `assets/rule-paths-coverage.sh`
**Prior:** A re-run compares each placed doc rule's § Rules bullet against its current `paths:` even when the rule file is current (a `rule-paths-coverage.sh` mode, DEBT-w0xk Verdict option C).
