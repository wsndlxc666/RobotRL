# 当前状态

**更新时间**: 2026-11-05 09:15
**阶段**: P5 训练完成(有缺陷),P6 待做
**一句话**: FlowSDE 训练跑满 120 步,但末尾 ckpt 因爆盘损坏;eval 全部 n=10,无法判断提升。可用权重 = step_100。

## 最新数字

| 项 | 值 |
|---|---|
| 训练时长 | 6h50m(2026-11-04 23:00 → 11-05 05:50) |
| 迭代 | 119 / 120 |
| 完整 ckpt | step 20/40/60/80/100 |
| 损坏 ckpt | step 120(磁盘写满) |
| eval 成功率(n=10) | 均值 0.483,末次 0.80,step_99 时 0.30 |
| 训练成功率(8 env) | 均值 0.466,无趋势 |
| critic explained_variance | -6.62 → 0.76 |
| actor ratio_abs | 0.026(几乎没更新) |

## 判断

- **不能说训练有提升**:末次 0.8 是 n=10 的 8/10,前一次 3/10,纯噪声范围。
- **不能说训练失败**:策略几乎没动(ratio_abs 0.026),120 步更像预热。
- critic 学到东西了(explained_variance 0.76)。

## 阻塞项

- fs 只剩 13G(94%),下次训练前必须先清理或把 ckpt 写到别处。
- eval 口径与外部 baseline 不一致,不能直接比。

## 下一步

- [ ] 用与外部 baseline 相同口径(task_horizon,n≥48)复评 step_100
- [ ] 修 ckpt 保存策略(save_interval 或 keep_last_n)
- [ ] eval 的 n 提到 ≥48
- [ ] 查 `eval/return` 与 `eval/success_once` 数值完全相同的 bug
- [ ] 清理可回收空间(assets 源 zip 约 19G)

## 历史:7 任务 baseline(n=6,已作废)

| 任务 | n | success_once |
|---|---|---|
| PickPlaceCounterToCabinet | 6 | 1.000 |
| SlideDishwasherRack | 6 | 1.000 |
| OpenDrawer | 48 | 0.167(与 n=12 的 0.417 矛盾) |
| PickPlaceDrawerToCounter | 6 | 0.167 |
| CloseToasterOvenDoor / CoffeeSetupMug / TurnOnMicrowave | 6 | 0.000 |

详见 `runs/20261104_eval_baseline_7tasks/REPORT.md`。
