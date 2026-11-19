# DEBT-wnah — harness-bootstrap reads "fresh vs re-run" by two different criteria

**Logged:** 2026-11-19 · **Source:** DEBT-ymdg session — a build agent's cold walk of `harness-bootstrap/SKILL.md` after Phase 1 gained its file-state read
**Problem:** The skill decides "fresh install or re-run" two ways. Phase 1 § Existing CLAUDE.md reads the files present (fresh / split / legacy). The Phase 2 intro and § 2b's rot scan key on whether git history holds a bootstrap-shaped commit. On a repo with a hand-written `CLAUDE.md` and no harness file the two can disagree: Phase 1 reads fresh while a commit-keyed step reads the other way, or the reverse after a squashed history. Which criterion binds each step is not stated. The commit-keyed read is older than the ownership split; the file-state read arrived with it.
**Area:** `plugins/super-bootstrap/skills/harness-bootstrap/SKILL.md` — Phase 1 § Existing CLAUDE.md, Phase 2 intro, § 2b rot scan
**Prior:** One criterion for the whole run, or each commit-keyed step states why history rather than files is its signal.
