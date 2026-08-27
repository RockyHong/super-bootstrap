# DEBT-104 — the commit door has no guard against a shared index: a concurrent session's staged paths ride into this session's commit

**Logged:** 2026-08-27 · **Source:** two sessions in one checkout — one `git add`-ed five paths, the other's `git commit` landed seconds later and swept them in; split by soft-reset afterwards
**Problem:** [`commit/SKILL.md`](../../plugins/super-bootstrap/skills/commit/SKILL.md) § 5 stages by explicit path and never `-A`, but reads nothing back from the index before `git commit`: whatever another session (or a background agent) already staged is committed under this session's message. Session isolation is enforced at `git add` only, while the commit records the whole index. Same hole on the audit stamp — it fingerprints `git diff --cached --name-only`, so a foreign staged harness path widens the stamped set.
**Area:** `plugins/super-bootstrap/skills/commit/SKILL.md` § 5 (message + commit) · `skills/commit/assets/doc-links.sh` untouched · optionally `audit-harness-edits` stamp step (device skill — `/contribute`, not a local edit)
**Prior:** in § 5, after `git add <explicit paths>`, diff `git diff --cached --name-only` against the session file list; a path outside it → stop and surface (unstage-and-continue / abort), never commit through it. Keep `git add` + check + `git commit` in one flow so no window opens between them. Land after DEBT-101 / DEBT-102's in-flight edits to the same file.
**Test-feel:** manual
**Blast:** local
