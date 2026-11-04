# 当前状态

**更新时间**: 2026-11-04
**阶段**: P5 完成,**暂停**(让位给 robocasa365)
**一句话**: CloseDrawer baseline 20% → 最终评测 50%(最高 60%),有提升但 train/eval 差距未解释。

## 数字

| 指标 | 值 |
|---|---|
| baseline | 0.20 |
| 训练中最高 | 0.80 |
| 最终评测 | 0.50 |
| 评测最高 | 0.60 |

## 已完成

- venv `.venv-robocasa` + robocasa 0.2.0 可运行
- assets 下载并解压
- FlowSDE step90 训练 + 评测
- 报告:`/autodl-fs/data/robocasa/report/REPORT.md`(含 fig_* 图)

## 下一步 / 遗留

- [ ] **解释 train/eval gap**:80% vs 50%,先怀疑评测 trial 数不足,再加量
- [ ] 把 v0 源码从 `.venv-robocasa/robocasa` 迁到 `code/robocasa_v0` 并重装
- [ ] 归档训练日志与中间 ckpt(目前只留 step90)
- [ ] 与前一个项目的资产去重(assets 与 365 重叠 ~7G)

## 阻塞项

无,单纯优先级降低。
