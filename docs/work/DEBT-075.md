# DEBT-075 — harness-bootstrap §2c staging list never names CODING_STANDARDS.md

**Logged:** 2026-08-21 · **Source:** DEBT-074 triage verdict — adjacent surface, different failure mode
**Problem:** `harness-bootstrap/SKILL.md` Phase 2c's explicit staging list (~lines 534-552) enumerates the files the scaffold commit stages and never names `CODING_STANDARDS.md`, which § 2a always scaffolds at the repo root (~line 190). It is covered only by the trailing catch-all "Any other adaptive files / folders created" — a file that is always created is not adaptive, so a literal reading of the list can leave it unstaged and the scaffold commit (now the handoff's pointer, per DEBT-073) incomplete.
**Area:** `plugins/super-bootstrap/skills/harness-bootstrap/SKILL.md` § 2c staging list
**Prior:** Add `CODING_STANDARDS.md` to the explicit list beside `CLAUDE.md`; check the same list for `docs/decisions.md`, `.claude/super-bootstrap-runway.json`, and the hook scripts while there. Harness edit — `audit-harness-edits` binds.
