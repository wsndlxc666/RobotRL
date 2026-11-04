# RoboCasa v0 + FlowSDE 计划

## 目标

在 RoboCasa v0(robocasa 0.2.0)上验证:以 pi0.5 为策略,用 FlowSDE 做在线微调,
能否在 CloseDrawer 任务上把成功率从 baseline 显著提升。

## 方案

1. 用 `pi05_robocasa_100demos_s30000` 作为初始策略(已在 RoboCasa 100 demos 上 SFT)
2. 先跑 baseline 评测确认起点
3. 切到 FlowSDE 训练(flow-matching 采样改 SDE,便于算 advantage)
4. 分阶段训练,定期评测,记录成功率曲线
5. 最终对比 baseline vs 训练后

## 阶段

| 阶段 | 内容 | 状态 |
|---|---|---|
| P0 | 克隆 venv、装 robocasa 0.2.0、setup_macros | done |
| P1 | 下载 assets 并解压 | done |
| P2 | baseline 评测(CloseDrawer) | done |
| P3 | FlowSDE 训练 step90 | done |
| P4 | 评测 step90 | done |
| P5 | 报告 | done |

## 已知结果

| 指标 | 值 |
|---|---|
| baseline 成功率 | 20% |
| 训练中最高成功率 | 80% |
| 最终评测成功率 | 50% |
| 评测最高成功率 | 60% |
| 训练点数 | 90 |

## 风险与遗留

- **训练/评测成功率差距大**(80% train vs 50% eval),存在分布偏移或过拟合,需要更多 trial 确认
- 训练日志与中间 ckpt 未归档,只剩 `flow_sde_step90` 一个最终 ckpt
- v0 源码埋在 `.venv-robocasa/robocasa` 里,不适合长期维护
- 与 robocasa365 的 assets 重复,占约 7.4G

## 验收标准

- [x] FlowSDE 训练跑完并产出 ckpt
- [x] 最终评测高于 baseline
- [ ] 差距归因(train/eval gap)
