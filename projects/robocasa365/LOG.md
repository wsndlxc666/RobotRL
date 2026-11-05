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
