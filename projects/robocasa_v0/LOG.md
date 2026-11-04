# 推进日志

> 只追加,不删改历史。

---

## 2026-11-03 — 环境搭建

**目标**: 把 robocasa 0.2.0 装进独立 venv,能跑仿真
**计划**: ① 复制 .venv ② clone RLinf/robocasa ③ pip install -e ④ setup_macros
**实际**: venv 克隆与 editable 安装成功;assets 需单独下载解压
**结论**: `.venv-robocasa` 可用,但源码被装进 venv 内部,目录不直观
**下一步**: 下 assets

---

## 2026-11-03 — 训练与评测(FlowSDE)

**目标**: baseline → 训练 → 评测,看是否提升
**计划**: ① 评 baseline ② 训练到 step90 ③ 评 step90
**实际**:
- baseline 20%
- 训练中最高 80%
- 最终评测 50%,评测最高 60%
**结论**: 有提升(+30pp vs baseline),但 train/eval 差距(80 vs 50)没有解释,可能是 trial 数少
**产出**: `/autodl-fs/data/robocasa/report/REPORT.md`、`ckpt/flow_sde_step90`
**下一步**: 加 trial 复测;但随后转去 robocasa365,项目暂停
