# RoboCasa365 计划

## 目标

在 RoboCasa365 上打通 pi0.5 的完整链路：评测管线 → 可比的 baseline → FlowSDE 在线微调 → 用稠密信用分配改善长程任务。

## 关键约定

- 环境：`.venv-robocasa365` + robocasa 1.0.1 + robosuite master
- 资产：`ROBOCASA_ASSETS_PATH=/autodl-fs/data/artifacts/robocasa365/data/assets`
- 评测口径（所有对比必须一致）：
  - `episode_horizon_source=task_horizon`
  - `max_steps_per_rollout_epoch=1500`
  - `flow_ode`、`num_steps=5`、`num_action_chunks=5`
  - **n=50**（25 env × 2 epoch；48 env 会 OOM）
- 任务：OpenDrawer（长程，~600–750 步）

## 阶段

| 阶段 | 内容 | 状态 |
|---|---|---|
| P0 | 装 robocasa365 + robosuite 依赖 | done |
| P1 | 下载 assets 与权重 | done |
| P2 | 单任务 eval 冒烟 | done |
| P3 | 7 任务 baseline（n=6，仅参考） | done |
| P4 | OpenDrawer baseline（n=48 → 0.167） | done |
| P5 | FlowSDE 训练 120 步 | done（119 步后存盘崩溃） |
| P6 | 历史 ckpt 统一 n=50 评测（SFT/20/40/60/80） | done |
| P7 | 归档到魔搭 + 清理本地 | done |
| P8 | 续跑 100→120 并评测 100/120 | done |
| P9 | Robometer 稠密信用分配 + 40 步 pilot | done |
| P10 | A/B 对比 + 报告与结论 | done（120 步中止，出收尾报告） |

## 当前结论（2026-11-05）

### n=50 评测（统一口径）

| ckpt | 成功/50 | success_once | Wilson 95% CI |
|---|---|---|---|
| SFT | 10 | 0.20 | [0.112, 0.330] |
| step20 | 9 | 0.18 | [0.098, 0.308] |
| step40 | 11 | 0.22 | [0.128, 0.352] |
| step60 | 7 | 0.14 | [0.070, 0.262] |
| step80 | 10 | 0.20 | [0.112, 0.330] |
| step100 | 10 | 0.20 | [0.112, 0.330] |
| step120 | 13 | 0.26 | [0.159, 0.396] |

- step120 vs SFT：Fisher **p=0.635**，不显著
- 权重变化：SFT→120 **0.169%**，100→120 **0.009%**
- 结论：120 步内 actor 几乎没动，稀疏终局奖励是根因

### Robometer 40 步 pilot（进行中）

- 接入方式：`history_buffer`，窗口 8 个 chunk，每 8 步打分一次，`r = Δprogress/8`
- `env_reward_weight=0.1` 保留 GT success 锚点
- 1 iteration smoke：167s、奖励非零、无 OOM
- 当前 step 7/40，预计 23:20 完成

## A/B 对比（只有两组）

| 组 | 奖励 | 数据 |
|---|---|---|
| A. 二值 GT | 成功 r=1，其余 0 | 上一轮稀疏训练，SFT/20/40 = 0.20/0.18/0.22（n=50） |
| B. Robometer | `Δprogress/8` + 0.1×GT | 当前 pilot |

**控制变量**：同一 SFT 起点、同一 FlowSDE 配置、同 seed、8 env、40 步、同一评测口径。

**判据**：
- B > A（如 0.22 → 0.30+）→ 续到 120 步
- B ≈ A → 查奖励尺度/窗口，不急着加步数
- B < A → 查 reward hacking 与 GT 权重

## ckpt 状态

| ckpt | 本地 | 魔搭 |
|---|---|---|
| step_20/40/60/80 | 已删除 | 仅权重 |
| step_100 | 本地保留 | 仅权重 |
| step_120 | 本地保留（dcp + 权重） | 完整目录 |

## 归档（ModelScope）

- `wsndlxc666/robocasa365-opendrawer-flowsde-pi05`（private）
- 上传脚本：`run/upload_modelscope.sh`
- 凭据持久化：`/autodl-fs/data/.secrets/modelscope/`（不进 git，bootstrap 自动恢复）
- 上传实测约 13 MB/s

## 风险与已知问题

- **磁盘**：本地 tmp 59G、fs 43G 空闲；大 ckpt 必须“先传后删”
- **OOM**：评测用 25 env；训练 8 env；Robometer 与 pi0.5 同卡约 38G
- **step_120 不可精确恢复**：原权重随崩溃进程丢失，续跑是“新连续段”
- **稀疏奖励已确认无效**：γ=0.99 × 600 步 → 优势衰减，actor 120 步只动 0.169%
- **Robometer 域偏移**：需用 drawer joint qpos 做 sanity check
- **依赖脆弱**：装 sentence-transformers 曾误升级 transformers/numpy，已回滚到 4.57.6 / 2.2.5

## 验收标准

- [x] SFT/20/40/60/80/100/120 全部 n=50，同一口径
- [x] step_120 完整可加载
- [x] 所有 ckpt 上传魔搭，远端大小与本地一致
- [ ] Robometer 40 步 pilot 跑完，给出 A/B 成功率对比
- [ ] 每个实验有 REPORT.md
