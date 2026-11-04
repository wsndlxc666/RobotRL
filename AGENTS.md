# AGENTS.md — 本仓库的协作约定

这个仓库是机器人学习实验的档案库。任何 agent 在这里工作都必须遵守下面的约定,
目的是:**换实例、换会话之后,只看这个仓库就能接着干**。

## 硬性规则

1. **不提交大文件。** 任何 `>50MB` 的文件(权重、checkpoint、视频、数据集、assets)都不进 git。
   用 `artifacts.yaml` 占位,记录 `path / size / sha256 / source`。
2. **每个实验一个目录。** 不允许把结果散落在仓库根或项目根。
   路径固定为 `projects/<proj>/runs/<run_id>/`,命名 `<YYYYMMDD>_<stage>_<tag>`。
3. **三个项目文件必须保持最新。**
   - `PLAN.md` 只在方向变化时改;
   - `STATUS.md` 每次收工覆盖;
   - `LOG.md` 每次开工/收工追加,不删历史。
4. **代码不复制进仓库。** 只记录 repo / commit / patch。本地改动必须导成 `run/patches/*.patch`,
   否则换实例就复现不了。
5. **写报告前先读原始数据。** 不允许凭印象写结论;所有数字必须能追到 `raw/` 或 `metrics.json`。

## 开工流程

```
1. 读 projects/<proj>/PLAN.md      → 项目要干什么
2. 读 projects/<proj>/STATUS.md    → 现在到哪了,下一步是什么
3. 读 projects/<proj>/LOG.md 尾部  → 上次做了什么、踩了什么坑
4. 在 LOG.md 追加今天的「目标/计划」
5. 干活
```

## 收工流程

```
1. 有实验 → 跑 exp-report 流程,生成 runs/<id>/REPORT.md
2. 覆盖 STATUS.md(当前阶段、下一步、阻塞项)
3. 在 LOG.md 追加「实际/结论/产出/下一步」
4. 更新 manifest.yaml 的 runs 索引(如有新实验)
5. git add -A && git commit && git push   ← 用 tools/lab sync
```

## 报告骨架(REPORT.md 必须包含)

```markdown
# <run_id>
## 1. 目的        这次想问什么问题
## 2. 实验设置    代码commit / 权重 / 数据 / 超参 / 环境 / 命令
## 3. 结果        表格 + 图 + 原始数字(样本数 n 必须写)
## 4. 结论        回答第 1 节的问题;没结论就写"无结论,原因:"
## 5. 下一步      具体到下一步跑什么
## 6. 产物        artifacts.yaml 的摘要
```

## 目录职责

| 路径 | 职责 |
|---|---|
| `projects/<p>/PLAN.md` | 长期计划,方向锚点 |
| `projects/<p>/STATUS.md` | 当前状态快照,可被覆盖 |
| `projects/<p>/LOG.md` | 只追加的推进日志 |
| `projects/<p>/manifest.yaml` | 机器可读:代码、环境、资产、入口、实验索引 |
| `projects/<p>/run/` | 可复现入口脚本 + patch |
| `projects/<p>/runs/` | 每个实验一个目录 |
| `shared/models/INDEX.md` | 跨项目共用权重的出处与落盘路径 |
| `tools/` | `lab` 命令、bootstrap、archive、run_with_report |

## 环境分工

- `/autodl-fs/data/lab` — 本仓库(文本、持久、跨实例)
- `/autodl-fs/data/artifacts/<proj>/` — 大文件冷存储(持久、IO 慢)
- `/root/autodl-tmp/code/` — 代码 + venv(快、每实例重建)
- `/root/autodl-tmp/projects/<proj>/` — 正在产生的日志/ckpt(快、可丢)
