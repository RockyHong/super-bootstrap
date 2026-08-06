# Carry — issue-wave (a4b13da1)

**Anchor:** GitHub issues #27–#33 absorbed via /pull-issue; quick wins shipped same session (DEBT-049 harness-paths, skeleton prose wave DEBT-048/050/051 + GAP-053 residual, released v2.29.3). Downstream order below is the settled remainder.

**Read first:** docs/work/BUG-026.md (incl. its three candidate shapes), docs/work/GAP-054.md (incl. its Amendment).

**State:** all seven issues closed with dispositions; cards BUG-026 + GAP-054 remain from the batch. v2.29.3 tagged; skeleton fixes reach consumers on next sync.

**Next step (settled downstream order):**
1. BUG-026 — design discussion first (cluster 2): pick among the card's three shapes (stamp coverage list / withhold stamp on incomplete coverage / durable decline marker) before any build. Shape 3 is what harness-bootstrap SKILL.md § 2b already gestures at unimplemented.
2. GAP-054 — triage probe after BUG-026's direction lands: discriminate whether 2b treats an absent pipeline-owned section as drift (SKILL.md:128 nominally covers § Edit Discipline; observed re-run didn't backfill). Likely folds into the BUG-026 fix family (sync-completeness).

**Watch-outs:** BUG-026 is a design fork — don't route it straight to implement; the user picks the shape. GAP-053's scope was narrowed by amendment before resolution — the shipped rider-note fix is the whole residual, don't reopen the LSP-category ask.
