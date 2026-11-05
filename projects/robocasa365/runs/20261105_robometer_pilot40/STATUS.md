# Robometer 40 步 pilot — 当前状态

**更新时间**: 2026-11-05 21:10
**状态**: 运行中（step 7/40）
**预计完成**: 2026-11-05 23:20 左右

## 已完成

- Robometer-4B 权重下载完成（8.90G，两个分片大小与 index 一致）
- 代码 vendor 到 `/root/autodl-tmp/code/robometer`
- 最小 loader 跑通：**missing=0 / unexpected=6**（只有未使用的 `similarity_head`）
- RLinf 奖励接入完成（`history_buffer` + 延迟回填），补齐了 `input_interval>1` 的边界 bug
- 1 个 iteration smoke 通过：
  - 单步 167 秒
  - `reward_model_output` 非零
  - 无 OOM
- 40 步 pilot 于 20:40 启动

## 前 7 步指标

| step | ratio_abs | grad_norm |
|---|---|---|
| 1 | 0.032 | 9.80 |
| 2 | 0.028 | 7.12 |
| 5 | 0.025 | — |
| 7 | 0.028 | 9.08 |

`ratio_abs` 与稀疏版（0.025–0.027）持平，符合 `normalize_advantages=True` 的预期；主判据是成功率，不是 ratio_abs。

## 待做

- [ ] 40 步跑完，保存 step20/step40 ckpt
- [ ] step20、step40 各做 n=50 评测
- [ ] 与 A 组（SFT/20/40 = 0.20/0.18/0.22）对比
- [ ] （可选）Robometer progress vs drawer joint qpos 的 sanity check
- [ ] 写 REPORT.md，决定是否续到 120 步

## 产物

| 类型 | 位置 |
|---|---|
| 配置 | `config.yaml` |
| 补丁 | `patches/robometer_integration.patch` |
| 原始日志 | `/root/autodl-tmp/projects/robocasa365/logs/robometer40.out` |
| ckpt | `.../logs/robocasa365_flowsde_opendrawer_pi05_robometer40/checkpoints/`（step20/40，待生成） |
