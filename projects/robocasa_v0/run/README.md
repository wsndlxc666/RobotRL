# robocasa_v0 / run

历史入口脚本(从 `/root/autodl-tmp/robocasa_rl/run` 迁移):

| 脚本 | 作用 |
|---|---|
| `00_setup_env.sh` | 复制 `.venv` → `.venv-robocasa`,clone 并 editable 安装 robocasa 0.2.0 |
| `01_install_robocasa.sh` | 安装 robocasa |
| `02_download_assets.sh` | 下载 assets |
| `10_train.sh` / `11_chunked_train.sh` / `12_continue_train.sh` | 训练 |
| `13_train_flownoise.sh` / `14_switch_to_flownoise.sh` / `15_upgrade_flownoise.sh` | FlowSDE 相关 |
| `16_eval_flownoise.sh` / `20_eval_ckpt.sh` / `21_eval_all.sh` | 评测 |
| `17_finish_and_shutdown.sh` | 收尾 |
| `gate0_env_smoke.py` / `gate2_state_stats.py` | 环境与状态检查 |
| `patch_obj_sites.py` | 资产修补 |
| `plot_curves.py` / `plot_external.py` | 画图 |
| `prune_ckpt.sh` | 清理 checkpoint |
| `robocasa_eval.py` | 评测实现 |

环境变量见同目录 `env.sh`(`RCAS_*`,已随脚本迁移)。
