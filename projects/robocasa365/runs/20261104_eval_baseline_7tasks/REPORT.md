# 20261104_eval_baseline_7tasks

**日期**: 2026-11-04
**项目**: robocasa365
**类型**: eval
**结论一句话**: 评测管线可用,但 7 个任务的 baseline 数字方差极大,其中 3 个恒为 0、2 个恒为 1.0,OpenDrawer 同任务不同 n 差 2.5 倍——**当前数字不足以支撑后续训练对比**。

## 1. 目的

用 `pi05_pretrain_human300`(75000 步)在 7 个 RoboCasa365 任务上跑 baseline,确认:
① 评测管线是否稳定;② 各任务难度分布;③ 后续 FlowSDE 训练的对比基准。

## 2. 实验设置

| 项 | 值 |
|---|---|
| 代码 | RLinf @ `0067f7d5`;robocasa365 @ `3443cdf3`;robosuite @ `5ce6643f` |
| 权重 | `pi05_pretrain_human300` / multitask_learning/75000 |
| 资产 | `/autodl-fs/data/artifacts/robocasa365/data/assets` |
| 任务 | OpenDrawer, PickPlaceCounterToCabinet, PickPlaceDrawerToCounter, SlideDishwasherRack, TurnOnMicrowave, CloseToasterOvenDoor, CoffeeSetupMug |
| n | 每任务 6;OpenDrawer 另测 48 |
| 环境 | `.venv-robocasa365`;`MUJOCO_GL=egl`;`NUMBA_DISABLE_JIT=1` |
| 命令 | `bash evaluations/run_eval.sh robocasa365 robocasa365_eval_pi05 env.eval.total_num_envs=N "env.eval.task_filter=[\"<task>\"]" env.eval.episode_horizon_source=task_horizon env.eval.max_steps_per_rollout_epoch=1500` |
| 原始日志 | `/root/autodl-tmp/eval_<task>_n<N>.log` |

## 3. 结果

| 任务 | n | success_once | 判断 |
|---|---|---|---|
| PickPlaceCounterToCabinet | 6 | 1.000 | 疑似过易或存在泄漏 |
| SlideDishwasherRack | 6 | 1.000 | 疑似过易或存在泄漏 |
| OpenDrawer | 48 | 0.167 | 与 n=12 的 0.417 矛盾 |
| PickPlaceDrawerToCounter | 6 | 0.167 | 样本不足 |
| CloseToasterOvenDoor | 6 | 0.000 | 样本不足/任务过难 |
| CoffeeSetupMug | 6 | 0.000 | 样本不足/任务过难 |
| TurnOnMicrowave | 6 | 0.000 | 样本不足/任务过难 |

### 异常与疑问

1. **OpenDrawer 口径不一致**:n=12 时 0.417(5/12),n=48 时 0.167(8/48)。两者都不是小样本能解释的偏差,怀疑 ckpt 或 horizon 不同,需核对日志时间与权重。
2. **两个任务恒为 1.0**:先排除初始化/成功判定泄漏,再谈难度。
3. **四个任务恒为 0.0 或 0.167**:n=6 时 0/6 的 95% 置信上界约 39%,**不能据此认定任务失败**,只能说明样本太少。

## 4. 结论

- 评测管线**能跑通**,exit_code 正常。
- baseline **不可用于对比**:n 太小、任务间难度极端、同一任务口径不一致。
- 在修好这三点之前,任何"训练后提升"的结论都不可信。

## 5. 下一步

1. 核对 OpenDrawer n=12 与 n=48 的 ckpt / horizon / 评测时间,确定哪份数字有效。
2. 固定评测口径(同一 ckpt、同一 horizon、同一 n),把有效任务的 n 提到 ≥ 48。
3. 排查 PickPlaceCounterToCabinet / SlideDishwasherRack 恒 1.0 的原因。
4. 用修正后的口径重测,再作为 FlowSDE 的 baseline。

## 6. 产物

- 原始日志:`/root/autodl-tmp/eval_*.log`(待 archive.sh 归档)
- 结构化数字:`metrics.json`
- 本次无 ckpt 产出
