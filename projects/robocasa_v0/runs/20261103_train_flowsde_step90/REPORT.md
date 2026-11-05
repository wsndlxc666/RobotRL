# FlowSDE 在线 RL 复现报告（π0.5 + RoboCasa CloseDrawer）

**日期**：2026-11-03
**框架**：RLinf（commit `0067f7d`，`/root/autodl-tmp/code/RLinf`）
**算法**：FlowSDE（`noise_method="flow_sde"`）+ PPO
**模型**：π0.5（openpi PyTorch），RoboCasa SFT checkpoint
**任务**：RoboCasa v0.2，`CloseDrawer`（PandaOmron 移动机械臂）
**硬件**：单卡 NVIDIA A800-80GB；容器内存上限 120 GiB；144 vCPU

---

## 1. 结论（TL;DR）

在单卡 A800-80GB 上跑通 π0.5 + RoboCasa + FlowSDE 在线 RL。以 RoboCasa v0.2 的
`CloseDrawer` 为任务，从公开的 π0.5 RoboCasa SFT checkpoint 出发，训练 90 个 PPO
iteration（分 3 块）后，统一协议的外部评测成功率为：

| 策略 | CloseDrawer 成功率（统一 300 步、固定 seed、ODE 评测） |
|---|---|
| 起始策略（π0.5 RoboCasa SFT，zero-shot） | **20.0%** (4/20) |
| FlowSDE PPO step 30 | **25.0%** (5/20) |
| FlowSDE PPO step 60 | **30.0%** (9/30) |
| **FlowSDE PPO step 90** | **46.0%** (23/50) |

**绝对提升约 +26 个百分点**（20% → 46%），且随训练步数单调上升。
需要注意样本量与置信区间（见 §6）：step 90 vs baseline 的 Fisher 精确检验
**p = 0.058**（未过 0.05）；同 seed 子集（n=20）上为 7/20 vs 4/20（p≈0.48）。
因此**提升方向明确，但尚未达到统计显著**。

![result](fig_result.png)

---

## 2. 方法

RLinf 的 FlowSDE 实现在 `rlinf/models/embodiment/openpi/sampling/rl_sampler.py`：
把 π0.5 的 flow-matching ODE 采样转换为 SDE，在去噪过程中注入高斯噪声，使其成为
可计算 log-prob 的随机策略；PPO 用每个去噪步的高斯 log-prob 做重要性比。

关键配置（`actor.model.openpi`）：

| 参数 | 值 |
|---|---|
| `noise_method` | `flow_sde` |
| `noise_level` | 0.5 |
| `num_steps`（去噪步数） | 3 |
| `action_horizon`（网络） | 50 |
| `num_action_chunks`（执行） | 5 |
| `add_value_head` | True |
| `value_after_vlm` | True |
| `train_expert_only` | True（冻结 VLM，只训 action expert + value head） |
| `joint_logprob` | False |

PPO 超参：`lr=5e-6`，`value_lr=1e-4`，`gamma=0.99`，`gae_lambda=0.95`，
`update_epoch=1`，`clip_ratio=0.2`，`micro_batch=10`，`global_batch=300`，
`entropy_bonus=0`，`kl_beta=0`。

---

## 3. 环境与资产

| 项 | 值 |
|---|---|
| Python | 3.11.14（UV venv 副本 `/root/autodl-tmp/code/RLinf/.venv-robocasa`） |
| torch | 2.11.0+cu130 |
| robosuite / mujoco | 1.5.1 / 3.2.6（robocasa 0.2.0 的固定版本） |
| RoboCasa 代码 | RLinf fork `https://github.com/RLinf/robocasa.git`（v0.2 结构） |
| RoboCasa 资产 | 官方 v0.2（textures / fixtures / objaverse / generative_textures），经 HF 镜像 `Tej3/robocasa-v02-kitchen-assets` 获取 |
| 渲染 | EGL 离屏渲染（`MUJOCO_GL=egl`） |

> 注：RoboCasa 官方 box.com 资产链接已全部 404；HuggingFace `robocasa/robocasa-assets`
> 是 RoboCasa365 的资产集（fixtures 只有 accessories、objaverse 缺少 `*_site`），
> 与 v0.2 不兼容。本复现改用上述 v0.2 镜像。

---

## 4. 起始策略与兼容适配

### 4.1 Checkpoint

- HF：`changyeon/pi05_robocasa_as50_filteredbc_pytorch`，取 `30000/`（step 30000）。
- 结构：openpi PyTorch 格式（`metadata.pt + model.safetensors`），π0.5，
  `action_horizon=50`，`action_dim=32`，`max_token_len=200`，
  `discrete_state_input=True`；约 3.6B 参数。
- 训练数据（来自 `metadata.pt`）：`changyeon/deas_robocasa_demo_success_rollouts`，
  filtered BC（100 demos）。

### 4.2 非标准 state/action 约定

该 checkpoint 与 RLinf 自带的 RoboCasa 25d/12d 约定不同，已通过 `norm_stats.json`
反推并验证：

- **state（16d）**：`[base_pos(3), base_quat(4), gripper_qpos(2),
  base_to_eef_pos(3), base_to_eef_quat(4)]`
  - 移动底盘只做 yaw，故 `base_quat` 的 x/y 恒为 0（与 norm stats 一致）。
- **action（12d）**：模型输出中 `0:5` 恒为 0，arm delta 在 `5:11`，gripper 在 `11`；
  gripper 原始范围 `[0,1]`（RLinf env 期望 `[-1,1]`）。

适配方式（新增代码）：

1. `rlinf/envs/sim/robocasa/utils.py`：新增 `16d_pi05_100demos` state 预设。
2. `rlinf/models/embodiment/openpi/policies/robocasa_policy.py`：
   新增 `ActionRemap`，在输出端把模型 action 映射为 env canonical 12d：
   ```
   env[0:6]  = model[5:11]        # arm delta
   env[6]    = 2*model[11] - 1    # gripper
   env[7:10] = 0                  # base
   env[10]   = 0                  # torso
   env[11]   = -1                 # base_mode
   ```
3. `rlinf/models/embodiment/openpi/dataconfig/__init__.py`：新增
   `pi05_robocasa_human_100demos`（`pi05=True, action_horizon=50`）。
4. 训练配置：`examples/embodiment/config/robocasa_closedrawer_ppo_openpi_pi05.yaml`。

### 4.3 验证

- checkpoint 严格加载成功（无 unexpected Pi0 参数）。
- 用 env 随机 rollout 采集 25d state，按 16d 选择后的统计结构与 norm stats 一致
  （base_pos x/y 变化、z 恒定；base_quat x/y≈0；gripper qpos ~±0.02）。
- zero-shot：`CloseDrawer` **20.0%（4/20）**，`OpenDrawer` 0/10 →
  选择 CloseDrawer 作为 RL 任务。

---

## 5. 训练设置

- 单卡，`component_placement: actor,env,rollout: all`。
- 容器内存 120GB，单个 RoboCasa env 子进程约 7–9GB，且存在每步约 0.5GB 的缓慢增长，
  因此：
  - 每轮 5 个训练 env + 2 个 eval env（eval 每轮跑 5 个 episode，共 10 episodes）；
  - 训练分块进行：每 30 步保存 checkpoint 后重启（`runner.resume_dir`）以重置 env 内存，
    共 3 块（30/60/90），总计 **90 个 PPO iteration**；
  - 每 10 步做一次 in-run eval；每 30 步存 checkpoint（`full_weights.pt`）。
- 单步约 60–80s，单块约 45–50 分钟。

---

## 6. 结果

### 6.1 训练曲线

![reward](fig_reward.png)

![success](fig_success.png)

![training](fig_training.png)

### 6.2 成功率对比

统一评测协议：CloseDrawer，`max_episode_steps=300`，`num_action_chunks=5`，
`num_steps=3`，ODE 采样（与训练 eval 一致），固定 seed 0..N-1，
每个 episode 重建 env（不同厨房布局），成功判定用 `env._check_success()`。

| 策略 | trials | 成功 | 成功率 | Wilson 95% CI |
|---|---|---|---|---|
| SFT baseline | 20 | 4 | 20.0% | [8.1%, 41.6%] |
| FlowSDE step 30 | 20 | 5 | 25.0% | [11.2%, 46.9%] |
| FlowSDE step 60 | 30 | 9 | 30.0% | [16.7%, 47.9%] |
| **FlowSDE step 90** | 50 | 23 | **46.0%** | [33.0%, 59.6%] |

![external](fig_external_success.png)

同 seed 子集（每个 checkpoint 都有 seeds 0–19，唯一严格可比的配对口径）：

| 策略 | seeds 0–19 |
|---|---|
| SFT baseline | 4/20 = 20% |
| FlowSDE step 30 | 5/20 = 25% |
| FlowSDE step 60 | 4/20 = 20% |
| FlowSDE step 90 | 7/20 = 35% |

配对比较：baseline 4/20 vs step90 7/20；不一致对为 baseline 独有 2 个、
step90 独有 5 个（McNemar/Fisher p≈0.48，不显著）。
所有 trials 口径下（baseline n=20 vs step90 n=50）Fisher 精确检验 **p=0.058**。
因此 step 90 的提升方向明确，但受样本量限制，不能声称统计显著。

### 6.3 观察

1. **成功率随训练单调上升**：20.0% → 25.0% → 30.0% → 46.0%。
2. **in-run eval 与外部评测有差距**：训练中的 eval 只有 2 个固定布局 × 5 次重复
   （n=10），波动大且在 0.2–0.6 之间；外部评测覆盖 20–50 个不同布局，更可信。
3. **训练 rollout 成功率（5 个固定布局）偏高**（0.4–0.8），说明策略对布局敏感；
   报告以外部多布局评测为准。
4. **失败模式**：多数失败 episode 跑满 300 步，gripper 动作饱和在 ~1.4（env 侧截断到 1），
   策略会靠近抽屉但无法稳定完成闭合；成功 episode 步数多在 100–300 之间。
5. **value head 从头训练**（`explained_variance` 在 0 附近波动），稀疏奖励 + 300 步
   horizon 下 credit assignment 仍然困难；更长的训练或更好的 value 初始化可能继续提升。

---

## 7. 与官方设置的差异（诚实声明）

1. **起始 checkpoint 非官方**：RLinf 官方 RoboCasa recipe 使用 π0
   `RLinf/RLinf-Pi0-RoboCasa`；本复现按用户要求使用公开的 π0.5 RoboCasa SFT
   checkpoint（`changyeon/...`，100 demos filtered BC），并为其编写了 state/action 适配层。
2. **单卡 + 缩小规模**：官方 recipe 为 1 节点 8 卡、64 envs、global batch 2048；
   本复现单卡、5 train envs、global batch 300。
3. **训练步数**：90 个 PPO iteration（官方未给出 RoboCasa 的固定步数）。
4. **env 内存分块重启**：受 120GB 容器内存限制，每 30 步从 checkpoint 重启
   （共 3 块），优化器状态通过 FSDP dcp checkpoint 恢复。
5. **RoboCasa 资产**：官方 box 链接失效，使用 HF 上的 v0.2 镜像。
6. **零样本评测与训练采样均使用 ODE（eval）**；训练 rollout 使用 FlowSDE 随机采样。

---

## 8. 复现命令

```bash
# 0) 环境（已就绪）
source /root/autodl-tmp/robocasa_rl/env.sh
cd /root/autodl-tmp/code/RLinf

# 1) 环境冒烟
MUJOCO_GL=egl PYOPENGL_PLATFORM=egl ./.venv-robocasa/bin/python \
  /root/autodl-tmp/robocasa_rl/run/gate0_env_smoke.py

# 2) zero-shot 评测
bash /root/autodl-tmp/robocasa_rl/run/20_eval_ckpt.sh \
  /root/autodl-fs/robocasa/models/pi05_robocasa_100demos_s30000/30000 \
  CloseDrawer 20 /root/autodl-tmp/robocasa_rl/logs/eval_base_close20.json

# 3) 分块 FlowSDE PPO 训练（90 iter，3 块）
TOTAL=90 CHUNK=30 bash /root/autodl-tmp/robocasa_rl/run/11_chunked_train.sh

# 4) 评测训练后 checkpoint
bash /root/autodl-tmp/robocasa_rl/run/20_eval_ckpt.sh \
  <log_dir>/flow_sde_closedrawer_pi05/checkpoints/global_step_90/actor \
  CloseDrawer 50 /root/autodl-tmp/robocasa_rl/logs/eval_step90_n50.json

# 5) 曲线
./.venv-robocasa/bin/python /root/autodl-tmp/robocasa_rl/run/plot_curves.py \
  --logdir /root/autodl-tmp/robocasa_rl/logs \
  --outdir /root/autodl-tmp/robocasa_rl/report --baseline 0.20
./.venv-robocasa/bin/python /root/autodl-tmp/robocasa_rl/run/plot_external.py \
  --items "SFT baseline:.../eval_base_close20.json" "step 30:.../eval_step30_n20.json" \
          "step 60:.../eval_step60_n30.json" "step 90:.../eval_step90_n50.json" \
  --out /root/autodl-tmp/robocasa_rl/report/fig_external_success.png
```

---

## 9. 产物

- 起始模型：`/root/autodl-fs/robocasa/models/pi05_robocasa_100demos_s30000/30000`
- 训练 checkpoint（`full_weights.pt`，约 6.96GB / 个）：
  - `<log_dir_1>/flow_sde_closedrawer_pi05/checkpoints/global_step_30/actor/model_state_dict/full_weights.pt`
  - `<log_dir_2>/flow_sde_closedrawer_pi05/checkpoints/global_step_60/actor/model_state_dict/full_weights.pt`
  - `<log_dir_3>/flow_sde_closedrawer_pi05/checkpoints/global_step_90/actor/model_state_dict/full_weights.pt`
- 曲线：`fig_result.png`（总览图：总体 + 同 seed 子集 + Fisher p）、`fig_success.png`（训练/eval 成功率）、`fig_reward.png`（episode return）、
  `fig_training.png`（policy/value loss、grad norm、ratio、explained variance）、
  `fig_external_success.png`（外部评测 + Wilson CI）
- 原始 metrics：`metrics.csv`、`summary.json`
- 外部评测 JSON：`logs/eval_base_close20.json`、`eval_step30_n20.json`、
  `eval_step60_n30.json`、`eval_step90_n50.json`
- 训练日志：`logs/chunked_train.log` 及各 chunk 的 `run.log`
- TensorBoard：`logs/<timestamp>-*/tensorboard/`
- 本报告：`REPORT.md`
