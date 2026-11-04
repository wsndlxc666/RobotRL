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
