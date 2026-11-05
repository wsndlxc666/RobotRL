# Robometer 40 步 pilot — 方案

**日期**: 2026-11-05
**状态**: 运行中（step 7/40）
**目标**: 在同一 SFT 起点、同一 FlowSDE 配置下，对比 **Robometer 稠密 progress 奖励** 与 **上一轮的二值 GT success 奖励**，看固定预算下成功率/样本效率是否更好。

## 1. 为什么做

上一轮 120 步 FlowSDE 的结果：

- 评测（n=50）：SFT 0.20 → step120 0.26，Fisher p=0.635，无显著提升
- `actor/ratio_abs` 全程 0.025–0.027
- 权重变化：SFT→120 仅 **0.169%**，100→120 仅 **0.009%**

根因是稀疏终局奖励 + γ=0.99 × 600 步：`γ^600 ≈ 0.0024`，离终局越远的优势越接近 0，actor 几乎学不到东西。

Robometer 提供逐帧 progress，构造 `Δprogress` 作为稠密奖励，让每个窗口都有非零信用分配。

## 2. 接入方式（不改 critic、不改 PPO）

```
rollout 每个 env step 的 main_images
        ↓
RLinf HistoryManager（window=8 chunk，每 8 步打分一次）
        ↓
Robometer-4B（冻结）
  per-frame progress p_t
        ↓
r_window = clip(p_last - p_prev, ±0.2) / 8
        ↓
RLinf 延迟奖励回填到窗口内每一步
        ↓
GAE → critic / actor（critic 仍学 return）
```

### 代码改动

| 文件 | 改动 |
|---|---|
| `rlinf/models/embodiment/reward/robometer_reward_model.py` | 新增；最小 loader（Qwen3-VL-4B + 3 head），逐窗口 progress，输出 Δprogress |
| `rlinf/models/embodiment/reward/__init__.py` | 注册 `robometer` |
| `rlinf/workers/env/env_worker.py` | `input_interval>1` 时 `history_lengths` 为空会崩，加 guard |
| `examples/embodiment/config/..._robometer40.yaml` | 新配置 |

补丁：`patches/robometer_integration.patch`（5 个 diff）。

### 关键配置

```yaml
reward:
  use_reward_model: true
  reward_mode: history_buffer
  history_reward_assign: true
  reward_weight: 1.0
  env_reward_weight: 0.1        # 保留 GT success 作锚点
  model:
    model_type: robometer
    model_path: /root/autodl-tmp/models/robometer-4B
    precision: bf16
    max_frames: 8
    reward_clip: 0.2
    history_buffers:
      window: {history_size: 8, min_history_size: 4, input_interval: 8, input_on_done: true}
```

## 3. 对比设计（只保留两组）

| 组 | 奖励 | 数据来源 |
|---|---|---|
| **A. 二值 GT** | 成功 r=1，其余 0 | 上一轮 120 步稀疏训练，n=50 评测已有 |
| **B. Robometer** | `Δprogress/8`，GT success 权重 0.1 | 本 pilot |

控制变量：同一 SFT 起点、同一 FlowSDE 配置、同 seed、8 env、40 步、同一评测口径（n=50、task_horizon、ODE）。

## 4. 指标

**主指标**
- n=50 成功率：A 用已有 SFT/20/40 数据（0.20/0.18/0.22）；B 跑完后补 step20/40 的 n=50
- 样本效率：达到同一成功率所需步数

**辅助指标**
- `reward_model_output` 均值/分布
- `actor/ratio_abs`、`grad_norm`
- SFT→step40 权重相对变化
- Robometer 奖励与 GT success 的相关性

> 注意：`normalize_advantages: True` 会归一化优势，因此 ratio_abs 不会因为奖励变稠密而显著变大。pilot 前 7 步 ratio_abs 0.022–0.028，与稀疏版持平，这是预期现象；**主判据必须是成功率/样本效率**。

## 5. 判据

| 40 步结果 | 结论 |
|---|---|
| B > A（如 0.22 → 0.30+） | 稠密信用分配有效，续到 120 步 |
| B ≈ A | 奖励信号没转化成行为差异，查奖励尺度/窗口 |
| B < A | 奖励把策略带偏，查 reward hacking 与 GT 权重 |

## 6. 时间

- pilot：20:40 启动，~4 min/step，预计 **23:20 左右**完成 40 步
- step20/40 n=50 评测：约 40 分钟
- 汇总 + 对比图 + 报告：约 20 分钟

## 7. 风险

- Robometer 在 RoboCasa365 上的域偏移（相机/语言/仿真纹理）→ 先用 drawer joint qpos 做 sanity check
- 4B VLM 与 pi0.5 同卡 → 当前显存 38G/80G，正常
- 每 8 个 chunk 打分一次，一集约 15 次；若太慢可降到 4 或提高到 16
- 原始 step120 是续跑版，A 组的 120 步数据带此 caveat；40 步 A/B 不受影响
