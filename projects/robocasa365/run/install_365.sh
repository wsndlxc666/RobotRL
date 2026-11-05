#!/bin/bash
set -x
source /etc/network_turbo
export no_proxy="$no_proxy,localhost,127.0.0.1,mirrors.aliyun.com,aliyun.com,pypi.org,files.pythonhosted.org"
export UV_CACHE_DIR=/root/autodl-tmp/.uv_cache
export UV_PYTHON_INSTALL_DIR=/root/autodl-tmp/.uv_python
export UV_LINK_MODE=hardlink
export UV_DEFAULT_INDEX=http://mirrors.aliyun.com/pypi/simple
export ROBOCASA_PATH=/root/autodl-tmp/code/robocasa365
export ROBOCASA_ASSETS_PATH=/autodl-fs/data/artifacts/robocasa365/data/assets
export REPO_PATH=/root/autodl-tmp/code/RLinf
export MUJOCO_GL=egl
export PYOPENGL_PLATFORM=egl
cd /root/autodl-tmp/code/RLinf
bash requirements/install.sh embodied --model openpi --env robocasa365 --venv .venv-robocasa365 --no-root
echo INSTALL_DONE_RC=$?
