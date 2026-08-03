# Carry — non-mattpocock batch; probes + DEBT-041/045 shipped + v2.28.0 out, dispatch-cost family next

## Anchor

Work the remaining non-mattpocock board items; mattpocock-parked group stays untouched until change B is discussed.

## Read first

- `docs/work/GAP-052.md` — probe (2) headless-e2e GREEN(amendment 已載);probe (1) browser-MCP multi-instance 仍開(device-gated,需活 Chrome)
- `docs/work/DEBT-046.md` — frozen drain template 死 Write 規則(fix = 刪兩行 + version-bump propagation)
- `docs/work/DEBT-022.md` + `DEBT-030.md` — dispatch-cost family 殘餘(fixed floor / breadcrumb trace / log collapse-to-inline + dedup-surfacing 契約),DEBT-045 的 52.3k 實測數據已入 git(卡已刪)可援引

## State

DEBT-041 resolved(repo 端 + lore reshape 送 CCM inbox `edit-discipline-dedupe-reshape-20260803-235240`)。DEBT-045 resolved(help agent retired → `render-menu.py` + gateway-inline filter,cold audit 5 findings applied)。GAP-052 half-verified。v2.28.0 released + tagged。CCM inbox 五筆待 digest(本 session 三筆 + 先前兩筆)。

## Next step

User picks: DEBT-046(小,mechanical,下個版本 bump 一起)· DEBT-022/030 doctrine 批(dispatch 何時 earn its cost,45 的數據為據;本 session 的 audit/scan 開銷 ~330k 亦是活證據)· GAP-052 probe (1)(需 Chrome 在場)· GAP-048 design fork · mattpocock 討論(解凍 DEBT-035/040, GAP-038/042)。

## Watch-outs

- mattpocock parked group 不動直到 change B 討論
- drain scoped-brief session 尚無實跑;GAP-052 probe (2) 的 worktree spawn 是最接近的一次 smoke(green)
- CCM inbox 五筆待 digest — repo 端責任
- `/plugin update super-bootstrap` 至 2.28.0 後,第一次真 `/super-bootstrap:help` 是新 script+inline-filter 路徑的 live smoke
