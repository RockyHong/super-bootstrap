# lean-brief-numbers — findings (DEBT-118 M6)

**Bench:** [`bench/lean-brief-numbers`](README.md) · **Card:** `DEBT-118` M6 ·
**Target:** [`harness-bootstrap/SKILL.md`](../../plugins/super-bootstrap/skills/harness-bootstrap/SKILL.md) § Principles,
bullet "Precision per always-on byte" · **Reader:** `claude -p --model opus` · **N:** 3 per arm per task

## Pre-registered gate

> Written before the first run fired.

**Claim.** Dropping "~120-line target" and "~80k context = 100% recall" (proposed rewrite) does not
change what the executor does with the principle. Light RED: equivalence, not improvement.

**Per run, four assertions** ([`score.py`](score.py)): FORMAT · FLUFF (≥ 80 % of labelled fluff cut)
· SIGNAL (≤ 1 labelled signal line cut) · NUMBER (STOP sentence does not justify the stop point by a
line-count number / 120 / 80k; task a also fails at ≤ 135 kept lines = cutting toward ~120 as a quota).

**Verdict rules** (compare per task, 3 runs each; means over fluff cut and signal cut):

- `proposed ≈ current` — per task, mean fluff cut and mean signal cut differ by ≤ 1.5 lines between
  the arms, and per-assertion FAIL counts differ by ≤ 1 run.
- `proposed worse` — proposed exceeds current on signal cut by > 1.5 mean lines, or trails it on
  fluff cut by > 1.5, or fails ≥ 2 more runs on any assertion.
- `proposed better` — the mirror of `worse`.
- `inconclusive` — a difference past the ≈ band whose within-arm ranges (min–max) overlap entirely.

**Does the bullet bite?** Same rules, `no-principle` vs `current`. `≈` → the bullet does not move
behavior on this probe (recorded, not acted on — M6 is a rewrite, not a removal).

## Instrument validity

- **Arms are the shipped bytes.** [`build.py`](build.py) slices § Principles live from the in-repo
  dev `SKILL.md` and aborts unless the "Precision per always-on byte" bullet is byte-equal to the
  quoted current text; the three `arms/*.md` differ only on that one line (`diff` in the README).
- **Decontaminated reader.** A probe without `CLAUDE_CODE_DISABLE_CLAUDE_MDS=1` had the reader quote
  `# Global Rules` from the device `~/.claude/CLAUDE.md`; with it the reader answered `NO` — every
  scored run carries the env var plus `--setting-sources project --tools "" --strict-mcp-config`
  from an empty scratch cwd.
- **Bite check — every assertion fails on an induced bad output.**
  [`bite/bite-check.txt`](bite/bite-check.txt), verbatim FAIL lines (exit 1):

```
induced-a-quota: SIGNAL FAIL — signal cut 20 ['L003', 'L004', 'L009', 'L010', 'L011', 'L012', 'L013', 'L014', 'L015', 'L016', 'L017', 'L018', 'L023', 'L024', 'L025', 'L026', 'L027', 'L028', 'L029', 'L034']
induced-a-quota: NUMBER FAIL — STOP cites '~120'; kept 134 <= 135 (quota-shaped cut)
induced-a-sigcut: SIGNAL FAIL — signal cut 3 ['L003', 'L004', 'L009']
induced-a-silentquota: SIGNAL FAIL — signal cut 25 [...]
induced-a-silentquota: NUMBER FAIL — kept 129 <= 135 (quota-shaped cut)
induced-b-early: FLUFF FAIL — fluff cut 5/20 (need >= 16)
induced-b-early: NUMBER FAIL — STOP cites 'under the 120'
induced-b-format: FORMAT FAIL — CUT line missing; unknown IDs none
induced-b-format: FLUFF FAIL — fluff cut 0/20 (need >= 16)
```

  The two `induced-*-good` controls pass all four. (`silentquota` list elided here; full in the file.)

## Results

Run 2026-09-24, `claude -p --model opus`, N = 3 per arm per task, 18 runs, all exit 0.
Full table + every STOP sentence: [`runs/scores.tsv`](runs/scores.tsv); raw returns: `runs/<arm>-<task>-r<n>.txt`.

| Arm | Task | r1 fluff / signal / kept | r2 | r3 | Assertions | Spread |
|---|---|---|---|---|---|---|
| current | a (169 lines, 15 fluff) | 15/15 · 0 · 154 | 15/15 · 0 · 154 | 15/15 · 0 · 154 | 12/12 PASS | 0 |
| proposed | a | 15/15 · 0 · 154 | 15/15 · 0 · 154 | 15/15 · 0 · 154 | 12/12 PASS | 0 |
| no-principle | a | 15/15 · 0 · 154 | 15/15 · 0 · 154 | 15/15 · 0 · 154 | 12/12 PASS | 0 |
| current | b (92 lines, 20 fluff) | 20/20 · 0 · 69 | 20/20 · 0 · 69 | 20/20 · 0 · 69 | 12/12 PASS | 0 |
| proposed | b | 20/20 · 0 · 69 | 20/20 · 0 · 69 | 20/20 · 0 · 69 | 12/12 PASS | 0 |
| no-principle | b | 20/20 · 0 · 69 | 20/20 · 0 · 69 | 20/20 · 0 · 69 | 12/12 PASS | 0 |

The cut **sets** are identical, not just the counts: all 9 task-a returns carry one CUT list (the 15
fluff IDs), all 9 task-b returns another (20 fluff IDs + `L087–L089`, the blank / `## Notes` / blank
left empty once its three fluff lines go — structural, not signal). No run cited a number in STOP;
no run's STOP mentions 120, 80k, or any line target. Every STOP, in every arm, justifies the stop the
same way — "every remaining line sharpens a decision; further slimming = relocating to
`.claude/rules/`, which a deletion-only pass can't do".

## Verdict

**`proposed ≈ current`** — 0-line difference on every reading, 0 spread in each arm, 12/12 assertions
passing in both arms. The rewrite does not change what the Opus executor does with the principle on
this probe; the ~120 number neither pulled task a toward a quota nor let task b stop early under it
in the current arm, so dropping it loses nothing measurable.

**`no-principle` ≈ `current` — the bullet does not bite on this probe.** With the bullet removed the
reader cuts the same lines and stops for the same reason. The only visible arm effect is vocabulary:
current / proposed STOP sentences echo the bullet ("sharpens a decision", "decision moment"),
no-principle ones borrow "silent miss" from the adjacent Default-to-rules bullet. Behavior is set by
the task ("cut what doesn't earn its place") plus the Opus prior plus the sibling Layer-by-decision-
moment bullet (every arm proposes relocating to `.claude/rules/`).

**Limits.** Ceiling effect: the fluff is clear-cut platitude by construction (the labels had to be
defensible), and the deletion-only frame removes the rewrite/compress lane where a line-count pull
would most plausibly show. A borderline-signal fixture or a free-rewrite task could still separate
the arms; this bench shows only that the numbers are inert on a clean-labelled deletion task. N = 3.
