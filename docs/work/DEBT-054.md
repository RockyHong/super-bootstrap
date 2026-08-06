# DEBT-054 — legacy-migration table routes rejected-alternatives content into techstack § Coding Patterns, against the history-dimension routing

**Logged:** 2026-08-06 · **Source:** DEBT-053 drain subprocess — triage side-finding (drain/debt-053 run)
**Problem:** `harness-bootstrap/SKILL.md` § 2b legacy-CLAUDE.md migration table maps "Reference material — rejected alternatives, design rationale, architecture decisions, deep examples" to `docs/techstack.md § Coding Patterns`. The techstack skeleton header and `docs/decisions.md` scope both route rejected alternatives to `decisions.md` (history dimension — "never a section here"). A legacy migration following the table as written plants history content into a state doc.
**Area:** `plugins/super-bootstrap/skills/harness-bootstrap/SKILL.md` (§ 2b migration patterns table, "Reference material" row)
**Prior:** split the row — rejected alternatives / closed design rationale → `docs/decisions.md § Closed Forks`; live reference examples → techstack § Coding Patterns.
