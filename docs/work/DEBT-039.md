# DEBT-039 — release pre-flight warns on drain + release-init every release; inline rationale undocumented

**Logged:** 2026-08-01 · **Source:** `/release` v2.25.0 pre-flight (§1.5 dispatch-shell check), surfaced at session close
**Problem:** The dispatch-shell check warns on `drain` and `release-init` at every release: both SKILL bodies carry bounded-judgment verbs (classify / rank / scan) with no typed-agent dispatch, and `plugins/super-bootstrap/README.md` § Inline vs Dispatch documents only the principle table — no per-skill rationale rows. The check's own contract skips documented rows precisely because an un-silenceable warn trains the reader to ignore the check.
**Area:** `plugins/super-bootstrap/skills/drain/SKILL.md`; `plugins/super-bootstrap/skills/release-init/SKILL.md`; `plugins/super-bootstrap/README.md` § Inline vs Dispatch; `.claude/skills/release/SKILL.md` §1.5 (the check's contract)
**Prior:** Decide per skill: document the inline rationale as a README § Inline vs Dispatch row (silences the warn via the check's skip clause), or split into dispatch-shell + typed agent.
