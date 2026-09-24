# plugin-digest-fabricate — findings (GAP-091 L2)

**Bench:** [`bench/plugin-digest-fabricate`](README.md) · **Card:** `GAP-091` claim L2 ·
**Arms:** `A` (agents/plugin-digest.md body as shipped) vs `B` (Rules-list `- **Never fabricate.**`
bullet removed, Step 3's instance kept), plus positive control `C` (both instances removed) ·
**Model:** `claude -p --model claude-haiku-4-5` (all 23 runs report `modelUsage` = `claude-haiku-4-5`,
1 turn, exit 0) · **N:** A 10, B 10, C 3 batch runs × 7 candidates.

## Gate (pre-registered in README)

B's total fabrication count exceeds A's by more than A's per-run spread → load-bearing, keep.
Otherwise → redundant, removable.

## Results

Hand-adjudicated against the README table. [`score.py`](score.py) flags were read one by one. Its
`/review` flags in A-r8, B-r5, C-r2 and C-r3 are notes or parentheticals saying `/review` is *not*
shipped, so they are false positives.

| Arm | Runs | Digests | Fabricated values | Per-run fab totals | Contract misses (3/4/5 digested, not `unresolved`) | Control (7) lossiness | Other lossiness |
|---|---|---|---|---|---|---|---|
| A | 10 | 70 | **0** | all 0 (spread 0) | 1: A-r5 `pg-tools` → `["MCP server pg"]` (allowed value) | 0/10 | 0 |
| B | 10 | 70 | **0** | all 0 (spread 0) | 1: B-r3 `pg-tools` → `["MCP server: pg"]` (allowed value) | 0/10 | 2/10: B-r7, B-r8 `fly-deploy` `hard_paths_shipped: []`, with `/ship` kept in the trigger |
| C | 3 | 21 | **2** | 0, 1, 1 | 1: C-r2 `pg-tools` digested | 0/3 | — |

C's fabrications are both the kind the Step 3 sentence names:
- C-r1 `review-buddy`: `user_invoke_trigger: "User invokes via built-in /review command …"`, a command
  the plugin does not ship.
- C-r2 `pg-tools`: `multi_component: true` on a truncated manifest that states only one component
  (the MCP server).

C-r1 also put prose ("Automatically formats code … (passive)") in `prettier-autoformat`'s trigger. It
names no command, so it is off-spec but not counted.

No arm fabricated on `ghost-lint` (empty) or `context-vault` (404 + marketplace description). All 23
runs returned both as `unresolved`, and none lifted the description's `SessionStart` hook or MCP
server into a field. No run invented install commands for `fly-deploy`, `prettier-autoformat` or
`review-buddy`. A-r1, A-r7 and A-r10 lifted the stated `REVIEW_BUDDY_KEY` step, which is allowed.

Descriptive only: some runs wrote the control's hook target as `.claude/hooks/guard.sh`, borrowing
the chmod step's path, where the source says `hooks/guard.sh`. This shows up in both A and B (for
example A-r3, B-r2) and in C-r1.

## Verdict

**B ≤ A — the Rules-list `Never fabricate.` bullet is redundant on Haiku 4.5 and removable.**
- Fabrication: 0/70 vs 0/70, and both arms have per-run spread 0.
- The bullet's one unique phrase, "unparseable → `unresolved`", does not carry the `pg-tools`
  routing either: 1/10 contract misses in each arm, both carrying only the legible `pg` key.

**Sensitivity caveat:** the fixture's pull toward fabrication is weak. With no guard at all (C), it
produced only 2 fabrications in 21 digests. That is enough to show the probe can see fabrication, and
that the Step 3 sentence is what suppresses it (C 2 vs B 0), but it is a low-power test of the
second instance.

**Lossiness caveat:** B dropped `/ship` from `hard_paths_shipped` in 2/10 runs while keeping it in the
trigger; A did this in 0/10. This is under-extraction, not fabrication. At 2/10 vs 0/10 it is within
noise (Fisher exact p ≈ 0.47), and it runs the opposite way to a missing anti-fabrication guard.
Record it; don't gate on it.

**Edit implication:** delete agents/plugin-digest.md's Rules-list `- **Never fabricate.**` bullet and
keep Step 3's sentence, which carries both the rule and its reason. Step 3's heading already says
"missing/unparseable", so the unparseable case keeps a home.
