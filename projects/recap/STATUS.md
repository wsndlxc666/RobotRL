# 当前状态

**更新时间**: 2026-11-04
**阶段**: 已完成(P9)
**一句话**: RECAP 四步跑通,Task0 从 21.7% 提到 43.3%(+21.6pp),复现成立。

## 关键结论

| 策略 | Task 0 成功率 | n |
|---|---|---|
| π0.5 裸 base | 0.0% | 20 |
| 起始策略(RLinf LIBERO SFT) | 21.7% | 60 |
| RECAP step900 | 15.0% | 20 |
| RECAP step1200 | 20.0% | 20 |
| **RECAP step1500** | **43.3%** | 60 |

重要发现:**RECAP 的提升依赖"已经会做任务"的起始策略**。从 0% 的裸 base 出发训练无效,
必须换中等成功率的起点,这与官方起点(48.8% few-shot SFT)的差异一致。

## 已完成

- 四步流水线全部产出 parquet / checkpoint
- 权重落在 `/autodl-fs/data/artifacts/recap/models`(recap_task0_step300~1200、recap_fromsft_step900~1500)
- 报告:历史完整报告见 `/autodl-fs/data/recap/report/REPORT.md`

## 下一步 / 遗留

- [ ] **数据集已不在盘上**(`/root/autodl-tmp/recap_data` 不存在),复跑需重新下载
- [ ] trial 数偏少(20–60),方差大,若要写论文需加量到每档 ≥100
- [ ] 训练日志与中间 ckpt 未归档,只在最终报告里有数字
- [ ] 本项目已收尾,不再推进

## 阻塞项

无(项目已结束)
