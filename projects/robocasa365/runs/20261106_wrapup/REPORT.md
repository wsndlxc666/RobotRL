# 20261106_wrapup

**日期**: 2026-11-05 → 2026-11-06
**项目**: robocasa365
**类型**: 收尾报告（eval + train + video）
**结论一句话**: 120 步稀疏 FlowSDE 的 n=50 评测没有趋势（SFT 0.20 → step120 0.26，p=0.635）；Robometer 40 步 pilot 也没有提升（step40 0.12 vs 0.22）；按用户决定中止 120 步 Robometer 训练，导出 3 条 SFT 视频并收尾。

## 1. 目的

汇总当天的三项任务：

1. 补全昨天爆盘的 `step_120`
2. 7 个 ckpt 统一 n=50 评测
3. 接入 Robometer 稠密 progress 奖励并做 A/B 对比

## 2. 评测设置

| 项 | 值 |
|---|---|
| 任务 | OpenDrawer |
| 口径 | `task_horizon`、`max_steps_per_rollout_epoch=1500`、ODE、n=50（25 env × 2 epoch） |
| seed | 7 |
| 代码 | RLinf `0067f7d5` |

## 3. 结果

### 3.1 二值 GT 稀疏奖励（上一轮）

| ckpt | 成功/50 | rate | Wilson 95% CI |
|---|---|---|---|
| SFT | 10 | 0.20 | [0.112, 0.330] |
| step20 | 9 | 0.18 | [0.098, 0.308] |
| step40 | 11 | 0.22 | [0.128, 0.352] |
| step60 | 7 | 0.14 | [0.070, 0.262] |
| step80 | 10 | 0.20 | [0.112, 0.330] |
| step100 | 10 | 0.20 | [0.112, 0.330] |
| step120 | 13 | 0.26 | [0.159, 0.396] |

- step120 vs SFT：Fisher **p=0.635**
- 权重变化：SFT→120 **0.169%**；100→120 **0.009%**
- 结论：120 步内 actor 几乎没动，评测在起点附近波动

### 3.2 Robometer 40 步 pilot

| 组 | step20 | step40 |
|---|---|---|
| A 二值 GT | 0.18 (9/50) | 0.22 (11/50) |
| B Robometer | 0.18 (9/50) | **0.12 (6/50)** |

- 训练 40 步，ratio_abs 均值 0.0254、grad_norm 8.79、reward_model_output 均值 1.12e-4
- 未看到提升；按用户决定不再继续 120 步
- 120 步训练已中止，未产出 ckpt

### 3.3 导出的视频

均为 SFT 策略，4 env 并行录制成 2×2 拼屏，20fps，224×224 单路：

| 文件 | seed | 该批 4 条成功率 | 时长 |
|---|---|---|---|
| `runs/20261106_videos/sft_opendrawer.mp4` | 7 | 2/4 = 0.50 | ~3.5 min |
| `runs/20261106_videos/sft_opendrawer_seed11.mp4` | 11 | 1/4 = 0.25 | ~3.5 min |
| `runs/20261106_videos/sft_opendrawer_seed13.mp4` | 13 | 4/4 = 1.00 | ~3.5 min |

> 视频文件在本地磁盘，`.gitignore` 排除 `*.mp4`，未进 git。

## 4. 归档

- ModelScope：`wsndlxc666/robocasa365-opendrawer-flowsde-pi05`（private）
  - 20/40/60/80/100：仅 `full_weights.pt`
  - 120：完整目录（权重 + dcp）
- 本地已删除 20–100 与 120（节省约 96G），评测 JSON 与报告保留
- 魔搭凭据持久化在 `/autodl-fs/data/.secrets/modelscope/`，不进 git

## 5. 结论

1. **稀疏终局奖励在 120 步内无法带来可测提升**：评测无趋势，权重只动 0.169%。
2. **Robometer 40 步 pilot 也没有提升**：step40 反而降到 0.12。可能是奖励尺度/窗口粒度/域偏移，但在本轮预算内未解决。
3. **本轮到此为止**：120 步 Robometer 训练按用户决定中止，不再继续。
4. 已导出 3 条 SFT 视频用于定性观察。

## 6. 下一步（如果以后继续）

- 先做 Robometer progress vs drawer joint qpos 的离线 sanity check，确认没有域偏移
- 再调 `reward_scale` / `reward_clip` / 窗口粒度（8 → 4）
- 考虑关闭 `normalize_advantages` 或提高 actor lr，验证"actor 是否愿意动"
- 每个配置至少 2–3 个 seed

## 7. 产物

| 类型 | 位置 |
|---|---|
| 7 点评测报告 | `runs/20261105_eval_opendrawer_n50_full/REPORT.md` |
| step120 续跑报告 | `runs/20261105_train_step120_resume/REPORT.md` |
| Robometer pilot | `runs/20261105_robometer_pilot40/`（PLAN/STATUS/results/patch） |
| 视频 | `runs/20261106_videos/*.mp4`（本地） |
| 复现脚本 | `run/*.sh`、`run/finalize_robometer120.py` |
