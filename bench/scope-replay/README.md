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
