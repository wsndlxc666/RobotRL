# 推进日志

> 只追加,不删改历史。每次开工写「目标/计划」,收工写「实际/结论/产出/下一步」。

---

## 2026-10-10 ~ 2026-10-11 — 环境搭建与数据准备

**目标**: 在 A800 上把 RLinf + pi0.5 跑起来,准备 RECAP 所需资产
**计划**: ① clone RLinf + uv 安装 ② 下 pi0.5 base / siglip2 / gemma ③ 下 RECAP 数据集
**实际**:
- RLinf 装好,`import rlinf` 与 ray 正常
- pi05_base 走 jax_to_openpi → openpi_to_openpi_pytorch 两步转换成功
- 数据集体积大,下载耗时
**结论**: 环境可用;转换链条对 reference model 的 lm_head 有依赖,已记录在 PLAN
**下一步**: 跑基线评测

---

## 2026-10-11 — RECAP 四步跑通 + 报告

**目标**: 四步全跑完,得到最终成功率
**计划**: ① Compute Returns ② Value SFT 8000 步 ③ Compute Advantages ④ CFG Training ⑤ 评测 step900/1200/1500
**实际**:
- 四步全部完成,单卡 GPU0 适配无误
- step900 15.0% → step1200 20.0% → step1500 43.3%,单调上升
**结论**: RECAP 在本机复现成立,相对 21.7% 起始策略 +21.6pp;裸 base 0% 说明起点很关键
**产出**: `/autodl-fs/data/recap/report/REPORT.md` + `fig_success.png` `fig_curves.png` `fig_advantage.png`
**下一步**: 项目收尾,转向 RoboCasa
