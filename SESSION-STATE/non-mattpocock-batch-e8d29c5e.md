# Carry — non-mattpocock batch; GAP-050 design settled (context-engineering reframe), execution next

## Anchor
Work the remaining non-mattpocock board items; mattpocock-parked group stays untouched until change B is discussed.

## Read first
- `docs/work/GAP-050.md` — `## Design — 2026-08-03` (context-engineering reframe, 6 deliverables, charter-first; **user 原話 anchor 附於卡尾 — root 參考,防 drift**)
- `docs/work/GAP-051.md` — drain re-derivation (sequenced after GAP-050 deliverables 1-4)
- `docs/work/GAP-046.md` — `## Progress` (judge container 解凍路徑 = GAP-050 deliverable 4 的同構 door)

## State
Wave-1 shipped (`c2a99b7` + dedup fix `47fb4c5`). GAP-050 discussion done, Design settled + landed on card: pipeline staging = 蒸餾殘留,價值收斂到永久組(doc-sync/cold docs/cards/grounding/link graph);temporal artifact = context scope,非 spec。Code-review 層 deferred(冷讀 blind-spot insights,impl 層,mattpocock/superpowers cover — 註記在 Design block)。Tree: GAP-050 append + GAP-051 new + README high-water + this carry uncommitted at park time (commit rides the close). main ahead of origin (push pending — wall).

## Next step
Execute GAP-050 deliverables,順序 1 → 4 → 2 → 3(charter 先、judges spec 次、thread contract 再、classify 詞彙最後;5 是不動項、6 已卡 GAP-051):
1. `agents/triage.md` charter 放寬為 universal grounding(保名,charter-first)
2. `shared/` grounding-discipline spec + 三 door agents 變薄(含 DEBT-044 殘留 README row — intake 獨立 door)
3. `docs/work/README.md` thread contract:Design/Plan → scope 條件 sections
4. `shared/classify-actionable.md` 詞彙重推導(`Write plan` demote、stage 語彙)
每項 = harness edit:RED/micro-test where behavior-shaping、audit-harness-edits post、skeleton mirror check。

**Walls:** `/release`(wave-1 + GAP-050 波次一起攤);push;mattpocock parked group(DEBT-035/040, GAP-038/042);GAP-050 執行中遇 aim 歧義回 user(Design 的 anchor 引文為 root 參考)。

## Watch-outs
- GAP-050 deliverable 3(thread contract)動 `docs/work/README.md` — 是 doc 面非 harness 面,但 classify/todo/drain 全下游消費,改前先讀 GAP-051 的共面註記
- `docs/specs/harness-architecture.md` §6 stage-set 辯護行在 GAP-050 落地後將過時 — doc-sync 應抓,漏了手動補
- CCM inbox pending finding `harness-audit-gate-shared-path-gap-20260802-130847` — repo 端 digest,非本 repo 責任
