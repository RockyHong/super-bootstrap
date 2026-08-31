# doc-sync container read-out — scoring sheet

Skeleton. Grids are empty until a round runs; the answer key below is filled and
is the only place in this directory it appears. `check-key-absence.sh` enforces
that — it reads the leak-literal list at the bottom of this file and fails if any
of them reaches `prompts/` or `parts/`.

Protocol, bounds and fixture provenance: [`README.md`](README.md).

---

## Fixture 1 — `d3161f3` replay · coverage axis

### Answer key

Recovered from git history, three independent sources, none of which any arm can
reach (the arms run tool-restricted to Read/Grep/Glob inside a worktree whose
`HEAD` is `d3161f3` — the fixes all postdate it):

- `5e7cb31` — *fix(doc-sync): compare claims across docs, not only terms*. Its
  message carries the measured arm results on this exact fixture.
- `10916e9` — *docs: supersede the mattpocock opt-in posture with pairing*. Its
  message names the drift outright: "§4, §6 and decisions row 21 kept asserting
  'per-repo adaptive pick, bootstrap pins nothing' while the runbook said
  otherwise, and a reader entering through the spec got the superseded answer."
- The `DEBT-062` card body (`git show a6c59e7^:docs/work/DEBT-062.md`), which
  names both contradictions and grades their difficulty against each other.

**K1 — carried-questions list mismatch.** *(easy — list versus list)*

| | |
|---|---|
| Stale doc | `docs/specs/harness-architecture.md` § "Questions carried into live coexistence" (§7) |
| Stale because | §7 lists three carried questions — head-contract content, drain's wall-vs-progress ratio, his set's ambient token weight. The new runbook's Watch list cites *that very section* as its source and lists five: it adds three §7 does not carry (his discipline layer inside sb-dispatched subagents · his lane committing outside the commit door · field-shape breaks) and drops one §7 does (drain's ratio). |
| Diff hunk | the new file `docs/specs/mattpocock-coexistence.md`, § Watch list |
| Shape | reachable by the linked-line residual lane — the asserting line carries an anchored link to its target, compared per entry. DEBT-062: "any arm that reaches it reports it." |

**K2 — install-posture contradiction.** *(hard — judgment fork)*

| | |
|---|---|
| Stale docs | `docs/specs/harness-architecture.md` §6 *Decided — coexistence (change B)* — "mattpocock/skills enters a repo only as a per-repo adaptive pick in `resolve-plugins` — bootstrap pins nothing", and later "the opt-in posture plus the `pre-mattpocock` rollback tag". Also §4's closing paragraph, which the diff carries as an **unchanged context line** three lines from a changed one. And `docs/decisions.md` row 21 — "Shipped instead: coexistence with per-repo opt-in via `resolve-plugins`". |
| Stale because | the new runbook opens "**Posture: device-level unify.** The plugin installs user-scoped once and is visible in every repo." |
| Diff hunk | the new file, opening posture paragraph |
| Shape | judgment fork, not a coverage miss. DEBT-062: 3 of 6 arms *enumerated* it and cleared it as an install-scope-versus-adoption-scope layer distinction. They are wrong — the runbook's own "splitting back to per-repo opt-in later is a per-repo disable" settles it — but wrong on a defensible-looking distinction. |

A `clean` return misses both.

### Cold-arm priors on record

Same fixture, same replay protocol, Sonnet ×3 per round. These are the numbers
the new arms have to be read against; N=3 was chosen to keep them comparable.

| Round | Source | K1 | K2 | `clean` |
|---|---|---|---|---|
| pre-step-4 scanner prose | `5e7cb31` message | 0/3 | 0/3 | 3/3 |
| step-4 prose (as `5e7cb31` shipped it) | `5e7cb31` message | 2/3 | 1/3 | 0/3 |
| shipped-prose condition | `DEBT-062` Amendment | one named in 2/3 | — | 1/3 |
| coverage-line-contract condition | `DEBT-062` Amendment | one named in 2/3 | — | 1/3 |
| phase-D v3 — **the door as shipped today** | `GAP-058` Progress 2026-08-12 | **3/3** | **0/3** | 0/3 |

`DEBT-062`: no arm in either of its conditions named both. Cost on record:
~69–80k subagent tokens and 6–10 tool calls per arm.

### Coverage grid

`Y` = named as a candidate with a concrete staleness. `~` = enumerated then
cleared (K2's known failure mode — record it, it is not a miss of the same kind).
`n` = never reached. FP = candidates that are not K1/K2, judged individually.

| Arm | Repeat | Return shape | K1 | K2 | FP | Tool calls | Tokens | Notes |
|---|---|---|---|---|---|---|---|---|
| cold (Sonnet) | 1 | `clean` | n | ~ | 0 | 6 turns | 72k cr / 11.4k out | K2 cleared: "兩者主語不同…並無矛盾" — the recorded defensible-distinction failure, verbatim class |
| cold (Sonnet) | 2 | `stale-docs` | Y | ~ | 0 | 6 turns | 71k cr / 10.4k out | K1 full per-entry roster diff; K2 cleared: "対象が異なる問いに答えている" (answered in Japanese) |
| cold (Sonnet) | 3 | `stale-docs` | Y | n | 0 | 6 turns | 48k cr / 11.9k out | K1 named; §6 posture never engaged — decisions.md cleared as "無受 diff 影響的宣告" |
| warm (Sonnet) | 1 | `stale-docs` | n | n | 1 | 6 turns | 86k cr / 6.3k out | Sole candidate: §6 "cost is deleting the mattpocock-coupled cards" vs the diff deleting the only such card — plausible genuine find, outside the key |
| warm (Sonnet) | 2 | `stale-docs` | ~ | Y | 0 | 6 turns | 88k cr / 11.8k out | K2 via install-path reading: runbook flow bypasses `resolve-plugins`, §6's "only" broken; K1 enumerated then cleared "互相一致" |
| warm (Sonnet) | 3 | `stale-docs` | n | Y | 0 | 6 turns | 49k cr / 10.6k out | K2 same install-path reading; K1 never mentioned |
| opus-control | 1 | `stale-docs` | Y | Y | ~3 | 9 turns | 328k cr / 10.2k out | 7 candidates incl. parked fact-fields "only plausible home" + techstack resolve-plugins line |
| opus-control | 2 | `stale-docs` | Y | Y | ~3 | 6 turns | 197k cr / 8.9k out | 7 candidates; flags the decisions-row ambiguity explicitly as gateway-judgment |
| opus-control | 3 | `stale-docs` | Y | Y | ~2 | 6 turns | 192k cr / 10.2k out | 6 candidates; K2 spans §6 + §4 context line + both decisions rows |

| Arm | K1 | K2 | both | `clean` |
|---|---|---|---|---|
| cold (Sonnet) | 2/3 | 0/3 | 0/3 | 1/3 |
| warm (Sonnet) | 0/3 | 2/3 | 0/3 | 0/3 |
| opus-control | 3/3 | 3/3 | 3/3 | 0/3 |

**Read-out question.** Is the warm−cold gap larger or smaller than the
cold-Sonnet−cold-Opus gap? The Opus row exists only to give the container gap a
scale — see [`README.md`](README.md) § The Opus arm is a control.

---

## Fixture 2 — techstack fork-free-inner-loops, Run B revision · stability axis

No answer key exists and none can be constructed: Run A said `clean` and Run B
said `stale-docs` on the same doc entry, and the gateway picked Run B by its own
judgment, not by anything either return established. That dispute *is* the card's
Amendment. This fixture scores agreement, not correctness.

**The target verdict** — every arm is pointed at the same entry by the fixed
prompt: does `docs/techstack.md` § Coding Patterns' "Fork-free inner loops in
shell assets" bullet come back `stale` or does it hold as written?

Classify each return into exactly one:

- `S` — `stale-docs` naming the fork-free-inner-loops entry
- `C` — `clean`, or `stale-docs` that does not name that entry
- `X` — malformed / no parseable verdict

### Agreement grid

| Arm | R1 | R2 | R3 | Modal | Agreement | Tokens |
|---|---|---|---|---|---|---|
| cold (Sonnet) | S | S | S | S | 3/3 | 31–45k cr / ~5k out |
| warm (Sonnet) | S | S | S | S | 3/3 | 33–53k cr / ~4k out |

**Historical datum, N=1 per condition, from the session store:** the original
Run B — cold Sonnet, this exact prompt — returned `S`. Run A, the same agent at
the same tier over the same scope doc against the *previous* revision (strictly
more forks), returned `C`. Agreement across those two is 0/2 in the direction
opposite the change. Whether that is container-borne or tier-borne is what the
warm row is here to say.

Per-repeat stated reason matters as much as the verdict — record the sentence the
arm justifies itself with. Run A's was "the entry's cost prose is about the
success path"; Run B's was "the entry's claim is literal and absolute".

| Arm | Repeat | Verdict | Stated reason (quote) |
|---|---|---|---|
| cold (Sonnet) | 1 | S | "條目以無條件語氣斷言" — 但 miss path 上有 fork |
| cold (Sonnet) | 2 | S | 理由段 "one helper fork per link…" 精確描述縮放問題，新函式迴圈 per-slug-table-entry 違反 |
| cold (Sonnet) | 3 | S | "keeps subprocesses out of its per-item loops — made stale"; 逐 call 分析 fork 行為 |
| warm (Sonnet) | 1 | S | "an absolute claim … the no-per-item-fork claim does not [hold], for the miss-path loop"; globals-return 半句仍成立 |
| warm (Sonnet) | 2 | S | 항목이 절대적 주장 (answered in Korean); 並主動提出解消方向（條目加 miss-path 例外一行） |
| warm (Sonnet) | 3 | S | early return 符合條目意圖，但 non-ASCII 表面上 per-slug 迴圈仍 fork — 逐半句判斷後仍判 stale |

All six arms read the entry the way Run B did ("literal and absolute"), none the way
Run A did ("cost prose is about the success path") — including the warm arms, which
held the gateway's own cost rationale for the early return and still returned `S`.
On a fixed prompt the verdict is container-stable at N=3; the historical Run A/B
inversion is therefore attributable to the varied inputs (different revision +
different gateway narration per dispatch), not to the container.

---

## Environment

Filled from `runs/ENV.txt`, which `run.sh` writes before the first arm.
Cross-date comparison is suspect when the device-hook set changed — see
[`../consult-hook/bench-decontamination.md`](../consult-hook/bench-decontamination.md)
channel 3.

| | |
|---|---|
| Date run | 2026-08-31T18:18Z – 2026-09-01 (f1-cold first round; remainder after the run.sh stdin fix) |
| `claude --version` | 2.1.251 (Claude Code) |
| Device hook set | recorded in `runs/ENV.txt`; arms ran `disableAllHooks` |
| Arms completed / attempted | 15 / 15 (one aborted f1-warm r1 from a killed round discarded and re-run) |

**Language noise observed:** arm output language varied freely (zh/ja/ko/en) against
an English prompt — no verdict impact seen, but it is a reminder that surface-form
variance at this tier is high even where verdict variance is low.

---

## Leak literals

`check-key-absence.sh` reads the fenced block below verbatim, one literal per
line, and fails the round if any appears in `prompts/` or `parts/`. Each is a
string that only the answer, its provenance, or the eventual resolution contains
— never the fixture diff itself. Blank lines and `#` comments are ignored.

```leak-literals
# fixture 1 — the verdict and where it is written down
Questions carried into live coexistence
carried-questions
row 21
decisions row 21
answer key
# fixture 1 — the resolution, all of it postdating d3161f3
10916e9
5e7cb31
pairing
paired
# fixture 2 — the resolution the gateway landed after Run B
c7f5ce9
bounded exception
scales with findings
# both — the cards and commits that carry the key
DEBT-058
DEBT-062
GAP-058
GAP-059
GAP-069
d4dcd28
a6c59e7
```
