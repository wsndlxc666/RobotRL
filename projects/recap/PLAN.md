# RECAP 复现计划

## 目标

在单卡 A800-80GB 上,以 pi0.5 base 为策略、RLinf 为框架,复现 RECAP
(RL with Experience and Corrections via Advantage-conditioned Policies) 四步离线优化,
在 LIBERO-10 Task 0 上相对 few-shot 基线看到明确提升(官方参考 48.8% → 66.5%,+17.7%)。

## 方案

四步流水线,全部使用官方 demo 设定与官方离线数据,不自行采样:

1. **Compute Returns** — `gamma=1.0`,`failure_reward=-300`,产出 `returns_{tag}.parquet`
2. **Value Model SFT** — SigLIP2-so400m + Gemma3-270m + Critic Expert,8000 步
3. **Compute Advantages** — `positive_quantile=0.3`,`advantage_lookahead_step=10`
4. **CFG Training** — advantage-conditioned pi0.5

tag 链:Step1 `data.tag` → Step2 读;Step3 读 `advantage.returns_tag` 写 `advantage.tag` → Step4 读 `data.advantage_tag`。

## 阶段

| 阶段 | 内容 | 状态 |
|---|---|---|
| P0 | 环境与目录 | done |
| P1 | 克隆并安装 RLinf | done |
| P2 | 资产准备(权重、tokenizer、数据集) | done |
| P3 | 配置注入(单卡、路径) | done |
| P4 | few-shot 基线评测 | done |
| P5 | Step1 Compute Returns | done |
| P6 | Step2 Value SFT | done |
| P7 | Step3 Compute Advantages | done |
| P8 | Step4 CFG Training | done |
| P9 | 最终评测与报告 | done |

## 风险与已知问题

- **数据集当前不在盘上**:`/root/autodl-tmp/recap_data` 已不存在,复跑前必须重新下载。
- 单卡需把 `cluster.component_placement` 全部设为 GPU 0。
- 显存紧张时下调 `actor.micro_batch_size`(32 → 16/8),已开 gradient checkpointing。
- `pi05_base_pytorch` 需两步转换(jax_to_openpi → openpi_to_openpi_pytorch),依赖 reference model 的 lm_head。

## 验收标准

- [x] 四步全部产出 parquet / checkpoint
- [x] 最终评测成功率高于 few-shot 基线
- [x] 报告与图落在 `runs/`
