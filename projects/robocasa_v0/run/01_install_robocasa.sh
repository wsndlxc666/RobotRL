#!/bin/bash
set -e
export UV_DEFAULT_INDEX=http://mirrors.aliyun.com/pypi/simple
NEW=/root/autodl-tmp/RLinf/.venv-robocasa
cd "$NEW/robocasa"
echo "[$(date)] uv pip install ..."
"$NEW/bin/uv" pip install --python "$NEW/bin/python" -e . 2>&1 | tail -40
echo "[$(date)] setup_macros ..."
"$NEW/bin/python" -m robocasa.scripts.setup_macros
echo "[$(date)] versions:"
"$NEW/bin/python" -c "import robosuite, mujoco, numpy; print('robosuite', robosuite.__version__, 'mujoco', mujoco.__version__, 'numpy', numpy.__version__)"
echo "[$(date)] DONE"
