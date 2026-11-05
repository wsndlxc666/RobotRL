# robocasa365 项目环境
# 用法: source /autodl-fs/data/lab/projects/robocasa365/env.sh
#   或先 source /root/lab_env.sh,再 lab_use robocasa365

[[ -n "${LAB_ROOT:-}" ]] || source /root/lab_env.sh

export PROJECT=robocasa365
export ROBOCASA_PATH=$CODE/robocasa365
export ROBOCASA_ASSETS_PATH=$ARTIFACTS/robocasa365/data/assets
export REPO_PATH=$CODE/RLinf
export EVALUATIONS_PATH=$REPO_PATH/evaluations
export EMBODIED_PATH=$REPO_PATH/examples/embodiment
export PROJECT_WORK=$WORK/robocasa365
export PROJECT_ARTIFACTS=$ARTIFACTS/robocasa365

export NUMBA_DISABLE_JIT=1

# shellcheck disable=SC1091
source "$CODE/RLinf/.venv-robocasa365/bin/activate"
