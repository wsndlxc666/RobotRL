# 20261105_train_step120_resume

**日期**: 2026-11-05 15:34 → 16:40
**项目**: robocasa365
**类型**: train（续跑）
**结论一句话**: 从 step_100 带优化器续跑 20 步，产出完整 `global_step_120`（dcp + 权重）；但 actor 仍然几乎不更新（ratio_abs 均值 0.027），20 步的权重相对变化只有 **0.009%**。

## 1. 目的

昨天的 120 步 FlowSDE 训练在第 120 步存盘时因磁盘写满崩溃，`global_step_120` 只有半个 `__0_0.distcp`，无法使用。本次目标：

1. 从 step_100 的完整优化器状态续跑 20 步
2. 产出可加载的 `global_step_120`
3. 量化这 20 步里 actor 到底改了多少

## 2. 实验设置

| 项 | 值 |
|---|---|
| 代码 | RLinf `0067f7d5` |
| 起点 | `.../20261104-23:00:07-.../checkpoints/global_step_100`（含 dcp） |
| 配置 | `config.yaml`（`..._resume100.yaml`） |
| 步数 | 101–120（`max_steps=120`，`save_interval=20`） |
| 算法 | FlowSDE PPO，lr=5e-6，value_lr=1e-4，γ=0.99，GAE λ=0.95 |
| 硬件 | 单卡 A800-80GB |
| 耗时 | 约 66 分钟（含 110/120 两次内置 eval） |

## 3. 结果

### 3.1 ckpt

| 文件 | 大小 |
|---|---|
| `dcp_checkpoint/.metadata` | 465,814 B |
| `dcp_checkpoint/__0_0.distcp` | 9,176,509,916 B |
| `model_state_dict/full_weights.pt` | 6,957,548,034 B |

三件套齐全，进程正常退出；后续 n=50 评测能直接加载（step120 = 0.26）。

### 3.2 训练指标（101–120，逐 step 见 `metrics_steps101_120.csv`）

| 指标 | 均值 | 范围 |
|---|---|---|
| actor/ratio_abs | **0.0269** | 0.023–0.031 |
| actor/grad_norm | 8.75 | 6.98–11.74 |
| actor/policy_loss_abs | 0.755 | 0.669–0.876 |
| critic/explained_variance | 0.671 | 0.249–0.881 |
| critic/value_loss | 0.0078 | 0.0046–0.0100 |

内置 eval（n=10）在 step110 / step120 分别约 0.4 / 0.5，噪声太大，不作为结论。

### 3.3 权重变化（逐张量对比 `full_weights.pt`）

| 区间 | 全局相对变化 `‖ΔW‖/‖W‖` |
|---|---|
| **SFT → step120**（整轮 120 步） | **0.169%** |
| **step100 → step120**（本次 20 步） | **0.009%** |

- 变化最大的是 `value_head.mlp.*.bias`（相对 0.25–0.31）
- action expert / VLM 主干中位数约 0.166%（120 步累计），20 步内除 value head 外基本为 0

## 4. 结论

1. **任务完成**：`global_step_120` 已补全、可加载、可评测。
2. **不是精确恢复**：原始 step120 权重随崩溃进程丢失，这是从 step100 续跑出的新连续段，报告与图里必须标注。
3. **actor 没动起来**：20 步权重变化 0.009%，整轮 120 步也只有 0.169%。稀疏终局奖励 + γ=0.99 × 600 步是根因，继续堆步数没有意义。

## 5. 下一步

- 用 Robometer 的逐帧 progress 稠密奖励替代稀疏终局奖励，做 A/B 对比（见 `runs/20261105_robometer_pilot40/PLAN.md`）。

## 6. 产物

| 类型 | 位置 |
|---|---|
| 配置 | `config.yaml` |
| 逐 step 指标 | `metrics_steps101_120.csv` |
| ckpt | 本地 `.../logs/robocasa365_flowsde_opendrawer_pi05_resume100/checkpoints/global_step_120` |
| 远端归档 | `wsndlxc666/robocasa365-opendrawer-flowsde-pi05`：`global_step_120/actor/`（权重 + dcp） |
