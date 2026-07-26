# Carry — harness interface design (2e024f2f)

## Anchor

從「抽離 superpowers 後的 harness 全圖」infographic 起手，收束到真正的問題：**super-bootstrap 與外部 process harness 如何共存**。討論狀態，未動任何實作。

## Read first

- [`docs/specs/harness-architecture.md`](../docs/specs/harness-architecture.md) — §2 槽位圖 · §4 seam + grep 護欄 · §6 decided/open · §8 downstream migration
- `CLAUDE.md` § The envelope · § Dispatch · § Doc Sync
- `git show 6a44d05:.review/mattpocock-adapt-report.md` — mattpocock-adapt watch-out report，已於 `1d99a4e` 吸收後刪除，只在歷史裡

## State

Tree clean，main 與 origin 同步。本 session 對 repo 的唯一寫入是 `BUG-020` / `DEBT-038` 兩張卡 + 本檔。

**已核可、未執行** — 把「定位」寫進 `docs/specs/harness-architecture.md` 與 `docs/overview.md`：服務對象是 agentic builder（不是純 engineer），因此涵蓋 product 維度（`/log`、backlog 的 GAP、`overview.md` 的 Problem/User），且跑道刻意輕到 consumer 可自行修改。使用者對此回「可」，隨後兩次指示不動實作，故未落地。

**提案中、未核可** — bracketed parallel（帶介面的並行）：不 pin、不串接任何外部 process harness；頭尾契約為我們所有，中段是有契約但不具名的空槽位。四條契約：
1. tail — middle 不得以任何路徑落地 commit；交回完成的 diff / file list + 一句意圖
2. tail — 不得引用 middle 的 phase 名稱 / artifact 路徑 / 技能名（可測的回歸護欄）
3. head — 交出 card ID + problem-aim（不含 cause/fix prior）+ boundary；不指定 middle 內部步驟
4. 儀式量條款 — middle 不自做 sizing 時只有兩個合法選項：整包跑，或不用；不得挑步驟

配套推論：**subagent 例外** — 工具受限的 subagent（如 `agents/triage.md`，tool list 無 `Skill`）無法自取 doctrine，doctrine 只能以內容傳入，於是我們就擁有它。故 dispatched agent 屬頭尾、不屬中段；`DEBT-035` 因此可以「triage 在頭側、vacate 測試不適用」關掉。

未核可的收注清單另有：karpathy pin 保留但補上「預設值 ≠ 推薦」的理由、`GAP-042` 讓覆蓋分支可及、`decisions.md` 記兩條關掉的分岔（不蒸餾外部 doctrine body；不 pin/不串接 process harness）。

## Next step

先確認使用者對 bracketed-parallel 買不買單 —— **不要再寫長論證，給事實 + 選項**。

- 買單 → 落已核可的定位 + 介面契約
- 不買單 → 只落定位，其餘丟掉

## Watch-outs

- **使用者明確反饋：我一直在自行 rationalize 試圖說服。收斂成事實 + 選項。**
- 不 pin / 不串接 mattpocock 的三個獨立理由：spec §6 教條（「改指向 X」形狀錯）· 他的 `/setup-matt-pocock-skills` 只從自家 skill 資料夾讀 seed template，跨 plugin 的接點物理上不存在 · 證據仍是 grade B（seed-template bodies 未讀）
- 那份 report 的 grade B 主張已被推翻過一次：它建議 `DEBT-026` 整個放棄工作單槽位，提到 grade A 後發現他不擁有任何路徑，結論翻盤。剩下的 §2 主張同等打折
- W4 殘留：`DEBT-027` / `DEBT-022` / `BUG-019` 必須對 `DEBT-026` 之後的現狀重新瞄準，不可各自獨立執行 —— 否則會做出下一張卡要刪的東西
- artifact（唯讀參考，非 repo 產物）：https://claude.ai/code/artifact/d0e3abcc-0f2f-472e-844c-e1def4ccf519
