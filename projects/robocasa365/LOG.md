# 推进日志

> 只追加,不删改历史。

---

## 2026-11-04 — 环境搭建

**目标**: 装通 robocasa 1.0.1 + robosuite master,能起仿真
**计划**: ① 建 `.venv-robocasa365` ② 装 robocasa365 editable ③ 下 assets/权重
**实际**:
- `requirements/install.sh embodied --model openpi --env robocasa365` 成功
- nbformat 与 `NUMBA_DISABLE_JIT=1` 是必要规避
**结论**: 环境可用;365 需要 robosuite master,不能用 pip 的稳定版
**产出**: run/install.sh、run/dl_365.sh、run/unpack_365.sh

---

## 2026-11-04 — 评测管线打通(baseline)

**目标**: 单任务冒烟 → 7 任务 baseline
**计划**: ① smoke eval ② 逐任务 n=6 ③ OpenDrawer 加量 n=48
**实际**:
- PickPlaceCounterToCabinet / SlideDishwasherRack = 1.0
- OpenDrawer n=12 → 0.417,n=48 → 0.167(**不一致**)
- 其余 4 个任务 0.0 或 0.167
**结论**: 管线能跑;但数字方差大,且同一任务不同 n 差 2.5 倍,先要统一口径
**产出**: `/root/autodl-tmp/eval_*.log`(待归档进 runs/)
**下一步**: 查 OpenDrawer 差异原因;起 FlowSDE 训练

---

## 2026-11-04 22:43 — FlowSDE 训练启动

**目标**: 在 OpenDrawer 上跑 FlowSDE 在线微调
**计划**: ① 确认 baseline ② 起训练 ③ 训练后评测
**实际**: 训练已启动,`robocasa365_flowsde_opendrawer_pi05`;critic 正在学习(explained_variance 仍为负)
**结论**: 待训练收敛后判断
**下一步**: 训练结束 → exp-report 出报告 → 评测

---

## 2026-11-04 23:00 → 2026-11-05 05:50 — FlowSDE 训练(120 步)

**目标**: 在 OpenDrawer 上跑通 FlowSDE 在线微调,看是否高于 baseline
**计划**: ① 120 步训练 ② 每 10 步内置评测 ③ 每 20 步存 ckpt
**实际**:
- 119 次迭代完成,第 120 步存 ckpt 时崩溃
- **原因:磁盘写满**(6 个 16G ckpt 占满 150G,只剩 200K),step_120 只写了一半
- eval(n=10):0.4,0.3,0.7,0.4,0.5,0.5,0.5,0.7,0.4,0.3,0.3,0.8
- 训练成功率(8 env)均值 0.466,无趋势
- critic explained_variance -6.62 → 0.76;actor ratio_abs ~0.026
**结论**: 训练流程跑通,但结果不可用——末次 0.8 是 n=10 的噪声,策略几乎没更新
**产出**: `runs/20261104_train_flowsde_opendrawer_pi05/`
**下一步**: 用统一口径(n≥48)复评 step_100;修 ckpt 保存策略

---

## 2026-11-05 — 目录结构统一

**目标**: 把两块盘整理成统一结构,并把档案同步到 GitHub
**计划**: ① fs 建 artifacts 分层 ② tmp 建 code/projects/cache ③ 修 venv ④ 改路径 ⑤ 验证
**实际**:
- `migrate_layout.sh --apply` 执行成功,4 个 import 全部通过
- 共用权重抽到 `artifacts/shared/models/`
- 旧路径全部留软链
**结论**: 结构统一完成,`/root/autodl-tmp` 根目录只剩 code/projects/cache
**产出**: `https://github.com/wsndlxc666/RobotRL`
**下一步**: 下次开机先跑 `tools/bootstrap.sh all`

---

## 2026-11-05 — step_120 补全 + 全量 n=50 评测

**目标**: 补全昨天爆盘损坏的 step_120;用统一口径评测 SFT/20/40/60/80/100/120
**计划**: ① 用 step_100 带 dcp 续跑 20 步 ② 校验 ckpt ③ 每档 n=50 评测 ④ 出曲线
**实际**:
- 从 `global_step_100` 续跑 101–120,66 分钟完成;`global_step_120` 三件套齐全(dcp 9.18G + 权重 6.96G)
- 101–120:ratio_abs 均值 0.0269、grad_norm 8.75、critic EV 0.671
- n=50:SFT 0.20 / 20 0.18 / 40 0.22 / 60 0.14 / 80 0.20 / 100 0.20 / 120 0.26
- step120 vs SFT:Fisher p=0.635,不显著
- 权重变化:SFT→120 0.169%,100→120 0.009%;变化主要在 value_head bias
**结论**: 120 步内 actor 几乎没动,评测在 SFT 附近波动;稀疏终局奖励是根因
**产出**: `runs/20261105_eval_opendrawer_n50_full/`、`runs/20261105_train_step120_resume/`
**下一步**: 接 Robometer 稠密 progress 奖励

---

## 2026-11-05 — 魔搭归档 + 本地清理

**目标**: 把历史 ckpt 传到 ModelScope,释放本地磁盘
**计划**: ① 建私有 repo ② 传 20/40/60/80/100 权重 ③ 传 120 完整目录 ④ 核对大小 ⑤ 删本地
**实际**:
- repo:`wsndlxc666/robocasa365-opendrawer-flowsde-pi05`(private)
- 20/40/60/80/100 只传 `full_weights.pt`;120 传权重 + dcp
- 远端 7 个文件大小与本地逐字节一致
- 本地删除 20–80(释放 tmp 30G + fs 30G);100/120 保留
- 实测上传约 13 MB/s
- 凭据持久化到 `/autodl-fs/data/.secrets/modelscope/`,bootstrap 自动恢复
**结论**: 归档完成,本地磁盘压力解除
**产出**: ModelScope repo + `run/upload_modelscope.sh`
**下一步**: 后续 120 步 Robometer 训练完成后同样归档

---

## 2026-11-05 — Robometer 接入 + 40 步 pilot

**目标**: 用 Robometer 的逐帧 progress 做稠密信用分配,对比二值 GT success
**计划**: ① 下模型/装代码 ② 最小 loader ③ 接 RLinf history_buffer ④ 1 步 smoke ⑤ 40 步 pilot
**实际**:
- Robometer-4B 下载完成(8.90G),最小 loader missing=0 / unexpected=6
- 新增 `RobometerRewardModel`,注册 `robometer`;修 `input_interval>1` 的 history 边界 bug
- 1 iteration smoke 通过:167s、奖励非零、无 OOM
- 40 步 pilot 20:40 启动,step 7/40;ratio_abs 0.022–0.028(与稀疏版持平,符合 advantage 归一化预期)
- 依赖事故:sentence-transformers 误升级 transformers/numpy,已回滚到 4.57.6 / 2.2.5,RLinf 冒烟通过
**结论**: 接入链路可用;效果待 40 步跑完后的 n=50 对比
**产出**: `runs/20261105_robometer_pilot40/`(PLAN/STATUS/config/patch)
**下一步**: pilot 跑完 → step20/40 n=50 → 与 A 组对比 → 决定是否续 120

---

## 2026-11-06 — 收尾：视频 + 报告

**目标**: 中止 Robometer 120 步训练，导出视频，出收尾报告并关机
**计划**: ① 停训练/自动收尾 ② 导 3 条 SFT 视频 ③ 写 wrapup 报告 ④ push ⑤ shutdown
**实际**:
- 120 步 Robometer 训练在 step ~2 中止（用户决定），未产出 ckpt
- 导出 3 条 SFT OpenDrawer 视频（4 env 拼屏）：
  - seed 7：2/4；seed 11：1/4；seed 13：4/4
- Robometer pilot 最终：step20 0.18 (9/50)、step40 0.12 (6/50)；对照组 0.18/0.22
- 收尾报告：`runs/20261106_wrapup/REPORT.md`
- 脚本归档到 `run/`（评测、上传、Robometer finalize）
**结论**: 本轮结束；稀疏 RL 与 Robometer 40 步 pilot 都没有带来可测提升
**产出**: 3 条视频 + wrapup 报告 + 更新的 STATUS/PLAN
**下一步**: 项目暂停；若继续，先做 Robometer vs drawer qpos 的 sanity check
