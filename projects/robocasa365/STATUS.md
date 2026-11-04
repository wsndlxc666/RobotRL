# 当前状态

**更新时间**: 2026-11-04 22:45
**阶段**: P3/P4/P5 并行中
**一句话**: 7 任务 baseline 已跑过一轮(n=6),数字方差极大;OpenDrawer 正在跑 FlowSDE 训练。

## Baseline 数字(pi05_pretrain_human300-75k)

| 任务 | n | success_once | 备注 |
|---|---|---|---|
| PickPlaceCounterToCabinet | 6 | 1.000 | 疑似任务过易 |
| SlideDishwasherRack | 6 | 1.000 | 疑似任务过易 |
| OpenDrawer | 48 | 0.167 | 同一任务 n=12 时为 0.417,**方差大/口径不一致** |
| PickPlaceDrawerToCounter | 6 | 0.167 | |
| CloseToasterOvenDoor | 6 | 0.000 | |
| CoffeeSetupMug | 6 | 0.000 | |
| TurnOnMicrowave | 6 | 0.000 | |

> ⚠️ OpenDrawer 的 0.417(n=12)vs 0.167(n=48)差异需要先查明原因再谈训练提升,
> 否则后续对比没有意义。

## 正在进行

- `robocasa365_flowsde_opendrawer_pi05` 训练中(22:43 启动)
  - 日志:`/root/autodl-tmp/RLinf/logs/20261104-22:43:43-robocasa365_flowsde_opendrawer_pi05/`

## 下一步

- [ ] 等训练跑完,按 exp-report 出报告
- [ ] 统一评测口径,重测 OpenDrawer(n ≥ 48,固定 ckpt)
- [ ] 过滤掉 1.0 的"过易任务",避免虚高
- [ ] 清理 `_downloads/*.zip`(11G)

## 阻塞项

- 显存:48 env 时 OOM,目前上限 32
