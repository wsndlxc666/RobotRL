# RoboCasa365 计划

## 目标

在 RoboCasa365 上打通 pi0.5 的完整链路:评测管线 → baseline 数字 → FlowSDE 微调 → 提升。
先解决"能稳定跑评测",再谈提升。

## 方案

1. 用 RLinf 的 `.venv-robocasa365` + robocasa 1.0.1 + robosuite master
2. 资产走 `ROBOCASA_ASSETS_PATH` 指向 `/autodl-fs/data/robocasa365_assets`
3. 权重用 `pi05_pretrain_human300`(75000 步多任务预训练)
4. 评测通过 `evaluations/run_eval.sh robocasa365 robocasa365_eval_pi05`,逐任务过滤
5. baseline 稳定后,切 FlowSDE 在线训练(`robocasa365_flowsde_*`)

## 阶段

| 阶段 | 内容 | 状态 |
|---|---|---|
| P0 | 装 robocasa365 + robosuite 依赖 | done |
| P1 | 下载 assets 与权重 | done |
| P2 | 单任务 eval 冒烟(smoke) | done |
| P3 | 7 个任务 baseline 评测(n=6) | in_progress |
| P4 | OpenDrawer 加大 trial(n=48) | in_progress |
| P5 | FlowSDE 训练 | in_progress |
| P6 | 训练后评测 + 报告 | pending |

## 风险与已知问题

- **OOM**:48 env 时显存吃紧,降到 32 或 24
- **评测口径**:`episode_horizon_source=task_horizon` + `max_steps_per_rollout_epoch=1500`,改动口径后数字不可比
- 任务 horizon 差异大,单任务 n=6 方差大
- `_downloads/*.zip` 与解压后内容重复 11G

## 验收标准

- [ ] 7 个任务 baseline 全跑完且数字可复现
- [ ] 至少一个任务上 FlowSDE 训练后成功率高于 baseline
- [ ] 每个实验有 REPORT.md
