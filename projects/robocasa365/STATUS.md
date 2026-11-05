# 当前状态

**更新时间**: 2026-11-05 21:10
**阶段**: P9 — Robometer 40 步 pilot 运行中（step 7/40）
**一句话**: 120 步 FlowSDE 的统一 n=50 评测没有趋势（SFT 0.20 → step120 0.26，p=0.635），权重只动了 0.169%；现已把 Robometer 稠密 progress 奖励接进 RLinf，正在跑 40 步 A/B pilot。

## 最新数字

### n=50 评测（OpenDrawer，task_horizon，25 env × 2 epoch）

| ckpt | 成功/50 | 成功率 | Wilson 95% CI |
|---|---|---|---|
| SFT | 10 | 0.20 | [0.112, 0.330] |
| step20 | 9 | 0.18 | [0.098, 0.308] |
| step40 | 11 | 0.22 | [0.128, 0.352] |
| step60 | 7 | 0.14 | [0.070, 0.262] |
| step80 | 10 | 0.20 | [0.112, 0.330] |
| step100 | 10 | 0.20 | [0.112, 0.330] |
| step120 | 13 | 0.26 | [0.159, 0.396] |

- step120 vs SFT：Fisher **p=0.635**
- 权重变化：SFT→120 **0.169%**，100→120 **0.009%**

### step_120 续跑

| 项 | 值 |
|---|---|
| 区间 | step 101–120（从 step_100 带 dcp 续跑） |
| 耗时 | 约 66 分钟 |
| actor/ratio_abs | 均值 **0.0269** |
| actor/grad_norm | 均值 8.75 |
| critic/explained_variance | 均值 0.671 |
| ckpt | 完整（dcp 9.18G + 权重 6.96G） |

### Robometer pilot（进行中）

| 项 | 值 |
|---|---|
| 起点 | SFT |
| 奖励 | `Δprogress/8`，窗口 8 chunk，`env_reward_weight=0.1` |
| smoke | 1 iter 167s、奖励非零、无 OOM |
| 当前 | step 7/40，ratio_abs 0.022–0.028 |
| 预计完成 | 23:20 左右 |

## 已完成

- step_120 补全 + 可加载
- SFT/20/40/60/80/100/120 全部 n=50 评测 + 曲线
- step80 评测视频（75s，4 路 2×2）
- 20/40/60/80/100 权重 + 120 完整目录上传魔搭，远端大小逐字节一致
- 本地 20–80 已删除；100/120 本地保留
- Robometer 接入：
  - 新增 `RobometerRewardModel` + 注册
  - 修 `input_interval>1` 的 history 边界 bug
  - 配置 `..._robometer40.yaml`
  - 补丁在 `runs/20261105_robometer_pilot40/patches/`
- 魔搭凭据持久化到 `/autodl-fs/data/.secrets/modelscope/`，bootstrap 自动恢复

## 下一步

- [ ] Robometer pilot 跑完 40 步
- [ ] step20/step40 各做 n=50 评测
- [ ] 与 A 组（0.20/0.18/0.22）对比，决定是否续到 120 步
- [ ] （可选）Robometer progress vs drawer joint qpos sanity check
- [ ] 写 REPORT.md，更新 LOG

## 阻塞项

无。磁盘：tmp 59G、fs 43G 空闲。

## 归档

- ModelScope：`wsndlxc666/robocasa365-opendrawer-flowsde-pi05`（private）
  - 20/40/60/80/100：仅 `full_weights.pt`
  - 120：完整目录（权重 + dcp）
- 详细报告：
  - `runs/20261105_eval_opendrawer_n50_full/REPORT.md`
  - `runs/20261105_train_step120_resume/REPORT.md`
  - `runs/20261105_robometer_pilot40/PLAN.md`
