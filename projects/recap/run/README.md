# recap / run

历史入口脚本(从 `/autodl-fs/data/recap/run` 迁移),按执行顺序编号:

| 脚本 | 作用 |
|---|---|
| `1_returns.sh` | Step1 Compute Returns |
| `2_value.sh` | Step2 Value Model SFT |
| `3_adv.sh` | Step3 Compute Advantages |
| `4_cfg.sh` | Step4 CFG Training |
| `5_sft.sh` | 参考 SFT |
| `convert_cfg.sh` | 配置转换 |
| `eval_cfg.sh` / `eval_task0.sh` / `eval_big.sh` | 评测 |

环境变量集中在 `env.sh`。注意:`env.sh` 里的 `$DS` 指向
`/root/autodl-tmp/recap_data/...`,该目录**当前不存在**,复跑前需重新下载数据集。
