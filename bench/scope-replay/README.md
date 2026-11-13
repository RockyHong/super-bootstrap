# scope-replay

Replays the commit door's four scope lanes (`commit/SKILL.md` §3: citers, grep hits, link-targets, changed docs) over historical commits, and lists the hub-doc citers no lane reaches. Reads both repos without writing to them.

## Fixture

- Repos: this repo at `35b4c3e`, and `magnetized-remake` (`mr`) at `c70a5c43`.
- Script under test: `doc-links.sh` at `35b4c3e` (`head`). `old` is the copy at `24d0382`. The copy at `a14b5dd` is byte-identical to `head`.
- Session-list assumption: a whole commit is one door run's session list. Merges are left out. `docs/work/*` and `docs/outward/OUT-*.md` paths leave the gate, as §3's exemption says. A commit with only those paths skips the gate and is counted separately.
- Each commit's doc surface comes from `git archive` with `core.autocrlf=false`. Scope bytes are blob sizes at that commit.
- Lanes not run: `term-uses` and `volatile-ids`. They add no scope docs. A deleted doc takes no `refs` query, because `anchors` prints nothing for it. Link-targets follow §3's regex over every non-exempt added line, bench markdown included.

| Set | Filter | Ends at |
|---|---|---|
| `sb-recent`, `mr-recent` | last 30 gate-reaching | HEAD |
| `sb-24d-gate` | last 30 gate-reaching | `24d0382^` |
| `sb-24d-doc`, `sb-24d-doc45` | last 30 or 45 with a doc-surface path | `24d0382^` |
| `sb-et1c-doc`, `mr-et1c-doc` | last 15 with a doc-surface path | `a14b5dd^` and the same time in `mr` |
| `sb-et1c-doc40`, `mr-et1c-doc40` | last 40 with a doc-surface path; `self > 0` picks the filter probe's rows | as above |
| `ctrl-4451477d` | the 16-file diff with a recorded 29-doc scope | one commit |

## Run

```bash
export REPLAY_DIR=<scratch dir> SB_REPO=<this repo> MR_REPO="<magnetized-remake>"
bash replay.sh all results     # results/commits.tsv, results/pairs.tsv
bash summarize.sh results/commits.tsv > results/summary.tsv
```

`results/judged.tsv` holds one reader's class per citer line, on `pairs.tsv`'s rows deduplicated by commit. The script does not derive it.

Pair classes, read against the commit's changed section:

- **pointer-only**: the line sends the reader to the hub and states no fact the section holds.
- **restating**: the line states a fact the section holds. `note` says whether that fact is in the commit's changed text or in an unchanged row.
- **stale**: the commit's changed text makes the line wrong.

## Findings

Crossing rate, HEAD script:

| Set | Crossing | Median scope | Median bytes | Median bytes, crossing only |
|---|---|---|---|---|
| `sb-recent` | 10/30 | 6 | 77 KB | 143 KB |
| `mr-recent` | 21/30 | 13 | 901 KB | 1025 KB |
| `sb-24d-gate` | 2/30 | 3.5 | 30 KB | not used |

Card-only commits inside each span skip the gate: 7 in `sb-recent`, 7 in `mr-recent`, 13 in `sb-24d-gate`. Counted as door runs, the rates are 10/37, 21/37 and 2/43. Only commits with `self > 0`: `sb-recent` 8/12, `mr-recent` 19/21.

The earlier replays reproduce as follows:

- The 29-doc scope reproduces exactly on `4451477d`.
- `mr`, with `self > 0` as the filter: 15/15, the recorded figure, with `4451477d` in the sample. Median 28.
- This repo, same filter: 11/15 against the recorded 13/15. Median 11. Pooled median 14 against the recorded 21. No stored list exists, so the difference stays open.
- `24d0382`'s window: 2/30 under the gate filter and 4/30 under the doc filter, median 3.5 and 5.5, max 11. The record says 3/30, median 4.5, max 11.

Cause of the 3/30 and 28/30 gap:

- Lane code does not cause it. Both scripts print the same rows on `24d0382`'s window, and on `sb-recent` the old script crosses more (15/30 against 10/30).
- The replay does not cause it, as the reproductions above show.
- Three things cause it: the filter (`self > 0` against all gate runs), the pool (`mr`'s 15/15 was added), and a rise in this repo's commits. On one filter, this repo goes from 6/30 at `24d0382` to 19/30 at `a14b5dd`. The surface stayed at 12 and 13 docs, and median link-targets on doc commits rose from 1 to 3 and 4.

Bytes do not follow the ceiling. `mr-recent`'s largest scope under the ceiling is 718 KB, and `docs/overview.md` alone is 382 KB. `sb-recent`'s smallest crossing scope is 30 KB. The cold arms in [`bench/doc-sync/README.md`](../doc-sync/README.md) cost 69–80k tokens on a 5-doc fixture. No bench measures either lane at 1 MB.

Unreached hub citers, 87 pairs (commit × hub × citer × kind). All are judged, none sampled:

| Repo and window | Link pairs | Mention pairs | Restating | Stale |
|---|---|---|---|---|
| this repo, recent | 22 | 1 | 11 | 0 |
| this repo, `24d0382` | 11 | 8 | 8 | 0 |
| `mr`, recent | 42 | 3 | 12 | 0 |

One restating pair is on changed text (`docs/parked.md` at `a14b5ddc`). 30 are on unchanged rows of the `closed-forks` table, which is one section for the whole file. Most pairs have `decisions.md` as the hub.

`docs/overview.md` at `cd3d85a3` calls the term-ledger row "closed", while that row reads "Overturned — card reopened". That commit's changed text did not cause this, so the pair is not stale under the class above. Read against the whole section, it is one stale unlinked mention. The line is still at `35b4c3e`.

Limits: one reader judged the pairs. Unchanged rows were checked by keyword only, and four `mr` citers' rows were not located (lv60 curves, SOC, colour register, the in-game line).

## Code-origin term arms

`arms.sh` replays the grep lane under alternative term rules for a changed path off the doc surface; its header defines the arms. The other three lanes are the same in every arm. Fixture: `mr` at `3891bf41`, this repo at `d25164e`, the last 30 commits in each that change a term-yielding path off the doc surface, plus `ctrl-3891bf41` — a two-line diff with a recorded 24-doc scope.

```bash
export REPLAY_DIR=<scratch dir> SB_REPO=<this repo> MR_REPO="<magnetized-remake>"
bash arms.sh all results                      # results/arms-{commits,dropped,terms,summary}.tsv
bash arms.sh parity <doc-links.sh> results    # results/arms-parity.tsv
```

`AB`: a code-origin term that alone hits more docs than the ceiling is demoted to hub-stem matching, and the symbol-shaped identifiers on its path's changed lines join the terms. The door runs it as `doc-links.sh grep-scope`, with one narrowing: a term is demoted only when every changed path that yields it is a modified file off the doc surface, so an added, deleted or renamed path keeps its path mentions in scope.

- `mr` commits changing no doc (9): crossings 4 → 0, mean scope 8.6 → 3.4. `mr` commits that also change a doc (21): 21 → 21 in every arm; their scope comes from the doc-origin lanes.
- This repo: no term is demoted in 30 commits; `AB` equals `head` on every row.
- `ctrl-3891bf41`: 24 docs → 8, the three that name the changed constant among them.
- On these 60 commits `AB` widens no scope. `A-all` widens 53 and `A-shaped` 9; `A-shaped` drops the most docs (87 in `mr`, 58 here).
- What `AB` drops, `results/arms-judged.tsv`: 68 (commit, doc) pairs over 12 `mr` commits — 63 pointer-only, 5 restating an unchanged neighbouring fact, 0 stale.
- `grep-scope` equals `AB` on 61 of 61 commits (`results/arms-parity.tsv`): no demoted term in the fixture comes from a path the narrowing holds back.

A finished commit cannot show a catch the rule would lose: a doc the door caught as stale was fixed inside that commit, so it sits on the changed-doc lane. `prefix.sh` covers that side.

## Pre-fix replay of recorded catches

`prefix.sh` takes the door's recorded real catches that the grep lane brought into scope (`results/prefix-cases.tsv`: 30 cases from 30 days of door runs, 26 in `mr` and 4 here, plus 2 excluded rows where the judge's own grep found the doc) and replays each at its pre-fix doc surface; its header defines the surface and the verdicts.

```bash
bash prefix.sh results/prefix-cases.tsv <out.tsv>            # NOPRE=1: non-doc paths only
```

`results/prefix-catches.tsv` is that output with `other_lane` and the `NOPRE=1` re-run joined into `note` by hand.

- Kept 26, lost 0, not-grep 4. With non-doc paths only on every row: kept 23, lost 0, not-grep 7.
- 8 kept rows have a demoted term (`game`, `ui-strings`, `audio`, `level_sheet`, all `mr`); the other 18 are kept by construction. In 3 rows the baseline reaches the stale doc through a demoted term alone, and the added identifiers reach it.
- The rule can widen a scope here: 28 → 29 and 13 → 18, where an added identifier hits a doc the basename did not. Both scopes are over the ceiling either way.
- The 4 not-grep rows: the stale doc names the changed file in prose only, or was a changed doc itself.

Limits: every demotion comes from one consumer repo and four terms. The pre-fix surface approximates the working tree the door saw; 5 of the 13 pre-gate doc lists are inferred. The case list holds caught docs only, so this is recall over known catches, not a miss rate.
