# Lab Book

机器人学习实验的**唯一真相**。盘上的目录、GitHub 上的仓库、以及每个实验的报告都从这里出发。

- 远程仓库:https://github.com/wsndlxc666/RobotRL
- 本地仓库:`/autodl-fs/data/lab`(跨实例持久)

## 这里放什么

| 放进来 | 不放进来 |
|---|---|
| 计划、状态、日志、实验报告 | 模型权重、数据集、assets |
| 入口脚本、配置、patch | checkpoint、视频、原始日志 |
| 每个实验的指标与结论 | 任何 > 50MB 的文件 |

大文件见 `projects/<name>/manifest.yaml` 的 `artifacts` 段,或在 `artifacts.yaml` 里查。

## 项目

| 项目 | 状态 | 目标 | 最新进展 |
|---|---|---|---|
| [recap](projects/recap/PLAN.md) | done | pi0.5 + RLinf 复现 RECAP 四步,超过 few-shot 基线 | [报告](projects/recap/runs/) |
| [robocasa_v0](projects/robocasa_v0/PLAN.md) | paused | FlowSDE 在 RoboCasa v0 上提升成功率 | [报告](projects/robocasa_v0/runs/) |
| [robocasa365](projects/robocasa365/PLAN.md) | active | pi0.5 在 RoboCasa365 上跑通并评测 | [报告](projects/robocasa365/runs/) |

## 分析报告

| 报告 | 内容 | 日期 |
|---|---|---|
| [benchmark_survey](reports/benchmark_survey/REPORT.md) | LIBERO / RoboCasa v0.2 / RoboCasa365 的任务规模、episode 长度、决策点、能力覆盖对比;含全量任务池 CSV | 2026-11-05 |

## 每个项目的三个文件

- **PLAN.md** — 长期计划:目标、方案、阶段、里程碑。改它 = 改方向。
- **STATUS.md** — 当前快照:做到哪、下一步、阻塞项。每次收工覆盖。
- **LOG.md** — 推进日志:只追加,按日期。每次开工写目标、收工写结论。

## 每次实验

一个实验 = `projects/<proj>/runs/<YYYYMMDD>_<stage>_<tag>/`,内含
`REPORT.md`(目的/设置/结果/结论)、`config.yaml`、`metrics.json`、`figures/`、`artifacts.yaml`。

命名:`<YYYYMMDD>_<project>_<stage>_<tag>`,stage ∈ {train, eval, sft, rl, debug}。

## 常用命令

```bash
lab ls                          # 三个项目一览
lab today robocasa365 "目标"     # 开工:写今日目标
lab run-new robocasa365 eval opendrawer_n48   # 建实验目录
lab sync "commit message"       # 提交并推送到 GitHub
```

环境重建见 `tools/bootstrap.sh`;同步大文件见 `tools/archive.sh`。
