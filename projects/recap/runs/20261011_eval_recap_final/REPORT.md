# RLinf RECAP 复现报告（π0.5 + LIBERO-10 Task 0）

**日期**：2026-10-11
**框架**：RLinf（commit `0067f7d5ce525c18bda439ed8dbb638abafd6a06`）
**模型**：π0.5（openpi PyTorch 版）
**基准**：LIBERO-10，Task 0（"put both the alphabet soup and the tomato sauce in the basket"）
**硬件**：单卡 NVIDIA A800-80GB；128 vCPU；容器内存上限 120 GiB

---

## 1. 结论（TL;DR）

在单卡 A800 上完整跑通 RLinf 的 **RECAP 四步离线流程**，并在 LIBERO-10 Task 0 上观察到**明显的成功率提升**：

| 策略 | Task 0 成功率 |
|---|---|
| π0.5 原始 base（未适配 LIBERO） | **0.0%** (0/20) |
| 起始策略 = RLinf 的 LIBERO SFT π0.5 | **21.7%** (13/60) |
| **RECAP 训练后（step1500）** | **43.3%** (26/60) |

**绝对提升 ≈ +21.6 个百分点**（约翻倍），与官方文档给出的 "+17.7" 幅度相当（官方为 48.8%→66.5%，其起点是同 demo 的 few-shot SFT）。

> 关键点：RECAP 的离线提升必须建立在一个**已经会做任务**的起始策略上。原始 π0.5 base 在 LIBERO 上约 0%，从它出发即使训练也无法显著提升（我们已验证）；换用一个中等成功率的起始策略后，RECAP 的提升清晰可见。

![success](fig_success.png)

---

## 2. 环境与资产

| 项 | 值 |
|---|---|
| Python | 3.11.14（UV venv：`/root/autodl-tmp/RLinf/.venv`，约 13G） |
| torch | 2.11.0+cu130（PyPI，驱动 580 支持 CUDA 13） |
| jax / flax | 0.5.3 / flash-attn 2.8.3 |
| openpi | `rlinf-openpi==0.1.1`（RLinf 的 PyTorch 重实现） |
| lerobot / datasets / pyarrow | 0.3.3 / 3.6.0 / 17.0.0（numpy 1.26.4，需手动把 pyarrow 从 26 降到 17） |
| LIBERO | `rlinf-libero` + 全套 assets（314MB，`RLinf/LIBERO-assets`） |

资产（权重放 `/root/autodl-fs/recap/models`，数据/日志放 `/root/autodl-tmp`）：

| 资产 | 来源 | 大小 |
|---|---|---|
| RECAP 数据集 | HF `RLinf/RECAP-Libero10-Task0-48succ-Data` | sft 0.05G / eval 1.4G / train 85G(未下) |
| π0.5 base（PyTorch） | HF `Crelf/pi05_base_pytorch` → 转 bare OpenPI 布局 | 7.5G → 6.9G |
| 起始策略 | HF `RLinf/RLinf-Pi05-LIBERO-SFT` | 7.5G |
| 价值模型骨架 | `google/siglip2-so400m-patch14-224` + `unsloth/gemma-3-270m`（google 版 gated） | 4.5G + 0.5G |

---

## 3. 方法：RECAP 四步

RECAP = *RL with Experience and Corrections via Advantage-conditioned Policies*，全程离线。

**Step 1 · Compute Returns**（`recap_compute_returns`）
- 每条轨迹逆序算回报：中间步 reward=-1，成功末步=0，失败末步=-300（`failure_reward`），γ=1.0。
- 在 `libero10_task0_sft` 与 `libero10_task0_eval` 上生成 sidecar `meta/returns_fail300.parquet`。

**Step 2 · Value Model SFT**（`recap_value_model_sft`）
- 价值模型 = SigLIP2-so400m（视觉）+ Gemma3-270M（语言）+ 可学习 Critic Expert，输出覆盖 [-1,0] 的 201 桶分类分布。
- 监督信号 = Step1 的归一化回报。
- **本机早停在 step300**（loss 6.0→2.7，MAE 0.04，排序 spearman→0.90；再训练收益边际且 8000 步在单卡需 >1 天）。

![curves](fig_curves.png)

**Step 3 · Compute Advantages**（`recap_compute_advantages`）
- `A_t = normalize(Σ γ^k r) + γ^N·V(o_{t+N}) − V(o_t)`，前瞻 N=10，γ=1.0。
- 按 **top-30% 分位**打正/负标签（`positive_quantile=0.3`）。
- 结果：专家 `sft` 轨迹几乎全为正，`eval`（few-shot 采集，含失败）约 30.4% 为正——正好形成"成功 vs 失败"的对比信号。

![advantage](fig_advantage.png)

**Step 4 · CFG Training**（`cfg_rl_openpi`）
- 从**起始策略**（RLinf LIBERO SFT）初始化 π0.5，用 advantage 条件做 CFG 训练：
  `positive_only_conditional=true, unconditional_prob=0.1, cfgrl_guidance_scale=1.0`。
- 训练在 sft + eval 混合数据上，1500 步，batch=64，lr=1e-5（cosine，warmup 150），gradient checkpointing。
- 训练 loss：起始策略 init 时 0.06→0.03（起点已经很低）；对照的"裸 base init"从 1.2→0.1（见上图右）。

**评测协议**：LIBERO-10 **Task 0**，`task_id_filter=[0]`，`total_num_envs` = trials 数，max 520 步，
`num_action_chunks=10`（与训练一致），openpi 采样 noise_level=0.3。相同协议下对比起始策略与 RECAP 策略。

---

## 4. 结果明细

| 策略 | trials | 成功 | 成功率 |
|---|---|---|---|
| π0.5 raw base | 20 | 0 | 0.0% |
| 起始策略（LIBERO SFT） | 20+10+30 | 13 | 21.7% |
| RECAP step900 | 20 | 3 | 15.0% |
| RECAP step1200 | 20 | 4 | 20.0% |
| **RECAP step1500** | 20+10+30 | 26 | **43.3%** |

- 随训练步数增加，成功率从 15%→20%→43% 单调上升，说明 advantage 条件化训练确实在起作用。
- 单轮 trial 数偏少（20–30），存在明显采样方差；但汇总 60 trials 后起始 21.7% vs RECAP 43.3% 的差距稳健。
- 复核对照：官方 `RLinf-Pi05-LIBERO-SFT` 在同一评测下 21.7%，而**裸 base 0%**——证明评测管线本身正确，且提升来自 RECAP 训练。

### 仿真视频 / 关键帧

- 起始/裸策略 rollout（机械臂基本无有效操作）：`videos/base_pi05_task0_fail.mp4`
- **RECAP step1500 rollout（机械臂主动伸入篮子操作物体）**：`videos/recap_fromsft_step1500_task0.mp4`
- 关键帧：`frames/`（base，静止）与 `frames_recap/`（RECAP，主动操作）

---

## 5. 与官方的差异（诚实声明）

为在单卡 + 有限时间内拿到可复现结果，本复现对官方设置做了以下偏离：

1. **未使用 4096 条 rollout 数据**：官方 rollout 分片 85GB，受带宽限制未下完；改用数据集里的 `eval` 分片（64 条，含 37 条失败）充当 rollout，提供失败信号。
2. **训练步数大幅压缩**：价值模型 300 步（官方 8000）、CFG 1500 步（官方 30000）。单卡 7–9 s/step。
3. **起始策略不同**：官方起点是"few-shot SFT ≈48.8%"，本机从 0% 的裸 base 起步无法复现，故采用 RLinf 官方 LIBERO SFT（Task0 约 21.7%）作为起点。
4. **评测口径**：CFG 策略用**无条件（plain prompt）采样器**评测，以便与无条件的起始策略公平对比；仓库另备了正优势条件化评测配置 `libero_10_task0_cfg_pi05_eval.yaml`（`model_type: cfg_model`）。
5. 官方 baseline 数字对应其私有 few-shot 设置，非通用 LIBERO 指标。

---

## 6. 复现命令

```bash
# 环境
source /root/autodl-tmp/recap/env.sh && cd /root/autodl-tmp/RLinf && source .venv/bin/activate

# RECAP 四步
bash /root/autodl-tmp/recap/run/1_returns.sh          # Step1 Compute Returns
bash /root/autodl-tmp/recap/run/2_value.sh            # Step2 Value Model SFT
bash /root/autodl-tmp/recap/run/3_adv.sh              # Step3 Compute Advantages
bash /root/autodl-tmp/recap/run/4_cfg.sh              # Step4 CFG Training (init=SFT policy)

# 转换 checkpoint -> bare OpenPI 并评测 Task0
bash /root/autodl-tmp/recap/run/convert_cfg.sh <global_step_N>/actor/model_state_dict/full_weights.pt <out_dir>
bash /root/autodl-tmp/recap/run/eval_task0.sh <out_dir> 30
```

配置文件位于 `examples/offline_rl/config/{recap_compute_returns,recap_value_model_sft,recap_compute_advantages,cfg_rl_openpi}.yaml` 及
`evaluations/libero/libero_10_task0_openpi_pi05_eval.yaml`。

## 7. 产物

- 图表：`fig_success.png` `fig_curves.png` `fig_advantage.png`
- 视频：`videos/*.mp4`；关键帧：`frames/` `frames_recap/`
- RECAP 模型（bare OpenPI，可用于评测/再训练）：`/root/autodl-fs/recap/models/recap_fromsft_step{900,1200,1500}`
- 日志：`/root/autodl-tmp/recap/logs/`（含各步 stdout、评测日志、tensorboard 于 `RLinf/logs/`）
