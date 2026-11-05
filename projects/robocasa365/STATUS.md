# 当前状态

**更新时间**: 2026-11-06 00:15
**阶段**: P10 收尾完成 — 项目暂告一段落
**一句话**: 120 步稀疏 FlowSDE 的 n=50 评测无趋势（SFT 0.20 → step120 0.26，p=0.635）；Robometer 40 步 pilot 也没提升（step40 0.12 vs 0.22）；已按决定中止 120 步 Robometer 训练，导出 3 条 SFT 视频并收尾。

## 最新数字

### A. 二值 GT 稀疏（上一轮）

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
- 权重：SFT→120 0.169%，100→120 0.009%

### B. Robometer 40 步 pilot

| 组 | step20 | step40 |
|---|---|---|
| A 二值 GT | 0.18 | 0.22 |
| B Robometer | 0.18 | **0.12** |

- ratio_abs 均值 0.0254、grad_norm 8.79、critic EV 0.041
- 未提升；120 步训练已中止

## 视频

`runs/20261106_videos/`（本地，未进 git）：

| 文件 | seed | 该批成功率 |
|---|---|---|
| sft_opendrawer.mp4 | 7 | 2/4 |
| sft_opendrawer_seed11.mp4 | 11 | 1/4 |
| sft_opendrawer_seed13.mp4 | 13 | 4/4 |

## 已完成

- step_120 补全（从 step_100 带 dcp 续跑 20 步）
- SFT/20/40/60/80/100/120 全量 n=50 评测 + 曲线
- 20/40/60/80/100 权重 + 120 完整目录上传魔搭，大小逐字节一致
- 本地 20–100 与 120 已删除（归档在魔搭）
- Robometer 接入 RLinf（history_buffer + 延迟回填），补丁在 pilot run 目录
- 3 条 SFT OpenDrawer 视频
- 收尾报告：`runs/20261106_wrapup/REPORT.md`

## 下一步（如果以后继续）

- Robometer progress vs drawer joint qpos 的离线 sanity check
- 调 reward_scale / reward_clip / 窗口粒度
- 关闭 normalize_advantages 或提高 actor lr，验证 actor 是否愿意动
- 每个配置至少 2–3 个 seed

## 阻塞项

无。项目暂停。
