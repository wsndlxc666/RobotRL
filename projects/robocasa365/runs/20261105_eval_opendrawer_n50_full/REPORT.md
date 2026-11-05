# 20261105_eval_opendrawer_n50_full

**日期**: 2026-11-05
**项目**: robocasa365
**类型**: eval
**结论一句话**: 7 个 ckpt 统一 n=50 评测后，成功率在 0.14–0.26 之间波动，**没有趋势**；step120 的 0.26 是最高点，但与 SFT 的 0.20 差异不显著（Fisher p=0.635）。

## 1. 目的

用统一口径评测 FlowSDE 训练各阶段的 OpenDrawer 成功率，回答两个问题：

1. 120 步训练是否比 SFT 起点更好？
2. 曲线是否随训练步数单调上升？

## 2. 实验设置

| 项 | 值 |
|---|---|
| 代码 | RLinf `0067f7d5`；robocasa365 `3443cdf3`；robosuite `5ce6643f` |
| 任务 | OpenDrawer（`atomic_seen`, pretrain split） |
| 策略 | SFT + `global_step_{20,40,60,80,100,120}` |
| 评测 | `episode_horizon_source=task_horizon`、`max_steps_per_rollout_epoch=1500`、`flow_ode`、`num_steps=5` |
| 轨迹数 | **n=50**（25 env × 2 epoch） |
| seed | 7（`seed_strategy=openpi`） |
| 耗时 | 每档约 18 分钟 |
| 原始数据 | `raw/*.json` |
| 图 | `figures/curve_n50_full.png` |

## 3. 结果

| ckpt | 成功/50 | success_once | Wilson 95% CI |
|---|---|---|---|
| SFT | 10 | 0.20 | [0.112, 0.330] |
| step20 | 9 | 0.18 | [0.098, 0.308] |
| step40 | 11 | 0.22 | [0.128, 0.352] |
| step60 | 7 | 0.14 | [0.070, 0.262] |
| step80 | 10 | 0.20 | [0.112, 0.330] |
| step100 | 10 | 0.20 | [0.112, 0.330] |
| step120 | 13 | 0.26 | [0.159, 0.396] |

关键检验：

- step120 vs SFT：13/50 vs 10/50，**Fisher 精确 p = 0.635**
- step100 vs SFT：10/50 vs 10/50，p = 1.0
- 7 个点的置信区间大面积重叠

## 4. 结论

1. **不能说训练带来了提升**：最高点 0.26 与 SFT 0.20 不显著，且中间点有 0.14 的低谷。
2. **不能说训练失败**：所有点都在 SFT 的噪声范围内。
3. 这与权重分析一致：SFT→step120 的全局相对权重变化只有 **0.169%**，100→120 只有 **0.009%**。策略在 120 步内几乎没动，评测自然在起点附近波动。

## 5. 下一步

- 不再增加 120 步内的评测点数；问题在监督信号，不在评测。
- 用 Robometer 的稠密 progress 奖励替代稀疏终局奖励，做 A/B 对比（见 `runs/20261105_robometer_pilot40/PLAN.md`）。

## 6. 产物

| 类型 | 位置 |
|---|---|
| 原始 JSON | `raw/*.json` |
| 汇总 | `metrics.json` |
| 曲线图 | `figures/curve_n50_full.png` |
| step80 视频 | `videos/step80_rollout.mp4`（75s，4 路 2×2） |
| 缩略图 | `videos/step80_contact_sheet.png` |
