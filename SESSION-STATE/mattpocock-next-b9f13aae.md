# Carry — mattpocock next; GAP-048 closed, 2.29.1 smoke 過半

## Anchor

mattpocock change B 討論 — 解凍 parked group（DEBT-035/040、GAP-038/042）。

## Read first

- `docs/work/DEBT-035.md` · `DEBT-040.md` · `GAP-038.md` · `GAP-042.md` — parked 四卡，全數凍結待 change B

## State

GAP-048 closed（5/5 pressure-test 證偽 clobber 前提，收 decisions.md row，skill 未動）。2.29.1 smoke：help script ✓（產出 BUG-023 mojibake）、board cards-only ✓（產出 BUG-024 narration leak）、log inline capture ✓（BUG-023/024 就是 live 演練）。

## Next step

mattpocock 討論（change B）→ 解凍四卡。BUG-023/024 為新開非 parked 卡，可隨時 triage/drain。

## Watch-outs

- 2.29.x 未驗殘項：drain template warning 消失、drain scoped-brief 實跑（等真 drainable 工作）；log dedup-surface 分支未演練（等一個真 dup）
