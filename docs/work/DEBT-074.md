# DEBT-074 — super-bootstrap disclosure line under-reports what the run wrote

**Logged:** 2026-08-21 · **Source:** DEBT-073 triage verdict — third surface of the same under-report, scoped out as a different skill's contract
**Problem:** `super-bootstrap/SKILL.md` § Disclosure (post-hoc) emits `Wrote/changed: CLAUDE.md, .claude/settings.json, docs/ skeletons{, rules}. Review with \`git diff\`…` — the enumeration omits `CODING_STANDARDS.md` and the default-on hooks in `.claude/hooks/`, the item that most changes repo behavior. Same class as DEBT-072 (contract enumeration) and DEBT-073 (handoff), on the entry skill's disclosure line.
**Area:** `plugins/super-bootstrap/skills/super-bootstrap/SKILL.md` § Disclosure (post-hoc), ~line 73
**Prior:** Either complete the enumeration (CODING_STANDARDS.md, hooks) or collapse it to the pointer the line already carries (`git diff`) — pick by the same pointer-vs-inventory call DEBT-073 made. Harness edit — `audit-harness-edits` binds.
