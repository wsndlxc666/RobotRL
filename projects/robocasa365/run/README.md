# robocasa365 / run

入口脚本(从 `/root/autodl-tmp` 根目录收敛到这里):

| 脚本 | 作用 |
|---|---|
| `install.sh` | 建 `.venv-robocasa365` 并安装 RLinf embodied + openpi + robocasa365 |
| `dl_365.sh` | 下载 assets 与权重(HF) |
| `unpack_365.sh` | 解压 assets 到 `ROBOCASA_ASSETS_PATH` |
| `run_task_eval.sh` | 单任务评测,用法 `run_task_eval.sh <task> <N> [tag]` |
| `convert_fix.py` | 权重/配置转换修补 |
| `inspect_jax.py` | 检查 jax/GPU |
| `convert_365.log` | 转换过程记录 |

## 必需环境变量

```bash
export ROBOCASA_PATH=/root/autodl-tmp/code/robocasa365
export ROBOCASA_ASSETS_PATH=/autodl-fs/data/artifacts/robocasa365/data/assets
export REPO_PATH=/root/autodl-tmp/code/RLinf
export MUJOCO_GL=egl
export PYOPENGL_PLATFORM=egl
export NUMBA_DISABLE_JIT=1
```

## 标准评测命令

```bash
/autodl-fs/data/lab/tools/run_with_report.sh robocasa365 eval <tag> -- \
  bash /autodl-fs/data/lab/projects/robocasa365/run/run_task_eval.sh <Task> <N> <tag>
```
