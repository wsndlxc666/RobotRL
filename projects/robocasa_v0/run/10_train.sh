#!/bin/bash
# Launch RLinf embodied RL (FlowSDE PPO) for RoboCasa + pi0.5.
# Usage: bash run/10_train.sh [config] [hydra overrides...]
set -e
source /root/autodl-tmp/robocasa_rl/env.sh
cd "$REPO_PATH"
export PYTHONPATH="$REPO_PATH:${PYTHONPATH}"
export EMBODIED_PATH="$REPO_PATH/examples/embodiment"
export MUJOCO_GL=egl
export PYOPENGL_PLATFORM=egl
export MUJOCO_EGL_DEVICE_ID=0
export ROBOT_PLATFORM=${ROBOT_PLATFORM:-LIBERO}

CONFIG="${1:-robocasa_closedrawer_ppo_openpi_pi05}"
shift || true
TS=$(date +%Y%m%d-%H%M%S)
LOG_DIR="${RCAS_LOGS}/${TS}-${CONFIG}"
mkdir -p "$LOG_DIR"
PY="$REPO_PATH/.venv-robocasa/bin/python"
CMD=("$PY" "$EMBODIED_PATH/train_embodied_agent.py"
     --config-path "$EMBODIED_PATH/config/" --config-name "$CONFIG"
     "runner.logger.log_path=$LOG_DIR" "$@")
printf '%q ' "${CMD[@]}" | tee "$LOG_DIR/run.log"
echo
"${CMD[@]}" 2>&1 | tee -a "$LOG_DIR/run.log"
