# RoboCasa v0 + FlowSDE 计划

## 目标

在 RoboCasa v0(robocasa 0.2.0)上验证:以 pi0.5 为策略,用 FlowSDE 做在线微调,
能否在 CloseDrawer 任务上把成功率从 SFT baseline 显著提升。

## 方案

1. 起始策略 `pi05_robocasa_100demos_s30000`(RoboCasa 100 demos SFT)
2. FlowSDE 在线训练到 step90
3. **统一口径评测:n=50、seed 0–49、同一脚本、ODE 采样**
4. SFT baseline 与 step90 都重跑 n=50,做配对比较
5. ckpt 归档到魔搭后清理本地

## 阶段

| 阶段 | 内容 | 状态 |
|---|---|---|
| P0 | 克隆 venv、装 robocasa 0.2.0、setup_macros | done |
| P1 | 下载 assets 并解压 | done |
| P2 | baseline 评测(CloseDrawer,n=20) | done |
| P3 | FlowSDE 训练 step90 | done |
| P4 | 评测 step90(n=50,0.46) | done |
| P5 | 报告 | done |
| P6 | SFT baseline n=50 + step90 n=50 统一口径对比 | pending |
| P7 | step90 上传魔搭 + 本地清理 | pending |

## 已知结果(口径未统一,待 P6 修正)

| 指标 | 值 | n |
|---|---|---|
| SFT baseline | 20% | 20 |
| FlowSDE step90 | 46% | 50 |
| 训练中最高 | 80% | — |

## ckpt 现状

| ckpt | 状态 |
|---|---|
| step_90 | `artifacts/robocasa_v0/ckpt/flow_sde_step90/`,仅权重 6.95G |
| step_30 / step_60 / step_120 | 已丢失,只剩 eval JSON |

## 归档(ModelScope)

- `wsndlxc666/robocasa-v0-closedrawer-flowsde-pi05`(private)
- 只传 `full_weights.pt`;上传核对后删除本地 step90

## 风险与遗留

- **训练/评测差距**(80% train vs 50% eval)需要用统一 n=50 复核
- 中间 ckpt 已丢失,无法补 step30/60 的 n=50
- v0 源码仍埋在 `.venv-robocasa/robocasa`,长期需迁移
- 与 robocasa365 assets 重复约 7.4G

## 验收标准

- [ ] SFT 与 step90 都是 n=50、同 seed
- [ ] 对比图含 Wilson CI 与配对检验
- [ ] step90 已上传魔搭且远端大小一致
