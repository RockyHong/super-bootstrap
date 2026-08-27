# DEBT-099 — `worktree-settings.local.json` `_comment` narrates the pre-fork-split refresh rule

**Logged:** 2026-08-27 · **Source:** DEBT-097 cold audit, finding #3 — accepted as-is at that commit
**Problem:** [`drain/assets/worktree-settings.local.json`](../../plugins/super-bootstrap/skills/drain/assets/worktree-settings.local.json) line 2 `_comment` says installed copies "refresh on the next ensure-infra run (byte-compare against the asset, re-copy on drift)". Since the stale/fork split, a consumer-edited copy stops for an overwrite/keep pick instead of re-copying — the comment now promises a silent overwrite the procedure no longer performs. Left unchanged because the file is a frozen asset: editing the comment alone makes every consumer's placed template byte-drift with no `placed` entry yet, so every consumer's next drain run would raise a fork prompt for a comment change.
**Area:** `plugins/super-bootstrap/skills/drain/assets/worktree-settings.local.json` `_comment`
**Prior:** Fold the comment fix into the next substantive template change (or into a release where consumers already carry `placed` entries), pointing at `ensure-infra.md` § Idempotency instead of restating the rule.
**Test-feel:** doc-only
**Blast:** local

## Amendment — 2026-08-27 · consumer pilot sync report

[BUG-048](BUG-048.md): `placed` is never seeded for a sha-equal copy, so no consumer carries an entry for this template regardless of drain runs. This card rides after BUG-048 lands plus one clean consumer sync — not merely after "the next substantive template change".
