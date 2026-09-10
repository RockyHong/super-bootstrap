# Carry — dogfood runway sync (DEBT-114), halted at the approval gate

**Anchor:** `/super-bootstrap:harness-bootstrap` re-run on this repo — receipt 2.39.0 vs plugin 2.49.0. Drift walk done, **nothing written to the harness yet**.

**Read first:** [`docs/work/DEBT-114.md`](../docs/work/DEBT-114.md) § Amendment (2026-09-10) — carries the two-lane finding, the completed walk's result, and the three pending writes · `.claude/bootstrap-sync-report.md` (untracked, keep) — full per-section enumeration; re-use it, don't re-derive · [`docs/work/DEBT-115.md`](../docs/work/DEBT-115.md) — the prose-lane sibling logged this session.

**State:** Phase 1 + 2a/2b comparisons complete under enforced `version_stale`. Everything sha-current except: root `AGENTS.md` absent (`⊕ new`), two consult-check settings snippets not deep-equal to asset (quoting only), receipt stale. Four `declined` rows re-confirmed dogfood-specific; `docs/work/README.md`'s row re-typed mixed → DEBT-115. Rot scan clean, 2b-adopt no collisions, scale + drain infra current. The user asked for a proposed order and had not answered it when the session broke.

**Next step:** get the go on the proposed **1 → 2 → 3**, then execute in that order.
1. Write the golden rule into [`.claude/rules/repo-boundary.md`](../.claude/rules/repo-boundary.md) — two-lane § Sync direction + three literal doc paths in `paths:` (DEBT-115 half b). Harness edit → `audit-harness-edits` after.
2. Propagate the five consumer-safe links into the three skeleton assets (DEBT-115 half a) — its own commit, `[CODING_STANDARDS.md]` link excluded.
3. Finish this run: place `AGENTS.md` + register it, replace the two snippets, overwrite the receipt to 2.49.0, then Phase 2c commit and delete the sync report. Resolves DEBT-114.

**Watch-outs:**
- `.claude/bootstrap.md` stays unseeded — decided, not pending (167 commits past `3eff71a`; Tasks 1/2 both drop).
- Don't re-read the four `declined` rows as fresh drift — the Amendment already types them; the receipt's flat `declined` list carries no reason field, which is the amnesia this cost a full walk to undo (candidate GAP, unlogged).
- Step 3's receipt write must read `placed` back **off disk** after the hook steps run, not from the Phase 1 snapshot.
- Ordering matters: 1 before 2, so the rule that should have caught the miss exists before the miss is repaired.
