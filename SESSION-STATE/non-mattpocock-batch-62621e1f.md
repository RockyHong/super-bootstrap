# Carry — non-mattpocock batch; DEBT-046 + GAP-052 resolved, v2.29.0 out; doctrine 批 + GAP-048 next

## Anchor

Work the remaining non-mattpocock board items; mattpocock-parked group stays untouched until change B is discussed.

## Read first

- `docs/work/DEBT-022.md` + `DEBT-030.md` — dispatch-cost family 殘餘(fixed floor / breadcrumb trace / log collapse-to-inline + dedup-surfacing 契約);DEBT-045 52.3k 與 audit/scan 開銷數據在 git 歷史可援引
- `docs/work/GAP-048.md` — design fork 待討論

## State

DEBT-046 resolved(template 死 Write 規則刪除 + `_comment` propagation note)。GAP-052 resolved(兩 probe 皆落:headless e2e 綠、browser-MCP headless 缺席;classify-actionable e2e 改 derive-by-run-shape,RED/GREEN 驗證 3/3 收斂;消費端 drain/todo 六檔同步)。v2.29.0 released + pushed。CCM inbox 五筆待 digest(含本 session 的 `claude-in-chrome-absent-headless-p-20260804-005858`)— repo 端責任。

## Next step

User picks: DEBT-022/030 doctrine 批(dispatch 何時 earn its cost)· GAP-048 design fork · mattpocock 討論(解凍 DEBT-035/040, GAP-038/042)。

## Watch-outs

- mattpocock parked group 不動直到 change B 討論
- `/plugin update super-bootstrap` 至 2.29.0 後:第一次真 `/super-bootstrap:help` 是 help script 路徑 live smoke;第一次真 drain spawn 驗證 template warning 消失 + e2e 新分類實跑
- drain scoped-brief session 尚無實跑
